`timescale 1ns/1ps

module tb_riscv;

    // Señales de prueba
    reg [31:0] instr;
    reg clk;
    reg rst;

    // Instancia del DUT
    riscv uut (
        .clk(clk),
        .rst(rst),
        .instr(instr)
    );

    integer i;
    initial begin
        $dumpfile("tb_riscv.vcd");
        $dumpvars(0, tb_riscv);

        for(i = 0; i < 32; i = i + 1) $dumpvars(0, uut.rv_rf.mem[i]);
        for(i = 0; i < 32; i = i + 1) uut.rv_rf.mem[i] = i;

        $monitor($time, " clk=%b ins=%h x4=%h x5=%h x6=%h x7=%h x8=%h", 
                 clk, instr,
                 uut.rv_rf.mem[4], uut.rv_rf.mem[5], uut.rv_rf.mem[6], uut.rv_rf.mem[7], uut.rv_rf.mem[8]);

        clk = 0; 
        rst = 1;
        #10; 
        rst = 0;

        // 1. ADD: x4 = x3 + x2 = 3 + 2 = 5
        $display("--- add x4, x3, x2 ---");
        instr = 32'b0000000_00010_00011_000_00100_0110011; 
        #16;

        // 2. SUB: x5 = x3 - x2 = 3 - 2 = 1
        $display("--- sub x5, x3, x2 ---");
        instr = 32'b0100000_00010_00011_000_00101_0110011; 
        #16;

        // 3. AND: x6 = x10 & x12 = 10 & 12 = 8
        $display("--- and x6, x10, x12 ---");
        instr = 32'b0000000_01100_01010_111_00110_0110011; 
        #16;

        // 4. OR: x7 = x10 | x12 = 10 | 12 = 14 (0xE)
        $display("--- or x7, x10, x12 ---");
        instr = 32'b0000000_01100_01010_110_00111_0110011; 
        #16;

        // 5. XOR: x8 = x10 ^ x12 = 10 ^ 12 = 6
        $display("--- xor x8, x10, x12 ---");
        instr = 32'b0000000_01100_01010_100_01000_0110011; 
        #16;

        $finish;
    end

    // Generador de reloj
    always #2 clk = ~clk;

endmodule