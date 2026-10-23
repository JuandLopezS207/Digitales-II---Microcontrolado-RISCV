    #Bootloader para probar el MCU basado en RISC-V
    .section .text
    .balign 16
    .global main

start:
    #Fija el puntero de pila en la última posición de la DMEM
    li sp, 0x3FFF

	#Hace un salto al main
	jal ra,main

_end_start: 
    #Después de retornar del main se queda en un bucle infinito
    bge x0,x0,_end_start
