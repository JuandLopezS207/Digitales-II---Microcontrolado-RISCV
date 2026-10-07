// Declaración de la memoria SRAM de datos (DMEM)
module sram_32x #(
    parameter WORDS = 1024
) (
    input wire clk,
    input wire [9:0] addr,
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

    // Alta impedancia cuando drd_en no está activo para evitar cortocircuitos
    assign rd_data = rd_en ? rd_reg : 32'bz;
endmodule

module mcu (
    input wire clk, // Reloj del microcontrolador
    input wire rst  // Reset del microcontrolador
);
    // Buses con la memoria de programa (IMEM)
    wire [31:0] instr; // Instrucción leída
    wire [31:0] iaddr; // Dirección del PC emitida por la CPU

    // Buses con la memoria de datos (DMEM)
    wire [31:0] daddr;     // Dirección en la DMEM
    wire [31:0] ddata_in;  // Bus de datos DMEM (entrada)
    wire [31:0] ddata_out; // Bus de datos DMEM (salida)
    wire dwr_en;           // Señal de escritura en DMEM
    wire drd_en;           // Señal de lectura en DMEM

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

    // Instancia de la Memoria RAM de datos (DMEM)
    sram_32x DMEM (
        .clk(clk),
        .addr(daddr[11:2]), // Ignoramos los dos bits menos significativos por alineación de 4 bytes
        .wr_en(dwr_en),
        .rd_en(drd_en),
        .wr_data(ddata_out),
        .rd_data(ddata_in)
    );

endmodule