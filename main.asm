.model small
.stack 100h

; ============================================
; ARQUIVO: main.asm
; (Implementado Score/seg e Game Over)
; ============================================

; --- Segmento do Buffer (para Double Buffering) ---
BUFFER_SEG SEGMENT
    buffer db 64000 dup(0)
BUFFER_SEG ENDS

.data
    ; --- Constantes de Teclado ---
    TECLA_CIMA    EQU 72
    TECLA_BAIXO   EQU 80
    TECLA_ESQUERDA EQU 75
    TECLA_DIREITA EQU 77
    TECLA_ENTER   EQU 13
    TECLA_ESC     EQU 1

    ; --- Constantes de Cor ---
    COR_VERDE_CLARO EQU 0Ah
    COR_BRANCA_TXT  EQU 0Fh
    COR_VERMELHA_CLARO EQU 0Ch
    COR_CIANO_CLARO EQU 0Bh

    ; --- Constantes do Jogo ---
    STATUS_BAR_HEIGHT EQU 16
    GAME_START_TIME   EQU 40 ; (Tempo em segundos)
    SCORE_PER_SECOND  EQU 10 ; (Pontos ganhos por segundo)

    ; --- Includes de DADOS ---
    INCLUDE strings.asm
    INCLUDE sprites.asm
    INCLUDE font.asm

    ; --- Vari?veis de Estado ---
    gameState        db 0  ; 0 = Menu, 1 = Jogo, 2 = Game Over
    currentPhase     db 1
    opcaoSelecionada db 0
    teclaPressionada dw 0
    
    ; --- Vari?veis de Scrolling ---
    terrainScroll    dw 0
    
    ; --- Vari?veis das Anima??es do Menu ---
    naveX    dw 0
    naveY    dw 60
    meteoroX dw 319 - SPRITE_LARGURA
    meteoroY dw 75
    alienX   dw 160
    alienY   dw 90
    alienDir db 1
    
    naveLastX    dw 0
    naveLastY    dw 60
    meteoroLastX dw 319 - SPRITE_LARGURA
    meteoroLastY dw 75
    alienLastX   dw 160
    alienLastY   dw 90

    ; --- Vari?veis do Jogo ---
    playerX         dw 10
    playerY         dw 100
    playerLastX     dw 10
    playerLastY     dw 100
    playerVelocidade EQU 3
    playerLives     db 3
    playerScore     dw 0
    gameTime        dw GAME_START_TIME
    
    lastSecond      db 99
    
    ; --- Variaveis dos Inimigos ---
    MAX_ENEMIES     EQU 5
    enemiesX        dw MAX_ENEMIES dup(0)
    enemiesY        dw MAX_ENEMIES dup(0)
    enemiesActive   db MAX_ENEMIES dup(0) ; 0=Inativo, 1=Ativo
    enemySpawnTimer db 0
    enemySpawnRate  db 30 ; Frames entre spawns (ajustavel)

    ; --- Variaveis dos Tiros ---
    MAX_TIROS       EQU 5
    tirosX          dw MAX_TIROS dup(0) ; Posicao X
    tirosY          dw MAX_TIROS dup(0) ; Posicao Y
    tirosAtivo      db MAX_TIROS dup(0) ; 0=Inativo, 1=Ativo
    
    tempWord        dw 0 ; Variavel temporaria para calculos
    
    TECLA_ESPACO    EQU 57              ; Scan code (39h = 57 decimal)
    
    ; --- Timer de Estado (para evitar saida imediata) ---
    stateTimer      db 0

.code
INCLUDE graphics.asm

main proc
    ; 1. Inicializa DS para @data
    mov ax, @data
    mov ds, ax
    
    ; 2. Configura o modo de v?deo
    call setupVideoMode

    ; 3. Configura ES para o BUFFER_SEG
    mov ax, BUFFER_SEG
    mov es, ax
    ; (DS = @data, ES = BUFFER_SEG)
    
    ; 4. Inicia o loop mestre do jogo
masterLoop:
    ; 1. L? o teclado (sempre)
    call checkInput
    
    ; 2. Limpa o buffer
    call clearBuffer
    
    ; 3. Verifica o estado do jogo
    cmp [gameState], 0
    je runMenu
    cmp [gameState], 1
    je runGame
    cmp [gameState], 2
    je runGameOver
    
    ; Se for 3 (Vencedor)
    jmp runGameWin

runMenu:
    ; --- L?gica do Estado de Menu ---
    call drawMenuToBuffer
    call updateAnims
    call drawAnims
    call handleMenuInput
    jmp drawFrame

