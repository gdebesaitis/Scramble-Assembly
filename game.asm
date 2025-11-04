.286

DADOS SEGMENT
    ; Posi??es fixas das estrelas (X, Y)
    estrelas DW 30,10,  80,15,  120,25, 200,18, 250,12
             DW 45,40,  95,45,  150,50, 210,55, 280,48
             DW 20,70,  110,75, 160,80, 230,85, 290,78
             DW 50,100, 130,105, 180,110, 240,115, 300,108
             DW 35,130, 85,135, 140,140, 195,145, 270,138
             DW 60,160, 100,165, 170,170, 220,175, 310,168
             DW 25,35,  155,22, 190,60, 265,90, 145,125
             DW 75,55,  185,95, 225,125, 255,155, 40,185
             DW 115,18, 205,38, 235,72, 275,102, 90,142
             DW 135,62, 175,88, 245,118, 285,148, 55,178
    num_estrelas DW 50
    
    ; T?tulo simplificado
    titulo1 DB 'SCRAMBLE', 0
    
    ; Sprites (8x6 pixels cada)
    sprite_nave DB 0,0,1,1,1,1,0,0
                DB 0,1,1,1,1,1,1,0
                DB 1,1,1,1,1,1,1,1
                DB 1,1,1,1,1,1,1,1
                DB 0,1,1,1,1,1,1,0
                DB 0,0,1,1,1,1,0,0
    
    sprite_meteoro DB 0,1,1,1,1,1,0,0
                   DB 1,1,1,1,1,1,1,0
                   DB 1,1,0,1,1,1,1,1
                   DB 1,1,1,1,0,1,1,1
                   DB 1,1,1,1,1,1,1,0
                   DB 0,1,1,1,1,1,0,0
    
    sprite_alien DB 1,0,0,0,0,0,1,0
                 DB 0,1,1,0,1,1,0,0
                 DB 0,0,1,1,1,0,0,0
                 DB 0,0,1,1,1,0,0,0
                 DB 0,1,1,0,1,1,0,0
                 DB 1,0,0,0,0,0,1,0
    
    ; Posi??es dos objetos
    nave_x DW 0
    nave_y DW 70
    meteoro_x DW 312
    meteoro_y DW 90
    alien_x DW 150
    alien_y DW 110
    alien_dir DB 1
    
    ; Menu
    opcao_selecionada DB 0
    menu_jogar DB 'JOGAR', 0
    menu_sair DB 'SAIR', 0
    
    seed DW 12345
DADOS ENDS

BUFFER_SEG SEGMENT
    buffer DB 64000 DUP(0)
BUFFER_SEG ENDS

PILHA SEGMENT STACK
    DW 128 DUP(0)
PILHA ENDS

CODIGO SEGMENT
    ASSUME CS:CODIGO, DS:DADOS, SS:PILHA, ES:BUFFER_SEG
    
INICIO:
    ; Inicializar segmento de dados
    MOV AX, DADOS
    MOV DS, AX
    
    ; Ativar modo de v?deo 13h
    MOV AX, 13h
    INT 10h
    
    ; Gerar posi??o inicial aleat?ria para o alien
    MOV AH, 2Ch
    INT 21h
    MOV seed, DX
    CALL RANDOM
    AND AX, 01FFh
    CMP AX, 312
    JGE POS_ALIEN_OK
    MOV alien_x, AX
POS_ALIEN_OK:

LOOP_PRINCIPAL:
    ; Limpar buffer
    CALL LIMPA_BUFFER
    
    ; Desenhar no buffer
    CALL DESENHA_ESTRELAS_BUF
    CALL DESENHA_SPRITES_BUF
    
    ; Copiar buffer para v?deo (sem flickering)
    CALL COPIA_BUFFER_VIDEO
    
    ; Atualizar posi??es
    CALL ATUALIZA_POSICOES
    
    ; Delay
    CALL DELAY
    
    ; Verificar tecla (sem esperar)
    MOV AH, 1
    INT 16h
    JZ LOOP_PRINCIPAL
    
    ; Ler tecla
    MOV AH, 0
    INT 16h
    
    CMP AH, 48h         ; Seta cima
    JE SETA_CIMA
    CMP AH, 50h         ; Seta baixo
    JE SETA_BAIXO
    CMP AL, 13          ; Enter
    JE ENTER_PRESS
    JMP LOOP_PRINCIPAL
    
