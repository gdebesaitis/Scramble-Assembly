.model small
.stack 100h

; ============================================
; arquivo: main.asm
; (implementado score/seg e game over)
; ============================================

; --- segmento do buffer (para double buffering) ---
BUFFER_SEG SEGMENT
    buffer db 64000 dup(0)
BUFFER_SEG ENDS

.data
    ; --- constantes de teclado ---
    TECLA_CIMA    EQU 72
    TECLA_BAIXO   EQU 80
    TECLA_ESQUERDA EQU 75
    TECLA_DIREITA EQU 77
    TECLA_ENTER   EQU 13
    TECLA_ESC     EQU 1

    ; --- constantes de cor ---
    COR_VERDE_CLARO EQU 0Ah
    COR_BRANCA_TXT  EQU 0Fh
    COR_VERMELHA_CLARO EQU 0Ch
    COR_CIANO_CLARO EQU 0Bh

    ; --- constantes do jogo ---
    STATUS_BAR_HEIGHT EQU 16
    GAME_START_TIME   EQU 30 ; (tempo em segundos)
    INITIAL_LIVES     EQU 3

    ; --- pontuacao por fase ---
    SCORE_FASE_1      EQU 10 ; pontos/seg na fase 1
    SCORE_FASE_2      EQU 15 ; pontos/seg na fase 2
    SCORE_FASE_3      EQU 20 ; pontos/seg na fase 3

    ; --- includes de dados ---
    INCLUDE strings.asm
    INCLUDE sprites.asm
    INCLUDE font.asm

    ; --- variaveis de estado ---
    gameState        db 0  ; 0 = menu, 1 = jogo, 2 = game over
    currentPhase     db 1
    opcaoSelecionada db 0
    teclaPressionada dw 0
    
    ; --- estado das teclas (para input fluido) ---
    keyUp            db 0  ; 1 = pressionada
    keyDown          db 0
    keyLeft          db 0
    keyRight         db 0
    keySpace         db 0
    keyEsc           db 0
    keyEnter         db 0
    
    ; --- variaveis de scrolling ---
    terrainScroll    dw 0
    
    ; --- variaveis das animacoes do menu ---
    naveX    dw 0
    naveY    dw 52
    meteoroX dw 319 - SPRITE_LARGURA
    meteoroY dw 84
    alienX   dw 160
    alienY   dw 116
    alienDir db 1
    
    naveLastX    dw 0
    naveLastY    dw 60
    meteoroLastX dw 319 - SPRITE_LARGURA
    meteoroLastY dw 75
    alienLastX   dw 160
    alienLastY   dw 90

    ; --- variaveis do jogo ---
    playerX         dw 10
    playerY         dw 100
    playerLastX     dw 10
    playerLastY     dw 100
    playerVelocidade EQU 5
    playerLives     db INITIAL_LIVES
    playerScore     dw 0
    gameTime        dw GAME_START_TIME
    
    lastSecond      db 99
    
    ; --- variaveis dos inimigos ---
    MAX_ENEMIES     EQU 5
    enemiesX        dw MAX_ENEMIES dup(0)
    enemiesY        dw MAX_ENEMIES dup(0)
    enemiesActive   db MAX_ENEMIES dup(0) ; 0=inativo, 1=ativo
    enemySpawnTimer db 0
    enemySpawnRate  db 30 ; frames entre spawns (ajustavel)

    ; --- variaveis dos tiros ---
    MAX_TIROS       EQU 5
    tirosX          dw MAX_TIROS dup(0) ; posicao x
    tirosY          dw MAX_TIROS dup(0) ; posicao y
    tirosAtivo      db MAX_TIROS dup(0) ; 0=inativo, 1=ativo
    
    tempWord        dw 0 ; variavel temporaria para calculos
    
    TECLA_ESPACO    EQU 57              ; scan code (39h = 57 decimal)
    
    ; --- timer de estado (para evitar saida imediata) ---
    stateTimer      db 0

.code
INCLUDE graphics.asm

;-------------------------------------------------
; main: funcao principal do programa
; funcao: inicializa o jogo e executa o loop principal
; parametros de entrada: nenhum
; parametros de saida: nenhum
;-------------------------------------------------
main proc
    ; 1. inicializa ds para @data
    mov ax, @data
    mov ds, ax
    
    ; 2. configura o modo de video
    call setupVideoMode

    ; 3. configura es para o buffer_seg
    mov ax, BUFFER_SEG
    mov es, ax
    ; (ds = @data, es = buffer_seg)
    
    ; 4. inicia o loop mestre do jogo
masterLoop:
    ; 1. le o teclado (sempre)
    call checkInput
    
    ; 2. limpa o buffer
    call clearBuffer
    
    ; 3. verifica o estado do jogo
    cmp [gameState], 0
    je runMenu
    cmp [gameState], 1
    je runGame
    cmp [gameState], 2
    je runGameOver
    
    ; se for 3 (vencedor)
    jmp runGameWin

runMenu:
    ; --- logica do estado de menu ---
    call drawMenuToBuffer
    call updateAnims
    call drawAnims
    call handleMenuInput
    jmp drawFrame

runGame:
    ; --- logica do estado de jogo ---
    call handleGameInput
    call updatePlayer
    call updateTiros
    call spawnEnemy
    call updateEnemies
    call checkCollisions
    call checkTerrainCollision ; <--- colisao com terreno
    call updateTimer
    call updateTerrainScroll
    call drawTerrain    ; desenha terreno primeiro (fundo)
    call drawStatusBar
    call drawPlayer
    call drawTiros
    call drawEnemies
    jmp drawFrame

runGameOver:
    ; --- logica do estado de game over ---
    call drawGameOverScreen
    call handleGameOverInput
    jmp drawFrame

runGameWin:
    ; --- logica do estado de vencedor ---
    call drawWinScreen
    call handleGameOverInput ; reusa input (qualquer tecla volta ao menu)
    jmp drawFrame

drawFrame:
    ; --- desenha e repete ---
    call copyBufferToVideo
    
    push 20000
    call delay
    
    jmp masterLoop

exitGame:
    ; restaura o modo de texto
    mov ax, 0003h
    int 10h
    
    ; termina o programa
    mov ax, 4C00h
    int 21h
main endp


; --- rotinas de logica (ds = @data, es = buffer_seg) ---

;-------------------------------------------------
; checkInput: le e limpa o buffer de teclado
; (corrige o lag/ghosting de movimento)
;-------------------------------------------------
checkInput proc
    ; 1. zera a tecla atual (assume nenhuma apertada)
    mov [teclaPressionada], 0

.drainLoop:
    ; verifica se tem tecla no buffer (ah=01h)
    mov ah, 01h
    int 16h
    jz .fimCheck    ; se zeroflag=1, buffer vazio, terminamos

    ; tem tecla! vamos ler e retira-la da fila (ah=00h)
    mov ah, 00h
    int 16h
    
    ; salva essa tecla como a "mais recente"
    mov [teclaPressionada], ax
    
    ; volta para ver se tem mais teclas acumuladas (ignora as antigas)
    jmp .drainLoop

.fimCheck:
    ret
checkInput endp

