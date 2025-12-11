; ============================================
; arquivo: graphics.asm
; rotinas de video e desenho (com sprite generico)
; ============================================

;-------------------------------------------------
; setupVideoMode: configura o modo grafico 13h
; funcao: inicializa modo vga 320x200x256 cores
; parametros de entrada: nenhum
; parametros de saida: modo de video alterado
;-------------------------------------------------
setupVideoMode proc
    mov ax, 0013h           ; define modo de video 13h (320x200, 256 cores)
    int 10h                 ; chama interrupcao de video bios
    ret
setupVideoMode endp

;-------------------------------------------------
; clearBuffer: limpa o buffer de video
; funcao: preenche o buffer com zeros (cor preta)
; parametros de entrada: nenhum
; parametros de saida: buffer limpo
;-------------------------------------------------
clearBuffer proc
    push ax                 ; salva ax
    push cx                 ; salva cx
    push di                 ; salva di
    xor di, di              ; zera di (inicio do buffer)
    xor al, al              ; zera al (cor preta)
    mov cx, 64000           ; define contador para 64000 bytes
    rep stosb               ; preenche buffer com al
    pop di                  ; restaura di
    pop cx                  ; restaura cx
    pop ax                  ; restaura ax
    ret
clearBuffer endp

;-------------------------------------------------
; copyBufferToVideo: copia buffer para tela
; funcao: transfere conteudo do buffer para memoria de video
; parametros de entrada: nenhum
; parametros de saida: tela atualizada
;-------------------------------------------------
copyBufferToVideo proc
    push ds                 ; salva ds
    push ax                 ; salva ax
    push cx                 ; salva cx
    push si                 ; salva si
    push di                 ; salva di
    push es                 ; salva es
    
    mov ax, BUFFER_SEG      ; carrega segmento do buffer
    mov ds, ax              ; define ds para buffer
    xor si, si              ; zera si (inicio do buffer)
    
    mov ax, 0A000h          ; carrega segmento de video vga
    mov es, ax              ; define es para video
    xor di, di              ; zera di (inicio da memoria de video)
    
    mov cx, 32000           ; define contador para 32000 palavras (64000 bytes)
    rep movsw               ; copia palavras de ds:si para es:di
    
    pop es                  ; restaura es
    pop di                  ; restaura di
    pop si                  ; restaura si
    pop cx                  ; restaura cx
    pop ax                  ; restaura ax
    pop ds                  ; restaura ds
    ret
copyBufferToVideo endp

;-------------------------------------------------
; drawGenericSprite: desenha sprite com transparencia
; funcao: renderiza sprite no buffer com suporte a clipping horizontal
; parametros de entrada: [bp+12]=x, [bp+10]=y, [bp+8]=offset, [bp+6]=largura, [bp+4]=altura
; parametros de saida: sprite desenhado no buffer
;-------------------------------------------------
drawGenericSprite proc
    push bp                 ; salva bp
    mov bp, sp              ; define bp
    push ax                 ; salva ax
    push bx                 ; salva bx
    push cx                 ; salva cx
    push si                 ; salva si
    push di                 ; salva di

    mov si, [bp+8]          ; carrega offset do sprite em si

    ; --- clipping x ---
    mov ax, [bp+12]         ; carrega x em ax
    mov cx, [bp+6]          ; carrega largura em cx
    
    ; verifica se x >= 320
    cmp ax, 320             ; compara x com 320
    jge fimDrawGeneric      ; se x >= 320, sai (fora da tela)
    
    ; verifica se x + w > 320 (saiu pela direita)
    mov bx, ax              ; copia x para bx
    add bx, cx              ; soma largura
    cmp bx, 320             ; compara com 320
    jle checkLeftClip       ; se menor ou igual, verifica esquerda
    
    ; recorta largura
    sub bx, 320             ; calcula excesso
    sub cx, bx              ; ajusta largura
    
