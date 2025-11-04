; ========================================
; MENU_FUNCS.ASM
; Fun??es auxiliares do menu e jogo
; ========================================

; ===== DESENHA ANIMA??ES DO MENU =====
DESENHA_ANIMACOES_MENU PROC NEAR
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI
    
    ; Nave aliada
    MOV BX, anim_nave_x
    MOV DX, 70
    MOV SI, OFFSET sprite_nave_aliada
    MOV AL, 11
    CALL DESENHA_SPRITE_BUF
    
    ; Meteoro
    MOV BX, anim_meteoro_x
    MOV DX, 90
    MOV SI, OFFSET sprite_meteoro
    MOV AL, 6
    CALL DESENHA_SPRITE_BUF
    
    ; Alien
    MOV BX, anim_alien_x
    MOV DX, 110
    MOV SI, OFFSET sprite_nave_alien
    MOV AL, 12
    CALL DESENHA_SPRITE_BUF
    
    POP SI
    POP DX
    POP BX
    POP AX
    RET
DESENHA_ANIMACOES_MENU ENDP

; ===== ATUALIZA ANIMA??ES DO MENU =====
ATUALIZA_ANIMACOES_MENU PROC NEAR
    ; Nave
    ADD anim_nave_x, 2
    CMP anim_nave_x, 320
    JL NAVE_OK_ANIM
    MOV anim_nave_x, 0
NAVE_OK_ANIM:
    
    ; Meteoro
    SUB anim_meteoro_x, 2
    CMP anim_meteoro_x, 0
    JGE METEORO_OK_ANIM
    MOV anim_meteoro_x, 312
METEORO_OK_ANIM:
    
    ; Alien
    CMP anim_alien_dir, 1
    JE ALIEN_ESQ_ANIM
    
    INC anim_alien_x
    CMP anim_alien_x, 312
    JL FIM_ALIEN_ANIM
    MOV anim_alien_dir, 1
    JMP FIM_ALIEN_ANIM
    
ALIEN_ESQ_ANIM:
    DEC anim_alien_x
    CMP anim_alien_x, 0
    JG FIM_ALIEN_ANIM
    MOV anim_alien_dir, 0
    
FIM_ALIEN_ANIM:
    RET
ATUALIZA_ANIMACOES_MENU ENDP

; ===== DESENHA MENU =====
DESENHA_MENU PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Caixa Jogar
    MOV DH, 18
    MOV DL, 14
    MOV CH, 12
    MOV CL, 3
    CMP opcao_selecionada, 0
    JNE COR_JOGAR
    MOV BL, 12
    JMP DESENHA_JOGAR
COR_JOGAR:
    MOV BL, 15
DESENHA_JOGAR:
    CALL DESENHA_CAIXA_BUF
    
    ; Texto Jogar
    MOV SI, OFFSET menu_jogar
    MOV DH, 19
    MOV DL, 16
    MOV BL, 15
    CALL DESENHA_STRING_BUF
    
    ; Caixa Sair
    MOV DH, 22
    MOV DL, 14
    MOV CH, 12
    MOV CL, 3
    CMP opcao_selecionada, 1
    JNE COR_SAIR
    MOV BL, 12
    JMP DESENHA_SAIR
COR_SAIR:
    MOV BL, 15
DESENHA_SAIR:
    CALL DESENHA_CAIXA_BUF
    
    ; Texto Sair
    MOV SI, OFFSET menu_sair
    MOV DH, 23
    MOV DL, 17
    MOV BL, 15
    CALL DESENHA_STRING_BUF
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHA_MENU ENDP

; ===== INICIALIZA JOGO =====
INICIALIZA_JOGO PROC NEAR
    MOV vidas, NUM_VIDAS
    MOV score, 0
    MOV fase_atual, 1
    MOV tempo_restante, TEMPO_FASE
    
    MOV nave_x, 50
    MOV nave_y, 90
    
    ; Limpar tiros
    MOV CX, MAX_TIROS
    MOV SI, OFFSET tiros_ativos
LMP_TIROS_INIT:
    MOV BYTE PTR [SI], 0
    INC SI
    LOOP LMP_TIROS_INIT
    
    ; Limpar inimigos
    MOV CX, MAX_INIMIGOS
    MOV SI, OFFSET inimigos_ativos
LMP_INIM_INIT:
    MOV BYTE PTR [SI], 0
    INC SI
    LOOP LMP_INIM_INIT
    
    RET
INICIALIZA_JOGO ENDP

; ===== LOOP DO JOGO =====
LOOP_JOGO PROC NEAR
    ; Mostrar tela de apresenta??o
    CALL TELA_APRESENTACAO_FASE
    
