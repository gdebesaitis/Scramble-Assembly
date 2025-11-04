; ========================================
; GAME.ASM - SCRAMBLE
; Arquivo principal do jogo
; ========================================
.286

; ===== INCLUDES (comentar se n?o suportado pelo montador) =====
INCLUDE sprites.asm
INCLUDE strings.asm

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
    
    ; Superf?cie Fase 1 (ondulada) - 480 pontos
    superficie_f1 DW 160,158,156,154,152,150,148,146,144,142
                  DW 140,138,136,134,132,130,132,134,136,138
                  DW 140,142,144,146,148,150,152,154,156,158
                  DW 160,162,164,166,168,170,172,174,176,178
                  DW 180,178,176,174,172,170,168,166,164,162
                  DW 160,158,156,154,152,150,148,146,144,142
                  DW 140,142,144,146,148,150,152,154,156,158
                  DW 160,162,164,166,168,170,168,166,164,162
                  ; Repetir padr?o at? 480 elementos...
                  ; (adicionar mais valores conforme necess?rio)
    
    ; Superf?cie Fase 2 (irregular) - 480 pontos
    superficie_f2 DW 170,168,165,163,160,158,155,153,150,152
                  DW 155,158,160,163,165,168,170,173,175,178
                  DW 180,177,174,171,168,165,162,160,158,156
                  DW 154,152,150,153,156,159,162,165,168,171
                  DW 174,177,180,178,176,174,172,170,168,166
                  ; (continuar...)
    
    ; ----- SUPERF?CIE FASE 3 (TIJOLOS) -----
    ; Estrutura: altura de cada coluna (em blocos de 16px)
    colunas_f3 DB 3,4,5,4,3,2,3,4,5,6,5,4,3,4,5,6,7,6,5,4
               DB 3,2,3,4,5,4,3,2,3,4  ; 30 colunas
    num_colunas_f3 EQU 30
    
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
    
DADOS ENDS

; ===== SEGMENTO DE BUFFER =====
BUFFER_SEG SEGMENT
    buffer DB 64000 DUP(0)
BUFFER_SEG ENDS

; ===== PILHA =====
PILHA SEGMENT STACK
    DW 256 DUP(0)
PILHA ENDS

; ===== C?DIGO =====
CODIGO SEGMENT

    ASSUME CS:CODIGO, DS:DADOS, SS:PILHA

; ===== INCLUDES DE ROTINAS GR?FICAS =====
INCLUDE graphics.asm
INCLUDE font.asm

    ASSUME CS:CODIGO, DS:DADOS, SS:PILHA, ES:BUFFER_SEG
    
    
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
    ; Verificar estado do jogo
    CMP estado_jogo, 0
    JE ESTADO_MENU
    CMP estado_jogo, 1
    JE ESTADO_JOGANDO
    CMP estado_jogo, 2
    JE ESTADO_GAME_OVER
    CMP estado_jogo, 3
    JE ESTADO_VENCEDOR
    JMP FIM_JOGO

ESTADO_MENU:
    CALL TELA_INICIAL
    JMP LOOP_PRINCIPAL

ESTADO_JOGANDO:
    CALL LOOP_JOGO
    JMP LOOP_PRINCIPAL

ESTADO_GAME_OVER:
    ;CALL TELA_GAME_OVER
    JMP LOOP_PRINCIPAL

ESTADO_VENCEDOR:
    ;CALL TELA_VENCEDOR
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
    
    ; Desenhar t?tulo (simplificado)
    MOV SI, OFFSET menu_jogar  ; Placeholder
    MOV DH, 3
    MOV DL, 12
    MOV BL, 10                 ; Verde claro
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
    
    CMP AH, 48h                ; Seta cima
    JE MENU_CIMA
    CMP AH, 50h                ; Seta baixo
    JE MENU_BAIXO
    CMP AL, 13                 ; Enter
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
    
    ; Iniciar jogo
    CALL INICIALIZA_JOGO
    MOV estado_jogo, 1
    JMP FIM_TELA_INI
    
MENU_SAIR_JG:
    MOV estado_jogo, 99        ; Sair
    
FIM_TELA_INI:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
TELA_INICIAL ENDP