SETA_CIMA:
    MOV opcao_selecionada, 0
    JMP LOOP_PRINCIPAL
    
SETA_BAIXO:
    MOV opcao_selecionada, 1
    JMP LOOP_PRINCIPAL
    
ENTER_PRESS:
    CMP opcao_selecionada, 1
    JE SAIR_JOGO
    ; Aqui entra o jogo
    JMP SAIR_JOGO

SAIR_JOGO:
    MOV AX, 3
    INT 10h
    MOV AX, 4C00h
    INT 21h

; ===== LIMPA BUFFER =====
LIMPA_BUFFER PROC NEAR
    PUSH AX
    PUSH CX
    PUSH DI
    PUSH ES
    
    MOV AX, BUFFER_SEG
    MOV ES, AX
    XOR DI, DI
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
    MOV AX, BUFFER_SEG
    MOV DS, AX
    XOR SI, SI
    
    ; ES:DI = v?deo
    MOV AX, 0A000h
    MOV ES, AX
    XOR DI, DI
    
    ; Copiar 64000 bytes
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

; ===== DESENHA ESTRELAS NO BUFFER =====
DESENHA_ESTRELAS_BUF PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    PUSH ES
    
    MOV AX, BUFFER_SEG
    MOV ES, AX
    
    MOV SI, OFFSET estrelas
    MOV CX, num_estrelas
    
LOOP_EST:
    MOV BX, [SI]        ; X
    ADD SI, 2
    MOV DX, [SI]        ; Y
    ADD SI, 2
    
    ; Calcular offset: Y * 320 + X
    MOV AX, DX
    PUSH DX
    MOV DX, 320
    MUL DX
    POP DX
    ADD AX, BX
    MOV DI, AX
    
    MOV BYTE PTR ES:[DI], 15
    
    LOOP LOOP_EST
    
    POP ES
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHA_ESTRELAS_BUF ENDP

; ===== DESENHA T?TULO NO BUFFER =====
DESENHA_TITULO_BUF PROC NEAR
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI
    
    MOV SI, OFFSET titulo1
    MOV DH, 3           ; Linha
    MOV DL, 15          ; Coluna (centralizado)
    MOV BL, 10          ; Verde claro
    CALL DESENHA_STRING_BUF
    
    POP SI
    POP DX
    POP BX
    POP AX
    RET
DESENHA_TITULO_BUF ENDP

; ===== DESENHA STRING NO BUFFER =====
; SI = string, DH = linha, DL = coluna, BL = cor
DESENHA_STRING_BUF PROC NEAR
    PUSH AX
    PUSH DX
    PUSH SI
    
LOOP_STR:
    MOV AL, [SI]
    CMP AL, 0
    JE FIM_STR
    
    PUSH DX
    PUSH SI
    CALL DESENHA_CHAR_BUF
    POP SI
    POP DX
    
    INC SI
    ADD DL, 2           ; Espa?amento entre letras
    JMP LOOP_STR
    
FIM_STR:
    POP SI
    POP DX
    POP AX
    RET
DESENHA_STRING_BUF ENDP

; ===== DESENHA CARACTERE NO BUFFER =====
; AL = char, DH = linha, DL = coluna, BL = cor
DESENHA_CHAR_BUF PROC NEAR
    PUSH AX
    PUSH CX
    PUSH DX
    PUSH DI
    PUSH ES
    
    MOV AX, BUFFER_SEG
    MOV ES, AX
    
    ; Calcular posi??o no buffer
    PUSH AX
    MOV AL, DH
    MOV AH, 0
    MOV CX, 12
    MUL CX
    MOV CX, 320
    MUL CX
    MOV DI, AX
    
    MOV AL, DL
    MOV AH, 0
    MOV CX, 8
    MUL CX
    ADD DI, AX
    POP AX
    
    ; Desenhar bloco 8x12
    MOV CX, 12