runGame:
    ; --- L?gica do Estado de Jogo ---
    call handleGameInput
    call updatePlayer
    call updateTiros
    call spawnEnemy     ; <--- NOVO
    call updateEnemies  ; <--- NOVO
    call checkCollisions ; <--- NOVO (Colisoes)
    call updateTimer
    call updateTerrainScroll ; <--- NOVO (Scrolling)
    call drawStatusBar
    call drawPlayer
    call drawTiros
    call drawEnemies    ; <--- NOVO
    call drawTerrain    ; <--- NOVO
    jmp drawFrame

runGameOver:
    ; --- L?gica do Estado de Game Over ---
    call drawGameOverScreen
    call handleGameOverInput
    jmp drawFrame

runGameWin:
    ; --- Logica do Estado de Vencedor ---
    call drawWinScreen
    call handleGameOverInput ; Reusa input (qualquer tecla volta ao menu)
    jmp drawFrame

drawFrame:
    ; --- Desenha e repete ---
    call copyBufferToVideo
    
    push 20000 ; 20ms (50 FPS te?ricos)
    call delay
    
    jmp masterLoop

exitGame:
    ; Restaura o modo de texto
    mov ax, 0003h
    int 10h
    
    ; Termina o programa
    mov ax, 4C00h
    int 21h
main endp


; --- Rotinas de L?gica (DS = @data, ES = BUFFER_SEG) ---

;-------------------------------------------------
; checkInput: Apenas l? o teclado
;-------------------------------------------------
checkInput proc
    mov [teclaPressionada], 0
    
    mov ah, 01h
    int 16h
    jz noKey

    mov ah, 00h
    int 16h
    mov [teclaPressionada], ax
noKey:
    ret
checkInput endp

;-------------------------------------------------
; handleMenuInput: Processa a entrada do menu
;-------------------------------------------------
handleMenuInput proc
    mov ax, [teclaPressionada]
    cmp ax, 0
    je menuInputFim

    cmp ah, TECLA_CIMA
    je pressionouCima
    cmp ah, TECLA_BAIXO
    je pressionouBaixo
    cmp al, TECLA_ENTER
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
    je exitGame
    
    ; --- Iniciar Jogo ---
    call resetGameVars
    
    mov [currentPhase], 1       ; Define Fase 1
    mov al, [currentPhase]      ; Passa o n?mero 1 para AL
    call showTransitionScreen   ; <--- CHAMA A NOVA TELA
    
    mov [gameState], 1          ; Muda para o jogo
    call initTimer
    
    jmp menuInputFim
    
menuInputFim:
    ret
handleMenuInput endp

;-------------------------------------------------
; handleGameInput: Processa a entrada do jogo
;-------------------------------------------------
handleGameInput proc
    mov ax, [teclaPressionada]
    cmp ax, 0
    je gameInputFim

    cmp ah, TECLA_ESC
    je exitGame
    
    cmp ah, TECLA_ESPACO
    je tentarAtirar
    jmp gameInputFim

tentarAtirar:
    call spawnTiro
    jmp gameInputFim
    
gameInputFim:
    ret
handleGameInput endp

;-------------------------------------------------
; handleGameOverInput: Processa a entrada do Game Over
;-------------------------------------------------
handleGameOverInput proc
    ; Verifica Timer de Estado
    cmp [stateTimer], 0
    je .checkInputGO
    
    dec [stateTimer]
    ret ; Ignora input enquanto timer > 0

.checkInputGO:
    mov ax, [teclaPressionada]
    cmp ax, 0
    je gameOverFim ; Se nenhuma tecla, continua
    
    ; Se qualquer tecla for pressionada, volta ao menu
    mov [gameState], 0
    
gameOverFim:
    ret
handleGameOverInput endp


; -----------------------------------------------------------------
; showTransitionScreen
; Desenha a arte ASCII da Fase correspondente
; -----------------------------------------------------------------
showTransitionScreen proc
    push ax
    push cx
    push dx
    
    call clearBuffer        ; Limpa a tela

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
    push 4
    push 76
    push COR_CIANO_CLARO
    push offset fase1Linha1
    call drawStringToBuffer
    push 4
    push 84
    push COR_CIANO_CLARO
    push offset fase1Linha2
    call drawStringToBuffer
    push 4
    push 92
    push COR_CIANO_CLARO
    push offset fase1Linha3
    call drawStringToBuffer
    push 4
    push 100
    push COR_CIANO_CLARO
    push offset fase1Linha4
    call drawStringToBuffer
    push 4
    push 108
    push COR_CIANO_CLARO
    push offset fase1Linha5
    call drawStringToBuffer
    push 4
    push 116
    push COR_CIANO_CLARO
    push offset fase1Linha6
    call drawStringToBuffer
    jmp .waitTransition

