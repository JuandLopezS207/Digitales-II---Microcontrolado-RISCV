`timescale 1ns/1ps

//Test bench para my_mcu_guia3.v

module tb_mcu;
  
  // Señales de prueba
  reg  clk;
  reg  rst;
  wire [7:0] PORTA;
  wire [7:0] PORTB;
  reg  [7:0] PORTC;
  
  // Instancia del microcontrolador
  mcu mcuuq (
    .rst(rst),
    .clk(clk),
    .PORTA(PORTA),
    .PORTB(PORTB),
    .PORTC(PORTC)
  );

  // Bloque inicial: aplica estímulos
  integer i;
  initial begin
    // Configurar la generación de archivos de volcado
    $dumpfile("tb_mcu.vcd");
    $dumpvars(0, tb_mcu);
    for(i=0; i<32; i=i+1) $dumpvars(0, mcuuq.cpu.rf.mem[i]);
	  $monitor($time, " PORTA=%d PORTB=%b", PORTA, PORTB);
    

    #0;  clk = 0;
		 rst = 1;
	
    #9;  rst = 0; 
    
    #4000;  //Termina después de X ciclos de reloj

	#16;
    // Fin de la simulación
    $finish;
  end
  
  always
    begin
        #2 clk=!clk;
    end

endmodule
