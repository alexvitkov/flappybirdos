org 0x7c00
bits 16

PIPE_WIDTH EQU 6
PIPE_HOLE EQU 6
FLAPPY_X EQU 20

DIST EQU 30

FULL_BLOCK EQU 0xdb
SKY EQU 0x19db
PIPE_DARK EQU 0xb2dd
PIPE EQU 0x2adb

; uninitialized variables
fill EQU 0x500

start:

    ; load ES with video memory address
    mov AX, 0xB800
    mov ES, AX

    xor AX, AX
    mov SS, AX
    mov DS, AX
    mov SP, 0x7BF0

;;; Make the sky BLue
    mov DI, 80*25 * 2
DrawSky:
    dec DI
    dec DI
    mov word ES:[DI], SKY
    test DI, DI
    jnz DrawSky



;;; Game Loop
NextFrame:
    ; sleep for 33 miliseconds (game runs at 30FPS)
    mov CX, 0
	mov DX, 0xc000
	mov AH, 0x86
	int 0x15

    ; draw pipes
    mov CX, 5
    mov DI, scroll
    mov SI, pipe_height
draw_pipes_loop:
    call draw_pipe_and_move_left
    inc DI
    inc DI
    inc SI
    inc SI
    loop draw_pipes_loop

    ; clear old flappy sprite
    mov BX, flappy_sprite_sky
    call draw_flappy

    ; move flappy
    mov AL, [frame]
    and AL, 0x01
    test AL, 0x01
    jnz skip_move

    inc byte [velocity]

skip_move:

    ; check input
    mov ah, 0x01
    int 16h ; https://www.ctyme.com/intr/rb-1755.htm

    jz no_space

    xor ah, ah
    int 16h
    mov byte [velocity], -6

    ; update entropy
    mov AL, [frame]
    xor AL, [entropy]
    mov [entropy], AL


no_space:
    mov AL, [velocity]
    add [flappy_y], AL

    ; draw new flappy
    mov BX, flappy_sprite
    call draw_flappy

    inc byte [frame]

    mov BX, scroll
    add BL, [next_pipe_to_collide]
    add BL, [next_pipe_to_collide]
    mov BX, [BX]
    sub BX, FLAPPY_X

    cmp BX, 1
    jg not_under_pipe

    cmp BX, -5
    jl next_pipe

    ; we're under pipe, check altitude

    xor AH, AH
    mov AL, [flappy_y] 
    SHR AL, 3          ; shr by 3 to get the row

    mov BX, pipe_height
    add BL, [next_pipe_to_collide]
    add BL, [next_pipe_to_collide]
    mov BX, [BX] ; BX <- height of the current hole

    sub BL, PIPE_HOLE
    cmp BL, AL
    jg crashing

    add BL, PIPE_HOLE
    cmp BL, AL
    jle crashing


not_crashing:
    

    jmp NextFrame

crashing:
    ; crashing
    int 19h

; increment next_pipe_to_collide, modulo 5
next_pipe:
    mov AL, [next_pipe_to_collide]
    inc AL
    cmp AL, 5
    jl loop1
    xor AL, AL
loop1:
    mov [next_pipe_to_collide], al

not_under_pipe:
jmp NextFrame


    
; AL - skip bottom
; BL - skip top
; DI - x
vert_bar:
    cmp DI, 0
    jl vert_bar_ret
    cmp DI, 80
    jge vert_bar_ret
    
    pusha
    shl DI, 1
    add DI, 80*25*2 

    mov AH, 160 ; 80 columns, 2 bytes per column
    mul AH 
    sub DI, AX

    mov AL, BL
    inc AL
    mov AH, 160 ; 80 columns, 2 bytes per column
    mul AH 

vert_bar_loop:
    sub DI, 80 * 2
    cmp DI, AX
    mov word SI, [fill]
    mov word ES:[DI], SI
    jge vert_bar_loop
    popa
vert_bar_ret:
    ret
    

draw_pipe_and_move_left:
    mov word [fill], PIPE
    pusha

    push DI
    mov DI, [DI]

    mov BL, [SI]

    xor AL, AL
    call vert_bar
    inc DI
    call vert_bar
    inc DI
    call vert_bar
    inc DI
    call vert_bar
    inc DI
    mov word [fill], PIPE_DARK
    call vert_bar
    inc DI
    mov word [fill], SKY
    call vert_bar

    mov AL, 25 + PIPE_HOLE
    sub AL, BL
    xor BL, BL

    mov word [fill], SKY
    call vert_bar
    dec DI
    mov word [fill], PIPE_DARK
    call vert_bar
    dec DI
    mov word [fill], PIPE
    call vert_bar
    dec DI
    call vert_bar
    dec DI
    call vert_bar
    dec DI
    call vert_bar
    dec DI


    ; move pipe left
    pop DI
    dec word [DI]

    cmp word [DI], -6
    jg left_skip_wraparound

    mov AL, [entropy]
    shr AL, 4
    add AL, 9
    mov [SI], AL
    add word [DI], DIST*5

left_skip_wraparound:
    popa
    ret



draw_flappy:
    mov AH, [flappy_y] ; get the current Y
    SHR AH, 3          ; shr by 3 to get the row
    mov AL, 160        ; multiply by 160 to get position on screen
    mul AH

    mov DI, FLAPPY_X * 2
    add DI, AX            ; DI - offset in VRAM, DI = X + Row offset

    mov CX, [BX]
    mov word ES:[DI], CX
    add DI, 2
    mov CX, [BX + 2]
    mov word ES:[DI], CX
    add DI, 2
    mov CX, [BX + 4]
    mov word ES:[DI], CX
    ret



;;;
;;; Variables
;;;
scroll:
    dw 90
    dw 90 + DIST
    dw 90 + DIST*2
    dw 90 + DIST*3
    dw 90 + DIST*4

pipe_height:
    dw 9
    dw 24
    dw 19
    dw 11
    dw 22


flappy_y: db 5 * 8
velocity: db 0

flappy_sprite:
    dw 0xf0f8, 0xf0f8, 0x9f10
flappy_sprite_sky:
    dw SKY,SKY,SKY

frame: db 0
entropy: db 0
next_pipe_to_collide: db 0

db (510 - ($ - $$)) dup 0
db 0x55, 0xaa
