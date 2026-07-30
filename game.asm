.db "NES", $1a, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

  .org $C000

PAD_DATA    = $00
POS_X_LO    = $02
POS_X_HI    = $03
POS_Y_LO    = $04
POS_Y_HI    = $05
SPEED_LO    = $06
SPEED_HI    = $07

RESET:
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

vblank1:
  BIT $2002
  BPL vblank1

clrmem:
  LDA #$00
  STA $000,x
  STA $100,x
  STA $300,x
  STA $400,x
  STA $500,x
  STA $600,x
  STA $700,x
  LDA #$FE
  STA $200,x
  INX
  BNE clrmem

vblank2:
  BIT $2002
  BPL vblank2

  JSR init_ppu

  LDA #$00
  STA POS_X_LO
  STA POS_Y_LO
  LDA #120
  STA POS_X_HI
  LDA #112
  STA POS_Y_HI

  LDA #%00000000
  STA $2000
  LDA #%00011110
  STA $2001

main_loop:
  JSR wait_vblank
  JSR read_controller
  JSR update_player
  JSR update_sprites
  JMP main_loop

wait_vblank:
  BIT $2002
  BPL wait_vblank
  LDA #$00
  STA $2003
  LDA #$02
  STA $4014
  RTS

init_ppu:
  LDA $2002
  LDA #$3F
  STA $2006
  LDA #$00
  STA $2006

  LDX #$00
load_pal_loop:
  LDA palette_data,x
  STA $2007
  INX
  CPX #32
  BNE load_pal_loop
  RTS

read_controller:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016
  LDX #$08
read_pad_loop:
  LDA $4016
  LSR A
  ROL PAD_DATA
  DEX
  BNE read_pad_loop
  RTS

update_player:
  LDA #$00
  STA SPEED_LO
  LDA #$01
  STA SPEED_HI

  LDA PAD_DATA
  AND #%00000011
  BEQ no_diagonal
  LDA PAD_DATA
  AND #%00001100
  BEQ no_diagonal

  LDA #$B5
  STA SPEED_LO
  LDA #$00
  STA SPEED_HI

no_diagonal:
  LDA PAD_DATA
  AND #%00000001
  BEQ check_left
  CLC
  LDA POS_X_LO
  ADC SPEED_LO
  STA POS_X_LO
  LDA POS_X_HI
  ADC SPEED_HI
  STA POS_X_HI

check_left:
  LDA PAD_DATA
  AND #%00000010
  BEQ check_down
  SEC
  LDA POS_X_LO
  SBC SPEED_LO
  STA POS_X_LO
  LDA POS_X_HI
  SBC SPEED_HI
  STA POS_X_HI

check_down:
  LDA PAD_DATA
  AND #%00000100
  BEQ check_up
  CLC
  LDA POS_Y_LO
  ADC SPEED_LO
  STA POS_Y_LO
  LDA POS_Y_HI
  ADC SPEED_HI
  STA POS_Y_HI

check_up:
  LDA PAD_DATA
  AND #%00001000
  BEQ move_done
  SEC
  LDA POS_Y_LO
  SBC SPEED_LO
  STA POS_Y_LO
  LDA POS_Y_HI
  SBC SPEED_HI
  STA POS_Y_HI

move_done:
  RTS

update_sprites:
  LDA POS_Y_HI
  STA $0200
  LDA #$01
  STA $0201
  LDA #$00
  STA $0202
  LDA POS_X_HI
  STA $0203

  LDA POS_Y_HI
  STA $0204
  LDA #$02
  STA $0205
  LDA #$00
  STA $0206
  CLC
  LDA POS_X_HI
  ADC #$08
  STA $0207

  CLC
  LDA POS_Y_HI
  ADC #$08
  STA $0208
  LDA #$03
  STA $0209
  LDA #$00
  STA $020A
  LDA POS_X_HI
  STA $020B

  CLC
  LDA POS_Y_HI
  ADC #$08
  STA $020C
  LDA #$04
  STA $020D
  LDA #$00
  STA $020E
  CLC
  LDA POS_X_HI
  ADC #$08
  STA $020F
  RTS

NMI:
  RTI

IRQ:
  RTI

palette_data:
  .db $0F, $00, $10, $30, $0F, $00, $10, $30
  .db $0F, $00, $10, $30, $0F, $00, $10, $30
  .db $0F, $00, $10, $30, $0F, $10, $00, $20
  .db $0F, $00, $10, $30, $0F, $00, $10, $30

  .pad $FFFA
  .dw NMI, RESET, IRQ

; [AUTO-FIXED]   .org $0000
; [AUTO-FIXED]   .pad $0010, $00

  .db %00000011
  .db %00000111
  .db %00001111
  .db %00011101
  .db %00111101
  .db %01111111
  .db %11111111
  .db %11111111
  .db %00000000
  .db %00000010
  .db %00000010
  .db %00000010
  .db %00000010
  .db %00000000
  .db %00000000
  .db %00000000

  .db %11000000
  .db %11100000
  .db %11110000
  .db %10111000
  .db %10111100
  .db %11111110
  .db %11111111
  .db %11111111
  .db %00000000
  .db %01000000
  .db %01000000
  .db %01000000
  .db %01000000
  .db %00000000
  .db %00000000
  .db %00000000

  .db %11111111
  .db %01111101
  .db %00111101
  .db %00011101
  .db %10001101
  .db %11001101
  .db %11001001
  .db %01000000
  .db %00000000
  .db %00000010
  .db %00000010
  .db %00000010
  .db %00000010
  .db %00000010
  .db %00000110
  .db %00000110

  .db %11111111
  .db %10111110
  .db %10111100
  .db %10111000
  .db %10110001
  .db %10110011
  .db %10010011
  .db %00000010
  .db %00000000
  .db %01000000
  .db %01000000
  .db %01000000
  .db %01000000
  .db %01000000
  .db %01100000
  .db %00110000

; [AUTO-FIXED]   .pad $2000, $00