.drawFase2:
    push 4
    push 76
    push COR_VERMELHA_CLARO
    push offset fase2Linha1
    call drawStringToBuffer
    push 4
    push 84
    push COR_VERMELHA_CLARO
    push offset fase2Linha2
    call drawStringToBuffer
    push 4
    push 92
    push COR_VERMELHA_CLARO
    push offset fase2Linha3
    call drawStringToBuffer
    push 4
    push 100
    push COR_VERMELHA_CLARO
    push offset fase2Linha4
    call drawStringToBuffer
    push 4
    push 108
    push COR_VERMELHA_CLARO
    push offset fase2Linha5
    call drawStringToBuffer
    push 4
    push 116
    push COR_VERMELHA_CLARO
    push offset fase2Linha6
    call drawStringToBuffer
    jmp .waitTransition

.drawFase3:
    push 4
    push 76
    push COR_VERDE_CLARO
    push offset fase3Linha1
    call drawStringToBuffer
    push 4
    push 84
    push COR_VERDE_CLARO
    push offset fase3Linha2
    call drawStringToBuffer
    push 4
    push 92
    push COR_VERDE_CLARO
    push offset fase3Linha3
    call drawStringToBuffer
    push 4
    push 100
    push COR_VERDE_CLARO
    push offset fase3Linha4
    call drawStringToBuffer
    push 4
    push 108
    push COR_VERDE_CLARO
    push offset fase3Linha5
    call drawStringToBuffer
    push 4
    push 116
    push COR_VERDE_CLARO
    push offset fase3Linha6
    call drawStringToBuffer
    jmp .waitTransition

.waitTransition:
    ; --- Mostra na tela e espera ---
    call copyBufferToVideo
    
    ; Delay de ~4 segundos
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
; drawGameOverScreen: Desenha o texto "GAME OVER"
;-------------------------------------------------
drawGameOverScreen proc
    ; X = (320 - (9 chars * 8 pixels)) / 2 = 124
    ; Y = (200 - 8 pixels) / 2 = 96
    push 124 ; X
    push 96  ; Y
    push COR_VERMELHA_CLARO
    push offset strGameOver
    call drawStringToBuffer
    ret
drawGameOverScreen endp

;-------------------------------------------------
; drawWinScreen: Desenha o texto "VENCEDOR!" e Score
;-------------------------------------------------
drawWinScreen proc
    ; VENCEDOR (Verde)
    push 124 ; X
    push 96  ; Y
    push COR_VERDE_CLARO
    push offset strVencedor
    call drawStringToBuffer
    
    ; Score (Branco)
    push 116 ; X
    push 110 ; Y
    push COR_BRANCA_TXT
    push offset strScore
    call drawStringToBuffer
    
    ret
drawWinScreen endp


;-------------------------------------------------
; drawStatusBar: Desenha a barra de status
;-------------------------------------------------
drawStatusBar proc
    push ax
    push bx
    
    ; 1. Desenha "SCORE: 00000"
    push 8
    push 4
    push COR_VERDE_CLARO
    push offset strScore
    call drawStringToBuffer
    
    ; 2. Desenha "TEMPO: 60"
    push 232
    push 4
    push COR_VERDE_CLARO
    push offset strTempo
    call drawStringToBuffer

    ; 3. Desenha Naves de Vida
    mov ax, 111
    mov bx, 2
    
    mov cl, [playerLives]
    cmp cl, 0
    jle .fimLives
    xor ch, ch
    
.loopLives:
    push ax
    push bx
    push offset naveAliadaSprite
    call drawSprite
    
    add ax, SPRITE_LARGURA
    add ax, 5
    loop .loopLives

.fimLives:
    pop bx
    pop ax
    ret
drawStatusBar endp


;-------------------------------------------------
; updatePlayer: Move o jogador
;-------------------------------------------------
updatePlayer proc
    mov ax, [playerX]
    mov [playerLastX], ax
    mov ax, [playerY]
    mov [playerLastY], ax

    mov ax, [teclaPressionada]
    cmp ax, 0
    je playerMoveFim
    
    mov bx, playerVelocidade

    ; Cima
    cmp ah, TECLA_CIMA
    jne checkBaixo
    sub [playerY], bx
    cmp [playerY], STATUS_BAR_HEIGHT
    jge playerMoveFim
    mov [playerY], STATUS_BAR_HEIGHT
    jmp playerMoveFim
