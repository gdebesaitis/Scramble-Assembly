; ============================================
; ARQUIVO: strings.asm
; Define os dados de texto e strings
; ============================================

; --- Arte ASCII "Scramble" ---
tituloLinha1 db '   ____                   __   __   ', 0
tituloLinha2 db '  / __/__________ ___ _  / /  / /__ ', 0
tituloLinha3 db ' _\ \/ __/ __/ _ `/  '' \/ _ \/ / -_)', 0
tituloLinha4 db '/___/\__/_/  \_,_/_/_/_/_.__/_/\__/ ', 0
                                
; --- Caixas do Menu (14 caracteres de largura) ---
boxJogarLinha1 db 218, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 191, 0
boxJogarLinha2 db 179, '            ', 179, 0
boxJogarLinha3 db 192, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 217, 0

boxSairLinha1 db 218, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 191, 0
boxSairLinha2 db 179, '            ', 179, 0
boxSairLinha3 db 192, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 217, 0

; --- Texto dos Botoes ---
strJogar db 'Jogar', 0
strSair  db 'Sair', 0

; --- FASE 1 ---
fase1Linha1 db ' _____   _    ____  _____    __ ', 0
fase1Linha2 db '|  ___| / \  / ___|| ____|  /  |', 0
fase1Linha3 db '| |_   / _ \ \___ \|  _|    `| |', 0
fase1Linha4 db '|  _| / ___ \ ___) | |___    | |', 0
fase1Linha5 db '|_|  /_/   \_\____/|_____|   |_|', 0
fase1Linha6 db '                                ', 0

; --- FASE 2 ---
fase2Linha1 db ' _____   _    ____  _____   ____  ', 0
fase2Linha2 db '|  ___| / \  / ___|| ____| |___ \ ', 0
fase2Linha3 db '| |_   / _ \ \___ \|  _|     __) |', 0
fase2Linha4 db '|  _| / ___ \ ___) | |___   / __/ ', 0
fase2Linha5 db '|_|  /_/   \_\____/|_____| |_____|', 0
fase2Linha6 db '                                  ', 0

; --- FASE 3 ---
fase3Linha1 db ' _____   _    ____  _____   _____ ', 0
fase3Linha2 db '|  ___| / \  / ___|| ____| |___ / ', 0
fase3Linha3 db '| |_   / _ \ \___ \|  _|     |_ \ ', 0
fase3Linha4 db '|  _| / ___ \ ___) | |___   ___) |', 0
fase3Linha5 db '|_|  /_/   \_\____/|_____| |____/ ', 0
fase3Linha6 db '                                  ', 0

; --- GAME OVER ---
gameOverL1  db '  ____   _    __  __ _____ ', 0
gameOverL2  db ' / ___| / \  |  \/  | ____|', 0
gameOverL3  db '| |  _ / _ \ | |\/| |  _|  ', 0
gameOverL4  db '| |_| / ___ \| |  | | |___ ', 0
gameOverL5  db ' \___/_/   \_\_|  |_|_____|', 0

gameOverL6      db '  ___ __     __ _____ ____  ', 0
gameOverL7      db ' / _ \\ \   / /| ____|  _ \ ', 0
gameOverL8      db '| | | |\ \ / / |  _| | |_) |', 0
gameOverL9      db '| |_| | \ V /  | |___|  _ < ', 0
gameOverL10     db ' \___/   \_/   |_____|_| \_\', 0

; --- VENCEDOR!  ---

venceL1 db '__     _______ _   _  ____ _____ ', 0
venceL2 db '\ \   / / ____| \ | |/ ___| ____|', 0
venceL3 db ' \ \ / /|  _| |  \| | |   |  _|  ', 0
venceL4 db '  \ V / | |___| |\  | |___| |___ ', 0
venceL5 db '   \_/  |_____|_| \_|\____|_____|', 0

dorL1 db ' ____   ___  ____  _ ', 0
dorL2 db '|  _ \ / _ \|  _ \| |', 0
dorL3 db '| | | | | | | |_) | |', 0
dorL4 db '| |_| | |_| |  _ <|_|', 0
dorL5 db '|____/ \___/|_| \_(_)', 0

strScoreLabel db 'SCORE: ', 0
strScoreValue db '00000', 0

strTempoLabel db 'TEMPO: ', 0
strTempoValue db '60', 0

