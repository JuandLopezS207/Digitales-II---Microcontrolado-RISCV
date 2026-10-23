# Prueba de los puertos de E/S
# Escribe el número binario 11001010 (0xCA) en la memoria DMEM (posición 100)
# y en PORTB (0x4004), y escribe un 1 en PORTA (0x4000).
#
# Resultado esperado: mem[25] (dirección 100) = 0xCA, PORTB = 0xCA, PORTA = 0x01

_main:
    addi x12, x0, 0B11001010
    addi x13, x0, 1
    sw x12, 100(x0)
    lui x14, 4          # x14 = 0x00004000 (dirección de PORTA)
    sw x12, 4(x14)      # PORTB = 0xCA
    sw x13, 0(x14)      # PORTA = 0x01
fin: bge x0,x0,fin
