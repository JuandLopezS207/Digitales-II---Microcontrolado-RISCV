`timescale 1ns/1ps

module riscv_tb;

    reg clk;
    reg rst;
    reg [31:0] instr;
    
    integer i;

    // Instanciación del DUT (Dispositivo bajo prueba)
    riscv uut (
        .clk(clk),
        .rst(rst),
        .instr(instr)
    );

    // Generador de Reloj (Período de 10ns)
    always begin
        #5 clk = ~clk;
    end

    initial begin
        // Configuración de GTKWave
        $dumpfile("riscv_tb.vcd");
        $dumpvars(0, riscv_tb);
        
        for(i = 0; i < 32; i = i + 1) begin
            $dumpvars(0, uut.rf.mem[i]);
        end

        $monitor("Tiempo=%0t | clk=%b | pc=%h | instr=%h | rd=%d | wdata=%h | wr_en=%b", 
                 $time, clk, uut.pc, instr, uut.rd, uut.wdata, uut.wr_en);

        // Inicialización
        clk = 0;
        rst = 1;
        instr = 32'd0;

        #10;
        rst = 0; // Desactivar reset

        // Estímulo 1: addi a0, x0, 12 (x10 = 12) -> 32'h00c00513
        #10;
        instr = 32'h00c00513; 

        // Estímulo 2: addi a1, x0, 3 (x11 = 3) -> 32'h00300593
        #10;
        instr = 32'h00300593;

        // Estímulo 3: jal ra, 8 (Salto incondicional, guarda PC+4 en ra / x1) -> 32'h008000ef
        #10;
        instr = 32'h008000ef;

        // Estímulo 4: add a0, a0, a1 (Suma x10 + x11 = 15, guarda en x10) -> 32'h00b50533
        #10;
        instr = 32'h00b50533;

        // Estímulo 5: jalr x0, ra, 0 (Retorno usando la dirección guardada en ra) -> 32'h00008067
        #10;
        instr = 32'h00008067;

        #30;
        $finish;
    end

endmodule