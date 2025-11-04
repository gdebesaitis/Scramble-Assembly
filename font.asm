; ========================================
; FONT.ASM - CORRIGIDO
; Sistema de fontes e impress?o de texto
; ========================================

; ===== DESENHA STRING NO BUFFER =====
; SI = string, DH = linha (em caracteres), DL = coluna (em caracteres), BL = cor
DESENHA_STRING_BUF PROC NEAR
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI
    
LOOP_STR_BUF:
    MOV AL, [SI]
    CMP AL, 0
    JE FIM_STR_BUF
    
    PUSH DX
    PUSH SI
    CALL DESENHA_CHAR_BUF
    POP SI
    POP DX
    
    INC SI
    INC DL
    JMP LOOP_STR_BUF
    
FIM_STR_BUF:
    POP SI
    POP DX
    POP BX
    POP AX
    RET
DESENHA_STRING_BUF ENDP

; ===== DESENHA CARACTERE NO BUFFER =====
; AL = caractere, DH = linha (em caracteres), DL = coluna (em caracteres), BL = cor
DESENHA_CHAR_BUF PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    PUSH ES
    
    MOV AH, AL
    
    ; Configurar ES
    PUSH DS
    MOV AX, SEG video_buffer
    MOV ES, AX
    POP DS
    
    ; Calcular posi??o: (linha * 8 * 320) + (coluna * 8)
    PUSH AX
    MOV AL, DH
    MOV AH, 0
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
    ADD DI, OFFSET video_buffer
    POP AX
    
    ; Desenhar bloco 8x8
    MOV CX, 8
    MOV AL, BL
    
LOOP_CH_LIN_BUF:
    PUSH CX
    PUSH DI
    
    MOV CX, 8
    REP STOSB
    
    POP DI
    ADD DI, 320
    POP CX
    LOOP LOOP_CH_LIN_BUF
    
    POP ES
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHA_CHAR_BUF ENDP

; ===== DESENHA CAIXA NO BUFFER =====
; DH = linha (char), DL = coluna (char), CH = largura (char), CL = altura (char), BL = cor
DESENHA_CAIXA_BUF PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    ; Converter para pixels
    PUSH AX
    MOV AL, DH
    MOV AH, 0
    MOV SI, 8
    MUL SI
    PUSH AX             ; Y em pixels [BP-2]
    
    MOV AL, DL
    MOV AH, 0
    MUL SI
    PUSH AX             ; X em pixels [BP-4]
    
    MOV AL, CH
    MOV AH, 0
    MUL SI
    PUSH AX             ; Largura em pixels [BP-6]
    
    MOV AL, CL
    MOV AH, 0
    MUL SI
    MOV CX, AX          ; Altura em pixels
    POP SI              ; Largura em pixels
    POP BX              ; X em pixels
    POP DX              ; Y em pixels
    POP AX
    
    ; Desenhar caixa simples (apenas contorno)
    ; Linha superior
    PUSH CX
    MOV CX, SI
    MOV AL, BL
    CALL DESENHA_LINHA_H_BUF
    POP CX
    
    ; Linha inferior
    PUSH BX
    PUSH DX
    PUSH CX
    ADD DX, CX
    DEC DX
    MOV CX, SI
    MOV AL, BL
    CALL DESENHA_LINHA_H_BUF
    POP CX
    POP DX
    POP BX
    
    ; Laterais (simplificado - desenhar linhas verticais)
    PUSH BX
    PUSH DX
    MOV AX, CX
LOOP_LAT_ESQ:
    CMP AX, 0
    JE FIM_LAT_ESQ
    PUSH AX
    MOV AL, BL
    CALL DESENHA_PIXEL_BUF
    POP AX
    INC DX
    DEC AX
    JMP LOOP_LAT_ESQ
    
FIM_LAT_ESQ:
    POP DX
    POP BX
    ADD BX, SI
    DEC BX
    
    MOV AX, CX
LOOP_LAT_DIR:
    CMP AX, 0
    JE FIM_LAT_DIR
    PUSH AX
    MOV AL, BL
    CALL DESENHA_PIXEL_BUF
    POP AX
    INC DX
    DEC AX
    JMP LOOP_LAT_DIR
    
FIM_LAT_DIR:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHA_CAIXA_BUF ENDP

; ===== DESENHA N?MERO =====
; AX = n?mero, DH = linha, DL = coluna, BL = cor
DESENHA_NUMERO_BUF PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    ; Converter n?mero para string
    MOV CX, 10
    MOV SI, OFFSET temp_num_buffer + 5
    MOV BYTE PTR [SI], 0
    DEC SI
    
CONV_NUM_BUF:
    XOR DX, DX
    DIV CX
    ADD DL, '0'
    MOV [SI], DL
    DEC SI
    CMP AX, 0
    JNE CONV_NUM_BUF
    
    INC SI
    CALL DESENHA_STRING_BUF
    
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHA_NUMERO_BUF ENDP