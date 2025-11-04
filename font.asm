; ========================================
; FONT.ASM
; Sistema de fontes e impress?o de texto
; ========================================

; ===== DESENHA STRING NA TELA (BIOS) =====
; Fun??o: Desenha uma string usando interrup??o BIOS
; Entrada: SI = offset string (terminada em 0), DH = linha, DL = coluna, BL = cor
; Sa?da: String desenhada na tela
; Destr?i: Nenhum (preserva todos os registradores)
DESENHA_STRING_BIOS PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH BP
    PUSH ES
    
    ; Contar tamanho da string
    PUSH SI
    XOR CX, CX
CONTA_STR:
    LODSB
    CMP AL, 0
    JE FIM_CONTA
    INC CX
    JMP CONTA_STR
FIM_CONTA:
    POP SI
    
    ; Configurar ES:BP para a string
    PUSH DS
    POP ES
    MOV BP, SI
    
    ; Chamar interrup??o
    MOV AH, 13h
    MOV AL, 1           ; Atualiza cursor
    MOV BH, 0           ; P?gina 0
    ; DH, DL, BL, CX, BP j? configurados
    INT 10h
    
    POP ES
    POP BP
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHA_STRING_BIOS ENDP

; ===== DESENHA STRING NO BUFFER =====
; Fun??o: Desenha uma string no buffer (caracteres simples 8x8)
; Entrada: SI = offset string, DH = linha, DL = coluna, BL = cor
; Sa?da: String desenhada no buffer
; Destr?i: Nenhum (preserva todos os registradores)
DESENHA_STRING_BUF PROC NEAR
    PUSH AX
    PUSH BX
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
    INC DL              ; Pr?xima coluna
    JMP LOOP_STR
    
FIM_STR:
    POP SI
    POP DX
    POP BX
    POP AX
    RET
DESENHA_STRING_BUF ENDP

; ===== DESENHA CARACTERE NO BUFFER =====
; Fun??o: Desenha um caractere 8x8 no buffer
; Entrada: AL = caractere, DH = linha, DL = coluna, BL = cor
; Sa?da: Caractere desenhado no buffer
; Destr?i: Nenhum (preserva todos os registradores)
DESENHA_CHAR_BUF PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    PUSH ES
    
    MOV AH, AL          ; Salvar caractere
    MOV AX, BUFFER_SEG
    MOV ES, AX
    
    ; Calcular posi??o no buffer (linha em pixels)
    PUSH AX
    MOV AL, DH
    MOV AH, 0
    MOV CX, 8           ; 8 pixels de altura
    MUL CX
    MOV CX, 320
    MUL CX
    MOV DI, AX
    
    MOV AL, DL
    MOV AH, 0
    MOV CX, 8           ; 8 pixels de largura
    MUL CX
    ADD DI, AX
    POP AX
    
    ; Desenhar bloco 8x8 (simplificado - bloco s?lido)
    MOV CX, 8
LOOP_CH_LIN:
    PUSH CX
    PUSH DI
    
    MOV AL, BL
    MOV CX, 8
    REP STOSB
    
    POP DI
    ADD DI, 320
    POP CX
    LOOP LOOP_CH_LIN
    
    POP ES
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHA_CHAR_BUF ENDP

; ===== DESENHA ASCII ART NO BUFFER =====
; Fun??o: Desenha uma linha de ASCII art no buffer
; Entrada: SI = offset linha, DH = linha, DL = coluna inicial, BL = cor
; Sa?da: Linha de ASCII art desenhada
; Destr?i: Nenhum (preserva todos os registradores)
DESENHA_ASCII_ART_LINHA PROC NEAR
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI
    
    MOV BH, DL          ; Salvar coluna inicial
    
LOOP_ART:
    MOV AL, [SI]
    CMP AL, 0
    JE FIM_ART
    
    ; Verificar se ? caractere especial UTF-8 (ignorar por enquanto)
    CMP AL, 80h
    JAE PROXIMO_ART
    
    PUSH DX
    PUSH SI
    CALL DESENHA_CHAR_BUF
    POP SI
    POP DX
    
