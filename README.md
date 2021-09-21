# FlappyBirdOS

![Gameplay](https://alexvitkov.github.io/img/flappy.gif)

This is a boot sector game - the binary fits in 512 bytes (the boot sector of a hard disk). It's written in 16-bit assembly and runs in 80x25 VGA mode. The only requirement is a IBM-style BIOS, it won't work with UEFI.

You can run it with QEMU: `qemu-system-x86_64 -drive file=flappy.img,format=raw`