;-------------------------------------------------
; handleMenuInput: processa a entrada do menu
; funcao: trata as teclas pressionadas no menu principal
; parametros de entrada: nenhum
; parametros de saida: atualiza opcaoselecionada e gamestate conforme necessario
;-------------------------------------------------
handleMenuInput proc
    ; usa teclapressionada para detectar novas teclas
    mov ax, [teclaPressionada]
    cmp ax, 0
    je menuInputFim

    ; ah = scan code
    cmp ah, 48h         ; cima
    je pressionouCima
    cmp ah, 50h         ; baixo
    je pressionouBaixo
    cmp ah, 1Ch         ; enter
    je pressionouEnter
    jmp menuInputFim

pressionouCima:
    mov [opcaoSelecionada], 0
    jmp menuInputFim
pressionouBaixo:
    mov [opcaoSelecionada], 1
    jmp menuInputFim
pressionouEnter:
    cmp [opcaoSelecionada], 1
    jne @@iniciarJogo
    jmp exitGame
    
@@iniciarJogo:
    ; --- iniciar jogo ---
    call resetGameVars
    
    mov [currentPhase], 1       ; define fase 1
    mov al, [currentPhase]      ; passa o numero 1 para al
    call showTransitionScreen   ; <--- chama a nova tela
    
    mov [gameState], 1          ; muda para o jogo
    call initTimer
    
    jmp menuInputFim
    
menuInputFim:
    ret
handleMenuInput endp

;-------------------------------------------------
; handleGameInput: processa a entrada do jogo
; funcao: trata as teclas pressionadas durante o jogo
; parametros de entrada: nenhum
; parametros de saida: pode chamar spawntiro ou sair do jogo
;-------------------------------------------------
handleGameInput proc
    mov ax, [teclaPressionada]
    cmp ax, 0
    je @@gameInputDone
    
    ; ah = scan code
    ; verifica esc
    cmp ah, 01h
    jne @@notEscGame
    jmp exitGame
@@notEscGame:
    
    ; verifica espaco para atirar
    cmp ah, 39h
    jne @@gameInputDone
    call spawnTiro
    
@@gameInputDone:
    ret
handleGameInput endp

;-------------------------------------------------
; handleGameOverInput: processa a entrada do game over
; funcao: trata entrada quando o jogo termina (game over ou vitoria)
; parametros de entrada: nenhum
; parametros de saida: pode voltar ao menu principal
;-------------------------------------------------
handleGameOverInput proc
    ; verifica timer de estado
    cmp [stateTimer], 0
    je .checkInputGO
    
    dec [stateTimer]
    ret ; ignora input enquanto timer > 0

.checkInputGO:
    ; usa teclapressionada para detectar qualquer tecla nova
    mov ax, [teclaPressionada]
    cmp ax, 0
    je gameOverFim ; se nenhuma tecla, continua
    
    ; se qualquer tecla for pressionada, volta ao menu
    ; reseta flags de tecla para evitar problemas no menu
    mov [keyUp], 0
    mov [keyDown], 0
    mov [keyLeft], 0
    mov [keyRight], 0
    mov [keySpace], 0
    mov [keyEnter], 0
    mov [keyEsc], 0
    mov [gameState], 0
    
gameOverFim:
    ret
handleGameOverInput endp


;-------------------------------------------------
; showTransitionScreen: mostra tela de transicao entre fases
; funcao: desenha a arte ascii da fase correspondente
; parametros de entrada: al = numero da fase (1, 2 ou 3)
; parametros de saida: nenhum
;-------------------------------------------------
showTransitionScreen proc
    push ax
    push cx
    push dx
    
    call clearBuffer

    cmp al, 1
    je .drawFase1
    cmp al, 2
    jne .checkFase3
    jmp .drawFase2
.checkFase3:
    cmp al, 3
    jne .checkFim
    jmp .drawFase3
.checkFim:
    jmp .fimTransition

.drawFase1:
    mov ax, 32
    
    push ax
    push 76
    push COR_CIANO_CLARO
    push offset fase1Linha1
    call drawStringToBuffer
    push ax
    push 84
    push COR_CIANO_CLARO
    push offset fase1Linha2
    call drawStringToBuffer
    push ax
    push 92
    push COR_CIANO_CLARO
    push offset fase1Linha3
    call drawStringToBuffer
    push ax
    push 100
    push COR_CIANO_CLARO
    push offset fase1Linha4
    call drawStringToBuffer
    push ax
    push 108
    push COR_CIANO_CLARO
    push offset fase1Linha5
    call drawStringToBuffer
    push ax
    push 116
    push COR_CIANO_CLARO
    push offset fase1Linha6
    call drawStringToBuffer
    jmp .waitTransition

.drawFase2:
    mov ax, 24
    
    push ax
    push 76
    push COR_VERMELHA_CLARO
    push offset fase2Linha1
    call drawStringToBuffer
    push ax
    push 84
    push COR_VERMELHA_CLARO
    push offset fase2Linha2
    call drawStringToBuffer
    push ax
    push 92
    push COR_VERMELHA_CLARO
    push offset fase2Linha3
    call drawStringToBuffer
    push ax
    push 100
    push COR_VERMELHA_CLARO
    push offset fase2Linha4
    call drawStringToBuffer
    push ax
    push 108
    push COR_VERMELHA_CLARO
    push offset fase2Linha5
    call drawStringToBuffer
    push ax
    push 116
    push COR_VERMELHA_CLARO
    push offset fase2Linha6
    call drawStringToBuffer
    jmp .waitTransition

.drawFase3:
    mov ax, 24
    
    push ax
    push 76
    push COR_VERDE_CLARO
    push offset fase3Linha1
    call drawStringToBuffer
    push ax
    push 84
    push COR_VERDE_CLARO
    push offset fase3Linha2
    call drawStringToBuffer
    push ax
    push 92
    push COR_VERDE_CLARO
    push offset fase3Linha3
    call drawStringToBuffer
    push ax
    push 100
    push COR_VERDE_CLARO
    push offset fase3Linha4
    call drawStringToBuffer
    push ax
    push 108
    push COR_VERDE_CLARO
    push offset fase3Linha5
    call drawStringToBuffer
    push ax
    push 116
    push COR_VERDE_CLARO
    push offset fase3Linha6
    call drawStringToBuffer
    jmp .waitTransition

.waitTransition:
    ; --- mostra na tela e espera ---
    call copyBufferToVideo
    
    ; delay de ~4 segundos
    mov cx, 200
.delayLoop:
    push 20000
    call delay
    loop .delayLoop

.fimTransition:
    pop dx
    pop cx
    pop ax
    ret
showTransitionScreen endp

;-------------------------------------------------
;-------------------------------------------------
; drawGameOverScreen: desenha tela de game over
; funcao: mostra mensagem de fim de jogo
; parametros de entrada: nenhum
; parametros de saida: nenhum
;-------------------------------------------------
drawGameOverScreen proc
    ; x = (320 - (9 chars * 8 pixels)) / 2 = 124
    ; y = (200 - 8 pixels) / 2 = 96
    push 124 ; x
    push 96  ; y
    push COR_VERMELHA_CLARO
    push offset strGameOver
    call drawStringToBuffer
    ret
drawGameOverScreen endp