checkLeftClip:
    ; verifica se x < 0 (assumindo x como signed word)
    cmp ax, 0               ; compara x com 0
    jge calcAddress         ; se x >= 0, calcula endereco
    
    ; se x < 0, precisa pular pixels iniciais do sprite
    ; ex: x = -5. pula 5 pixels do sprite. desenha a partir de x=0.
    ; nova largura = largura + x (ex: 29 + (-5) = 24)
    
    add cx, ax              ; reduz largura
    cmp cx, 0               ; verifica se largura <= 0
    jle fimDrawGeneric      ; se sim, sai
    
    ; ajusta si (offset do sprite) para pular os pixels
    mov bx, ax              ; move x para bx
    neg bx                  ; inverte sinal (positivo)
    add si, bx              ; avanca ponteiro do sprite
    
    mov ax, 0               ; novo x na tela = 0
    
calcAddress:
    ; calcula di = (y * 320) + x
    push ax                 ; salva x ajustado
    mov ax, [bp+10]         ; carrega y
    mov bx, 320             ; carrega 320
    mul bx                  ; multiplica y * 320
    pop bx                  ; recupera x ajustado
    add ax, bx              ; soma x
    mov di, ax              ; move para di

    mov dx, [bp+4]          ; carrega altura em dx
    
    ; precisa saber o "pulo" no sprite ao fim de cada linha
    ; pulo = largura original - largura desenhada
    mov bx, [bp+6]          ; carrega largura original
    sub bx, cx              ; subtrai largura desenhada
    
loopLinhaGenerica:
    push cx                 ; salva largura desenhada
    push di                 ; salva di
    
loopPixelGenerico:
    lodsb                   ; carrega byte de [si]
    cmp al, 0               ; verifica transparencia
    je pularPixelGenerico   ; se 0, pula
    mov es:[di], al         ; desenha pixel
pularPixelGenerico:
    inc di                  ; proximo pixel na tela
    loop loopPixelGenerico  ; loop colunas
    
    pop di                  ; restaura di
    add di, 320             ; proxima linha na tela
    pop cx                  ; restaura largura
    
    ; pula pixels restantes do sprite (se houve clipping)
    add si, bx              ; ajusta si
    
    dec dx                  ; decrementa altura
    jnz loopLinhaGenerica   ; loop linhas

fimDrawGeneric:
    pop di                  ; restaura di
    pop si                  ; restaura si
    pop cx                  ; restaura cx
    pop bx                  ; restaura bx
    pop ax                  ; restaura ax
    pop bp                  ; restaura bp
    ret 10                  ; retorna limpando 10 bytes
drawGenericSprite endp

;-------------------------------------------------
; eraseGenericSprite: apaga sprite do buffer
; funcao: remove sprite desenhando sprite em branco na posicao
; parametros de entrada: [bp+12]=x, [bp+10]=y, [bp+8]=offset, [bp+6]=largura, [bp+4]=altura
; parametros de saida: sprite removido do buffer
;-------------------------------------------------
eraseGenericSprite proc
    push bp                 ; salva bp
    mov bp, sp              ; define bp
    push ax                 ; salva ax
    push bx                 ; salva bx
    push cx                 ; salva cx
    push si                 ; salva si
    push di                 ; salva di

    mov si, [bp+8]          ; carrega offset do sprite

    mov ax, [bp+10]         ; carrega y
    mov bx, 320             ; carrega 320
    mul bx                  ; multiplica y * 320
    add ax, [bp+12]         ; soma x
    mov di, ax              ; move para di

    mov cx, [bp+4]          ; carrega altura
loopLinhaEraseGen:
    push cx                 ; salva altura
    push di                 ; salva di
    
    mov cx, [bp+6]          ; carrega largura
loopPixelEraseGen:
    lodsb                   ; carrega byte
    mov es:[di], al         ; desenha (incluindo 0)
    inc di                  ; proximo pixel
    loop loopPixelEraseGen  ; loop colunas
    
    pop di                  ; restaura di
    add di, 320             ; proxima linha
    pop cx                  ; restaura altura
    loop loopLinhaEraseGen  ; loop linhas

    pop di                  ; restaura di
    pop si                  ; restaura si
    pop cx                  ; restaura cx
    pop bx                  ; restaura bx
    pop ax                  ; restaura ax
    pop bp                  ; restaura bp
    ret 10                  ; retorna limpando 10 bytes
eraseGenericSprite endp


