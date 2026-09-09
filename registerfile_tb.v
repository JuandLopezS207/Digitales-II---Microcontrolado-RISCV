`timescale 1ns/1ps

module registerfile_tb;

    // Señales de prueba
    reg clk;
    reg wr_en;
    reg [4:0] wr_index;
    reg [31:0] wr_data;
    reg [4:0] rd_index1;
    reg [4:0] rd_index2;
    
    wire [31:0] rd_data1;
    wire [31:0] rd_data2;

    integer i; // Variable para los bucles for

    // Instanciación del módulo (DUT)
    registerfile uut (
        .clk(clk),
        .wr_en(wr_en),
        .wr_index(wr_index),
        .wr_data(wr_data),
        .rd_index1(rd_index1),
        .rd_index2(rd_index2),
        .rd_data1(rd_data1),
        .rd_data2(rd_data2)
    );

    // Bloque inicial: aplica estímulos
    initial begin
        // Configurar la generación de archivos de volcado para Icarus Verilog y GTKWave
        $dumpfile("registerfile_tb.vcd");
        $dumpvars(0, registerfile_tb);
        
        // Volcar las variables internas de la memoria para verlas gráficamente
        for(i = 0; i < 32; i = i + 1) $dumpvars(0, uut.mem[i]);

        // Muestra en consola los valores de interés cada vez que cambien usando $monitor[cite: 1]
        $monitor("Tiempo=%0t | clk=%b | wr_en=%b | wr_index=%d | wr_data=%h || rd_index1=%d -> rd_data1=%h | rd_index2=%d -> rd_data2=%h", 
                 $time, clk, wr_en, wr_index, wr_data, rd_index1, rd_data1, rd_index2, rd_data2);

        // 1. Inicialización de señales
        clk = 0;
        wr_en = 0;
        wr_index = 0;
        wr_data = 0;
        rd_index1 = 0;
        rd_index2 = 0;

        // 2. Prueba de escritura en el registro x5
        #10;
        wr_en = 1;
        wr_index = 5;
        wr_data = 32'hAAAA_BBBB;
        
        // 3. Prueba de escritura en el registro x10
        #10;
        wr_index = 10;
        wr_data = 32'h1111_2222;

        // 4. Prueba de escritura en x0 (No debería modificarse, x0 siempre es cero)[cite: 1]
        #10;
        wr_index = 0;
        wr_data = 32'hFFFF_FFFF;

        // 5. Prueba de lectura dual (Desactivando escritura)
        #10;
        wr_en = 0;
        rd_index1 = 5;   // Debería leer AAAA_BBBB
        rd_index2 = 10;  // Debería leer 1111_2222

        // 6. Prueba de lectura del registro x0
        #10;
        rd_index1 = 0;   // Debería leer 0000_0000

        // Fin de la simulación
        #20;
        $finish; 
    end

    // Generación de la señal de reloj
    always begin
        #5 clk = ~clk;
    end

endmodule