;-------------------------------------------------
;-------------------------------------------------
; drawStatusBar: desenha barra de status
; funcao: mostra score, tempo, vidas e fase na parte superior da tela
; parametros de entrada: nenhum
; parametros de saida: nenhum
;-------------------------------------------------
drawStatusBar proc
    push ax
    push bx
    
    ; 1. score
    ; label (branco)
    push 8                  ; x
    push 4                  ; y
    push COR_BRANCA_TXT     ; cor branca
    push offset strScoreLabel
    call drawStringToBuffer
    
    ; valor (verde) - x = 8 + (7 chars * 8px) = 64
    push 64                 ; x ajustado
    push 4                  ; y
    push COR_VERDE_CLARO    ; cor verde
    push offset strScoreValue
    call drawStringToBuffer
    
    ; 2. tempo
    ; label (branco)
    push 232                ; x
    push 4                  ; y
    push COR_BRANCA_TXT     ; cor branca
    push offset strTempoLabel
    call drawStringToBuffer

    ; valor (verde) - x = 232 + (7 chars * 8px) = 288
    push 288                ; x ajustado
    push 4                  ; y
    push COR_VERDE_CLARO    ; cor verde
    push offset strTempoValue
    call drawStringToBuffer

    ; 3. desenha naves de vida
    mov ax, 130
    mov bx, 4
    
    mov cl, [playerLives]
    cmp cl, 0
    jle .fimLives
    xor ch, ch
    
.loopLives:
    push ax
    push bx
    push offset vidaSprite
    push 19
    push 7
    call drawGenericSprite
    
    add ax, 22
    loop .loopLives

.fimLives:
    pop bx
    pop ax
    ret
drawStatusBar endp

;-------------------------------------------------
;-------------------------------------------------
; drawWinScreen: desenha tela de vitoria
; funcao: mostra mensagem de vitoria e pontuacao final
; parametros de entrada: nenhum
; parametros de saida: nenhum
;-------------------------------------------------
drawWinScreen proc
    ; vencedor (verde)
    push 124 ; x
    push 96  ; y
    push COR_VERDE_CLARO
    push offset strVencedor
    call drawStringToBuffer
    
    ; label score (branco)
    push 116 ; x
    push 110 ; y
    push COR_BRANCA_TXT
    push offset strScoreLabel
    call drawStringToBuffer
    
    ; valor score (branco)
    push 172 ; x (116 + 56)
    push 110 ; y
    push COR_BRANCA_TXT
    push offset strScoreValue
    call drawStringToBuffer
    
    ret
drawWinScreen endp


;-------------------------------------------------
;-------------------------------------------------
; updatePlayer: move o jogador baseado na tecla pressionada
; funcao: atualiza posicao do jogador conforme teclas de movimento
; parametros de entrada: nenhum
; parametros de saida: atualiza playerx e playery
;-------------------------------------------------
updatePlayer proc
    push ax
    push bx
    push cx
    push dx
    
    ; salva posicao anterior
    mov ax, [playerX]
    mov [playerLastX], ax
    mov ax, [playerY]
    mov [playerLastY], ax

    ; velocidade base
    mov bx, playerVelocidade
    
    ; fase 3 = velocidade maior
    cmp [currentPhase], 3
    jne @@moveStart
    add bx, 2
@@moveStart:

    ; pega scan code da tecla (ah)
    mov ax, [teclaPressionada]
    mov cl, ah          ; cl = scan code
    
    ; --- movimento cima ---
    cmp cl, 48h
    jne @@checkDown
    
    mov ax, [playerY]
    sub ax, bx
    cmp ax, STATUS_BAR_HEIGHT
    jge @@salvaY
    mov ax, STATUS_BAR_HEIGHT
@@salvaY:
    mov [playerY], ax
    jmp @@playerMoveFim
    
@@checkDown:
    cmp cl, 50h
    jne @@checkLeft
    
    mov ax, [playerY]
    add ax, bx
    mov dx, 200 - SPRITE_ALTURA
    cmp ax, dx
    jle @@salvaY2
    mov ax, dx
@@salvaY2:
    mov [playerY], ax
    jmp @@playerMoveFim

    ; --- movimento horizontal ---
@@checkLeft:
    cmp cl, 4Bh
    jne @@checkRight
    
    mov ax, [playerX]
    sub ax, bx
    cmp ax, 0
    jge @@salvaX
    mov ax, 0
@@salvaX:
    mov [playerX], ax
    jmp @@playerMoveFim
    
@@checkRight:
    cmp cl, 4Dh
    jne @@playerMoveFim
    
    mov ax, [playerX]
    add ax, bx
    mov dx, 320 - SPRITE_LARGURA
    cmp ax, dx
    jle @@salvaX2
    mov ax, dx
@@salvaX2:
    mov [playerX], ax

@@playerMoveFim:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
updatePlayer endp
;-------------------------------------------------
;-------------------------------------------------
; drawPlayer: apaga e desenha o jogador
; funcao: remove sprite antigo e desenha sprite novo na nova posicao
; parametros de entrada: nenhum
; parametros de saida: nenhum
;-------------------------------------------------
drawPlayer proc
    push [playerLastX]
    push [playerLastY]
    push offset blankSprite
    call eraseSprite
    
    push [playerX]
    push [playerY]
    push offset naveAliadaSprite
    call drawSprite
    ret
drawPlayer endp


;-------------------------------------------------
;-------------------------------------------------
; drawMenuToBuffer: desenha menu completo no buffer
; funcao: renderiza titulo, opcoes e elementos visuais do menu principal
; parametros de entrada: nenhum
; parametros de saida: nenhum
;-------------------------------------------------
drawMenuToBuffer proc
    push ax
    push bx
    
    push 16              ; x = 16
    push 1*8             ; y = 8
    push COR_VERDE_CLARO
    push offset tituloLinha1
    call drawStringToBuffer
    
    push 16              ; x = 16
    push 2*8             ; y = 16
    push COR_VERDE_CLARO
    push offset tituloLinha2
    call drawStringToBuffer
    
    push 16              ; x = 16
    push 3*8             ; y = 24
    push COR_VERDE_CLARO
    push offset tituloLinha3
    call drawStringToBuffer
    
    push 16              ; x = 16
    push 4*8             ; y = 32
    push COR_VERDE_CLARO
    push offset tituloLinha4
    call drawStringToBuffer

    ; --- 2. define as cores dos botoes ---
    mov al, COR_BRANCA_TXT
    mov ah, COR_VERMELHA_CLARO
    cmp [opcaoSelecionada], 0
    je setCorJogar
    mov al, COR_BRANCA_TXT
    mov ah, COR_VERMELHA_CLARO
    jmp desenharBotoes
setCorJogar:
    mov al, COR_VERMELHA_CLARO
    mov ah, COR_BRANCA_TXT
desenharBotoes:
    
    ; --- 3. desenha o botao "jogar" ---
    ; caixa: x=104, w=14 chars (112px). centro = 160.
    push 104
    push 136
    push 14
    push 3
    push COR_BRANCA_TXT
    call drawBoxToBuffer
    
    ; texto "jogar" (5 chars = 40px). x = 160 - 20 = 140.
    push 140
    push 144
    push ax
    push offset strJogar
    call drawStringToBuffer

    ; --- 4. desenha o botao "sair" ---
    push 104
    push 168
    push 14
    push 3
    push COR_BRANCA_TXT
    call drawBoxToBuffer
    
    ; texto "sair" (4 chars = 32px). x = 160 - 16 = 144.
    push 144
    push 176
    mov al, ah
    push ax
    push offset strSair
    call drawStringToBuffer

    pop bx
    pop ax
    ret