LOOP_CH_LIN:
    PUSH CX
    PUSH DI
    
    MOV AL, BL
    MOV CX, 7
    REP STOSB
    
    POP DI
    ADD DI, 320
    POP CX
    LOOP LOOP_CH_LIN
    
    POP ES
    POP DI
    POP DX
    POP CX
    POP AX
    RET
DESENHA_CHAR_BUF ENDP

; ===== DESENHA SPRITES NO BUFFER =====
DESENHA_SPRITES_BUF PROC NEAR
    ; Nave
    MOV BX, nave_x
    MOV DX, nave_y
    MOV SI, OFFSET sprite_nave
    MOV AL, 11
    CALL DESENHA_SPRITE_BUF
    
    ; Meteoro
    MOV BX, meteoro_x
    MOV DX, meteoro_y
    MOV SI, OFFSET sprite_meteoro
    MOV AL, 6
    CALL DESENHA_SPRITE_BUF
    
    ; Alien
    MOV BX, alien_x
    MOV DX, alien_y
    MOV SI, OFFSET sprite_alien
    MOV AL, 12
    CALL DESENHA_SPRITE_BUF
    
    RET
DESENHA_SPRITES_BUF ENDP

; ===== DESENHA SPRITE NO BUFFER =====
; BX = X, DX = Y, SI = sprite, AL = cor
DESENHA_SPRITE_BUF PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    PUSH SI
    PUSH ES
    
    MOV AH, AL          ; Salvar cor em AH
    MOV AX, BUFFER_SEG
    MOV ES, AX
    
    ; Calcular posi??o
    MOV AX, DX
    PUSH DX
    MOV DX, 320
    MUL DX
    POP DX
    ADD AX, BX
    MOV DI, AX
    
    MOV CX, 6           ; 6 linhas
    
LOOP_SPR_Y:
    PUSH CX
    PUSH DI
    
    MOV CX, 8
    
LOOP_SPR_X:
    MOV BL, [SI]
    INC SI
    CMP BL, 0
    JE SKIP_PIX
    
    MOV ES:[DI], AH     ; Usar cor salva em AH
    
SKIP_PIX:
    INC DI
    LOOP LOOP_SPR_X
    
    POP DI
    ADD DI, 320
    POP CX
    LOOP LOOP_SPR_Y
    
    POP ES
    POP SI
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHA_SPRITE_BUF ENDP

; ===== ATUALIZA POSI??ES =====
ATUALIZA_POSICOES PROC NEAR
    ; Nave
    ADD nave_x, 2
    CMP nave_x, 320
    JL NAVE_OK
    MOV nave_x, 0
NAVE_OK:
    
    ; Meteoro
    SUB meteoro_x, 2
    CMP meteoro_x, 0
    JGE METEORO_OK
    MOV meteoro_x, 312
METEORO_OK:
    
    ; Alien
    CMP alien_dir, 1
    JE ALIEN_ESQ
    
    INC alien_x
    CMP alien_x, 312
    JL ALIEN_FIM
    MOV alien_dir, 1
    JMP ALIEN_FIM
    
ALIEN_ESQ:
    DEC alien_x
    CMP alien_x, 0
    JG ALIEN_FIM
    MOV alien_dir, 0
    
ALIEN_FIM:
    RET
ATUALIZA_POSICOES ENDP

