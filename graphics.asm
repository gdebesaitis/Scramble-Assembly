; ============================================
; ARQUIVO: graphics.asm
; Rotinas de v?deo e desenho (com Sprite Gen?rico)
; ============================================

;-------------------------------------------------
; setupVideoMode: Configura o modo gr?fico 13h
;-------------------------------------------------
setupVideoMode proc
    mov ax, 0013h
    int 10h
    ret
setupVideoMode endp

;-------------------------------------------------
; clearBuffer: Limpa o buffer de v?deo
;-------------------------------------------------
clearBuffer proc
    push ax
    push cx
    push di
    xor di, di
    xor al, al
    mov cx, 64000
    rep stosb
    pop di
    pop cx
    pop ax
    ret
clearBuffer endp

;-------------------------------------------------
; copyBufferToVideo: Copia o buffer para a tela
;-------------------------------------------------
copyBufferToVideo proc
    push ds
    push ax
    push cx
    push si
    push di
    push es
    
    mov ax, BUFFER_SEG
    mov ds, ax
    xor si, si
    
    mov ax, 0A000h
    mov es, ax
    xor di, di
    
    mov cx, 32000
    rep movsw
    
    pop es
    pop di
    pop si
    pop cx
    pop ax
    pop ds
    ret
copyBufferToVideo endp

;-------------------------------------------------
; drawGenericSprite: Desenha sprite (com transpar?ncia) NO BUFFER
; [bp+12] = PUSH X
; [bp+10] = PUSH Y
; [bp+8]  = PUSH offset
; [bp+6]  = PUSH Largura
; [bp+4]  = PUSH Altura
;-------------------------------------------------
drawGenericSprite proc
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push si
    push di

    mov si, [bp+8] ; offset do sprite

    ; --- CLIPPING X ---
    mov ax, [bp+12] ; X
    mov cx, [bp+6]  ; Largura
    
    ; Verifica se X >= 320
    cmp ax, 320
    jge fimDrawGeneric ; Totalmente fora a direita
    
    ; Verifica se X + W > 320 (Saiu pela direita)
    mov bx, ax
    add bx, cx
    cmp bx, 320
    jle checkLeftClip
    
    ; Recorta largura
    sub bx, 320 ; bx = excesso
    sub cx, bx  ; cx = nova largura
    
checkLeftClip:
    ; Verifica se X < 0 (Assumindo X como signed word)
    cmp ax, 0
    jge calcAddress
    
    ; Se X < 0, precisa pular pixels iniciais do sprite
    ; Ex: X = -5. Pula 5 pixels do sprite. Desenha a partir de X=0.
    ; Nova Largura = Largura + X (ex: 29 + (-5) = 24)
    
    add cx, ax ; Reduz largura
    cmp cx, 0
    jle fimDrawGeneric ; Totalmente fora a esquerda
    
    ; Ajusta SI (Offset do Sprite) para pular os pixels
    mov bx, ax
    neg bx ; bx = 5 (pixels a pular)
    add si, bx ; Avan?a ponteiro do sprite
    
    mov ax, 0 ; Novo X na tela ? 0
    
calcAddress:
    ; Calcula DI = (Y * 320) + X
    push ax ; Salva X ajustado
    mov ax, [bp+10] ; Y
    mov bx, 320
    mul bx
    pop bx ; Recupera X ajustado
    add ax, bx
    mov di, ax     

    mov dx, [bp+4] ; Altura (usar DX para loop externo)
    
    ; Precisa saber o "pulo" no sprite ao fim de cada linha
    ; Pulo = Largura Original - Largura Desenhada
    mov bx, [bp+6] ; Largura Original
    sub bx, cx     ; Pulo
    
loopLinhaGenerica:
    push cx ; Salva largura desenhada
    push di
    
loopPixelGenerico:
    lodsb
    cmp al, 0
    je pularPixelGenerico
    mov es:[di], al
pularPixelGenerico:
    inc di
    loop loopPixelGenerico
    
    pop di
    add di, 320
    pop cx
    
    ; Pula pixels restantes do sprite (se houve clipping)
    add si, bx
    
    dec dx
    jnz loopLinhaGenerica

fimDrawGeneric:
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    pop bp
    ret 10 ; Limpa 5 par?metros (10 bytes)
drawGenericSprite endp

;-------------------------------------------------
; eraseGenericSprite: Apaga sprite NO BUFFER
; [bp+12] = PUSH X
; [bp+10] = PUSH Y
; [bp+8]  = PUSH offset
; [bp+6]  = PUSH Largura
; [bp+4]  = PUSH Altura
;-------------------------------------------------
eraseGenericSprite proc
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push si
    push di

    mov si, [bp+8] ; offset do sprite

    mov ax, [bp+10] ; Y
    mov bx, 320
    mul bx
    add ax, [bp+12] ; X
    mov di, ax     

    mov cx, [bp+4] ; Altura
