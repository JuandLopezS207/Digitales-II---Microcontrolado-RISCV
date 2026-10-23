# Prueba de JAL / JALR (llamado y retorno de una función)
#
# void main() {
#   int w = funcion(x,3);
#   while(1) { }
# }
# int funcion(int x, int y) {
#   int z = x+y;
#   return z;
# }
#
# Resultado esperado: a0 (x10) = 12 -> 15, a1 (x11) = 3, ra (x1) = 0x0000000C
# Luego el programa queda en el ciclo infinito "fin"

_main:
    addi a0,x0,12   #Primer parámetro x = 12
    addi a1,x0,3    #Segundo parámetro y = 3
    jal ra, _funcion
fin:
    jal x0, fin

_funcion:
    add a0,a0,a1    #z = x+y
    jalr x0, ra, 0  #return z

