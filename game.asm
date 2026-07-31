.db "NES", $1a, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

  .org $C000

PAD_DATA      = $00
PAD_PREV      = $01
POS_X_LO      = $02
POS_X_HI      = $03
POS_Y_LO      = $04
POS_Y_HI      = $05
SPEED_LO      = $06
SPEED_HI      = $07
PAD_TRIG      = $08
PLAYER_DIR    = $09

BULLET_ACTIVE = $10
BULLET_X      = $14
BULLET_Y      = $18
BULLET_DIR    = $1C

ENEMY_ACTIVE  = $20
ENEMY_X       = $24
ENEMY_Y       = $28
ENEMY_TYPE    = $2C

SCROLL_Y      = $30
FRAME_CNT     = $31
RANDOM_SEED   = $32

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
  JSR clear_nametable
  JSR build_bg

  LDA #$00
  STA POS_X_LO
  STA POS_Y_LO
  STA PAD_PREV
  STA SCROLL_Y
  STA FRAME_CNT
  LDA #$55
  STA RANDOM_SEED
  LDA #$03
  STA PLAYER_DIR
  LDA #120
  STA POS_X_HI
  LDA #180
  STA POS_Y_HI

  LDA #%00000000
  STA $2000
  LDA #%00011110
  STA $2001

main_loop:
  JSR wait_vblank
  JSR read_controller
  JSR process_input
  JSR update_player
  JSR update_bullets
  JSR update_enemies
  JSR check_collisions
  JSR update_scroll
  JSR update_sprites
  JMP main_loop

wait_vblank:
  BIT $2002
  BPL wait_vblank
  LDA #$00
  STA $2003
  LDA #$02
  STA $4014
  LDA #$00
  STA $2005
  LDA SCROLL_Y
  STA $2005
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

clear_nametable:
  LDA $2002
  LDA #$20
  STA $2006
  LDA #$00
  STA $2006
  LDX #$04
  LDY #$00
  LDA #$00
clear_nt_loop:
  STA $2007
  DEY
  BNE clear_nt_loop
  DEX
  BNE clear_nt_loop
  RTS

build_bg:
  LDA $2002
  LDA #$20
  STA $2006
  LDA #$00
  STA $2006
  LDX #$04
  LDY #$00
build_bg_loop:
  TYA
  AND #$1F
  CMP #$07
  BEQ bg_star
  CMP #$15
  BEQ bg_star
  LDA #$00
  JMP bg_write
bg_star:
  LDA #$01
bg_write:
  STA $2007
  DEY
  BNE build_bg_loop
  DEX
  BNE build_bg_loop
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

process_input:
  LDA PAD_DATA
  EOR PAD_PREV
  AND PAD_DATA
  STA PAD_TRIG
  LDA PAD_DATA
  STA PAD_PREV

  LDA PAD_TRIG
  AND #%10000000
  BEQ pi_check_b
  JSR fire_bullet
pi_check_b:
  LDA PAD_TRIG
  AND #%01000000
  BEQ pi_done
  JSR fire_bullet
pi_done:
  RTS

fire_bullet:
  LDX #$00
find_bullet_slot:
  LDA BULLET_ACTIVE,x
  BEQ slot_found
  INX
  CPX #$04
  BNE find_bullet_slot
  RTS

slot_found:
  LDA #$01
  STA BULLET_ACTIVE,x
  LDA PLAYER_DIR
  STA BULLET_DIR,x

  CLC
  LDA POS_X_HI
  ADC #4
  STA BULLET_X,x
  SEC
  LDA POS_Y_HI
  SBC #4
  STA BULLET_Y,x
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
  LDA #$00
  STA PLAYER_DIR
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
  LDA #$01
  STA PLAYER_DIR
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
  LDA #$02
  STA PLAYER_DIR
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
  LDA #$03
  STA PLAYER_DIR
  SEC
  LDA POS_Y_LO
  SBC SPEED_LO
  STA POS_Y_LO
  LDA POS_Y_HI
  SBC SPEED_HI
  STA POS_Y_HI

move_done:
  RTS

update_bullets:
  LDX #$00
b_update_loop:
  LDA BULLET_ACTIVE,x
  BEQ b_next_jmp
  JMP b_is_active
b_next_jmp:
  JMP b_next

b_is_active:
  LDA BULLET_DIR,x
  CMP #$00
  BNE b_not_right
  CLC
  LDA BULLET_X,x
  ADC #$04
  STA BULLET_X,x
  JMP b_check_bounds

b_not_right:
  CMP #$01
  BNE b_not_left
  SEC
  LDA BULLET_X,x
  SBC #$04
  STA BULLET_X,x
  JMP b_check_bounds

b_not_left:
  CMP #$02
  BNE b_not_down
  CLC
  LDA BULLET_Y,x
  ADC #$04
  STA BULLET_Y,x
  JMP b_check_bounds

b_not_down:
  SEC
  LDA BULLET_Y,x
  SBC #$04
  STA BULLET_Y,x

b_check_bounds:
  LDA BULLET_X,x
  CMP #$04
  BCC b_deactivate
  CMP #$F8
  BCS b_deactivate

  LDA BULLET_Y,x
  CMP #$04
  BCC b_deactivate
  CMP #$F0
  BCS b_deactivate
  JMP b_next

b_deactivate:
  LDA #$00
  STA BULLET_ACTIVE,x

b_next:
  INX
  CPX #$04
  BEQ b_done
  JMP b_update_loop
b_done:
  RTS

update_enemies:
  LDA FRAME_CNT
  AND #$1F
  BNE ue_move_start

  LDX #$00
