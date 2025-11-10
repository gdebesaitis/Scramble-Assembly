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

    ; --- Constantes do Jogo ---
    STATUS_BAR_HEIGHT EQU 16
    GAME_START_TIME   EQU 10 ; (Tempo em segundos)
    SCORE_PER_SECOND  EQU 10 ; (Pontos ganhos por segundo)

    ; --- Includes de DADOS ---
    INCLUDE strings.asm
    INCLUDE sprites.asm
    INCLUDE font.asm

    ; --- Vari?veis de Estado ---
    gameState        db 0  ; 0 = Menu, 1 = Jogo, 2 = Game Over
    opcaoSelecionada db 0
    teclaPressionada dw 0
    
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
    
    ; Se n?o for 0 ou 1, ? 2 (Game Over)
    jmp runGameOver

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
    call updateTimer
    call drawStatusBar
    call drawPlayer
    jmp drawFrame

runGameOver:
    ; --- L?gica do Estado de Game Over ---
    call drawGameOverScreen
    call handleGameOverInput
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
    
    ; Inicia o Jogo
    call resetGameVars ; <-- NOVO: Reseta o jogo
    call showPhase1Screen
    mov [gameState], 1
    call initTimer
    
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
    
gameInputFim:
    ret
handleGameInput endp

;-------------------------------------------------
; handleGameOverInput: Processa a entrada do Game Over
;-------------------------------------------------
handleGameOverInput proc
    mov ax, [teclaPressionada]
    cmp ax, 0
    je gameOverFim ; Se nenhuma tecla, continua
    
    ; Se qualquer tecla for pressionada, volta ao menu
    mov [gameState], 0
    
gameOverFim:
    ret
handleGameOverInput endp


;-------------------------------------------------
; showPhase1Screen: Mostra a tela "Fase 1"
;-------------------------------------------------
showPhase1Screen proc
    call clearBuffer
    
    push 80
    push 96
    push COR_BRANCA_TXT
    push offset fase1Linha1
    call drawStringToBuffer
    
    call copyBufferToVideo
    
    ; Pausa por 4 segundos
    mov cx, 200
delayFase:
    push 20000
    call delay
    loop delayFase
    
    ret
showPhase1Screen endp

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
    
    push ax
    push bx
    push offset naveAliadaSprite
    call drawSprite
    
    add ax, SPRITE_LARGURA
    add ax, 5
    push ax
    push bx
    push offset naveAliadaSprite
    call drawSprite

    add ax, SPRITE_LARGURA
    add ax, 5
    push ax
    push bx
    push offset naveAliadaSprite
    call drawSprite

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
    
    ; For?a a atualiza??o das strings
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
    ; --- REQUISI??O 2 (Game Over) ---
    mov [gameState], 2 ; Muda o estado para "Game Over"

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

end main