; ========================================
; DESENHA ANIMA??ES DO MENU
; ========================================
DESENHA_ANIMACOES_MENU PROC NEAR
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI
    
    ; Nave aliada
    MOV BX, anim_nave_x
    MOV DX, 70
    MOV SI, OFFSET sprite_nave_aliada  ; (incluir do sprites.asm)
    MOV AL, 11                         ; Ciano claro
    ; CALL DESENHA_SPRITE_BUF (implementar)
    
    ; Meteoro
    MOV BX, anim_meteoro_x
    MOV DX, 90
    MOV SI, OFFSET sprite_meteoro
    MOV AL, 6
    ; CALL DESENHA_SPRITE_BUF
    
    ; Alien
    MOV BX, anim_alien_x
    MOV DX, 110
    MOV SI, OFFSET sprite_nave_alien
    MOV AL, 12
    ; CALL DESENHA_SPRITE_BUF
    
    POP SI
    POP DX
    POP BX
    POP AX
    RET
DESENHA_ANIMACOES_MENU ENDP

; ========================================
; ATUALIZA ANIMA??ES DO MENU
; ========================================
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

; ========================================
; DESENHA MENU
; ========================================
DESENHA_MENU PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Caixa Jogar
    MOV DH, 18                 ; Linha
    MOV DL, 14                 ; Coluna
    MOV CH, 12                 ; Largura
    MOV CL, 3                  ; Altura
    CMP opcao_selecionada, 0
    JNE COR_JOGAR
    MOV BL, 12                 ; Vermelho claro (selecionado)
    JMP DESENHA_JOGAR
COR_JOGAR:
    MOV BL, 15                 ; Branco
DESENHA_JOGAR:
    CALL DESENHA_CAIXA_BUF
    
    ; Texto Jogar
    MOV SI, OFFSET menu_jogar
    MOV DH, 19
    MOV DL, 17
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

; ========================================
; INICIALIZA JOGO
; ========================================
INICIALIZA_JOGO PROC NEAR
    MOV vidas, NUM_VIDAS
    MOV score, 0
    MOV fase_atual, 1
    MOV tempo_restante, TEMPO_FASE
    
    ; Posi??o inicial da nave
    MOV nave_x, 50
    MOV nave_y, 90
    
    ; Limpar tiros
    MOV CX, MAX_TIROS
    MOV SI, OFFSET tiros_ativos
LMP_TIROS:
    MOV BYTE PTR [SI], 0
    INC SI
    LOOP LMP_TIROS
    
    ; Limpar inimigos
    MOV CX, MAX_INIMIGOS
    MOV SI, OFFSET inimigos_ativos
LMP_INIM:
    MOV BYTE PTR [SI], 0
    INC SI
    LOOP LMP_INIM
    
    RET
INICIALIZA_JOGO ENDP

; ========================================
; LOOP DO JOGO
; ========================================
LOOP_JOGO PROC NEAR
    ; Mostrar tela de apresenta??o da fase
    CALL TELA_APRESENTACAO_FASE
    
LOOP_FASE:
    ; Limpar buffer
    CALL LIMPA_BUFFER
    
    ; Desenhar elementos
    CALL DESENHA_ESTRELAS_FASE
    CALL DESENHA_SUPERFICIE
    CALL DESENHA_NAVE_ALIADA
    CALL DESENHA_TIROS
    CALL DESENHA_INIMIGOS
    CALL DESENHA_STATUS
    
    ; Copiar para tela
    CALL COPIA_BUFFER_VIDEO
    
    ; Atualizar l?gica
    CALL ATUALIZA_LOGICA_JOGO
    
    ; Verificar colis?es
    CALL VERIFICA_COLISOES
    
    ; Delay
    CALL DELAY
    
    ; Verificar teclas
    CALL PROCESSA_INPUT
    
    ; Verificar fim de fase
    CMP tempo_restante, 0
    JE FIM_FASE_ATUAL
    
    ; Verificar game over
    CMP vidas, 0
    JE PERDEU_JOGO
    
    JMP LOOP_FASE
    
FIM_FASE_ATUAL:
    INC fase_atual
    CMP fase_atual, 4
    JE GANHOU_JOGO
    
    MOV tempo_restante, TEMPO_FASE
    JMP LOOP_FASE
    
PERDEU_JOGO:
    MOV estado_jogo, 2
    RET
    
GANHOU_JOGO:
    MOV estado_jogo, 3
    RET