checkBaixo:
    cmp ah, TECLA_BAIXO
    jne checkEsquerda
    add [playerY], bx
    mov ax, [playerY]
    cmp ax, (200 - SPRITE_ALTURA)
    jle playerMoveFim
    mov [playerY], (200 - SPRITE_ALTURA)
    jmp playerMoveFim
checkEsquerda:
    cmp ah, TECLA_ESQUERDA
    jne checkDireita
    sub [playerX], bx
    cmp [playerX], 0
    jge playerMoveFim
    mov [playerX], 0
    jmp playerMoveFim
checkDireita:
    cmp ah, TECLA_DIREITA
    jne playerMoveFim
    add [playerX], bx
    mov ax, [playerX]
    cmp ax, (320 - SPRITE_LARGURA)
    jle playerMoveFim
    mov [playerX], (320 - SPRITE_LARGURA)
playerMoveFim:
    ret
updatePlayer endp


;-------------------------------------------------
; drawPlayer: Apaga e desenha o jogador
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
; drawMenuToBuffer: Desenha o menu completo no buffer
;-------------------------------------------------
drawMenuToBuffer proc
    push ax
    push bx
    
    ; --- 1. Desenha o T?tulo ---
    push 1*8
    push 3*8
    push COR_VERDE_CLARO
    push offset tituloLinha1
    call drawStringToBuffer
    push 1*8
    push 4*8
    push COR_VERDE_CLARO
    push offset tituloLinha2
    call drawStringToBuffer
    push 1*8
    push 5*8
    push COR_VERDE_CLARO
    push offset tituloLinha3
    call drawStringToBuffer
    push 1*8
    push 6*8
    push COR_VERDE_CLARO
    push offset tituloLinha4
    call drawStringToBuffer

    ; --- 2. Define as cores dos bot?es ---
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
    
    ; --- 3. Desenha o bot?o "Jogar" ---
    push 104
    push 136
    push 14
    push 3
    push COR_BRANCA_TXT
    call drawBoxToBuffer
    push 112
    push 144
    push ax
    push offset strJogar
    call drawStringToBuffer

    ; --- 4. Desenha o bot?o "Sair" ---
    push 104
    push 168
    push 14
    push 3
    push COR_BRANCA_TXT
    call drawBoxToBuffer
    push 112
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
; updateAnims: Atualiza as coordenadas (Menu)
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
    
    add [naveX], 2
    mov ax, [naveX]
    cmp ax, 320
    jle naveOk
    mov [naveX], 0 - SPRITE_LARGURA
naveOk:
    sub [meteoroX], 2
    mov ax, [meteoroX]
    cmp ax, 0 - SPRITE_LARGURA
    jge meteoroOk
    mov [meteoroX], 320
meteoroOk:
    cmp [alienDir], 1
    je alienEsquerda
alienDireita:
    add [alienX], 2
    mov ax, [alienX]
    cmp ax, (320 - SPRITE_LARGURA)
    jl alienOk
    mov [alienX], (320 - SPRITE_LARGURA)
    mov [alienDir], 1
    jmp alienOk
alienEsquerda:
    sub [alienX], 2
    mov ax, [alienX]
    cmp ax, 0
    jg alienOk
    mov [alienX], 0
    mov [alienDir], 0
alienOk:
    ret
updateAnims endp


;-------------------------------------------------
; drawAnims: Desenha sprites (Menu)
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
; delay: Pausa a execu??o
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
; --- ROTINAS DE JOGO (NOVAS E ATUALIZADAS) ---
; -----------------------------------------------

;-------------------------------------------------
; resetGameVars: Reseta o Score, Tempo e Vidas
;-------------------------------------------------
resetGameVars proc
    mov [gameTime], GAME_START_TIME
    mov [playerScore], 0
    mov [playerLives], 3
    
    ; Reseta posi??o do jogador
    mov [playerX], 10
    mov [playerY], 100
    mov [playerLastX], 10
    mov [playerLastY], 100
    
    ; Limpa array de tiros
    mov cx, MAX_TIROS
    xor bx, bx          ; Zera o indice (BX = 0)
.limpaTiros:
    mov [tirosAtivo + bx], 0  ; Desativa o tiro neste slot
    inc bx
    loop .limpaTiros

    ; Limpa array de inimigos
    mov cx, MAX_ENEMIES
    xor bx, bx
.limpaInimigos:
    mov [enemiesActive + bx], 0
    inc bx
    loop .limpaInimigos
    
    ; Reseta Timer de Spawn para 1 (Spawn imediato)
    mov [enemySpawnTimer], 1
    
    ; Forca a atualizacao das strings
    call updateTimeString
    call updateScoreString
    ret
