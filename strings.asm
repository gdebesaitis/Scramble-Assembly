; ============================================
; ARQUIVO: strings.asm
; Define os dados de texto e strings
; ============================================

; --- Arte ASCII "Scramble" (Largura: 38 caracteres) ---
tituloLinha1 db '   ____                   __   __   ', 0
tituloLinha2 db '  / __/__________ ___ _  / /  / /__ ', 0
tituloLinha3 db ' _\ \/ __/ __/ _ `/  '' \/ _ \/ / -_)', 0
tituloLinha4 db '/___/\__/_/  \_,_/_/_/_/_.__/_/\__/ ', 0
                                
; --- Caixas do Menu (14 caracteres de largura) ---
boxJogarLinha1 db 218, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 191, 0
boxJogarLinha2 db 179, '            ', 179, 0 ; 12 espa?os
boxJogarLinha3 db 192, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 217, 0

boxSairLinha1 db 218, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 191, 0
boxSairLinha2 db 179, '            ', 179, 0 ; 12 espa?os
boxSairLinha3 db 192, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 217, 0

; --- Texto dos Bot?es (12 caracteres de largura) ---
strJogar db '   Jogar    ', 0
strSair  db '    Sair    ', 0

; --- Arte ASCII FASE 1 (6 linhas) ---
fase1Linha1 db '___________                       ____ ', 0
fase1Linha2 db '\_   _____/____    ______ ____   /_   |', 0
fase1Linha3 db ' |    __) \__  \  /  ___// __ \   |   |', 0
fase1Linha4 db ' |     \   / __ \_\___ \\  ___/   |   |', 0
fase1Linha5 db ' \___  /  (____  /____  >\___  >  |___|', 0
fase1Linha6 db '     \/        \/     \/     \/        ', 0

; --- FASE 2 ---
fase2Linha1 db '___________                       ________  ', 0
fase2Linha2 db '\_   _____/____    ______ ____    \_____  \ ', 0
fase2Linha3 db ' |    __) \__  \  /  ___// __ \    /  ____/ ', 0
fase2Linha4 db ' |     \   / __ \_\___ \\  ___/   /       \ ', 0
fase2Linha5 db ' \___  /  (____  /____  >\___  >  \_______ \', 0
fase2Linha6 db '     \/        \/     \/     \/   METEOROS\/', 0

; --- FASE 3 ---
fase3Linha1 db '___________                       ________  ', 0
fase3Linha2 db '\_   _____/____    ______ ____    \_____  \ ', 0
fase3Linha3 db ' |    __) \__  \  /  ___// __ \     _(__  < ', 0
fase3Linha4 db ' |     \   / __ \_\___ \\  ___/    /       \', 0
fase3Linha5 db ' \___  /  (____  /____  >\___  >  /______  /', 0
fase3Linha6 db '     \/        \/     \/     \/   CIDADE \/ ', 0

strGameOver db 'GAME OVER', 0
strVencedor db 'VENCEDOR!', 0 ; <--- NOVO

; (No final do arquivo strings.asm)
strScore db 'SCORE: 00000', 0
strTempo db 'TEMPO: 60', 0

