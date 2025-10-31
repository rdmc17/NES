; ================================================================
; Quatro Quadrantes Coloridos - Interativo com Scroll (Sem Mudar Cores)
; ================================================================
  .inesprg 1
  .ineschr 1
  .inesmap 0
  .inesmir 1

  .bank 0
  .org $C000

  .rsset $0000
scroll_x      .rs 1
scroll_y      .rs 1
buttons       .rs 1
prev_buttons  .rs 1
temp          .rs 2  ; Agora 2 bytes para endereço

_RESET:
    SEI
    CLD
    LDX #$40
    STX $4017
    LDX #$FF
    TXS
    INX
    STX $2000
    STX $2001
    STX $4010

; --- Aguarda VBlank ---
vblankwait1:
    BIT $2002
    BPL vblankwait1
vblankwait2:
    BIT $2002
    BPL vblankwait2

; --- Limpa RAM ---
    LDA #$00
    TAX
clear_ram:
    STA $0000, X
    STA $0100, X
    STA $0200, X
    STA $0300, X
    STA $0400, X
    STA $0500, X
    STA $0600, X
    STA $0700, X
    INX
    BNE clear_ram

; --- Inicializa variáveis ---
    LDA #$00
    STA scroll_x
    STA scroll_y
    STA buttons
    STA prev_buttons
    STA temp
    STA temp+1

; --- Desliga PPU ---
    LDA #$00
    STA $2000
    STA $2001

; --- Aguarda VBlank ---
    JSR wait_vblank

; --- Limpa Name Table e desenha quadrantes ---
    JSR draw_quadrants

; --- Paleta inicial (fixa com cores azul, verde, vermelho, roxo) ---
    JSR set_fixed_palette

; --- Atributos (define cor por quadrante) ---
    JSR init_attribute_table

; --- Scroll inicial e exibição ---
    LDA #$00
    STA $2005
    STA $2005
    LDA #%00001000
    STA $2001
    LDA #%10000000
    STA $2000

main_loop:
    ; Loop principal vazio, lógica movida para NMI para sincronização com frames
    JMP main_loop

_NMI:
    ; Lê entrada do controlador durante VBlank
    JSR read_controller

    ; Verifica setas para scroll contínuo (enquanto pressionado, scrolla a cada frame)
    LDA buttons
    AND #%00000001  ; Right
    BEQ no_right
    INC scroll_x  ; Scroll para a direita
no_right:

    LDA buttons
    AND #%00000010  ; Left
    BEQ no_left
    DEC scroll_x  ; Scroll para a esquerda
no_left:

    LDA buttons
    AND #%00000100  ; Down
    BEQ no_down
    INC scroll_y  ; Scroll para baixo
no_down:

    LDA buttons
    AND #%00001000  ; Up
    BEQ no_up
    DEC scroll_y  ; Scroll para cima
no_up:

    ; Atualiza scroll durante VBlank para evitar glitches
    LDA scroll_x
    STA $2005
    LDA scroll_y
    STA $2005
    RTI

; ===============================
; Espera VBlank
; ===============================
wait_vblank:
    BIT $2002
    BPL wait_vblank
    RTS

; ===============================
; Lê estado do controlador
; ===============================
read_controller:
    LDA #$01
    STA $4016
    LDA #$00
    STA $4016
    LDX #$08
read_loop:
    LDA $4016
    LSR A
    ROL buttons
    DEX
    BNE read_loop
    RTS

; ===============================
; Desenha 4 quadrados menores na Name Table (um por quadrante)
; ===============================
draw_quadrants:
    ; Quadrado superior esquerdo (azul, paleta 0) - posição aproximada 4x4 tiles
    LDA #$20
    STA $2006
    LDA #$40  ; Linha 2, coluna 2 (aprox. centro do quadrante sup. esq.)
    STA $2006
    LDX #$10  ; 16 tiles (4x4)
draw_quad1:
    LDA #$01
    STA $2007
    DEX
    BNE draw_quad1

    ; Quadrado superior direito (verde, paleta 1)
    LDA #$20
    STA $2006
    LDA #$45  ; Linha 2, coluna 18 (aprox. centro do quadrante sup. dir.)
    STA $2006
    LDX #$10