drawMenuToBuffer endp

;-------------------------------------------------
;-------------------------------------------------
; updateAnims: atualiza coordenadas das animacoes do menu
; funcao: salva posicoes anteriores e atualiza posicoes dos elementos animados
; parametros de entrada: nenhum
; parametros de saida: atualiza posicoes dos sprites animados
;-------------------------------------------------
updateAnims proc
    mov ax, [naveX]
    mov [naveLastX], ax
    mov ax, [naveY]
    mov [naveLastY], ax
    mov ax, [meteoroX]
    mov [meteoroLastX], ax
    mov ax, [meteoroY]
    mov [meteoroLastY], ax
    mov ax, [alienX]
    mov [alienLastX], ax
    mov ax, [alienY]
    mov [alienLastY], ax
    
    add [naveX], 4
    mov ax, [naveX]
    cmp ax, 320
    jle naveOk
    mov [naveX], 0 - SPRITE_LARGURA
naveOk:
    sub [meteoroX], 4
    mov ax, [meteoroX]
    cmp ax, 0 - SPRITE_LARGURA
    jge meteoroOk
    mov [meteoroX], 320
meteoroOk:
    cmp [alienDir], 1
    je alienEsquerda
alienDireita:
    add [alienX], 4
    mov ax, [alienX]
    cmp ax, (320 - SPRITE_LARGURA)
    jl alienOk
    mov [alienX], (320 - SPRITE_LARGURA)
    mov [alienDir], 1
    jmp alienOk
alienEsquerda:
    sub [alienX], 4
    mov ax, [alienX]
    cmp ax, 0
    jg alienOk
    mov [alienX], 0
    mov [alienDir], 0
alienOk:
    ret
updateAnims endp


;-------------------------------------------------
;-------------------------------------------------
; drawAnims: desenha sprites das animacoes do menu
; funcao: remove sprites antigos e desenha sprites novos nas novas posicoes
; parametros de entrada: nenhum
; parametros de saida: nenhum
;-------------------------------------------------
drawAnims proc
    push [playerLastX]
    push [playerLastY]
    push offset blankSprite
    call eraseSprite
    push [meteoroLastX]
    push [meteoroLastY]
    push offset blankSprite
    call eraseSprite
    push [alienLastX]
    push [alienLastY]
    push offset blankSprite
    call eraseSprite

    push [naveX]
    push [naveY]
    push offset naveAliadaSprite
    call drawSprite
    push [meteoroX]
    push [meteoroY]
    push offset meteoroSprite
    call drawSprite
    push [alienX]
    push [alienY]
    push offset alienSprite
    call drawSprite
    ret
drawAnims endp


;-------------------------------------------------
;-------------------------------------------------
; delay: pausa a execucao
; funcao: cria um atraso na execucao do programa
; parametros de entrada: dx = tempo em microssegundos
; parametros de saida: nenhum
;-------------------------------------------------
delay proc
    push bp
    mov bp, sp
    push ax
    push cx
    push dx
    
    mov dx, [bp+4]
    xor cx, cx
    
    mov ah, 86h
    int 15h
    
    pop dx
    pop cx
    pop ax
    pop bp
    ret 2
delay endp

; -----------------------------------------------
; --- rotinas de jogo (novas e atualizadas) ---
; -----------------------------------------------

;-------------------------------------------------
;-------------------------------------------------
; resetGameVars: reseta variaveis do jogo
; funcao: inicializa todas as variaveis do jogo para valores padrao
; parametros de entrada: nenhum
; parametros de saida: nenhum
;-------------------------------------------------
resetGameVars proc
    mov [gameTime], GAME_START_TIME
    mov [playerScore], 0
    mov [playerLives], INITIAL_LIVES
    
    ; reseta posicao do jogador
    mov [playerX], 10
    mov [playerY], 100
    mov [playerLastX], 10
    mov [playerLastY], 100
    
    ; reseta flags de teclas
    mov [keyUp], 0
    mov [keyDown], 0
    mov [keyLeft], 0
    mov [keyRight], 0
    mov [keySpace], 0
    mov [keyEsc], 0
    mov [keyEnter], 0
    
    ; limpa array de tiros
    mov cx, MAX_TIROS
    xor bx, bx          ; zera o indice (bx = 0)
.limpaTiros:
    mov [tirosAtivo + bx], 0  ; desativa o tiro neste slot
    inc bx
    loop .limpaTiros

    ; limpa array de inimigos
    mov cx, MAX_ENEMIES
    xor bx, bx
.limpaInimigos:
    mov [enemiesActive + bx], 0
    inc bx
    loop .limpaInimigos
    
    ; reseta timer de spawn para 1 (spawn imediato)
    mov [enemySpawnTimer], 1
    
    ; forca a atualizacao das strings
    call updateTimeString
    call updateScoreString
    ret
resetGameVars endp

;-------------------------------------------------
;-------------------------------------------------
; initTimer: inicializa o timer do jogo
; funcao: armazena o segundo atual do sistema para controle de tempo
; parametros de entrada: nenhum
; parametros de saida: atualiza variavel lastsecond
;-------------------------------------------------
initTimer proc
    push ax
    push dx
    
    mov ah, 2Ch
    int 21h
    mov [lastSecond], dh
    
    pop dx
    pop ax
    ret
initTimer endp

;-------------------------------------------------
; updateTimer: atualiza tempo e score por segundo
;-------------------------------------------------
; updateTimer: atualiza o timer do jogo
; funcao: decrementa o tempo restante e adiciona pontos por segundo
; parametros de entrada: nenhum
; parametros de saida: pode alterar gametime, playerscore e gamestate
;-------------------------------------------------
updateTimer proc
    push ax
    push dx
    
    mov ah, 2Ch
    int 21h
    
    cmp dh, [lastSecond]
    jne .processaSegundo
    jmp timerFim

.processaSegundo:
    ; --- um novo segundo comecou ---
    mov [lastSecond], dh
    
    mov ax, [gameTime]
    cmp ax, 0
    je gameOverTrigger
    
    ; --- se o tempo nao acabou ---
    ; 1. decrementa o tempo
    dec ax
    mov [gameTime], ax
    call updateTimeString

    ; 2. adiciona score baseado na fase atual (usando constantes)
    mov ax, [playerScore]
    
    cmp [currentPhase], 1
    je .scoreFase1
    cmp [currentPhase], 2
    je .scoreFase2
    
    ; se for fase 3 (ou maior)
    add ax, SCORE_FASE_3  ; <--- usa constante (20)
    jmp .saveScoreTimer

.scoreFase1:
    add ax, SCORE_FASE_1  ; <--- usa constante (10)
    jmp .saveScoreTimer

.scoreFase2:
    add ax, SCORE_FASE_2  ; <--- usa constante (15)

.saveScoreTimer:
    mov [playerScore], ax
    call updateScoreString
    
    jmp timerFim
    
gameOverTrigger:
    ; --- fim do tempo = proxima fase ---
    inc [currentPhase]
    cmp [currentPhase], 4
    je .gameWin
    
    ; mostra tela de transicao
    mov al, [currentPhase]
    call showTransitionScreen
    
    ; reseta timer
    mov [gameTime], GAME_START_TIME
    call updateTimeString
    
    ; limpa inimigos e tiros para a nova fase
    mov cx, MAX_TIROS
    xor bx, bx