LOOP_JOGO ENDP

; ========================================
; FUN??ES AUXILIARES
; ========================================

; Delay simples
DELAY PROC NEAR
    PUSH CX
    MOV CX, 3000h
DELAY_LOOP:
    LOOP DELAY_LOOP
    POP CX
    RET
DELAY ENDP

; Gerador de n?meros aleat?rios (Linear Congruential Generator)
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

; CONTINUA NA PARTE 2...
; (Implementar demais fun??es)

; ========================================
; PROCEDIMENTOS STUB (TEMPOR?RIOS)
; Implementa??o m?nima para compila??o
; Estes ser?o implementados posteriormente
; ========================================

; ===== TELA DE APRESENTA??O DA FASE =====
; Fun??o: Exibe a tela de apresenta??o da fase atual
; Entrada: fase_atual
; Sa?da: Nenhuma
TELA_APRESENTACAO_FASE PROC NEAR
    PUSH AX
    PUSH CX
    PUSH DX
    
    ; TODO: Implementar apresenta??o da fase
    ; Por enquanto, apenas um delay de 4 segundos
    MOV CX, 4
DELAY_APRESENTACAO:
    PUSH CX
    CALL DELAY
    POP CX
    LOOP DELAY_APRESENTACAO
    
    POP DX
    POP CX
    POP AX
    RET
TELA_APRESENTACAO_FASE ENDP

; ===== DESENHA ESTRELAS DA FASE =====
; Fun??o: Desenha as estrelas de fundo no buffer
; Entrada: Nenhuma (usa array estrelas)
; Sa?da: Estrelas desenhadas no buffer
DESENHA_ESTRELAS_FASE PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    ; TODO: Implementar desenho de estrelas da fase
    ; Por enquanto, vazio (estrelas do menu s?o diferentes)
    
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHA_ESTRELAS_FASE ENDP

; ===== DESENHA SUPERF?CIE DO PLANETA =====
; Fun??o: Desenha a superf?cie do planeta no buffer
; Entrada: Nenhuma (usa array superficie)
; Sa?da: Superf?cie desenhada no buffer
DESENHA_SUPERFICIE PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    ; TODO: Implementar desenho da superf?cie
    ; Por enquanto, apenas uma linha horizontal no fundo
    MOV DX, 180        ; Linha Y=180
    MOV BX, 0          ; Come?ar em X=0
    MOV AL, 6          ; Cor marrom
LOOP_SUPERFICIE:
    CALL DESENHA_PIXEL_BUF
    INC BX
    CMP BX, 320
    JL LOOP_SUPERFICIE
    
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHA_SUPERFICIE ENDP

; ===== DESENHA NAVE ALIADA =====
; Fun??o: Desenha a nave aliada na posi??o atual
; Entrada: nave_x, nave_y
; Sa?da: Nave desenhada no buffer
DESENHA_NAVE_ALIADA PROC NEAR
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI
    
    ; Carregar posi??o da nave
    MOV BX, nave_x
    MOV DX, nave_y
    
    ; Carregar sprite da nave
    MOV SI, OFFSET sprite_nave_aliada
    MOV AL, 11         ; Cor ciano claro
    
    CALL DESENHA_SPRITE_BUF
    
    POP SI
    POP DX
    POP BX
    POP AX
    RET
DESENHA_NAVE_ALIADA ENDP

; ===== DESENHA TIROS =====
; Fun??o: Desenha todos os tiros ativos no buffer
; Entrada: Arrays tiros_x, tiros_y, tiros_ativo
; Sa?da: Tiros desenhados no buffer
DESENHA_TIROS PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    ; TODO: Implementar desenho de tiros
    ; Por enquanto, vazio (sem tiros)
    
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHA_TIROS ENDP

; ===== DESENHA INIMIGOS =====
; Fun??o: Desenha todos os inimigos ativos no buffer
; Entrada: Arrays inimigos_x, inimigos_y, inimigos_ativo
; Sa?da: Inimigos desenhados no buffer
DESENHA_INIMIGOS PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    ; TODO: Implementar desenho de inimigos/meteoros
    ; Por enquanto, vazio
    
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHA_INIMIGOS ENDP

