bl30.bin.patched: bl30.bin 19ac.bin 7430.bin
	cp $< $@
	dd conv=notrunc bs=1 if=19ac.bin of=$@ seek=$$((0x19ac))
	dd conv=notrunc bs=1 if=7430.bin of=$@ seek=$$((0x7430))

19ac: 19ac.o
	arm-none-eabi-ld -Ttext-segment=0x100019ac $< -o $@

7430: 7430.o
	arm-none-eabi-ld -Ttext-segment=0x10007430 $< -o $@

%.bin: %
	arm-none-eabi-objcopy -O binary $< $@

%.o: %.asm
	arm-none-eabi-as $< -o $@
