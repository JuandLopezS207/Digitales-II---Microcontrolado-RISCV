# Prueba (opcional) del puerto de entrada PORTC (0x4008)
# Lee PORTC y copia el valor leído en PORTA (0x4000).
#
# Con PORTC = 0x3C en el testbench, el resultado esperado es PORTA = 0x3C

_main:
    lui x14, 4          # x14 = 0x00004000 (dirección de PORTA)
    lw  x5, 8(x14)      # x5 = PORTC (0x4008)
    sw  x5, 0(x14)      # PORTA = x5
fin: bge x0,x0,fin