.limpaTirosFase:
    mov [tirosAtivo + bx], 0
    inc bx
    loop .limpaTirosFase
    
    mov cx, MAX_ENEMIES
    xor bx, bx
.limpaInimigosFase:
    mov [enemiesActive + bx], 0
    inc bx
    loop .limpaInimigosFase
    
    jmp timerFim

.gameWin:
    mov [gameState], 3 ; 3 = vencedor
    mov [stateTimer], 50 ; delay de ~1 segundo
    jmp timerFim

timerFim:
    pop dx
    pop ax
    ret
updateTimer endp

;-------------------------------------------------
;-------------------------------------------------
; updateScoreString: converte score para string
; funcao: converte o valor numerico do score para representacao ascii
; parametros de entrada: playerscore
; parametros de saida: atualiza strscorevalue com string do score
;-------------------------------------------------
updateScoreString proc
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov ax, [playerScore]
    ; aponta para o ultimo digito de '00000' (offset 4)
    mov si, offset strScoreValue + 4 
    mov bx, 10
    mov cx, 5 

digitLoop:
    xor dx, dx  
    div bx      
    
    add dl, '0' 
    mov [si], dl 
    
    dec si      
    loop digitLoop
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
updateScoreString endp

;-------------------------------------------------
;-------------------------------------------------
; updateTimeString: converte tempo para string
; funcao: converte o valor numerico do tempo para representacao ascii
; parametros de entrada: gametime
; parametros de saida: atualiza strtempovalue com string do tempo
;-------------------------------------------------
updateTimeString proc
    push ax
    push bx
    push dx
    
    mov ax, [gameTime]
    xor dx, dx
    mov bl, 10
    div bl
    
    add al, '0'
    add ah, '0'
    
    ; atualiza na string separada (indices 0 e 1)
    mov [strTempoValue], al     ; dezena
    mov [strTempoValue + 1], ah ; unidade
    
    pop dx
    pop bx
    pop ax
    ret
updateTimeString endp

; -----------------------------------------------------------------
;-------------------------------------------------
; spawnTiro: cria um tiro se houver slot vazio
; funcao: procura slot livre no array de tiros e inicializa novo tiro
; parametros de entrada: playerx, playery
; parametros de saida: atualiza arrays tirosx, tirosy, tirosativo
;-------------------------------------------------
spawnTiro proc
    push ax
    push bx
    push cx
    push si

    mov cx, MAX_TIROS
    xor bx, bx
    lea si, tirosAtivo

.procuraSlot:
    mov al, [si + bx]
    cmp al, 0
    je .slotLivre
    inc bx
    loop .procuraSlot
    jmp .fimSpawn

.slotLivre:
    ; ativa o tiro
    mov byte ptr [si + bx], 1
    
    ; define posicao x (nave x + 29)
    mov di, bx
    shl di, 1           ; multiplica indice por 2 (para word)
    
    mov ax, [playerX]
    add ax, 24          ; sai da ponta da nave (aprox)
    mov [tirosX + di], ax
    
    ; define posicao y (nave y + 6)
    mov ax, [playerY]
    add ax, 6           ; sai do meio da altura
    mov [tirosY + di], ax

.fimSpawn:
    pop si
    pop cx
    pop bx
    pop ax
    ret
spawnTiro endp

; -----------------------------------------------------------------
; updateTiros: move os tiros para a direita
; -----------------------------------------------------------------
updateTiros proc
    push ax
    push bx
    push cx
    push di
    push si

    mov cx, MAX_TIROS
    xor bx, bx
    lea si, tirosAtivo

.loopUpdate:
    mov al, [si + bx]
    cmp al, 0
    je .proxUpdate

    mov di, bx
    shl di, 1
    
    ; move x + 8 pixels (rapido)
    mov ax, [tirosX + di]
    add ax, 8
    mov [tirosX + di], ax
    
    ; verifica se saiu da tela (320)
    cmp ax, 320
    jl .proxUpdate
    
    ; desativa se saiu
    mov byte ptr [si + bx], 0

.proxUpdate:
    inc bx
    loop .loopUpdate

    pop si
    pop di
    pop cx
    pop bx
    pop ax
    ret
updateTiros endp

; -----------------------------------------------------------------
; drawTiros: desenha tiros usando drawGenericSprite
; -----------------------------------------------------------------
drawTiros proc
    push ax
    push bx
    push cx
    push di
    push si

    mov cx, MAX_TIROS
    xor bx, bx
    lea si, tirosAtivo

.loopDraw:
    mov al, [si + bx]
    cmp al, 0
    je .proxDraw

    mov di, bx
    shl di, 1
    
    ; chama drawgenericsprite(x, y, offset, largura, altura)
    ; [bp+12]=x, [bp+10]=y, [bp+8]=offset, [bp+6]=w, [bp+4]=h
    
    push [tirosX + di]      ; x
    push [tirosY + di]      ; y
    push offset tiroSprite  ; offset
    push 4                  ; largura (4 pixels)
    push 1                  ; altura (1 pixel)
    call drawGenericSprite

.proxDraw:
    inc bx
    loop .loopDraw

    pop si
    pop di
    pop cx
    pop bx
    pop ax
    ret
drawTiros endp

;-------------------------------------------------
; spawnEnemy: cria inimigos
; funcao: gera novos inimigos em posicoes aleatorias acima do terreno
; parametros de entrada: nenhum
; parametros de saida: atualiza arrays enemiesx, enemiesy, enemiesactive
;-------------------------------------------------
spawnEnemy proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ; 1. verifica timer de spawn
    dec [enemySpawnTimer]
    jz @@continuaSpawn
    jmp .fimSpawnEnemy      ; jump longo para label distante
    
@@continuaSpawn:
    ; --- logica de intervalo ---
    mov ah, 00h
    int 1Ah     ; retorna cx:dx (ticks). cx e alterado aqui!
    
    ; fase 1
    mov ax, dx
    xor dx, dx
    mov cx, 30
    div cx      
    add dx, 30  ; range: 30..60
    
    cmp [currentPhase], 2
    jl .setTimer
    
    ; fase 2 e 3 (rapido)
    mov ax, [tempWord]
    add ax, dx
    xor dx, dx
    mov cx, 30
    div cx             
    add dx, 10         ; range: 10..40

.setTimer:
    mov [enemySpawnTimer], dl

    ; 2. procura slot livre
    mov cx, MAX_ENEMIES
    xor bx, bx
    lea si, enemiesActive

.procuraSlotEnemy:
    mov al, [si + bx]
    cmp al, 0
    je .slotLivreEnemy
    inc bx
    loop .procuraSlotEnemy
    jmp .fimSpawnEnemy

.slotLivreEnemy:
    ; 3. ativa inimigo
    mov byte ptr [si + bx], 1
    
    mov di, bx
    shl di, 1
    
    ; x = 320
    mov word ptr [enemiesX + di], 320
    
    ; --- calcular y aleatorio (respeitando terreno) ---
    
    push di             ; salva indice do inimigo
    push bx
    
    ; calcula posicao no mapa considerando scroll + x=320
    mov ax, [terrainScroll]
    add ax, 320         ; posicao x do spawn
    
    cmp [currentPhase], 3
    je @@spawnFase3
    
    ; --- fase 1 e 2: terrainmap ---
    ; indice = (scroll + 320) / 8
    mov bl, 8
    div bl              ; al = indice
    xor ah, ah
    mov si, ax
    
    ; wrap around no mapa (120 entradas)
