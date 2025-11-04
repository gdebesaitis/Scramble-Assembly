; ========================================
; GRAPHICS.ASM
; Fun??es de desenho e manipula??o gr?fica
; ========================================

; ===== LIMPA BUFFER =====
; Fun??o: Limpa todo o buffer de v?deo (preenche com cor 0 - preto)
; Entrada: Nenhuma
; Sa?da: Buffer limpo
; Destr?i: Nenhum (preserva todos os registradores)
LIMPA_BUFFER PROC NEAR
    PUSH AX
    PUSH CX
    PUSH DI
    PUSH ES
    
    MOV AX, BUFFER_SEG
    MOV ES, AX
    XOR DI, DI
    XOR AL, AL          ; Cor preta
    MOV CX, 64000
    REP STOSB
    
    POP ES
    POP DI
    POP CX
    POP AX
    RET
LIMPA_BUFFER ENDP

; ===== COPIA BUFFER PARA V?DEO =====
; Fun??o: Copia o buffer completo para a mem?ria de v?deo
; Entrada: Nenhuma
; Sa?da: Conte?do do buffer copiado para a tela
; Destr?i: Nenhum (preserva todos os registradores)
COPIA_BUFFER_VIDEO PROC NEAR
    PUSH AX
    PUSH CX
    PUSH SI
    PUSH DI
    PUSH DS
    PUSH ES
    
    ; DS:SI = buffer
    MOV AX, BUFFER_SEG
    MOV DS, AX
    XOR SI, SI
    
    ; ES:DI = v?deo
    MOV AX, 0A000h
    MOV ES, AX
    XOR DI, DI
    
    ; Copiar 64000 bytes (32000 words)
    MOV CX, 32000
    REP MOVSW
    
    POP ES
    POP DS
    POP DI
    POP SI
    POP CX
    POP AX
    RET
COPIA_BUFFER_VIDEO ENDP

; ===== DESENHA PIXEL NO BUFFER =====
; Fun??o: Desenha um pixel no buffer
; Entrada: BX = X, DX = Y, AL = cor
; Sa?da: Pixel desenhado no buffer
; Destr?i: Nenhum (preserva todos os registradores)
DESENHA_PIXEL_BUF PROC NEAR
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH DI
    PUSH ES
    
    ; Verificar limites
    CMP BX, 320
    JAE FIM_PIXEL
    CMP DX, 200
    JAE FIM_PIXEL
    
    MOV AH, AL          ; Salvar cor
    MOV AX, BUFFER_SEG
    MOV ES, AX
    
    ; Calcular offset: Y * 320 + X
    MOV AX, DX
    PUSH DX
    MOV DX, 320
    MUL DX
    POP DX
    ADD AX, BX
    MOV DI, AX
    
    MOV AL, AH          ; Restaurar cor
    MOV ES:[DI], AL
    
FIM_PIXEL:
    POP ES
    POP DI
    POP DX
    POP BX
    POP AX
    RET
DESENHA_PIXEL_BUF ENDP

; ===== DESENHA SPRITE NO BUFFER =====
; Fun??o: Desenha um sprite no buffer com clipping
; Entrada: BX = X, DX = Y, SI = offset sprite, CX = largura, 
;          [BP+4] = altura (via pilha), AL = cor
; Sa?da: Sprite desenhado no buffer
; Destr?i: Nenhum (preserva todos os registradores)
; Fun??o: Desenha sprite 29x13 no buffer
; BX = X, DX = Y, SI = sprite, AL = cor
DESENHA_SPRITE_29x13 PROC NEAR
    PUSH BP
    MOV BP, SP
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    PUSH SI
    PUSH ES
    
    MOV AH, AL              ; Salvar cor
    MOV AX, BUFFER_SEG
    MOV ES, AX
    
    ; Calcular posi??o: Y * 320 + X
    MOV AX, DX
    MOV CX, 320
    MUL CX
    ADD AX, BX
    MOV DI, AX
    
    MOV CX, 13              ; 13 linhas
    
LOOP_LINHA:
    PUSH CX
    PUSH DI
    
    MOV CX, 29              ; 29 colunas
    