;-------------------------------------------------
; drawSprite: atalho para drawGenericSprite
; funcao: desenha sprite padrao (29x13) com transparencia
; parametros de entrada: [bp+8]=x, [bp+6]=y, [bp+4]=offset
; parametros de saida: sprite desenhado no buffer
;-------------------------------------------------
drawSprite proc
    push bp                 ; salva bp
    mov bp, sp              ; define bp
    
    push [bp+8]             ; x
    push [bp+6]             ; y
    push [bp+4]             ; offset
    push SPRITE_LARGURA     ; largura padrao
    push SPRITE_ALTURA      ; altura padrao
    call drawGenericSprite  ; chama funcao generica
    
    pop bp                  ; restaura bp
    ret 6                   ; retorna limpando 6 bytes
drawSprite endp

;-------------------------------------------------
; eraseSprite: atalho para eraseGenericSprite
; funcao: remove sprite padrao (29x13) do buffer
; parametros de entrada: [bp+8]=x, [bp+6]=y, [bp+4]=offset
; parametros de saida: sprite removido do buffer
;-------------------------------------------------
eraseSprite proc
    push bp                 ; salva bp
    mov bp, sp              ; define bp
    
    push [bp+8]             ; x
    push [bp+6]             ; y
    push [bp+4]             ; offset
    push SPRITE_LARGURA     ; largura padrao
    push SPRITE_ALTURA      ; altura padrao
    call eraseGenericSprite ; chama funcao generica
    
    pop bp                  ; restaura bp
    ret 6                   ; retorna limpando 6 bytes
eraseSprite endp


; (rotinas de fonte: drawCharToBuffer, drawStringToBuffer, drawBoxToBuffer)
; ... (cole o resto do seu graphics.asm existente aqui, sem alteracoes) ...

;-------------------------------------------------
; drawCharToBuffer: desenha caractere 8x8 no buffer
; funcao: renderiza um caractere da fonte ibm bios no buffer
; parametros de entrada: [bp+10]=x, [bp+8]=y, [bp+6]=cor, [bp+4]=caractere
; parametros de saida: caractere desenhado no buffer
;-------------------------------------------------
drawCharToBuffer proc
    push bp                 ; salva bp
    mov bp, sp              ; define bp
    push ax                 ; salva ax
    push bx                 ; salva bx
    push cx                 ; salva cx
    push dx                 ; salva dx
    push si                 ; salva si
    push di                 ; salva di
    
    mov ax, 0               ; zera ax
    mov al, [bp+4]          ; carrega caractere
    mov bl, 8               ; carrega 8 (altura do char)
    mul bl                  ; multiplica
    mov si, ax              ; move para si
    add si, offset IBM_BIOS ; soma offset da fonte

    mov ax, [bp+8]          ; carrega y
    mov bx, 320             ; carrega 320
    mul bx                  ; multiplica
    add ax, [bp+10]         ; soma x
    mov di, ax              ; move para di
    
    mov cl, 8               ; contador de linhas (8)
charLinhaLoop:
    push di                 ; salva inicio da linha
    mov dh, [si]            ; carrega linha do char
    inc si                  ; proxima linha do char
    
    mov ch, 8               ; contador de pixels (8)
charPixelLoop:
    mov al, dh              ; move linha para al
    rol al, 1               ; rotaciona para pegar bit
    mov dh, al              ; salva estado
    
    jnc naoDesenhaPixel     ; se carry=0, nao desenha
    
    mov al, [bp+6]          ; carrega cor
    mov es:[di], al         ; desenha pixel
    
naoDesenhaPixel:
    inc di                  ; proximo pixel na tela
    dec ch                  ; decrementa contador pixels
    jnz charPixelLoop       ; loop pixels
    
    pop di                  ; restaura inicio da linha
    add di, 320             ; proxima linha na tela
    dec cl                  ; decrementa contador linhas
    jnz charLinhaLoop       ; loop linhas

    pop di                  ; restaura di
    pop si                  ; restaura si
    pop dx                  ; restaura dx
    pop cx                  ; restaura cx
    pop bx                  ; restaura bx
    pop ax                  ; restaura ax
    pop bp                  ; restaura bp
    ret 8                   ; retorna limpando 8 bytes
drawCharToBuffer endp

