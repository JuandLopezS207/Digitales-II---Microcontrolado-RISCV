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

    // Instancia de la Memoria ROM de programa
    rom4096x32 IMEM (
        .data(instr),
        .addr(iaddr[13:2]) 
    );

endmodule