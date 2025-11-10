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

; (No final do arquivo strings.asm)
fase1Linha1 db ' ***** FASE 1 ***** ', 0
strGameOver db 'GAME OVER', 0  ; <<< ADICIONE ESTA LINHA

; (No final do arquivo strings.asm)
strScore db 'SCORE: 00000', 0
strTempo db 'TEMPO: 60', 0