loopLinhaEraseGen:
    push cx
    push di
    
    mov cx, [bp+6] ; Largura
loopPixelEraseGen:
    lodsb
    mov es:[di], al ; Desenha (incluindo 0)
    inc di
    loop loopPixelEraseGen
    
    pop di
    add di, 320
    pop cx
    loop loopLinhaEraseGen

    pop di
    pop si
    pop cx
    pop bx
    pop ax
    pop bp
    ret 10 ; Limpa 5 par?metros (10 bytes)
eraseGenericSprite endp


;-------------------------------------------------
; drawSprite: Atalho para drawGenericSprite (29x13)
; [bp+8]  = PUSH X
; [bp+6]  = PUSH Y
; [bp+4]  = PUSH offset
;-------------------------------------------------
drawSprite proc
    push bp
    mov bp, sp
    
    push [bp+8] ; X
    push [bp+6] ; Y
    push [bp+4] ; Offset
    push SPRITE_LARGURA
    push SPRITE_ALTURA
    call drawGenericSprite
    
    pop bp
    ret 6
drawSprite endp

;-------------------------------------------------
; eraseSprite: Atalho para eraseGenericSprite (29x13)
; [bp+8]  = PUSH X
; [bp+6]  = PUSH Y
; [bp+4]  = PUSH offset
;-------------------------------------------------
eraseSprite proc
    push bp
    mov bp, sp
    
    push [bp+8] ; X
    push [bp+6] ; Y
    push [bp+4] ; Offset
    push SPRITE_LARGURA
    push SPRITE_ALTURA
    call eraseGenericSprite
    
    pop bp
    ret 6
eraseSprite endp


; (Rotinas de Fonte: drawCharToBuffer, drawStringToBuffer, drawBoxToBuffer)
; ... (Cole o resto do seu graphics.asm existente aqui, sem altera??es) ...

;-------------------------------------------------
; drawCharToBuffer: Desenha um caractere 8x8 no buffer
;-------------------------------------------------
drawCharToBuffer proc
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov ax, 0
    mov al, [bp+4]
    mov bl, 8
    mul bl
    mov si, ax
    add si, offset IBM_BIOS

    mov ax, [bp+8]
    mov bx, 320
    mul bx
    add ax, [bp+10]
    mov di, ax
    
    mov cl, 8
charLinhaLoop:
    push di
    mov dh, [si]
    inc si
    
    mov ch, 8
charPixelLoop:
    mov al, dh
    rol al, 1
    mov dh, al
    
    jnc naoDesenhaPixel
    
    mov al, [bp+6]
    mov es:[di], al
    
naoDesenhaPixel:
    inc di
    dec ch
    jnz charPixelLoop
    
    pop di
    add di, 320
    dec cl
    jnz charLinhaLoop

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 8
drawCharToBuffer endp

;-------------------------------------------------
; drawStringToBuffer: Desenha string no buffer
;-------------------------------------------------
drawStringToBuffer proc
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov si, [bp+4]
    mov dx, [bp+10]
    
loopStr:
    mov al, [si]
    cmp al, 0
    je fimStr
    
    push dx
    push [bp+8]
    push [bp+6]
    push ax
    call drawCharToBuffer
    
    inc si
    add dx, 8
    jmp loopStr
    
fimStr:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 8
drawStringToBuffer endp

;-------------------------------------------------
; drawBoxToBuffer: Desenha caixa de texto no buffer
;-------------------------------------------------
drawBoxToBuffer proc
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov di, [bp+12]
    mov si, [bp+10]
    mov bl, [bp+4]
    
    mov ax, [bp+8]
    dec ax
    mov ch, 8
    mul ch
    add ax, di
    mov dx, ax
    
    mov ax, [bp+6]
    dec ax
    mov ch, 8
    mul ch
    add ax, si
    mov cx, ax

    push di
    push si
    push bx
    push 218
    call drawCharToBuffer
    
    push dx
    push si
    push bx
    push 191
    call drawCharToBuffer
    
    push di
    push cx
    push bx
    push 192
    call drawCharToBuffer
    
    push dx
    push cx
    push bx
    push 217
    call drawCharToBuffer
    
    mov ax, di
    add ax, 8
HLoop:
    cmp ax, dx
    jge HLoopFim
    
    push ax
    push si
    push bx
    push 196
    call drawCharToBuffer
    
    push ax
    push cx
    push bx
    push 196
    call drawCharToBuffer
    
    add ax, 8
    jmp HLoop
HLoopFim:

    mov ax, si
    add ax, 8
VLoop:
    cmp ax, cx
    jge VLoopFim
    
    push di
    push ax
    push bx
    push 179
    call drawCharToBuffer
    
    push dx
    push ax
    push bx
    push 179
    call drawCharToBuffer
    
    add ax, 8
    jmp VLoop
VLoopFim:

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 10
drawBoxToBuffer endp