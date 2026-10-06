`timescale 1ns/1ps

module tb_mcu;

    reg clk;
    reg rst;

    // Instancia del Microcontrolador
    mcu mcuuq (
        .rst(rst),
        .clk(clk)
    );

    integer i;

    initial begin
        $dumpfile("tb_mcu.vcd");
        $dumpvars(0, tb_mcu);

        // Volcar las 32 posiciones del banco de registros para verlas en GTKWave
        for (i = 0; i < 32; i = i + 1)
            $dumpvars(0, mcuuq.cpu.rf.mem[i]);
            
        // NUEVO: Monitorear en consola las señales clave del proceso de fetch y ejecución
        $monitor("Tiempo=%0t | rst=%b | PC=%h | Instruccion leida=%h | Registro x12=%h", 
                 $time, rst, mcuuq.cpu.pc, mcuuq.IMEM.data, mcuuq.cpu.rf.mem[12]);

        clk = 0;
        rst = 1;

        #93;
        rst = 0; // Se libera el reset a los 93ns

        #500; // Damos suficiente tiempo para que se ejecuten todas las instrucciones
        $finish;
    end

    // Reloj con período de 4ns (2ns en alto / 2ns en bajo)
    always begin
        #2 clk = !clk;
    end

endmodule