#include <stdint.h>

#define PORTA (*(volatile int32_t *)(0x4000))
#define PORTB (*(volatile int32_t *)(0x4004))
#define PORTC (*(volatile int32_t *)(0x4008))

int32_t count;
int32_t val;

void main() {
  count = 0;
  val = 1;
  while(1) {
    count++;
    PORTA = count;
    val = val << 1;
    if (val==256) val = 1;
    PORTB = val;
  }
}