; ===== DESENHA STATUS =====
; Fun??o: Desenha a barra de status (score, vidas, tempo)
; Entrada: score, vidas, tempo_restante
; Sa?da: Status desenhado no buffer
DESENHA_STATUS PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    ; Desenhar "SCORE: "
    MOV SI, OFFSET texto_score
    MOV DH, 0
    MOV DL, 1
    MOV BL, 15         ; Branco
    CALL DESENHA_STRING_BUF
    
    ; Desenhar valor do score (simplificado)
    ; TODO: Converter score para string e desenhar
    
    ; Desenhar vidas (sprites de naves pequenas)
    ; TODO: Implementar desenho das vidas no centro
    
    ; Desenhar "TEMPO: "
    MOV SI, OFFSET texto_tempo
    MOV DH, 0
    MOV DL, 35
    MOV BL, 15
    CALL DESENHA_STRING_BUF
    
    ; Desenhar valor do tempo
    ; TODO: Converter tempo_restante para string e desenhar
    
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHA_STATUS ENDP

; ===== ATUALIZA L?GICA DO JOGO =====
; Fun??o: Atualiza posi??es, movimentos e l?gica do jogo
; Entrada: Todos os arrays do jogo
; Sa?da: Arrays atualizados
ATUALIZA_LOGICA_JOGO PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; TODO: Implementar l?gica completa do jogo:
    ; - Mover tiros
    ; - Mover inimigos
    ; - Scroll da superf?cie
    ; - Spawn de novos inimigos
    ; - Atualizar temporizador
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
ATUALIZA_LOGICA_JOGO ENDP

; ===== VERIFICA COLIS?ES =====
; Fun??o: Verifica todas as colis?es do jogo
; Entrada: Posi??es de nave, inimigos, tiros, superf?cie
; Sa?da: vidas atualizado, inimigos destru?dos, score atualizado
VERIFICA_COLISOES PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; TODO: Implementar detec??o de colis?es:
    ; - Nave vs inimigos
    ; - Nave vs superf?cie
    ; - Tiros vs inimigos
    ; - Tiros vs superf?cie
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
VERIFICA_COLISOES ENDP

; ===== PROCESSA INPUT =====
; Fun??o: Processa entrada do teclado durante o jogo
; Entrada: Nenhuma
; Sa?da: nave_x, nave_y atualizados, tiros criados
PROCESSA_INPUT PROC NEAR
    PUSH AX
    PUSH BX
    
    ; Verificar se h? tecla pressionada
    MOV AH, 01h
    INT 16h
    JZ FIM_INPUT_JOGO
    
    ; Ler tecla
    MOV AH, 00h
    INT 16h
    
    ; ESC - voltar ao menu
    CMP AH, 01h
    JNE VERIFICA_SETAS
    MOV estado_jogo, 0
    JMP FIM_INPUT_JOGO
    
VERIFICA_SETAS:
    ; Seta para cima
    CMP AH, 48h
    JNE NAO_CIMA
    MOV BX, nave_y
    SUB BX, 2
    CMP BX, 10         ; Limite superior (abaixo da barra de status)
    JL NAO_CIMA
    MOV nave_y, BX
NAO_CIMA:

    ; Seta para baixo
    CMP AH, 50h
    JNE NAO_BAIXO
    MOV BX, nave_y
    ADD BX, 2
    CMP BX, 165        ; Limite inferior (acima da superf?cie)
    JG NAO_BAIXO
    MOV nave_y, BX
NAO_BAIXO:

    ; Seta para direita
    CMP AH, 4Dh
    JNE NAO_DIREITA
    MOV BX, nave_x
    ADD BX, 2
    CMP BX, 290
    JG NAO_DIREITA
    MOV nave_x, BX
NAO_DIREITA:

    ; Seta para esquerda
    CMP AH, 4Bh
    JNE NAO_ESQUERDA
    MOV BX, nave_x
    SUB BX, 2
    CMP BX, 0
    JL NAO_ESQUERDA
    MOV nave_x, BX
NAO_ESQUERDA:

    ; Barra de espa?o - atirar
    CMP AL, 32
    JNE FIM_INPUT_JOGO
    ; TODO: Criar novo tiro na posi??o da nave
    
FIM_INPUT_JOGO:
    POP BX
    POP AX
    RET
PROCESSA_INPUT ENDP


CODIGO ENDS
END INICIO