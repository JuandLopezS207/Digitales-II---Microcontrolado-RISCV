`timescale 1ns/1ps

module riscv_tb;

    // 1. Señales de prueba
    reg clk;
    reg rst;
    reg [31:0] instr;
    
    integer i; // Variable para iterar en el volcado de memoria

    // 2. Instanciación del módulo RISC-V (DUT)
    riscv uut (
        .clk(clk),
        .rst(rst),
        .instr(instr)
    );

    // 3. Generación de la señal de reloj (Período de 10ns)
    always begin
        #5 clk = ~clk;
    end

    // 4. Bloque inicial: configuración y estímulos
    initial begin
        // Configurar la generación de archivos de volcado para Icarus Verilog y GTKWave[cite: 4]
        $dumpfile("riscv_tb.vcd");
        $dumpvars(0, riscv_tb);
        
        // Volcar las variables internas de la memoria del Register File para verlas gráficamente[cite: 4]
        for(i = 0; i < 32; i = i + 1) $dumpvars(0, uut.rv_rf.mem[i]);

        // Muestra en consola los valores de interés cada vez que cambien usando $monitor[cite: 2]
        // Se monitorea la instrucción, el registro destino (rd), la salida de la ALU y la señal de escritura
        $monitor("Tiempo=%0t | clk=%b | instr=%h | rd=%d | alu_out=%d | wr_en=%b", 
                 $time, clk, instr, uut.rd, uut.alu_out, uut.wr_en);

        // Inicialización de señales
        clk = 0;
        rst = 1;
        instr = 32'd0;

        #10;
        rst = 0; // Desactivar reset

        /* PRUEBA DE INSTRUCCIONES TIPO I y TIPO R */
        
        // Estímulo 1: addi x5, x0, 10 (Instrucción Tipo I)
        // imm=10, rs1=0, funct3=000, rd=5, opcode=0010011 -> 32'h00A00293
        #10;
        instr = 32'h00A00293; 

        // Estímulo 2: addi x6, x5, 20 (Instrucción Tipo I)
        // imm=20, rs1=5, funct3=000, rd=6, opcode=0010011 -> 32'h01428313
        #10;
        instr = 32'h01428313;

        // Estímulo 3: add x7, x5, x6 (Instrucción Tipo R)
        // Suma los registros x5 y x6, y guarda en x7 (10 + 20 = 30)
        // funct7=0000000, rs2=6, rs1=5, funct3=000, rd=7, opcode=0110011 -> 32'h006283B3
        #10;
        instr = 32'h006283B3;

        // Estímulo 4: ori x8, x5, 5 (Instrucción Tipo I con operaciones lógicas)
        // Hace un OR entre x5 (valor 10 = 1010) y 5 (0101). Resultado = 15. Guarda en x8
        // imm=5, rs1=5, funct3=110, rd=8, opcode=0010011 -> 32'h0052E413
        #10;
        instr = 32'h0052E413;

        // Estímulo 5: sub x9, x6, x5 (Instrucción Tipo R)
        // Resta x5 de x6, guarda en x9 (20 - 10 = 10)
        // funct7=0100000, rs2=5, rs1=6, funct3=000, rd=9, opcode=0110011 -> 32'h405304B3
        #10;
        instr = 32'h405304B3;

        // Esperar un ciclo adicional para que se registre la última instrucción
        #20;
        $finish; // Fin de la simulación[cite: 2]
    end

endmodule