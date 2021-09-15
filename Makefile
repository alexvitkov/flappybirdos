flappy.img: flappy.asm
	nasm $< -o $@

.PHONY: run clean

run: flappy.img
	qemu-system-x86_64 $<

clean:
	rm flappy