@@wrapLoop1:
    cmp si, 120
    jl @@idxSpawnOk
    sub si, 120
    jmp @@wrapLoop1
@@idxSpawnOk:
    
    ; le altura (10-30) e escala (*3)
    mov al, [terrainMap + si]
    xor ah, ah
    mov bl, 3
    mul bl              ; ax = altura em pixels (30-90)
    
    ; y do topo do terreno = 200 - altura
    mov cx, 200
    sub cx, ax
    jmp @@calcYEnemy
    
@@spawnFase3:
    ; --- fase 3: phase3map ---
    mov bl, 24
    div bl              ; al = indice
    xor ah, ah
    mov si, ax
    
    ; wrap around (60 entradas)
@@wrapLoop3:
    cmp si, 60
    jl @@idxSpawnOkF3
    sub si, 60
    jmp @@wrapLoop3
@@idxSpawnOkF3:
    
    ; le altura em blocos (1-5) e converte (*16)
    mov al, [phase3Map + si]
    xor ah, ah
    shl ax, 4           ; * 16, ax = 16-80
    
    ; y do topo do terreno = 200 - altura
    mov cx, 200
    sub cx, ax
    
@@calcYEnemy:
    ; cx = y do topo do terreno (limite inferior para o inimigo)
    ; inimigo precisa spawnar acima desse valor
    ; y minimo = 25 (abaixo da status bar)
    ; y maximo = cx - 15 (sprite tem 13 de altura + margem)
    
    pop bx
    pop di              ; restaura indice do inimigo
    
    ; ajusta cx para ser o y maximo do inimigo (acima do terreno)
    sub cx, 15          ; cx = limite superior do terreno - margem
    
    ; se cx < 40, o terreno esta muito alto, spawn fixo no topo
    cmp cx, 40
    jg @@terrainOk
    mov cx, 40
@@terrainOk:
    
    ; range = cx - 25 (y maximo - y minimo)
    mov ax, cx
    sub ax, 25          ; ax = range disponivel
    
    ; se range < 10, usa spawn fixo
    cmp ax, 10
    jg @@rangeOk
    mov dx, 30          ; y fixo se nao tem espaco
    jmp @@setYEnemy
    
@@rangeOk:
    ; gera y aleatorio
    push cx             ; salva y maximo
    push ax             ; salva range
    
    ; obtem valor do relogio
    mov ah, 00h
    int 1Ah             ; dx = ticks
    
    ; usa ticks + indice + scroll para aleatoriedade
    mov ax, dx
    add ax, bx          ; adiciona indice (0-4)
    shl ax, 3           ; multiplica por 8 para mais variacao
    add ax, [terrainScroll]
    
    pop cx              ; cx = range
    xor dx, dx
    div cx              ; dx = resto (0..range-1)
    
    pop cx              ; cx = y maximo
    
    ; y final = 25 + resto (sempre acima do terreno)
    add dx, 25
    
@@setYEnemy:
    mov [enemiesY + di], dx

.fimSpawnEnemy:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
spawnEnemy endp

; -----------------------------------------------------------------
;-------------------------------------------------
; updateEnemies: move inimigos para a esquerda
; funcao: atualiza posicao de todos os inimigos ativos movendo-os horizontalmente
; parametros de entrada: nenhum
; parametros de saida: atualiza arrays enemiesx e enemiesactive
;-------------------------------------------------
updateEnemies proc
    push ax
    push bx
    push cx
    push dx
    push di
    push si

    mov cx, MAX_ENEMIES
    xor bx, bx
    lea si, enemiesActive

.loopUpdateEnemies:
    mov al, [si + bx]
    cmp al, 0
    je .proxUpdateEnemy

    mov di, bx
    shl di, 1
    
    ; velocidade baseada na fase
    mov dx, 4 ; velocidade padrao (fase 1)
    cmp [currentPhase], 3
    jne .moveEnemy
    mov dx, 6 ; velocidade rapida (fase 3)

.moveEnemy:
    mov ax, [enemiesX + di]
    sub ax, dx
    mov [enemiesX + di], ax
    
    ; verifica se saiu da tela (x < -30)
    cmp ax, -30
    jg .proxUpdateEnemy
    
    ; desativa se saiu
    mov byte ptr [si + bx], 0

.proxUpdateEnemy:
    inc bx
    loop .loopUpdateEnemies

    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
updateEnemies endp

;-------------------------------------------------
; drawEnemies: desenha inimigos ativos
; funcao: renderiza todos os inimigos ativos no buffer de video
; parametros de entrada: nenhum
; parametros de saida: inimigos desenhados no buffer
;-------------------------------------------------
drawEnemies proc
    push ax
    push bx
    push cx
    push dx
    push di
    push si

    mov cx, MAX_ENEMIES
    xor bx, bx
    lea si, enemiesActive

.loopDrawEnemies:
    mov al, [si + bx]
    cmp al, 0
    je .proxDrawEnemy

    mov di, bx
    shl di, 1
    
    ; seleciona sprite baseado na fase
    mov dx, offset alienSprite ; padrao (fase 1 e 3)
    cmp [currentPhase], 2
    jne .drawTheEnemy
    mov dx, offset meteoroSprite ; fase 2

.drawTheEnemy:
    push [enemiesX + di]    ; x
    push [enemiesY + di]    ; y
    push dx                 ; offset do sprite
    push SPRITE_LARGURA
    push SPRITE_ALTURA
    call drawGenericSprite

.proxDrawEnemy:
    inc bx
    loop .loopDrawEnemies

    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
drawEnemies endp

;-------------------------------------------------
; checkCollisions: verifica colisoes
; funcao: detecta colisoes entre nave-inimigo e tiro-inimigo
; parametros de entrada: nenhum
; parametros de saida: pode atualizar playerlives, playerscore, arrays de tiros e inimigos
;-------------------------------------------------
checkCollisions proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    ; --- 1. nave vs inimigos ---
    mov cx, MAX_ENEMIES
    xor bx, bx
    lea si, enemiesActive

.loopColNave:
    mov al, [si + bx]
    cmp al, 0
    je .proxColNave

    mov di, bx
    shl di, 1
    
    ; carrega coords do inimigo
    mov ax, [enemiesX + di] ; x2
    mov dx, [enemiesY + di] ; y2
    
    ; checa colisao com player (x1, y1)
    ; player: [playerx], [playery], w=29, h=13
    ; enemy: ax, dx, w=29, h=13
    
    ; x1 < x2 + w2  => playerx < enemyx + 29
    mov bp, ax
    add bp, SPRITE_LARGURA
    cmp [playerX], bp
    jge .proxColNave
    
    ; x1 + w1 > x2 => playerx + 29 > enemyx
    mov bp, [playerX]
    add bp, SPRITE_LARGURA
    cmp bp, ax
    jle .proxColNave
    
    ; y1 < y2 + h2 => playery < enemyy + 13
    mov bp, dx
    add bp, SPRITE_ALTURA
    cmp [playerY], bp
    jge .proxColNave
    
    ; y1 + h1 > y2 => playery + 13 > enemyy
    mov bp, [playerY]
    add bp, SPRITE_ALTURA
    cmp bp, dx
    jle .proxColNave
    
    ; --- colisao detectada (nave vs inimigo) ---
    ; 1. remove inimigo
    mov byte ptr [si + bx], 0
    
    ; 2. perde vida
    dec [playerLives]
    cmp [playerLives], 0
    jle .triggerGameOver
    
    ; 3. reseta posicao player (feedback visual simples)
    mov [playerX], 10
    mov [playerY], 100
    jmp .proxColNave

