; ========================================
; GAME.ASM - SCRAMBLE (CORRIGIDO)
; Arquivo principal do jogo
; ========================================
.286

; ===== SEGMENTO DE DADOS =====
DADOS SEGMENT
    ; ----- CONFIGURA??ES -----
    TEMPO_FASE EQU 60           ; Segundos por fase
    TEMPO_APRESENTACAO EQU 4    ; Segundos apresenta??o
    NUM_VIDAS EQU 3             ; Vidas iniciais
    
    ; ----- ESTADO DO JOGO -----
    vidas DB NUM_VIDAS
    score DW 0
    fase_atual DB 1
    tempo_restante DB TEMPO_FASE
    estado_jogo DB 0            ; 0=menu, 1=jogando, 2=game over, 3=vencedor
    
    ; ----- POSI??ES DAS ESTRELAS -----
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
    
    ; ----- NAVE ALIADA -----
    nave_x DW 50
    nave_y DW 90
    nave_vel EQU 3
    
    ; ----- TIROS -----
    MAX_TIROS EQU 10
    tiros_x DW MAX_TIROS DUP(0)
    tiros_y DW MAX_TIROS DUP(0)
    tiros_ativos DB MAX_TIROS DUP(0)
    tiro_vel EQU 5
    
    ; ----- INIMIGOS -----
    MAX_INIMIGOS EQU 5
    inimigos_x DW MAX_INIMIGOS DUP(320)
    inimigos_y DW MAX_INIMIGOS DUP(0)
    inimigos_ativos DB MAX_INIMIGOS DUP(0)
    inimigo_vel_f1 EQU 2
    inimigo_vel_f3 EQU 4
    contador_spawn DW 0
    
    ; ----- METEOROS (FASE 2) -----
    MAX_METEOROS EQU 4
    meteoros_x DW MAX_METEOROS DUP(320)
    meteoros_y DW MAX_METEOROS DUP(0)
    meteoros_ativos DB MAX_METEOROS DUP(0)
    meteoro_vel EQU 3
    
    ; ----- SUPERF?CIE DO PLANETA -----
    superficie_offset DW 0
    superficie_vel EQU 2
    
    ; ----- MENU -----
    opcao_selecionada DB 0      ; 0=Jogar, 1=Sair
    
    ; ----- ANIMA??O TELA INICIAL -----
    anim_nave_x DW 0
    anim_meteoro_x DW 312
    anim_alien_x DW 150
    anim_alien_dir DB 1         ; 1=esquerda, 0=direita
    
    ; ----- GERADOR ALEAT?RIO -----
    seed DW 12345
    
    ; ----- STRINGS -----
    titulo_linha1 DB 'S C R A M B L E', 0
    menu_jogar DB 'JOGAR', 0
    menu_sair DB 'SAIR', 0
    texto_score DB 'SCORE:', 0
    texto_tempo DB 'TEMPO:', 0
    
    ; Buffer tempor?rio
    temp_num_buffer DB 6 DUP(0)
    
    ; ----- SPRITES (INCLU?DOS AQUI) -----
    NAVE_WIDTH EQU 29
    NAVE_HEIGHT EQU 13
    
    sprite_nave_aliada DB 0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                       DB 0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0
                       DB 0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0
                       DB 0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0
                       DB 0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0
                       DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0
                       DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
                       DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0
                       DB 0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0
                       DB 0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0
                       DB 0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0
                       DB 0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0
                       DB 0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    
    sprite_nave_alien DB 0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0
                      DB 0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0
                      DB 0,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0
                      DB 1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1
                      DB 0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0
                      DB 0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0
                      DB 0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0
                      DB 0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0
                      DB 0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0
                      DB 1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1
                      DB 0,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0
                      DB 0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0
                      DB 0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0
    
    sprite_meteoro DB 0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0
                   DB 0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0
                   DB 0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0
                   DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0
                   DB 1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1,1,0
                   DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
                   DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
                   DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
                   DB 1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,0
                   DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0
                   DB 0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0
                   DB 0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0
                   DB 0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0
    
