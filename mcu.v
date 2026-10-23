// Declaración de la memoria SRAM de datos (DMEM): 4K palabras de 32 bits (16 KBytes)
module sram_32x #(
    parameter WORDS = 4096
) (
    input wire clk,
    input wire [11:0] addr,
    input wire wr_en,
    input wire rd_en,
    input wire [31:0] wr_data,
    output wire [31:0] rd_data
);
    reg [31:0] mem [0:WORDS-1];
    reg [31:0] rd_reg;

    always @(posedge clk) begin
        if (wr_en) begin
            mem[addr] <= wr_data;
        end
        if (rd_en) begin
            rd_reg <= mem[addr];
        end
    end

    // Alta impedancia cuando rd_en no está activo para evitar cortocircuitos en el bus ddata_in
    assign rd_data = rd_en ? rd_reg : 32'bz;
endmodule

//Definición del microcontrolador
module mcu(
    input clk,          //Reloj del microcontrolador
    input rst,          //Reset del microcontrolador
    output [7:0] PORTA, //Puerto A (salida)
    output [7:0] PORTB, //Puerto B (salida)
    input  [7:0] PORTC  //Puerto C (entrada)
    );

    // Buses con la memoria de programa (IMEM)
    wire [31:0] instr; // Instrucción leída
    wire [31:0] iaddr; // Dirección del PC emitida por la CPU

    // Buses con la memoria de datos (DMEM) y los puertos de E/S
    wire [31:0] daddr;     // Bus de direcciones de datos
    wire [31:0] ddata_in;  // Bus de datos (entrada a la CPU)
    wire [31:0] ddata_out; // Bus de datos (salida de la CPU)
    wire dwr_en;           // Señal de escritura (bus de control)
    wire drd_en;           // Señal de lectura (bus de control)

    // Instancia de la CPU RISC-V
    riscv cpu (
        .rst(rst),
        .clk(clk),
        .instr(instr),
        .iaddr(iaddr),
        .daddr(daddr),
        .ddata_in(ddata_in),
        .ddata_out(ddata_out),
        .dwr_en(dwr_en),
        .drd_en(drd_en)
    );

    // Instancia de la Memoria ROM de programa (Sincrónica)
    rom4096x32 IMEM (
        .clk(clk),
        .data(instr),
        .addr(iaddr[13:2])
    );

    // ------------------------------------------------------------------------
    // Decodificadores de dirección (Figura 21)
    // Mapa de memoria de datos:
    //   0000h - 3FFFh : DMEM
    //   4000h         : PORTA (salida)
    //   4004h         : PORTB (salida)
    //   4008h         : PORTC (entrada)
    // ------------------------------------------------------------------------
    wire sel_dmem  = (daddr[31:14] == 18'd0);       // 0000h - 3FFFh
    wire sel_porta = (daddr == 32'h0000_4000);
    wire sel_portb = (daddr == 32'h0000_4004);
    wire sel_portc = (daddr == 32'h0000_4008);

    // Señales de escritura/lectura de cada dispositivo: solo se activa la del
    // dispositivo seleccionado, las demás permanecen inactivas.
    wire dmem_wr_en  = dwr_en & sel_dmem;
    wire dmem_rd_en  = drd_en & sel_dmem;
    wire porta_wr_en = dwr_en & sel_porta;
    wire portb_wr_en = dwr_en & sel_portb;
    wire portc_rd_en = drd_en & sel_portc;

    // Instancia de la Memoria RAM de datos (DMEM)
    sram_32x DMEM (
        .clk(clk),
        .addr(daddr[13:2]), // Ignoramos los dos bits menos significativos por alineación de 4 bytes
        .wr_en(dmem_wr_en),
        .rd_en(dmem_rd_en),
        .wr_data(ddata_out),
        .rd_data(ddata_in)
    );

    // ------------------------------------------------------------------------
    // Puertos de salida PORTA y PORTB: registros conectados en paralelo al bus ddata_out
    // ------------------------------------------------------------------------
    reg [7:0] porta_reg;
    reg [7:0] portb_reg;

    always @(posedge clk) begin
        if (rst) begin
            porta_reg <= 8'd0;
            portb_reg <= 8'd0;
        end else begin
            if (porta_wr_en) porta_reg <= ddata_out[7:0];
            if (portb_wr_en) portb_reg <= ddata_out[7:0];
        end
    end

    assign PORTA = porta_reg;
    assign PORTB = portb_reg;

    // ------------------------------------------------------------------------
    // Puerto de entrada PORTC: buffer triestado conectado en paralelo al bus ddata_in
    // (igual que la DMEM, el dato se captura con el reloj y solo se maneja el bus
    // cuando se está leyendo el puerto)
    // ------------------------------------------------------------------------
    reg [31:0] portc_reg;

    always @(posedge clk) begin
        if (rst)              portc_reg <= 32'd0;
        else if (portc_rd_en) portc_reg <= {24'd0, PORTC};
    end

    assign ddata_in = portc_rd_en ? portc_reg : 32'bz;

endmodule