.triggerGameOver:
    mov [gameState], 2
    mov [stateTimer], 50 ; delay de ~1 segundo
    jmp .fimCollisions

.proxColNave:
    inc bx
    loop .loopColNave


    ; --- 2. tiros vs inimigos ---
    ; loop externo: tiros
    ; loop interno: inimigos
    
    mov cx, MAX_TIROS
    xor bx, bx ; index tiro
    
.loopTiro:
    cmp [tirosAtivo + bx], 0
    jne .processTiro
    jmp .proxTiroCheck
.processTiro:
    
    ; pega coords do tiro
    mov di, bx
    shl di, 1
    mov ax, [tirosX + di] ; tirox
    mov dx, [tirosY + di] ; tiroy
    ; tiro w=4, h=1
    
    push bx ; salva index tiro
    push cx ; salva contador tiros
    
    ; loop interno (inimigos)
    mov cx, MAX_ENEMIES
    xor bx, bx ; index inimigo
    lea si, enemiesActive
    
.loopEnemyTiro:
    mov al, [si + bx]
    cmp al, 0
    je .proxEnemyTiro
    
    push di
    mov di, bx
    shl di, 1
    mov si, [enemiesX + di] ; enemyx
    mov bp, [enemiesY + di] ; enemyy
    pop di
    
    ; ax=tirox, dx=tiroy
    ; si=enemyx, bp=enemyy
    
    ; check x: tirox < enemyx + 29
    mov word ptr [tempWord], si
    add word ptr [tempWord], SPRITE_LARGURA
    mov di, [tempWord]
    cmp ax, di
    jge .proxEnemyTiro
    
    ; check x: tirox + 4 > enemyx
    mov word ptr [tempWord], ax
    add word ptr [tempWord], 4
    mov di, [tempWord]
    cmp di, si
    jle .proxEnemyTiro
    
    ; check y: tiroy < enemyy + 13
    mov word ptr [tempWord], bp
    add word ptr [tempWord], SPRITE_ALTURA
    mov di, [tempWord]
    cmp dx, di
    jge .proxEnemyTiro
    
    ; check y: tiroy + 1 > enemyy
    mov word ptr [tempWord], dx
    add word ptr [tempWord], 1
    mov di, [tempWord]
    cmp di, bp
    jle .proxEnemyTiro
    
    ; --- colisao tiro vs inimigo ---
    
    ; 1. verifica se eh meteoro (fase 2) -> indestrutivel
    cmp [currentPhase], 2
    je .meteoroHit
    
    ; 2. remove inimigo (se nao for meteoro)
    ; bx eh index inimigo
    lea si, enemiesActive
    mov byte ptr [si + bx], 0 
    
    ; 3. adiciona score
    mov ax, [playerScore]
    add ax, 100 ; base 100
    cmp [currentPhase], 3
    jne .saveScore
    add ax, 50 ; +50 se fase 3 (total 150)
.saveScore:
    mov [playerScore], ax
    call updateScoreString
    
.meteoroHit:
    ; 4. remove tiro (mesmo em meteoro, o tiro some)
    pop cx ; restaura contador tiros
    pop bx ; restaura index tiro
    
    mov [tirosAtivo + bx], 0
    
    ; continua para o proximo tiro
    jmp .proxTiroCheck

.proxEnemyTiro:
    inc bx
    dec cx
    jz .fimLoopEnemy
    jmp .loopEnemyTiro
.fimLoopEnemy:
    
    ; fim loop interno
    pop cx ; restaura contador tiros
    pop bx ; restaura index tiro

.proxTiroCheck:
    inc bx
    dec cx
    jz .fimLoopTiro
    jmp .loopTiro
.fimLoopTiro:

.fimCollisions:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
checkCollisions endp

; -----------------------------------------------------------------
; drawRectToBuffer (com clipping)
; desenha retangulo solido respeitando os limites da tela
; [bp+12] = x
; [bp+10] = y
; [bp+8]  = w
; [bp+6]  = h
; [bp+4]  = cor
; -----------------------------------------------------------------
drawRectToBuffer proc
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push di
    
    mov ax, [bp+12] ; x
    mov cx, [bp+8]  ; w (largura)

    ; --- 1. clipping esquerda (x < 0) ---
    cmp ax, 0
    jge .checkRight
    ; se x negativo (ex: -5), reduz a largura e come?a em 0
    add cx, ax      ; w = w + (-5) -> diminui largura
    cmp cx, 0
    jle .fimRect    ; se largura ficou <= 0, n?o desenha nada
    mov ax, 0       ; novo x = 0
    
.checkRight:
    ; --- 2. clipping direita (x + w > 320) ---
    mov bx, ax
    add bx, cx      ; posi??o final (x + w)
    cmp bx, 320
    jle .calcAddr
    ; se passou da direita, corta o excesso
    sub bx, 320     ; excesso
    sub cx, bx      ; nova largura = w - excesso
    cmp cx, 0
    jle .fimRect

.calcAddr:
    ; calcula endere?o inicial no buffer: di = (y * 320) + x
    push ax         ; salva x j? corrigido
    mov ax, [bp+10] ; y
    mov bx, 320
    mul bx
    pop bx          ; recupera x
    add ax, bx
    mov di, ax
    
    ; prepara loop vertical
    mov dx, [bp+6]  ; h (altura)
    mov bl, [bp+4]  ; cor (salva em bl para usar al no stosb)

.loopRectY:
    push cx         ; salva largura
    push di         ; salva inicio da linha atual
    
    mov al, bl      ; move cor para al
    rep stosb       ; desenha a linha
    
    pop di
    add di, 320     ; pula para a mesma posi??o na linha de baixo
    pop cx          ; recupera largura
    
    dec dx          ; decrementa altura
    jnz .loopRectY

.fimRect:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 10
drawRectToBuffer endp

;-------------------------------------------------
; updateTerrainScroll: atualiza o offset do terreno
; funcao: move o terreno para criar efeito de scrolling horizontal
; parametros de entrada: nenhum
; parametros de saida: atualiza variavel terrainscroll
;-------------------------------------------------
updateTerrainScroll proc
    mov ax, [terrainScroll]
    add ax, 2              ; velocidade
    
    cmp ax, 1440           ; limite
    jl .saveScroll
    sub ax, 1440           ; reset
    
.saveScroll:
    mov [terrainScroll], ax
    ret
updateTerrainScroll endp

;-------------------------------------------------
; checkTerrainCollision: verifica colisao da nave com o terreno
; funcao: detecta se a nave colidiu com o terreno e aplica penalidade
; parametros de entrada: playerx, playery, terrainscroll
; parametros de saida: pode atualizar playerlives e gamestate
;-------------------------------------------------
checkTerrainCollision proc
    push ax
    push bx
    push cx
    push dx
    push si
    
    ; --- calcula a altura do terreno na posicao da nave ---
    ; posicao x do "pe" da nave = playerx + sprite_largura/2
    mov ax, [playerX]
    add ax, 14              ; centro da nave
    
    ; adiciona o scroll para saber qual coluna do mapa
    add ax, [terrainScroll]
    
    ; --- fase 3: usa phase3map ---
    cmp [currentPhase], 3
    je @@checkFase3Terrain
    
    ; --- fase 1 e 2: usa terrainmap ---
    ; indice no mapa = (x total) / 8 (cada coluna tem 8px de largura no mapa)
    mov bl, 8
    div bl              ; al = indice
    xor ah, ah
    mov si, ax
    
    ; limita ao tamanho do mapa (120 entradas)
    cmp si, 120
    jl @@idxOkTerrain
    sub si, 120