;-------------------------------------------------
; drawStringToBuffer: desenha string no buffer
; funcao: renderiza uma string de caracteres no buffer
; parametros de entrada: [bp+10]=x, [bp+8]=y, [bp+6]=cor, [bp+4]=offset string
; parametros de saida: string desenhado no buffer
;-------------------------------------------------
drawStringToBuffer proc
    push bp                 ; salva bp
    mov bp, sp              ; define bp
    push ax                 ; salva ax
    push bx                 ; salva bx
    push cx                 ; salva cx
    push dx                 ; salva dx
    push si                 ; salva si
    
    mov si, [bp+4]          ; carrega offset da string
    mov dx, [bp+10]         ; carrega x inicial
    
loopStr:
    mov al, [si]            ; carrega caractere
    cmp al, 0               ; verifica fim da string (null terminator)
    je fimStr               ; se 0, fim
    
    push dx                 ; x
    push [bp+8]             ; y
    push [bp+6]             ; cor
    push ax                 ; caractere
    call drawCharToBuffer   ; desenha caractere
    
    inc si                  ; proximo caractere
    add dx, 8               ; avanca x em 8 pixels
    jmp loopStr             ; loop
    
fimStr:
    pop si                  ; restaura si
    pop dx                  ; restaura dx
    pop cx                  ; restaura cx
    pop bx                  ; restaura bx
    pop ax                  ; restaura ax
    pop bp                  ; restaura bp
    ret 8                   ; retorna limpando 8 bytes
drawStringToBuffer endp

;-------------------------------------------------
; drawBoxToBuffer: desenha caixa de texto no buffer
; funcao: renderiza uma caixa retangular com bordas no buffer
; parametros de entrada: [bp+12]=x, [bp+10]=y, [bp+8]=largura, [bp+6]=altura, [bp+4]=cor
; parametros de saida: caixa desenhada no buffer
;-------------------------------------------------
drawBoxToBuffer proc
    push bp                 ; salva bp
    mov bp, sp              ; define bp
    push ax                 ; salva ax
    push bx                 ; salva bx
    push cx                 ; salva cx
    push dx                 ; salva dx
    push si                 ; salva si
    push di                 ; salva di
    
    mov di, [bp+12]         ; x
    mov si, [bp+10]         ; y
    mov bl, [bp+4]          ; cor
    
    mov ax, [bp+8]          ; largura (chars)
    dec ax                  ; ajusta para calculo
    mov ch, 8               ; 8 pixels
    mul ch                  ; largura em pixels
    add ax, di              ; x final
    mov dx, ax              ; dx = x final
    
    mov ax, [bp+6]          ; altura (chars)
    dec ax                  ; ajusta
    mov ch, 8               ; 8 pixels
    mul ch                  ; altura em pixels
    add ax, si              ; y final
    mov cx, ax              ; cx = y final

    ; canto superior esquerdo
    push di
    push si
    push bx
    push 218
    call drawCharToBuffer
    
    ; canto superior direito
    push dx
    push si
    push bx
    push 191
    call drawCharToBuffer
    
    ; canto inferior esquerdo
    push di
    push cx
    push bx
    push 192
    call drawCharToBuffer
    
    ; canto inferior direito
    push dx
    push cx
    push bx
    push 217
    call drawCharToBuffer
    
    ; linhas horizontais
    mov ax, di
    add ax, 8
HLoop:
    cmp ax, dx
    jge HLoopFim
    
    push ax                 ; x
    push si                 ; y (topo)
    push bx                 ; cor
    push 196                ; char '-'
    call drawCharToBuffer
    
    push ax                 ; x
    push cx                 ; y (base)
    push bx                 ; cor
    push 196                ; char '-'
    call drawCharToBuffer
    
    add ax, 8
    jmp HLoop
HLoopFim:

    ; linhas verticais
    mov ax, si
    add ax, 8
VLoop:
    cmp ax, cx
    jge VLoopFim
    
    push di                 ; x (esquerda)
    push ax                 ; y
    push bx                 ; cor
    push 179                ; char '|'
    call drawCharToBuffer
    
    push dx                 ; x (direita)
    push ax                 ; y
    push bx                 ; cor
    push 179                ; char '|'
    call drawCharToBuffer
    
    add ax, 8
    jmp VLoop
VLoopFim:

    pop di                  ; restaura di
    pop si                  ; restaura si
    pop dx                  ; restaura dx
    pop cx                  ; restaura cx
    pop bx                  ; restaura bx
    pop ax                  ; restaura ax
    pop bp                  ; restaura bp
    ret 10                  ; retorna limpando 10 bytes
drawBoxToBuffer endp