resetGameVars endp

;-------------------------------------------------
; initTimer: Pega o segundo atual e o armazena
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
; updateTimer: Compara o segundo atual com o ?ltimo salvo
; (MODIFICADO: Adiciona score e checa Game Over)
;-------------------------------------------------
updateTimer proc
    push ax
    push dx
    
    mov ah, 2Ch
    int 21h
    
    cmp dh, [lastSecond]
    je timerFim ; Se for igual, 1 segundo n?o passou
    
    ; --- Um novo segundo come?ou ---
    mov [lastSecond], dh
    
    mov ax, [gameTime]
    cmp ax, 0
    je gameOverTrigger ; Se o tempo ? 0, vai para Game Over
    
    ; --- Se o tempo n?o acabou ---
    ; 1. Decrementa o tempo
    dec ax
    mov [gameTime], ax
    call updateTimeString

    ; 2. Adiciona Score (REQUISI??O 1)
    mov ax, [playerScore]
    add ax, SCORE_PER_SECOND
    mov [playerScore], ax
    call updateScoreString
    
    jmp timerFim
    
gameOverTrigger:
    ; --- Fim do Tempo = Proxima Fase ---
    inc [currentPhase]
    cmp [currentPhase], 4
    je .gameWin
    
    ; Mostra Tela de Transicao
    mov al, [currentPhase]
    call showTransitionScreen
    
    ; Reseta Timer
    mov [gameTime], GAME_START_TIME
    call updateTimeString
    
    ; Limpa Inimigos e Tiros (Inline para simplificar)
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
    mov [gameState], 3 ; 3 = Vencedor
    mov [stateTimer], 50 ; Delay de ~1 segundo
    jmp timerFim

timerFim:
    pop dx
    pop ax
    ret
updateTimer endp

;-------------------------------------------------
; updateTimeString: Converte [gameTime] para 'strTempo'
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
    
    mov [strTempo + 7], al
    mov [strTempo + 8], ah
    
    pop dx
    pop bx
    pop ax
    ret
updateTimeString endp

;-------------------------------------------------
; updateScoreString: Converte [playerScore] para 'strScore'
; (Rotina 'itoa' para 5 d?gitos)
;-------------------------------------------------
updateScoreString proc
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov ax, [playerScore]
    mov si, offset strScore + 11 ; Aponta para o ?ltimo '0' de 'SCORE: 00000'
    mov bx, 10
    mov cx, 5 ; 5 d?gitos

digitLoop:
    xor dx, dx  ; Limpa o high-word do dividendo
    div bx      ; AX = AX / 10 -> AX = quociente, DX = resto
    
    add dl, '0' ; Converte o resto (0-9) para ASCII ('0'-'9')
    mov [si], dl ; Salva o d?gito na string
    
    dec si      ; Move para a esquerda
    loop digitLoop
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
updateScoreString endp

; -----------------------------------------------------------------
; spawnTiro: Cria um tiro se houver slot vazio
; -----------------------------------------------------------------
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
    ; Ativa o tiro
    mov byte ptr [si + bx], 1
    
    ; Define Posi??o X (Nave X + 29)
    mov di, bx
    shl di, 1           ; Multiplica ?ndice por 2 (para Word)
    
    mov ax, [playerX]
    add ax, 24          ; Sai da ponta da nave (aprox)
    mov [tirosX + di], ax
    
    ; Define Posi??o Y (Nave Y + 6)
    mov ax, [playerY]
    add ax, 6           ; Sai do meio da altura
    mov [tirosY + di], ax

.fimSpawn:
    pop si
    pop cx
    pop bx
    pop ax
    ret
spawnTiro endp

; -----------------------------------------------------------------
; updateTiros: Move os tiros para a direita
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
    
    ; Move X + 8 pixels (r?pido)
    mov ax, [tirosX + di]
    add ax, 8
    mov [tirosX + di], ax
    
    ; Verifica se saiu da tela (320)
    cmp ax, 320
    jl .proxUpdate
    
    ; Desativa se saiu
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
; drawTiros: Desenha tiros usando drawGenericSprite
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
    
    ; Chama drawGenericSprite(X, Y, Offset, Largura, Altura)
    ; [bp+12]=X, [bp+10]=Y, [bp+8]=Offset, [bp+6]=W, [bp+4]=H
    
    push [tirosX + di]      ; X
    push [tirosY + di]      ; Y
    push offset tiroSprite  ; Offset
    push 4                  ; Largura (4 pixels)
    push 1                  ; Altura (1 pixel)
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