LOOP_FASE_GAME:
    CALL LIMPA_BUFFER
    
    ; Desenhar elementos
    CALL DESENHA_ESTRELAS_FASE
    CALL DESENHA_SUPERFICIE
    CALL DESENHA_NAVE_ALIADA
    CALL DESENHA_TIROS
    CALL DESENHA_INIMIGOS
    CALL DESENHA_STATUS
    
    CALL COPIA_BUFFER_VIDEO
    
    ; Atualizar l?gica
    CALL ATUALIZA_LOGICA_JOGO
    CALL VERIFICA_COLISOES
    
    CALL DELAY
    CALL PROCESSA_INPUT
    
    ; Verificar fim
    CMP tempo_restante, 0
    JE FIM_FASE_ATUAL
    CMP vidas, 0
    JE PERDEU_JOGO
    
    JMP LOOP_FASE_GAME
    
FIM_FASE_ATUAL:
    INC fase_atual
    CMP fase_atual, 4
    JE GANHOU_JOGO
    MOV tempo_restante, TEMPO_FASE
    JMP LOOP_FASE_GAME
    
PERDEU_JOGO:
    MOV estado_jogo, 0
    RET
    
GANHOU_JOGO:
    MOV estado_jogo, 0
    RET
LOOP_JOGO ENDP

; ===== FUN??ES STUB =====
TELA_APRESENTACAO_FASE PROC NEAR
    PUSH CX
    MOV CX, 4
DELAY_APRES:
    PUSH CX
    CALL DELAY
    POP CX
    LOOP DELAY_APRES
    POP CX
    RET
TELA_APRESENTACAO_FASE ENDP

DESENHA_ESTRELAS_FASE PROC NEAR
    RET
DESENHA_ESTRELAS_FASE ENDP

DESENHA_SUPERFICIE PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV DX, 180
    MOV BX, 0
    MOV CX, 320
    MOV AL, 6
    CALL DESENHA_LINHA_H_BUF
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHA_SUPERFICIE ENDP

DESENHA_NAVE_ALIADA PROC NEAR
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI
    
    MOV BX, nave_x
    MOV DX, nave_y
    MOV SI, OFFSET sprite_nave_aliada
    MOV AL, 11
    CALL DESENHA_SPRITE_BUF
    
    POP SI
    POP DX
    POP BX
    POP AX
    RET
DESENHA_NAVE_ALIADA ENDP

DESENHA_TIROS PROC NEAR
    RET
DESENHA_TIROS ENDP

DESENHA_INIMIGOS PROC NEAR
    RET
DESENHA_INIMIGOS ENDP

DESENHA_STATUS PROC NEAR
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI
    
    MOV SI, OFFSET texto_score
    MOV DH, 0
    MOV DL, 1
    MOV BL, 15
    CALL DESENHA_STRING_BUF
    
    MOV SI, OFFSET texto_tempo
    MOV DH, 0
    MOV DL, 30
    MOV BL, 15
    CALL DESENHA_STRING_BUF
    
    POP SI
    POP DX
    POP BX
    POP AX
    RET
DESENHA_STATUS ENDP

ATUALIZA_LOGICA_JOGO PROC NEAR
    RET
ATUALIZA_LOGICA_JOGO ENDP

VERIFICA_COLISOES PROC NEAR
    RET
VERIFICA_COLISOES ENDP

PROCESSA_INPUT PROC NEAR
    PUSH AX
    PUSH BX
    
    MOV AH, 01h
    INT 16h
    JZ FIM_INPUT_GAME
    
    MOV AH, 00h
    INT 16h
    
    CMP AH, 01h
    JNE VERIFICA_SETAS
    MOV estado_jogo, 0
    JMP FIM_INPUT_GAME
    
VERIFICA_SETAS:
    CMP AH, 48h
    JNE NAO_CIMA
    MOV BX, nave_y
    SUB BX, 2
    CMP BX, 10
    JL NAO_CIMA
    MOV nave_y, BX
NAO_CIMA:

    CMP AH, 50h
    JNE NAO_BAIXO
    MOV BX, nave_y
    ADD BX, 2
    CMP BX, 165
    JG NAO_BAIXO
    MOV nave_y, BX
NAO_BAIXO:

    CMP AH, 4Dh
    JNE NAO_DIREITA
    MOV BX, nave_x
    ADD BX, 2
    CMP BX, 290
    JG NAO_DIREITA
    MOV nave_x, BX
NAO_DIREITA:

    CMP AH, 4Bh
    JNE FIM_INPUT_GAME
    MOV BX, nave_x
    SUB BX, 2
    CMP BX, 0
    JL FIM_INPUT_GAME
    MOV nave_x, BX
    
FIM_INPUT_GAME:
    POP BX
    POP AX
    RET
PROCESSA_INPUT ENDP

; ===== DELAY =====
DELAY PROC NEAR
    PUSH CX
    MOV CX, 5000h
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