LOOP_COLUNA:
    LODSB                   ; Carregar byte do sprite
    CMP AL, 0
    JE PULA_PIXEL
    
    ; Verificar limites
    PUSH AX
    MOV AX, DI
    SUB AX, BX              ; Offset atual - offset inicial
    CMP AX, 320
    POP AX
    JAE PULA_PIXEL
    
    MOV AL, AH              ; Usar cor salva
    STOSB
    JMP PROXIMO_PIXEL
    
PULA_PIXEL:
    INC DI
    
PROXIMO_PIXEL:
    LOOP LOOP_COLUNA
    
    POP DI
    ADD DI, 320             ; Pr?xima linha
    POP CX
    LOOP LOOP_LINHA
    
    POP ES
    POP SI
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    POP BP
    RET
DESENHA_SPRITE_29x13 ENDP

; ===== DESENHA SPRITE NO BUFFER =====
; Fun??o: Desenha um sprite 29x13 no buffer com transpar?ncia
; Entrada: BX = X, DX = Y, SI = offset do sprite, AL = cor
; Sa?da: Sprite desenhado no buffer
; Destr?i: Nenhum (preserva todos os registradores)
DESENHA_SPRITE_BUF PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    PUSH SI
    PUSH ES
    
    MOV AH, AL              ; Salvar cor em AH
    
    ; Verificar se sprite est? completamente fora da tela
    CMP BX, 320
    JAE FIM_SPRITE_BUF
    CMP DX, 200
    JAE FIM_SPRITE_BUF
    
    ; Configurar ES para o buffer
    PUSH DS
    MOV AX, BUFFER_SEG
    MOV ES, AX
    POP DS
    
    ; Calcular posi??o inicial no buffer
    ; offset = Y * 320 + X
    MOV AX, DX
    MOV CX, 320
    MUL CX
    ADD AX, BX
    MOV DI, AX              ; DI = offset no buffer
    
    ; Desenhar 13 linhas
    MOV CX, 13              ; Altura do sprite
    
LOOP_LINHA_SPRITE:
    PUSH CX                 ; Salvar contador de linhas
    PUSH DI                 ; Salvar offset da linha
    PUSH BX                 ; Salvar X inicial
    
    ; Desenhar 29 pixels da linha
    MOV CX, 29              ; Largura do sprite
    
LOOP_PIXEL_SPRITE:
    ; Verificar se pixel est? dentro da tela
    CMP BX, 320
    JAE SKIP_PIXEL_SPRITE
    CMP DX, 200
    JAE SKIP_PIXEL_SPRITE
    
    ; Carregar byte do sprite
    LODSB                   ; AL = [SI], SI++
    
    ; Verificar se ? pixel transparente (0)
    CMP AL, 0
    JE SKIP_PIXEL_SPRITE
    
    ; Se n?o for transparente, usar a cor especificada
    MOV AL, AH
    MOV ES:[DI], AL         ; Desenhar pixel no buffer
    
SKIP_PIXEL_SPRITE:
    INC DI                  ; Pr?xima posi??o no buffer
    INC BX                  ; Pr?ximo X
    LOOP LOOP_PIXEL_SPRITE
    
    POP BX                  ; Restaurar X inicial
    POP DI                  ; Restaurar offset da linha
    ADD DI, 320             ; Pr?xima linha no buffer
    POP CX                  ; Restaurar contador de linhas
    
    INC DX                  ; Pr?ximo Y
    LOOP LOOP_LINHA_SPRITE
    
FIM_SPRITE_BUF:
    POP ES
    POP SI
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHA_SPRITE_BUF ENDP

; ===== DESENHA LINHA HORIZONTAL NO BUFFER =====
; Fun??o: Desenha uma linha horizontal
; Entrada: BX = X inicial, DX = Y, CX = comprimento, AL = cor
; Sa?da: Linha desenhada no buffer
; Destr?i: Nenhum (preserva todos os registradores)
DESENHA_LINHA_H_BUF PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    PUSH ES
    
    ; Verificar limites
    CMP DX, 200
    JAE FIM_LINHA_H
    CMP BX, 320
    JAE FIM_LINHA_H
    
    ; Ajustar comprimento se exceder tela
    MOV DI, BX
    ADD DI, CX
    CMP DI, 320
    JBE COMP_OK
    MOV CX, 320
    SUB CX, BX