; ===== DESENHA MENU NO BUFFER =====
DESENHA_MENU_BUF PROC NEAR
    PUSH AX
    PUSH BX
    PUSH DX
    
    ; Caixa Jogar (centralizada)
    ; Tela 320x200, linha ~140 pixels (linha 11 de 12px cada)
    MOV DH, 11          ; Linha 11 * 12 = 132 pixels
    MOV DL, 16          ; Centralizado (320/2 - 64/2 = ~16)
    MOV CH, 10          ; Largura da caixa
    CMP opcao_selecionada, 0
    JNE COR1
    MOV BL, 12
    JMP CAIXA1
COR1:
    MOV BL, 15
CAIXA1:
    CALL DESENHA_CAIXA_BUF
    
    ; Texto Jogar
    MOV SI, OFFSET menu_jogar
    MOV DH, 12
    MOV DL, 17
    CALL DESENHA_STRING_BUF
    
    ; Caixa Sair (logo abaixo)
    MOV DH, 14          ; Linha 14 * 12 = 168 pixels
    MOV DL, 16
    MOV CH, 10
    CMP opcao_selecionada, 1
    JNE COR2
    MOV BL, 12
    JMP CAIXA2
COR2:
    MOV BL, 15
CAIXA2:
    CALL DESENHA_CAIXA_BUF
    
    ; Texto Sair
    MOV SI, OFFSET menu_sair
    MOV DH, 15
    MOV DL, 18
    CALL DESENHA_STRING_BUF
    
    POP DX
    POP BX
    POP AX
    RET
DESENHA_MENU_BUF ENDP

; ===== DESENHA CAIXA NO BUFFER =====
; DH = linha, DL = coluna, CH = largura, BL = cor
DESENHA_CAIXA_BUF PROC NEAR
    PUSH AX
    PUSH CX
    PUSH DX
    PUSH DI
    PUSH ES
    
    MOV AX, BUFFER_SEG
    MOV ES, AX
    
    ; Calcular posi??o
    MOV AL, DH
    MOV AH, 0
    PUSH CX
    MOV CX, 12
    MUL CX
    MOV CX, 320
    MUL CX
    MOV DI, AX
    
    MOV AL, DL
    MOV AH, 0
    MOV CX, 8
    MUL CX
    ADD DI, AX
    POP CX
    
    ; Linha superior
    PUSH CX
    PUSH DI
    MOV AL, BL
    MOV AH, 0
    MOV CL, CH
    MOV CH, 0
    PUSH CX
    MOV CX, 8
    MUL CX
    MOV CX, AX
    POP AX
    MOV AL, BL
    REP STOSB
    POP DI
    POP CX
    
    ; Laterais (10 linhas do meio)
    PUSH CX
    MOV CX, 10
LOOP_LAT:
    PUSH CX
    ADD DI, 320
    PUSH DI
    
    MOV ES:[DI], BL
    MOV AL, CH
    MOV AH, 0
    PUSH CX
    MOV CX, 8
    MUL CX
    POP CX
    ADD DI, AX
    SUB DI, 1
    MOV ES:[DI], BL
    
    POP DI
    POP CX
    LOOP LOOP_LAT
    POP CX
    
    ; Linha inferior
    ADD DI, 320
    MOV AL, BL
    MOV AH, 0
    MOV CL, CH
    MOV CH, 0
    PUSH CX
    MOV CX, 8
    MUL CX
    MOV CX, AX
    POP AX
    MOV AL, BL
    REP STOSB
    
    POP ES
    POP DI
    POP DX
    POP CX
    POP AX
    RET
DESENHA_CAIXA_BUF ENDP

; ===== DELAY =====
DELAY PROC NEAR
    PUSH CX
    MOV CX, 8000h
DELAY_LOOP:
    LOOP DELAY_LOOP
    POP CX
    RET
DELAY ENDP

; ===== RANDOM =====
RANDOM PROC NEAR
    PUSH DX
    PUSH CX
    MOV AX, seed
    MOV CX, 25173
    MUL CX
    ADD AX, 13849
    MOV seed, AX
    POP CX
    POP DX
    RET
RANDOM ENDP

CODIGO ENDS
END INICIO