@@idxOkTerrain:
    
    ; le a altura do terreno (10-30)
    mov al, [terrainMap + si]
    xor ah, ah
    
    ; altura em pixels = altura * 3 (escala)
    mov bl, 3
    mul bl
    
    ; y do topo do terreno = 200 - altura_pixels
    mov bx, 200
    sub bx, ax          ; bx = y do topo do terreno
    
    jmp @@checkColisaoTerrain
    
@@checkFase3Terrain:
    ; indice no mapa = (x total) / 24
    mov bl, 24
    div bl              ; al = indice
    xor ah, ah
    mov si, ax
    
    ; limita ao tamanho do mapa (60 entradas)
    cmp si, 60
    jl @@idxOkF3Terrain
    sub si, 60
@@idxOkF3Terrain:
    
    ; le a altura em blocos (1-5)
    mov al, [phase3Map + si]
    xor ah, ah
    
    ; altura em pixels = blocos * 16
    shl ax, 4           ; * 16
    
    ; y do topo do terreno = 200 - altura_pixels
    mov bx, 200
    sub bx, ax          ; bx = y do topo do terreno
    
@@checkColisaoTerrain:
    ; --- verifica se a nave colidiu ---
    ; y do "pe" da nave = playery + sprite_altura
    mov ax, [playerY]
    add ax, SPRITE_ALTURA
    
    ; se playery + altura > y_topo_terreno, colidiu
    cmp ax, bx
    jl @@semColisaoTerrain
    
    ; --- colisao com terreno ---
    dec [playerLives]
    cmp [playerLives], 0
    jle @@gameOverTerrain
    
    ; reseta posicao
    mov [playerX], 10
    mov [playerY], 100
    jmp @@semColisaoTerrain
    
@@gameOverTerrain:
    mov [gameState], 2
    mov [stateTimer], 50
    
@@semColisaoTerrain:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
checkTerrainCollision endp

; -----------------------------------------------------------------
;-------------------------------------------------
; drawTerrain: desenha terreno variado
; funcao: renderiza o terreno com scrolling baseado na fase atual
; parametros de entrada: currentphase, terrainscroll
; parametros de saida: terreno desenhado no buffer
;-------------------------------------------------
drawTerrain proc
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    
    ; verifica fase 3
    cmp [currentPhase], 3
    je .drawFase3Terrain
    
    ; --- fase 1 e 2: terreno com montanhas ---
    cmp [currentPhase], 2
    je .corFase2
    mov [tempWord], 3       ; fase 1: ciano
    jmp .desenhaMontanhas
.corFase2:
    mov [tempWord], 4       ; fase 2: vermelho

.desenhaMontanhas:
    ; desenha 42 colunas de 8px cada (336px, cobre a tela + margem)
    mov cx, 42
    
    ; x inicial = -(terrainscroll % 8)
    mov ax, [terrainScroll]
    and ax, 7           ; mod 8
    neg ax              ; x negativo para suavidade
    
    ; indice inicial = terrainscroll / 8
    push ax             ; salva x
    mov ax, [terrainScroll]
    shr ax, 3           ; div 8
    mov bx, ax          ; bx = indice inicial
    pop ax              ; recupera x
    
.loopMontanha:
    push cx
    push ax             ; salva x
    push bx             ; salva index
    
    ; limita indice ao tamanho do mapa (120)
    cmp bx, 120
    jl .idxMontOk
    sub bx, 120
.idxMontOk:
    
    ; le altura do mapa (10-30)
    push ax
    mov si, bx
    mov al, [terrainMap + si]
    xor ah, ah
    
    ; altura em pixels = valor * 3
    mov bl, 3
    mul bl
    mov dx, ax          ; dx = altura em pixels
    pop ax
    
    ; y = 200 - altura
    push ax
    mov ax, 200
    sub ax, dx
    mov si, ax          ; si = y do topo
    pop ax
    
    ; desenha coluna
    push ax             ; x
    push si             ; y
    push 8              ; w (8 pixels)
    push dx             ; h (altura)
    push [tempWord]     ; cor
    call drawRectToBuffer
    
    pop bx              ; recupera index
    inc bx              ; proximo indice
    
    pop ax              ; recupera x
    add ax, 8           ; avanca 8 pixels
    
    pop cx
    loop .loopMontanha
    
    jmp .fimTerrain

    ; --- fase 3: plataformas ---
.drawFase3Terrain:
    mov cx, 15      ; desenha 15 colunas na tela
    
    ; 1. x inicial
    mov ax, [terrainScroll]
    mov bl, 24
    div bl
    mov al, ah      ; resto
    xor ah, ah
    neg ax          ; x negativo para suavidade
    
    ; 2. ?ndice inicial
    mov bx, [terrainScroll]
    push ax         ; salva x
    mov ax, [terrainScroll]
    mov dl, 24
    div dl
    xor ah, ah
    mov bx, ax      ; bx = ?ndice inicial (0 a 59)
    pop ax          ; recupera x
    
.loopColunasF3:
    push cx
    push ax         ; salva x
    push bx         ; salva index
    
    ; 3. ler altura do mapa
    ; o ?ndice bx j? vem certo, mas precisamos garantir que ele 
    ; n?o estourou 60 no passo anterior.
    
    ; seguran?a: for?a bx para dentro de 0-59 (caso raro)
    cmp bx, 60
    jl .idxSeguro
    sub bx, 60
.idxSeguro:
    
    xor ah, ah
    mov al, [phase3Map + bx] ; l? altura
    xor ah, ah
    
    ; se altura for 0 (erro de leitura), corrige para 1
    cmp ax, 0
    jne .alturaOk
    mov ax, 1
.alturaOk:
    mov cx, ax      ; cx = altura em blocos
    
    ; 4. desenhar coluna
    mov si, 200     ; y do ch?o
    
.loopEmpilha:
    sub si, 16      ; sobe 16px
    
    mov bp, sp
    mov ax, [bp+2]  ; pega x
    
    push ax         ; x
    push si         ; y
    
    cmp cx, 1
    je .tijolo
    push offset columnSprite
    jmp .desenhaBloco
.tijolo:
    push offset brickSprite
.desenhaBloco:
    push 24         ; w
    push 16         ; h
    call drawGenericSprite
    
    loop .loopEmpilha
    
    ; --- l?gica de wrap around (cr?tico) ---
    pop bx
    inc bx          ; pr?ximo ?ndice
    cmp bx, 60      ; chegou no fim do mapa (60)?
    jl .proxIteracao
    mov bx, 0       ; volta para o come?o (0)
.proxIteracao:
    
    pop ax
    add ax, 24      ; avan?a x
    
    pop cx
    dec cx
    jnz .loopColunasF3

.fimTerrain:
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
drawTerrain endp

end main