; -----------------------------------------------------------------
; spawnEnemy: Cria inimigos periodicamente
; -----------------------------------------------------------------
spawnEnemy proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ; 1. Verifica Timer de Spawn
    dec [enemySpawnTimer]
    jnz .fimSpawnEnemy ; Se nao chegou a 0, sai

    ; Reset Timer
    mov al, [enemySpawnRate]
    mov [enemySpawnTimer], al

    ; 2. Procura Slot Livre
    mov cx, MAX_ENEMIES
    xor bx, bx
    lea si, enemiesActive

.procuraSlotEnemy:
    mov al, [si + bx]
    cmp al, 0
    je .slotLivreEnemy
    inc bx
    loop .procuraSlotEnemy
    jmp .fimSpawnEnemy ; Sem slots

.slotLivreEnemy:
    ; 3. Ativa Inimigo
    mov byte ptr [si + bx], 1
    
    mov di, bx
    shl di, 1
    
    ; X = 320 (Fora da tela a direita)
    mov word ptr [enemiesX + di], 320
    
    ; Y = Random (STATUS_BAR_HEIGHT + 10 ate 180)
    ; Usa System Time para Random
    mov ah, 00h
    int 1Ah ; DX = Clock ticks
    
    mov ax, dx
    xor dx, dx
    mov cx, 140 ; Range (180 - 40)
    div cx      ; DX = Resto (0..139)
    
    add dx, 30  ; Offset Y
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
; updateEnemies: Move inimigos para a esquerda
; -----------------------------------------------------------------
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
    
    ; Velocidade baseada na Fase
    mov dx, 2 ; Velocidade Padrao (Fase 1)
    cmp [currentPhase], 3
    jne .moveEnemy
    mov dx, 4 ; Velocidade Rapida (Fase 3)

.moveEnemy:
    mov ax, [enemiesX + di]
    sub ax, dx
    mov [enemiesX + di], ax
    
    ; Verifica se saiu da tela (X < -30)
    cmp ax, -30
    jg .proxUpdateEnemy
    
    ; Desativa se saiu
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

; -----------------------------------------------------------------
; drawEnemies: Desenha inimigos ativos
; -----------------------------------------------------------------
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
    
    ; Seleciona Sprite baseado na Fase
    mov dx, offset alienSprite ; Padrao (Fase 1 e 3)
    cmp [currentPhase], 2
    jne .drawTheEnemy
    mov dx, offset meteoroSprite ; Fase 2

.drawTheEnemy:
    push [enemiesX + di]    ; X
    push [enemiesY + di]    ; Y
    push dx                 ; Offset do Sprite
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

; -----------------------------------------------------------------
; checkCollisions: Verifica colisoes (Nave-Inimigo, Tiro-Inimigo)
; -----------------------------------------------------------------
checkCollisions proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    ; --- 1. Nave vs Inimigos ---
    mov cx, MAX_ENEMIES
    xor bx, bx
    lea si, enemiesActive

.loopColNave:
    mov al, [si + bx]
    cmp al, 0
    je .proxColNave

    mov di, bx
    shl di, 1
    
    ; Carrega coords do Inimigo
    mov ax, [enemiesX + di] ; X2
    mov dx, [enemiesY + di] ; Y2
    
    ; Checa colisao com Player (X1, Y1)
    ; Player: [playerX], [playerY], W=29, H=13
    ; Enemy: AX, DX, W=29, H=13
    
    ; X1 < X2 + W2  => playerX < enemyX + 29
    mov bp, ax
    add bp, SPRITE_LARGURA
    cmp [playerX], bp
    jge .proxColNave
    
    ; X1 + W1 > X2 => playerX + 29 > enemyX
    mov bp, [playerX]
    add bp, SPRITE_LARGURA
    cmp bp, ax
    jle .proxColNave
    
    ; Y1 < Y2 + H2 => playerY < enemyY + 13
    mov bp, dx
    add bp, SPRITE_ALTURA
    cmp [playerY], bp
    jge .proxColNave
    
    ; Y1 + H1 > Y2 => playerY + 13 > enemyY
    mov bp, [playerY]
    add bp, SPRITE_ALTURA
    cmp bp, dx
    jle .proxColNave
    
    ; --- COLISAO DETECTADA (Nave vs Inimigo) ---
    ; 1. Remove Inimigo
    mov byte ptr [si + bx], 0
    
    ; 2. Perde Vida
    dec [playerLives]
    cmp [playerLives], 0
    jl .triggerGameOver
    
    ; 3. Reseta Posicao Player (Feedback visual simples)
    mov [playerX], 10
    mov [playerY], 100
    jmp .proxColNave