find_enemy_slot:
  LDA ENEMY_ACTIVE,x
  BEQ slot_enemy_found
  INX
  CPX #$04
  BNE find_enemy_slot
  JMP ue_move_start

slot_enemy_found:
  LDA #$01
  STA ENEMY_ACTIVE,x
  LDA FRAME_CNT
  ADC RANDOM_SEED
  STA RANDOM_SEED
  AND #$7F
  CLC
  ADC #$20
  STA ENEMY_X,x
  LDA #$00
  STA ENEMY_Y,x
  TXA
  AND #$01
  STA ENEMY_TYPE,x

ue_move_start:
  LDX #$00
ue_loop:
  LDA ENEMY_ACTIVE,x
  BEQ ue_next_jmp
  JMP ue_is_active

ue_next_jmp:
  JMP ue_next

ue_is_active:
  CLC
  LDA ENEMY_Y,x
  ADC #$02
  STA ENEMY_Y,x

  LDA ENEMY_TYPE,x
  BEQ ue_check_y
  LDA FRAME_CNT
  AND #$08
  BEQ ue_left
  CLC
  LDA ENEMY_X,x
  ADC #$01
  STA ENEMY_X,x
  JMP ue_check_y

ue_left:
  SEC
  LDA ENEMY_X,x
  SBC #$01
  STA ENEMY_X,x

ue_check_y:
  LDA ENEMY_Y,x
  CMP #$F0
  BCC ue_next
  LDA #$00
  STA ENEMY_ACTIVE,x

ue_next:
  INX
  CPX #$04
  BEQ ue_done
  JMP ue_loop
ue_done:
  RTS

check_collisions:
  LDX #$00
cc_b_loop:
  LDA BULLET_ACTIVE,x
  BEQ cc_b_next_jmp
  JMP cc_b_active

cc_b_next_jmp:
  JMP cc_b_next

cc_b_active:
  LDY #$00
cc_e_loop:
  LDA ENEMY_ACTIVE,y
  BEQ cc_e_next

  LDA BULLET_X,x
  SEC
  SBC ENEMY_X,y
  BCS cc_x_pos
  EOR #$FF
  ADC #$01
cc_x_pos:
  CMP #$0C
  BCS cc_e_next

  LDA BULLET_Y,x
  SEC
  SBC ENEMY_Y,y
  BCS cc_y_pos
  EOR #$FF
  ADC #$01
cc_y_pos:
  CMP #$0C
  BCS cc_e_next

  LDA #$00
  STA BULLET_ACTIVE,x
  STA ENEMY_ACTIVE,y
  JMP cc_b_next

cc_e_next:
  INY
  CPY #$04
  BNE cc_e_loop

cc_b_next:
  INX
  CPX #$04
  BEQ cc_done
  JMP cc_b_loop
cc_done:
  RTS

update_scroll:
  INC FRAME_CNT
  LDA SCROLL_Y
  SEC
  SBC #1
  STA SCROLL_Y
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

  LDX #$00
  LDY #$10
draw_bullet_loop:
  LDA BULLET_ACTIVE,x
  BEQ hide_bullet
  LDA BULLET_Y,x
  STA $0200,y
  LDA #$01
  STA $0201,y
  LDA #$00
  STA $0202,y
  LDA BULLET_X,x
  STA $0203,y
  JMP next_bullet_draw
hide_bullet:
  LDA #$FE
  STA $0200,y
next_bullet_draw:
  INY
  INY
  INY
  INY
  INX
  CPX #$04
  BNE draw_bullet_loop

  LDX #$00
  LDY #$20
draw_enemy_loop:
  LDA ENEMY_ACTIVE,x
  BEQ hide_enemy
  LDA ENEMY_Y,x
  STA $0200,y
  LDA #$03
  STA $0201,y
  LDA #$01
  STA $0202,y
  LDA ENEMY_X,x
  STA $0203,y
  JMP next_enemy_draw
hide_enemy:
  LDA #$FE
  STA $0200,y
next_enemy_draw:
  INY
  INY
  INY
  INY
  INX
  CPX #$04
  BNE draw_enemy_loop
  RTS

NMI:
  RTI

IRQ:
  RTI

palette_data:
  .db $0F, $0F, $10, $30, $0F, $0F, $0F, $0F
  .db $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F
  .db $0F, $16, $28, $30, $0F, $0F, $16, $27
  .db $0F, $16, $28, $30, $0F, $16, $28, $30

  .pad $FFFA
  .dw NMI, RESET, IRQ

  .db $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00

  .db %00000000
  .db %00000001
  .db %00000011
  .db %00000111
  .db %00001111
  .db %00011111
  .db %00111111
  .db %01111111
  .db %00000000
  .db %00000000
  .db %00000001
  .db %00000011
  .db %00000111
  .db %00001111
  .db %00011111
  .db %00111111

  .db %00000000
  .db %10000000
  .db %11000000
  .db %11100000
  .db %11110000
  .db %11111000
  .db %11111100
  .db %11111110
  .db %00000000
  .db %00000000
  .db %10000000
  .db %11000000
  .db %11100000
  .db %11110000
  .db %11111000
  .db %11111100

  .db %01111111
  .db %00111111
  .db %00011111
  .db %00001111
  .db %00001110
  .db %00001100
  .db %00001000
  .db %00000000
  .db %00111111
  .db %00011111
  .db %00001111
  .db %00000111
  .db %00000110
  .db %00000100
  .db %00000000
  .db %00000000

  .db %11111110
  .db %11111100
  .db %11111000
  .db %11110000
  .db %01110000
  .db %00110000
  .db %00010000
  .db %00000000
  .db %11111100
  .db %11111000
  .db %11110000
  .db %11100000
  .db %01100000
  .db %00100000
  .db %00000000
  .db %00000000