draw_quad2:
    LDA #$01
    STA $2007
    DEX
    BNE draw_quad2

    ; Quadrado inferior esquerdo (vermelho, paleta 2)
    LDA #$20
    STA $2006
    LDA #$C0  ; Linha 12, coluna 2 (aprox. centro do quadrante inf. esq.)
    STA $2006
    LDX #$10
draw_quad3:
    LDA #$01
    STA $2007
    DEX
    BNE draw_quad3

    ; Quadrado inferior direito (roxo, paleta 3)
    LDA #$20
    STA $2006
    LDA #$C5  ; Linha 12, coluna 18 (aprox. centro do quadrante inf. dir.)
    STA $2006
    LDX #$10
draw_quad4:
    LDA #$01
    STA $2007
    DEX
    BNE draw_quad4

    RTS

; ===============================
; Paleta fixa com cores específicas por paleta
; ===============================
set_fixed_palette:
    LDA #$3F
    STA $2006
    LDA #$00
    STA $2006
    ; Paleta 0 (azul): fundo preto, azul sólido
    LDA #$0F
    STA $2007
    LDA #$01  ; Azul
    STA $2007
    STA $2007
    STA $2007
    ; Paleta 1 (verde): fundo preto, verde sólido
    LDA #$0F
    STA $2007
    LDA #$1A  ; Verde
    STA $2007
    STA $2007
    STA $2007
    ; Paleta 2 (vermelho): fundo preto, vermelho sólido
    LDA #$0F
    STA $2007
    LDA #$06  ; Vermelho
    STA $2007
    STA $2007
    STA $2007
    ; Paleta 3 (roxo): fundo preto, roxo sólido
    LDA #$0F
    STA $2007
    LDA #$14  ; Roxo
    STA $2007
    STA $2007
    STA $2007
    ; Preenche o resto com preto
    LDX #$10
fill_rest:
    LDA #$0F
    STA $2007
    DEX
    BNE fill_rest
    RTS

; ===============================
; Tabela de atributos (4 quadrantes com paletas diferentes) - Inicial
; ===============================
init_attribute_table:
    LDA #$23
    STA $2006
    LDA #$C0
    STA $2006

    ; 4 linhas superiores (quadrantes sup.: paleta 0 esq, 1 dir)
    LDX #$04
upper_rows:
    LDA #$00  ; Paleta 0 para esq
    STA $2007
    STA $2007
    STA $2007
    STA $2007
    LDA #$55  ; Paleta 1 para dir
    STA $2007
    STA $2007
    STA $2007
    STA $2007
    DEX
    BNE upper_rows

    ; 4 linhas inferiores (quadrantes inf.: paleta 2 esq, 3 dir)
    LDX #$04
lower_rows:
    LDA #$AA  ; Paleta 2 para esq
    STA $2007
    STA $2007
    STA $2007
    STA $2007
    LDA #$FF  ; Paleta 3 para dir
    STA $2007
    STA $2007
    STA $2007
    STA $2007
    DEX
    BNE lower_rows
    RTS

_IRQ:
    RTI

  .bank 1
  .org $0000

; --- Dados CHR-ROM: Define um tile sólido para #$01 (preenchido com pixels) ---
; Tile 0: Vazio (não usado)
  .db $00,$00,$00,$00,$00,$00,$00,$00  ; Linha 1-8 (8 bytes por tile)
  .db $00,$00,$00,$00,$00,$00,$00,$00  ; (continua vazio)

; Tile 1: Sólido preenchido (usado para os quadrados)
  .db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; Linha 1: Todos os pixels ligados
  .db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; Linha 2
  .db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; Linha 3
  .db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; Linha 4
  .db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; Linha 5
  .db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; Linha 6
  .db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; Linha 7
  .db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; Linha 8

; Preenche o resto do CHR-ROM com zeros (tiles vazios)
  .org $1FF0  ; Vai para o final do banco 1 (4096 bytes)
  .db $00     ; Preenche com zeros até o fim

  .org $FFFA
  .dw _NMI
  .dw _RESET
  .dw _IRQ