.triggerGameOver:
    mov [gameState], 2
    mov [stateTimer], 50 ; Delay de ~1 segundo
    jmp .fimCollisions

.proxColNave:
    inc bx
    loop .loopColNave


    ; --- 2. Tiros vs Inimigos ---
    ; Loop externo: Tiros
    ; Loop interno: Inimigos
    
    mov cx, MAX_TIROS
    xor bx, bx ; Index Tiro
    
.loopTiro:
    cmp [tirosAtivo + bx], 0
    jne .processTiro
    jmp .proxTiro
.processTiro:
    
    ; Pega coords do Tiro
    mov di, bx
    shl di, 1
    mov ax, [tirosX + di] ; TiroX
    mov dx, [tirosY + di] ; TiroY
    ; Tiro W=4, H=1
    
    push bx ; Salva index Tiro
    push cx ; Salva contador Tiros
    
    ; Loop Interno (Inimigos)
    mov cx, MAX_ENEMIES
    xor bx, bx ; Index Inimigo
    lea si, enemiesActive
    
.loopEnemyTiro:
    mov al, [si + bx]
    cmp al, 0
    je .proxEnemyTiro
    
    push di
    mov di, bx
    shl di, 1
    mov si, [enemiesX + di] ; EnemyX
    mov bp, [enemiesY + di] ; EnemyY
    pop di
    
    ; AX=TiroX, DX=TiroY
    ; SI=EnemyX, BP=EnemyY
    
    ; Check X: TiroX < EnemyX + 29
    mov word ptr [tempWord], si
    add word ptr [tempWord], SPRITE_LARGURA
    mov di, [tempWord]
    cmp ax, di
    jge .proxEnemyTiro
    
    ; Check X: TiroX + 4 > EnemyX
    mov word ptr [tempWord], ax
    add word ptr [tempWord], 4
    mov di, [tempWord]
    cmp di, si
    jle .proxEnemyTiro
    
    ; Check Y: TiroY < EnemyY + 13
    mov word ptr [tempWord], bp
    add word ptr [tempWord], SPRITE_ALTURA
    mov di, [tempWord]
    cmp dx, di
    jge .proxEnemyTiro
    
    ; Check Y: TiroY + 1 > EnemyY
    mov word ptr [tempWord], dx
    add word ptr [tempWord], 1
    mov di, [tempWord]
    cmp di, bp
    jle .proxEnemyTiro
    
    ; --- COLISAO TIRO vs INIMIGO ---
    
    ; 1. Verifica se eh Meteoro (Fase 2) -> Indestrutivel
    cmp [currentPhase], 2
    je .meteoroHit
    
    ; 2. Remove Inimigo (Se nao for meteoro)
    ; BX eh index inimigo
    lea si, enemiesActive
    mov byte ptr [si + bx], 0 
    
    ; 3. Adiciona Score
    mov ax, [playerScore]
    add ax, 100 ; Base 100
    cmp [currentPhase], 3
    jne .saveScore
    add ax, 50 ; +50 se Fase 3 (Total 150)
.saveScore:
    mov [playerScore], ax
    call updateScoreString
    
.meteoroHit:
    ; 4. Remove Tiro
    pop cx ; Restaura contador Tiros
    pop bx ; Restaura index Tiro
    
    mov [tirosAtivo + bx], 0
    
    push cx ; Salva contador Tiros de novo para o jump
    jmp .proxTiro ; Vai pro proximo tiro (esse ja morreu)

.proxEnemyTiro:
    inc bx
    dec cx
    jz .fimLoopEnemy
    jmp .loopEnemyTiro
.fimLoopEnemy:
    
    ; Fim loop interno
    pop cx ; Restaura contador Tiros
    pop bx ; Restaura index Tiro

.proxTiro:
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
; drawRectToBuffer: Desenha retangulo solido
; [bp+12] = X
; [bp+10] = Y
; [bp+8]  = W
; [bp+6]  = H
; [bp+4]  = Cor
; -----------------------------------------------------------------
drawRectToBuffer proc
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push di
    
    mov ax, [bp+10] ; Y
    mov bx, 320
    mul bx
    add ax, [bp+12] ; X
    mov di, ax
    
    mov dx, [bp+6] ; H
.loopRectY:
    push di
    mov cx, [bp+8] ; W
    mov al, [bp+4] ; Cor
    rep stosb
    pop di
    add di, 320
    dec dx
    jnz .loopRectY
    
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 10
drawRectToBuffer endp

