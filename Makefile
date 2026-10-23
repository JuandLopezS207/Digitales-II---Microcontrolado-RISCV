#Makefile para compilar un programa en C, sintetizar el microcontrolador basado en RISC-V 
#y simularlo en Icarus Verilog

PYTHON = python
IVERILOG = iverilog
VVP = vvp

FIRMWARE_OBJS = bootloader.o test_program.o
VERILOG_OBJS =  register_file.v alu_guia4.v riscv_guia6.v mcu_guia6.v mcu_guia6_tb.v
TOOLCHAIN_PREFIX = riscv64-unknown-elf-

test: tb_mcu.vvp test_program.hex sram.hex
	$(VVP) $<

tb_mcu.vvp: $(VERILOG_OBJS)
	$(IVERILOG) -o $@ $^
	chmod -x $@

test_program.hex: test_program.bin makehex.py
	$(PYTHON) makehex.py $< 4096 > $@

sram.hex: sram.bin makehex.py
	$(PYTHON) makehex.py $< 4096 > $@

test_program.bin: test_program.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary --only-section=.flash $< $@
	chmod -x $@

sram.bin: test_program.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary --only-section=.sram $< $@
	chmod -x $@

test_program.elf: $(FIRMWARE_OBJS) sections.lds
	$(TOOLCHAIN_PREFIX)gcc -Os -mabi=ilp32 -march=rv32i -ffreestanding -nostdlib -o $@ \
		-Wl,--build-id=none,-Bstatic,-T,sections.lds,-Map,test_program.map,--strip-debug \
		$(FIRMWARE_OBJS) -lgcc
	chmod -x $@

bootloader.o: bootloader.s
	$(TOOLCHAIN_PREFIX)gcc -c -mabi=ilp32 -march=rv32i -o $@ $<

%.o: %.c
	$(TOOLCHAIN_PREFIX)gcc -c -mabi=ilp32 -march=rv32i -Os -ffreestanding -nostdlib -o $@ $<

clean:
	rm -vrf $(FIRMWARE_OBJS) \
		test_program.elf test_program.bin sram.bin test_program.hex sram.hex test_program.map \
		tb_mcu.vvp tb_mcu.vcd
