`timescale 1ns/1ps

module alu_tb;

    // Señales de prueba
    reg [7:0] A;
    reg [7:0] B;
    reg [1:0] op;
    wire [7:0] ALU_out;

    // Instanciación del módulo
    alu uut (
        .A(A),
        .B(B),
        .op(op),
        .ALU_out(ALU_out)
    );

    initial begin
        // Directiva monitor recomendada en la guía
        $monitor("Tiempo = %0d | op = %b | A = %d | B = %d | ALU_out = %d", $time, op, A, B, ALU_out);
        
        // Estímulos
        A = 8'd20; B = 8'd10; op = 2'b00; // Suma (20 + 10 = 30)
        #10;
        op = 2'b01; // Resta (20 - 10 = 10)
        #10;
        op = 2'b10; // AND
        #10;
        op = 2'b11; // OR
        #10;
        
        $finish;
    end

endmodule