;-------------------------------------------------
; updateTerrainScroll: Atualiza o offset do terreno
;-------------------------------------------------
updateTerrainScroll proc
    inc [terrainScroll]
    ; Reseta a cada 320 pixels (opcional, mas bom para evitar overflow)
    cmp [terrainScroll], 320
    jl .fimScroll
    mov [terrainScroll], 0
.fimScroll:
    ret
updateTerrainScroll endp

; -----------------------------------------------------------------
; drawTerrain: Desenha o terreno baseado na fase
; -----------------------------------------------------------------
drawTerrain proc
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    
    cmp [currentPhase], 3
    je .drawFase3Terrain
    
    ; --- Fase 1 e 2: Montanhas (Scrolling) ---
    ; Desenha retangulos verdes na parte inferior
    ; Largura do bloco = 32
    
    mov cx, 12 ; Desenha 12 blocos para cobrir 320 + scroll
    
    ; Calcula X inicial baseado no scroll
    ; X = - (terrainScroll % 32)
    mov ax, [terrainScroll]
    and ax, 1Fh ; Mod 32 (0-31)
    neg ax      ; Come?a um pouco fora da tela a esquerda
    
    ; O indice do terreno tambem deve rolar
    ; Index = terrainScroll / 32
    mov bx, [terrainScroll]
    shr bx, 5   ; Div 32
    
.loopMontanhas:
    push cx
    push ax ; Salva X
    push bx ; Salva Index
    
    ; Altura pseudo-aleatoria baseada no Index (BX)
    ; Pseudo-random simples: (Index * 7 + 3) & 0Fh
    mov ax, bx
    mov dx, 7
    mul dx
    add ax, 3
    and ax, 0Fh ; 0-15
    
    mov dx, ax
    shl dx, 2   ; 0-60
    add dx, 20  ; 20-80 pixels de altura
    
    ; Y = 200 - Altura
    mov bx, 200
    sub bx, dx
    
    ; Recupera X da pilha (estava em AX antes)
    mov si, sp
    mov ax, [si+4] ; Pega X da pilha sem dar pop
    
    push ax ; X
    push bx ; Y
    push 32 ; W
    push dx ; H
    push 2  ; Cor (Verde)
    call drawRectToBuffer
    
    pop bx ; Recupera Index
    inc bx ; Proximo bloco do terreno
    
    pop ax ; Recupera X
    add ax, 32
    pop cx
    loop .loopMontanhas
    
    jmp .fimTerrain

.drawFase3Terrain:
    ; --- Fase 3: Colunas e Tijolos (Scrolling) ---
    ; Largura do bloco = 24
    
    mov cx, 15 ; 15 blocos * 24 = 360 pixels
    
    ; Calcula X inicial
    ; X = - (terrainScroll % 24)
    mov ax, [terrainScroll]
    mov bl, 24
    div bl ; AH = Resto
    mov al, ah
    xor ah, ah
    neg ax
    
    ; Index = terrainScroll / 24
    mov bx, [terrainScroll]
    push ax ; Salva X inicial temporariamente
    mov ax, [terrainScroll]
    mov dl, 24
    div dl
    xor ah, ah
    mov bx, ax ; BX = Index inicial
    pop ax ; Recupera X inicial
    
.loopColunas:
    push cx
    push ax ; Salva X
    push bx ; Salva Index
    
    ; Gera altura/tipo da plataforma baseado no Index (BX)
    ; Queremos plataformas de 2 a 4 colunas
    ; Vamos usar bits do Index para decidir altura
    
    ; Altura base: 1 a 5 blocos de altura (16px cada)
    ; Pseudo-random: ((Index * 13 + 7) % 5) + 1
    push ax
    mov ax, bx
    mov dx, 13
    mul dx
    add ax, 7
    mov dx, 0
    mov cx, 5
    div cx ; DX = Resto (0-4)
    inc dx ; 1-5
    mov cx, dx ; CX = Altura em blocos
    pop ax
    
    ; Desenha a pilha de colunas
    ; Y base = 200
    mov si, 200
    
.loopEmpilha:
    sub si, 16 ; Sobe 16 pixels
    
    push ax ; X
    push si ; Y
    
    ; Se for o ultimo bloco (topo), desenha tijolo
    cmp cx, 1
    je .desenhaTijolo
    
    push offset columnSprite
    jmp .doDraw
.desenhaTijolo:
    push offset brickSprite
.doDraw:
    push 24
    push 16
    call drawGenericSprite
    
    loop .loopEmpilha
    
    pop bx ; Recupera Index
    inc bx
    
    pop ax ; Recupera X
    add ax, 24
    pop cx
    loop .loopColunas

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