DADOS ENDS

; ===== BUFFER (64000 bytes) =====
BUFFER SEGMENT
    video_buffer DB 64000 DUP(0)
BUFFER ENDS

; ===== PILHA =====
PILHA SEGMENT STACK
    DW 256 DUP(0)
PILHA ENDS

; ===== C?DIGO =====
CODIGO SEGMENT
    ASSUME CS:CODIGO, DS:DADOS, SS:PILHA

; ===== INCLUDES =====
INCLUDE graphics.asm
INCLUDE font.asm

INICIO:
    ; Inicializar segmento de dados
    MOV AX, DADOS
    MOV DS, AX
    
    ; Ativar modo de v?deo 13h
    MOV AX, 13h
    INT 10h
    
    ; Inicializar seed aleat?rio
    MOV AH, 2Ch
    INT 21h
    MOV seed, DX
    
    ; Estado inicial: menu
    MOV estado_jogo, 0

; ===== LOOP PRINCIPAL =====
LOOP_PRINCIPAL:
    CMP estado_jogo, 0
    JE ESTADO_MENU
    CMP estado_jogo, 1
    JE ESTADO_JOGANDO
    CMP estado_jogo, 99
    JE FIM_JOGO
    JMP LOOP_PRINCIPAL

ESTADO_MENU:
    CALL TELA_INICIAL
    JMP LOOP_PRINCIPAL

ESTADO_JOGANDO:
    CALL LOOP_JOGO
    JMP LOOP_PRINCIPAL

FIM_JOGO:
    ; Restaurar modo texto
    MOV AX, 3
    INT 10h
    
    ; Sair
    MOV AX, 4C00h
    INT 21h

; ========================================
; TELA INICIAL
; ========================================
TELA_INICIAL PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
LOOP_TELA_INI:
    ; Limpar buffer
    CALL LIMPA_BUFFER
    
    ; Desenhar estrelas
    MOV SI, OFFSET estrelas
    MOV CX, num_estrelas
    CALL DESENHA_ESTRELAS_BUF
    
    ; Desenhar t?tulo
    MOV SI, OFFSET titulo_linha1
    MOV DH, 3
    MOV DL, 16
    MOV BL, 14
    CALL DESENHA_STRING_BUF
    
    ; Desenhar anima??es
    CALL DESENHA_ANIMACOES_MENU
    
    ; Desenhar menu
    CALL DESENHA_MENU
    
    ; Copiar para tela
    CALL COPIA_BUFFER_VIDEO
    
    ; Atualizar posi??es
    CALL ATUALIZA_ANIMACOES_MENU
    
    ; Delay
    CALL DELAY
    
    ; Verificar tecla
    MOV AH, 1
    INT 16h
    JZ LOOP_TELA_INI
    
    ; Ler tecla
    MOV AH, 0
    INT 16h
    
    CMP AH, 48h
    JE MENU_CIMA
    CMP AH, 50h
    JE MENU_BAIXO
    CMP AL, 13
    JE MENU_ENTER
    JMP LOOP_TELA_INI
    
MENU_CIMA:
    MOV opcao_selecionada, 0
    JMP LOOP_TELA_INI
    
MENU_BAIXO:
    MOV opcao_selecionada, 1
    JMP LOOP_TELA_INI
    
MENU_ENTER:
    CMP opcao_selecionada, 1
    JE MENU_SAIR_JG
    
    CALL INICIALIZA_JOGO
    MOV estado_jogo, 1
    JMP FIM_TELA_INI
    
MENU_SAIR_JG:
    MOV estado_jogo, 99
    
FIM_TELA_INI:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
TELA_INICIAL ENDP

INCLUDE menu_funcs.asm

CODIGO ENDS
END INICIO