tres: dd 0x03000000, 0x03000000, 0x03000000, 0x03000000 ; Reversado re loco little endian friendly
_170: dd 0xAA000000, 0xAA000000, 0xAA000000, 0xAA000000 
cientoSesentaYNueve: dd 0xA9000000, 0xA9000000, 0xA9000000, 0xA9000000 
ochentaYCuatro: dd 0x45000000, 0x45000000, 0x45000000, 0x45000000
muchasF: dd 0xFFFF, 0xFFFFF, 0xFFFFF, 0xFFFFF



crema: dd 0x00D6E9EC , 0x00D6E9EC, 0x00D6E9EC, 0x00D6E9EC ; LITTLE ENDIAN
verde: dd 0x006E7000, 0x006E7000, 0x006E7000, 0x006E7000 ; LITTLE ENDIan
rojo: dd 0x004158F4, 0x004158F4, 0x004158F4, 0x004158F4 ; little endian

global tresColores_asm

;void tresColores_asm (unsigned char *src, unsigned char *dst, int width, int height,
;                      int src_row_size, int dst_row_size);

; rdi = *src
; rsi = *dst
; edx = width
; ecx = height
; r8d = src_row_size
; r9d = dst_row_size

tresColores_asm:
push rbp
mov rbp, rsp

; el mov anda ok porque setea parte alta en cero
mov eax, edx
mul ecx
add rax, rdi; en rax termina la imagen

    ; xmm0 = *src
    ciclo_tresColores:
    cmp rdi, rax
    jmp fin_tresColores
    movdqu xmm0, [rdi]; xmm0=|r|g|b|a|...

    movaps xmm1, xmm0
    pslld xmm1, 24; xmm1=|0|0|0|r|...
    movaps xmm2, xmm0
    psrld xmm2, 8; xmm2=|g|b|a|0|...
    pslld xmm2, 24; xmm2=|0|0|0|g|...
    movaps xmm3, xmm0
    psrld xmm3, 16; xmm2=|b|a|0|0|...
    pslld xmm3, 24; xmm2=|0|0|0|b|...
    ;guardo la suma en xmm1
    paddsw xmm1, xmm2; xmm1=|0|0|0|r+g|...
    paddsw xmm1, xmm3; xmm1=|0|0|0|r+g+b|...
    ;xmm1 paso los ints a floats
    movaps xmm7, xmm1
    ; free xmm7
    cvtdq2ps xmm1, xmm7
    ;divido cada suma por 3 parte entera
    movdqu xmm15, [tres]
    divps xmm1, xmm15
    ;vuelvo a int
    cvtps2dq xmm1, xmm1
    ; xmm1 = [0 0 0 W_1 | 0 0 0 W_2 | 0 0 0 W_3 | 0 0 0 W_4] en int
    pcmpgtd xmm1, [cientoSesentaYNueve] ; cada W_i > 169 (>= 170)
    ; en xmm0 algo así [FFFF|0000|FFFF|FFFF] (ej.)
    ; en xmm0 tengo 0 donde elto falsos y -1 donde true
    mov xmm2, [crema]; guardo en otro registro para no perder los valores
    pand xmm2, xmm0 ; me quedo solo con los valores que me dieron true
    ; en xmm2 tengo los valores de "crema" en cada pixel que debería
    mov xmm7, xmm2 ; guardo los valores de xmm2 para usarlos despues
    ; xmm7 = xmm2 = [FFFF|0000|FFFF|FFFF] (ej.)
    ;xmm2 = |0|0|0|r+g+b||...
    pxor xmm0, [muchasF]
    mov xmm4, xmm0
    pcmpgtd xmm1, [ochentaYCuatro]
    ; NOT = 1111 XOR xmmAlgo
    pand xmm4, xmm0
    ; En xmm4 tengo las posiciones que cumplen las 2 condiciones (85<=W<170)
    mov xmm2, [verde]
    pand xmm2, xmm4
    mov xmm8, xmm2
    ; en xmm0 tengo los W >= 85
    ; lo niego y obtengo los W < 85
    pxor xmm0, [muchasF]
    mov xmm2, [rojo]
    pand xmm2, xmm0
    ; y en xmm2 tengo las posiciones que cumplen W < 85

    ; xmm2 = Posiciones Rojas, xmm7 = Posiciones Crema, xmm8 = Posiciones Verdes
    ; xmm1 = Brillos = |0|0|0|(r+g+b)/3|...

    pxor xmm9, xmm9
    punpckhbw xmm9, xmm2
    ; Rojas en words = xmm9, parte "alta", osea los 2 primeros, dword
    pxor xmm10, xmm10
    punpcklbw xmm10, xmm2
    ; Rojas en words = xmm10, parte "baja" los otros 2 que faltan, dword


    mov xmm11, xmm1
    pslldq xmm11, 4 ; lo muevo 4 bytes 
    ; xmm11 = | W | 0 || W | 0 |... dword
    paddw xmm11, xmm1
    ; xmm11 = | W | W || W | W |... dword

    ; Sumo los rojos primero
    pcmpgtd xmm9, 0
    pand xmm0, xmm11
    ; tengo en xmm0 los W's con las posiciones donde hay que sumar
    paddw xmm9, xmm0 
    
    
    ; ahora pasamos a multiplicar cada máscara por 3
    mulss xmm2, 3
    mulss xmm7, 3
    mulss xmm8, 3

    paddw xmm11, xmm2
    paddw xmm11, xmm7
    paddw xmm11, xmm8

    movdqu [rdi], xmm11

    ;sigo iterando
    add rdi, 16; aumento 4 pixeles
    loop ciclo_tresColores

fin_tresColores:

pop rbp
ret