COMP_OK:
    
    MOV AH, AL
    MOV AX, BUFFER_SEG
    MOV ES, AX
    
    ; Calcular offset
    MOV AX, DX
    PUSH DX
    MOV DX, 320
    MUL DX
    POP DX
    ADD AX, BX
    MOV DI, AX
    
    MOV AL, AH
    REP STOSB
    
FIM_LINHA_H:
    POP ES
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHA_LINHA_H_BUF ENDP

; ===== DESENHA LINHA VERTICAL NO BUFFER =====
; Fun??o: Desenha uma linha vertical
; Entrada: BX = X, DX = Y inicial, CX = altura, AL = cor
; Sa?da: Linha desenhada no buffer
; Destr?i: Nenhum (preserva todos os registradores)
DESENHA_LINHA_V_BUF PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    PUSH ES
    
    ; Verificar limites
    CMP BX, 320
    JAE FIM_LINHA_V
    CMP DX, 200
    JAE FIM_LINHA_V
    
    ; Ajustar altura se exceder tela
    MOV DI, DX
    ADD DI, CX
    CMP DI, 200
    JBE ALTURA_OK
    MOV CX, 200
    SUB CX, DX
ALTURA_OK:
    
    MOV AH, AL
    MOV AX, BUFFER_SEG
    MOV ES, AX
    
    ; Calcular offset
    MOV AX, DX
    PUSH DX
    MOV DX, 320
    MUL DX
    POP DX
    ADD AX, BX
    MOV DI, AX
    
LOOP_LINHA_V:
    MOV AL, AH
    MOV ES:[DI], AL
    ADD DI, 320
    INC DX
    CMP DX, 200
    JAE FIM_LINHA_V
    LOOP LOOP_LINHA_V
    
FIM_LINHA_V:
    POP ES
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHA_LINHA_V_BUF ENDP

; ===== DESENHA RET?NGULO PREENCHIDO NO BUFFER =====
; Fun??o: Desenha um ret?ngulo preenchido
; Entrada: BX = X, DX = Y, CX = largura, [BP+4] = altura, AL = cor
; Sa?da: Ret?ngulo desenhado no buffer
; Destr?i: Nenhum (preserva todos os registradores)
DESENHA_RETANGULO_BUF PROC NEAR
    PUSH BP
    MOV BP, SP
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV AH, [BP+4]      ; Altura
    
LOOP_RET:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    CALL DESENHA_LINHA_H_BUF
    POP DX
    POP CX
    POP BX
    POP AX
    
    INC DX
    DEC AH
    JNZ LOOP_RET
    
    POP DX
    POP CX
    POP BX
    POP AX
    POP BP
    RET 2
DESENHA_RETANGULO_BUF ENDP

; ===== APAGA SPRITE NO BUFFER =====
; Fun??o: Apaga um sprite (desenha ret?ngulo preto)
; Entrada: BX = X, DX = Y, CX = largura, [BP+4] = altura
; Sa?da: ?rea apagada no buffer
; Destr?i: Nenhum (preserva todos os registradores)
APAGA_SPRITE_BUF PROC NEAR
    PUSH BP
    MOV BP, SP
    PUSH AX
    
    MOV AL, 0           ; Cor preta
    PUSH WORD PTR [BP+4] ; Altura
    CALL DESENHA_RETANGULO_BUF
    
    POP AX
    POP BP
    RET 2
APAGA_SPRITE_BUF ENDP

; ===== DESENHA ESTRELAS NO BUFFER =====
; Fun??o: Desenha todas as estrelas de fundo
; Entrada: SI = offset array estrelas, CX = n?mero de estrelas
; Sa?da: Estrelas desenhadas no buffer
; Destr?i: Nenhum (preserva todos os registradores)
DESENHA_ESTRELAS_BUF PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
LOOP_EST:
    MOV BX, [SI]        ; X
    ADD SI, 2
    MOV DX, [SI]        ; Y
    ADD SI, 2
    
    MOV AL, 15          ; Cor branca
    PUSH CX
    PUSH SI
    CALL DESENHA_PIXEL_BUF
    POP SI
    POP CX
    
    LOOP LOOP_EST
    
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHA_ESTRELAS_BUF ENDP