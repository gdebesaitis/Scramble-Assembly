; ========================================
; GRAPHICS.ASM - CORRIGIDO
; Fun??es de desenho e manipula??o gr?fica
; ========================================

; ===== LIMPA BUFFER =====
LIMPA_BUFFER PROC NEAR
    PUSH AX
    PUSH CX
    PUSH DI
    PUSH ES
    
    MOV AX, SEG video_buffer
    MOV ES, AX
    MOV DI, OFFSET video_buffer
    XOR AL, AL
    MOV CX, 64000
    REP STOSB
    
    POP ES
    POP DI
    POP CX
    POP AX
    RET
LIMPA_BUFFER ENDP

; ===== COPIA BUFFER PARA V?DEO =====
COPIA_BUFFER_VIDEO PROC NEAR
    PUSH AX
    PUSH CX
    PUSH SI
    PUSH DI
    PUSH DS
    PUSH ES
    
    ; DS:SI = buffer
    MOV AX, SEG video_buffer
    MOV DS, AX
    MOV SI, OFFSET video_buffer
    
    ; ES:DI = v?deo
    MOV AX, 0A000h
    MOV ES, AX
    XOR DI, DI
    
    ; Copiar 64000 bytes
    MOV CX, 32000
    CLD
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
; BX = X, DX = Y, AL = cor
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
    
    PUSH AX
    MOV AX, SEG video_buffer
    MOV ES, AX
    POP AX
    
    PUSH AX
    ; Calcular offset: Y * 320 + X
    MOV AX, DX
    MOV CX, 320
    MUL CX
    ADD AX, BX
    MOV DI, AX
    ADD DI, OFFSET video_buffer
    POP AX
    
    MOV ES:[DI], AL
    
FIM_PIXEL:
    POP ES
    POP DI
    POP DX
    POP BX
    POP AX
    RET
DESENHA_PIXEL_BUF ENDP

; ===== DESENHA SPRITE 29x13 NO BUFFER =====
; BX = X, DX = Y, SI = sprite, AL = cor
DESENHA_SPRITE_BUF PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    PUSH SI
    PUSH ES
    PUSH BP
    
    MOV BP, AX              ; Salvar cor em BP (apenas BL ser? usado)
    
    ; Verificar limites b?sicos
    CMP BX, 320
    JAE FIM_SPRITE_BUF
    CMP DX, 200
    JAE FIM_SPRITE_BUF
    
    ; Configurar ES para buffer
    PUSH DS
    MOV AX, SEG video_buffer
    MOV ES, AX
    POP DS
    
    ; Calcular posi??o inicial: Y * 320 + X
    MOV AX, DX
    MOV CX, 320
    MUL CX
    ADD AX, BX
    ADD AX, OFFSET video_buffer
    MOV DI, AX
    
    ; Desenhar 13 linhas
    MOV CX, 13
    
LOOP_LINHA_SPR:
    PUSH CX
    PUSH DI
    PUSH BX
    
    ; Desenhar 29 pixels da linha
    MOV CX, 29
    
LOOP_PIXEL_SPR:
    ; Verificar limites horizontais
    CMP BX, 320
    JAE SKIP_PIXEL_SPR
    
    ; Carregar byte do sprite
    LODSB
    
    ; Se for 0 (transparente), pular
    CMP AL, 0
    JE SKIP_PIXEL_SPR
    
    ; Desenhar pixel com a cor especificada
    PUSH AX
    MOV AX, BP
    MOV ES:[DI], AL
    POP AX
    
SKIP_PIXEL_SPR:
    INC DI
    INC BX
    LOOP LOOP_PIXEL_SPR
    
    POP BX
    POP DI
    ADD DI, 320
    POP CX
    
    INC DX
    CMP DX, 200
    JAE FIM_SPRITE_BUF
    
    LOOP LOOP_LINHA_SPR
    
FIM_SPRITE_BUF:
    POP BP
    POP ES
    POP SI
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHA_SPRITE_BUF ENDP

; ===== DESENHA LINHA HORIZONTAL =====
; BX = X, DX = Y, CX = comprimento, AL = cor
DESENHA_LINHA_H_BUF PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    PUSH ES
    
    CMP DX, 200
    JAE FIM_LINHA_H
    CMP BX, 320
    JAE FIM_LINHA_H
    
    ; Ajustar comprimento
    PUSH AX
    MOV AX, BX
    ADD AX, CX
    CMP AX, 320
    POP AX
    JBE COMP_OK_H
    MOV CX, 320
    SUB CX, BX
COMP_OK_H:
    
    PUSH AX
    MOV AX, SEG video_buffer
    MOV ES, AX
    POP AX
    
    ; Calcular offset
    PUSH AX
    MOV AX, DX
    PUSH DX
    MOV DX, 320
    MUL DX
    POP DX
    ADD AX, BX
    ADD AX, OFFSET video_buffer
    MOV DI, AX
    POP AX
    
    CLD
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

; ===== DESENHA RET?NGULO =====
; BX = X, DX = Y, CX = largura, AL = altura (via pilha [BP+4]), AH = cor
DESENHA_RETANGULO_BUF PROC NEAR
    PUSH BP
    MOV BP, SP
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV AL, BYTE PTR [BP+4]     ; Altura
    MOV AH, 0
    PUSH AX                     ; Salvar altura
    
LOOP_RET_LIN:
    POP AX
    CMP AL, 0
    JE FIM_RET
    PUSH AX
    
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV AL, BYTE PTR [BP+6]     ; Cor
    CALL DESENHA_LINHA_H_BUF
    
    POP DX
    POP CX
    POP BX
    POP AX
    
    INC DX
    DEC AL
    PUSH AX
    JMP LOOP_RET_LIN
    
FIM_RET:
    POP DX
    POP CX
    POP BX
    POP AX
    POP BP
    RET 2
DESENHA_RETANGULO_BUF ENDP

; ===== DESENHA ESTRELAS =====
; SI = array, CX = quantidade
DESENHA_ESTRELAS_BUF PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
LOOP_EST:
    MOV BX, [SI]
    ADD SI, 2
    MOV DX, [SI]
    ADD SI, 2
    
    MOV AL, 15
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