PROXIMO_ART:
    INC SI
    INC DL
    JMP LOOP_ART
    
FIM_ART:
    POP SI
    POP DX
    POP BX
    POP AX
    RET
DESENHA_ASCII_ART_LINHA ENDP

; ===== DESENHA CAIXA NO BUFFER =====
; Fun??o: Desenha uma caixa com bordas usando caracteres ASCII
; Entrada: DH = linha, DL = coluna, CH = largura, CL = altura, BL = cor
; Sa?da: Caixa desenhada no buffer
; Destr?i: Nenhum (preserva todos os registradores)
DESENHA_CAIXA_BUF PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    PUSH ES
    
    MOV AX, BUFFER_SEG
    MOV ES, AX
    
    ; Calcular posi??o em pixels
    PUSH AX
    MOV AL, DH
    MOV AH, 0
    PUSH CX
    MOV CX, 8
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
    POP AX
    
    ; Salvar par?metros
    PUSH CX             ; Largura e altura
    PUSH DX             ; Linha e coluna
    
    ; Desenhar canto superior esquerdo
    MOV AL, CHAR_TOP_LEFT
    MOV ES:[DI], BL
    
    ; Linha superior
    INC DI
    MOV AL, BL
    PUSH CX
    MOV CL, CH
    MOV CH, 0
    DEC CX
    DEC CX
LOOP_TOP:
    MOV ES:[DI], AL
    INC DI
    LOOP LOOP_TOP
    POP CX
    
    ; Canto superior direito
    MOV ES:[DI], BL
    
    ; Laterais
    POP DX
    POP CX
    PUSH CX
    PUSH DX
    
    MOV AH, CL          ; Altura
    DEC AH
    DEC AH
    MOV AL, BL
    
LOOP_SIDES:
    ; Pr?xima linha
    PUSH DI
    XOR CX, CX
    MOV CL, CH
    SUB DI, CX
    ADD DI, 320
    MOV ES:[DI], AL     ; Esquerda
    
    MOV BH, 0
    MOV BL, CH
    ADD DI, BX
    DEC DI
    MOV ES:[DI], AL     ; Direita
    POP DI
    
    ADD DI, 320
    DEC AH
    JNZ LOOP_SIDES
    
    ; Linha inferior
    XOR CX, CX
    MOV CL, CH
    SUB DI, CX
    ADD DI, 320
    MOV ES:[DI], BL     ; Canto inferior esquerdo
    INC DI
    
    POP DX
    POP CX
    PUSH CX
    PUSH DX
    
    MOV AL, BL
    PUSH CX
    MOV CL, CH
    MOV CH, 0
    DEC CX
    DEC CX
LOOP_BOTTOM:
    MOV ES:[DI], AL
    INC DI
    LOOP LOOP_BOTTOM
    POP CX
    
    MOV ES:[DI], BL     ; Canto inferior direito
    
    POP DX
    POP CX
    POP ES
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHA_CAIXA_BUF ENDP

; ===== DESENHA N?MERO NO BUFFER =====
; Fun??o: Desenha um n?mero decimal no buffer
; Entrada: AX = n?mero, DH = linha, DL = coluna, BL = cor
; Sa?da: N?mero desenhado no buffer
; Destr?i: Nenhum (preserva todos os registradores)
DESENHA_NUMERO_BUF PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    ; Converter n?mero para string
    MOV CX, 10
    MOV SI, OFFSET temp_num_buffer + 5  ; Final do buffer
    MOV BYTE PTR [SI], 0                 ; Terminador
    DEC SI
    
CONV_NUM:
    XOR DX, DX
    DIV CX
    ADD DL, '0'
    MOV [SI], DL
    DEC SI
    CMP AX, 0
    JNE CONV_NUM
    
    INC SI
    POP DX              ; Restaurar DH, DL
    PUSH DX
    CALL DESENHA_STRING_BUF
    
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHA_NUMERO_BUF ENDP

; Buffer tempor?rio para convers?o de n?meros
temp_num_buffer DB 6 DUP(0)