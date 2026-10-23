`timescale 1ns/1ps

module tb_mcu;

    reg clk;
    reg rst;

    // Puertos del microcontrolador
    wire [7:0] PORTA;
    wire [7:0] PORTB;
    reg  [7:0] PORTC;

    // Tiempo total de simulación en ns (ajústelo según el programa que pruebe)
    localparam SIM_TIME = 20000;

    // Instancia del Microcontrolador
    mcu mcuuq (
        .rst(rst),
        .clk(clk),
        .PORTA(PORTA),
        .PORTB(PORTB),
        .PORTC(PORTC)
    );

    integer i;

    initial begin
        $dumpfile("tb_mcu.vcd");
        $dumpvars(0, tb_mcu);

        // Volcar las 32 posiciones del banco de registros para verlas en GTKWave
        for (i = 0; i < 32; i = i + 1)
            $dumpvars(0, mcuuq.cpu.rf.mem[i]);

        // Volcar las primeras posiciones de la DMEM (por ejemplo la posición 100 -> mem[25])
        for (i = 0; i < 32; i = i + 1)
            $dumpvars(0, mcuuq.DMEM.mem[i]);

        // Muestra en consola cada vez que cambian los puertos A y B
        $timeformat(-9, 0, " ns", 8);
        $monitor("Tiempo=%t | PORTA=%d (%b) | PORTB=%d (%b)", $time, PORTA, PORTA, PORTB, PORTB);

        clk = 0;
        rst = 1;
        PORTC = 8'h3C; // Valor de entrada de ejemplo (se usa en test_portc.s)

        #93;
        rst = 0; // Se libera el reset a los 93ns

        #SIM_TIME;
        $finish;
    end

    // Reloj con período de 4ns (2ns en alto / 2ns en bajo)
    always begin
        #2 clk = !clk;
    end

endmodule
