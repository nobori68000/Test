.db "NES", $1a, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

  .org $C000

PAD_DATA        = $00
PAD_PREV        = $01
POS_X_LO        = $02
POS_X_HI        = $03
POS_Y_LO        = $04
POS_Y_HI        = $05
SPEED_LO        = $06
SPEED_HI        = $07
PAD_TRIG        = $08
PLAYER_DIR      = $09

MAIN_ACTIVE     = $10
MAIN_X          = $14
MAIN_Y          = $18

ENEMY_ACTIVE    = $20
ENEMY_X         = $24
ENEMY_Y         = $28
ENEMY_TYPE      = $2C

SCROLL_Y        = $30
FRAME_CNT       = $31
RANDOM_SEED     = $32
SUB_WEAPON_TYPE = $33
BARRIER_ACTIVE  = $34
ROT_ANGLE       = $35

SUB_ACTIVE      = $40
SUB_X           = $48
SUB_Y           = $50
SUB_VX          = $58
SUB_VY          = $60
SUB_FLAGS       = $68

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
  STA SUB_WEAPON_TYPE
  STA BARRIER_ACTIVE
  STA ROT_ANGLE
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
  JSR update_sub_bullets
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
  JSR fire_main_bullet

pi_check_b:
  LDA PAD_TRIG
  AND #%01000000
  BEQ pi_check_sel
  JSR fire_sub_bullet

pi_check_sel:
  LDA PAD_TRIG
  AND #%00100000
  BEQ pi_done
  JSR next_sub_weapon

pi_done:
  RTS

next_sub_weapon:
  INC SUB_WEAPON_TYPE
  LDA SUB_WEAPON_TYPE
  CMP #10
  BCC nsw_done
  LDA #$00
  STA SUB_WEAPON_TYPE
nsw_done:
  RTS

fire_main_bullet:
  LDX #$00
find_main_slot:
  LDA MAIN_ACTIVE,x
  BEQ main_slot_found
  INX
  CPX #$04
  BNE find_main_slot
  RTS

main_slot_found:
  LDA #$01
  STA MAIN_ACTIVE,x
  CLC
  LDA POS_X_HI
  ADC #4
  STA MAIN_X,x
  SEC
  LDA POS_Y_HI
  SBC #4
  STA MAIN_Y,x
  RTS

fire_sub_bullet:
  LDA SUB_WEAPON_TYPE
  CMP #0
  BNE fs_not_0
  JMP fs_type_0
fs_not_0:
  CMP #1
  BNE fs_not_1
  JMP fs_type_1
fs_not_1:
  CMP #2
  BNE fs_not_2
  JMP fs_type_2
fs_not_2:
  CMP #3
  BNE fs_not_3
  JMP fs_type_3
fs_not_3:
  CMP #4
  BNE fs_not_4
  JMP fs_type_4
fs_not_4:
  CMP #5
  BNE fs_not_5
  JMP fs_type_5
fs_not_5:
  CMP #6
  BNE fs_not_6
  JMP fs_type_6
fs_not_6:
  CMP #7
  BNE fs_not_7
  JMP fs_type_7
fs_not_7:
  CMP #8
  BNE fs_not_8
  JMP fs_type_8
fs_not_8:
  JMP fs_type_9

fs_type_0:
  JSR spawn_sub_bullet
  CPX #$FF
  BEQ fs0_done
  LDA POS_X_HI
  STA SUB_X,x
  LDA POS_Y_HI
  STA SUB_Y,x
  LDA #$00
  STA SUB_VX,x
  LDA #$FC
  STA SUB_VY,x

  JSR spawn_sub_bullet
  CPX #$FF
  BEQ fs0_done
  LDA POS_X_HI
  STA SUB_X,x
  LDA POS_Y_HI
  STA SUB_Y,x
  LDA #$00
  STA SUB_VX,x
  LDA #$04
  STA SUB_VY,x

  JSR spawn_sub_bullet
  CPX #$FF
  BEQ fs0_done
  LDA POS_X_HI
  STA SUB_X,x
  LDA POS_Y_HI
  STA SUB_Y,x
  LDA #$FC
  STA SUB_VX,x
  LDA #$00
  STA SUB_VY,x

  JSR spawn_sub_bullet
  CPX #$FF
  BEQ fs0_done
  LDA POS_X_HI
  STA SUB_X,x
  LDA POS_Y_HI
  STA SUB_Y,x
  LDA #$04
  STA SUB_VX,x
  LDA #$00
  STA SUB_VY,x
fs0_done:
  RTS

fs_type_1:
  JSR spawn_sub_bullet
  CPX #$FF
  BEQ fs1_done
  LDA POS_X_HI
  STA SUB_X,x
  LDA POS_Y_HI
  STA SUB_Y,x
  LDA #$00
  STA SUB_VX,x
  LDA #$FA
  STA SUB_VY,x
  LDA #$01
  STA SUB_FLAGS,x
fs1_done:
  RTS

fs_type_2:
  LDA #15
  STA BARRIER_ACTIVE
  RTS

fs_type_3:
  LDX #$00
fs3_loop:
  LDA #$00
  STA ENEMY_ACTIVE,x
  INX
  CPX #$04
  BNE fs3_loop
  RTS

fs_type_4:
  JSR spawn_sub_bullet
  CPX #$FF
  BEQ fs4_done
  LDA POS_X_HI
  STA SUB_X,x
  LDA POS_Y_HI
  STA SUB_Y,x
  LDA #$00
  STA SUB_VX,x
  STA SUB_VY,x
  LDA #$02
  STA SUB_FLAGS,x
fs4_done:
  RTS

fs_type_5:
  JSR spawn_sub_bullet
  CPX #$FF
  BEQ fs5_done
  LDA POS_X_HI
  STA SUB_X,x
  LDA POS_Y_HI
  STA SUB_Y,x
  LDA #$00
  STA SUB_VX,x
  LDA #$FC
  STA SUB_VY,x
  LDA #$04
  STA SUB_FLAGS,x
fs5_done:
  RTS

fs_type_6:
  JSR spawn_sub_bullet
  CPX #$FF
  BEQ fs6_done
  LDA POS_X_HI
  STA SUB_X,x
  LDA POS_Y_HI
  STA SUB_Y,x
  LDA #$00
  STA SUB_VX,x
  LDA #$FE
  STA SUB_VY,x
  LDA #$01
  STA SUB_FLAGS,x
fs6_done:
  RTS

fs_type_7:
  JSR spawn_sub_bullet
  CPX #$FF
  BEQ fs7_done
  LDA POS_X_HI
  STA SUB_X,x
  LDA POS_Y_HI
  STA SUB_Y,x
  LDA #$00
  STA SUB_VX,x
  LDA #$F6
  STA SUB_VY,x
  LDA #$00
  STA SUB_FLAGS,x
fs7_done:
  RTS

fs_type_8:
  LDX #$00
fs8_loop:
  LDA #$00
  STA ENEMY_ACTIVE,x
  INX
  CPX #$04
  BNE fs8_loop
  RTS

fs_type_9:
  JSR spawn_sub_bullet
  CPX #$FF
  BEQ fs9_done
  LDA POS_X_HI
  STA SUB_X,x
  LDA POS_Y_HI
  STA SUB_Y,x
  LDA #$00
  STA SUB_VX,x
  LDA #$F8
  STA SUB_VY,x
  LDA #$01
  STA SUB_FLAGS,x
fs9_done:
  RTS

spawn_sub_bullet:
  LDX #$00
ssb_loop:
  LDA SUB_ACTIVE,x
  BEQ ssb_found
  INX
  CPX #$08
  BNE ssb_loop
  LDX #$FF
  RTS
ssb_found:
  LDA #$01
  STA SUB_ACTIVE,x
  LDA #$00
  STA SUB_FLAGS,x
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
mb_loop:
  LDA MAIN_ACTIVE,x
  BEQ mb_next_jmp
  JMP mb_is_active
mb_next_jmp:
  JMP mb_next

mb_is_active:
  SEC
  LDA MAIN_Y,x
  SBC #$06
  STA MAIN_Y,x

  CMP #$08
  BCS mb_next

  LDA #$00
  STA MAIN_ACTIVE,x

mb_next:
  INX
  CPX #$04
  BEQ mb_done
  JMP mb_loop
mb_done:
  RTS

update_sub_bullets:
  INC ROT_ANGLE
  LDX #$00
usb_loop:
  LDA SUB_ACTIVE,x
  BEQ usb_next_jmp
  JMP usb_is_active
usb_next_jmp:
  JMP usb_next

usb_is_active:
  LDA SUB_FLAGS,x
  CMP #$02
  BNE usb_not_rot
  LDA ROT_ANGLE
  CLC
  ADC POS_X_HI
  STA SUB_X,x
  LDA POS_Y_HI
  STA SUB_Y,x
  JMP usb_check_bounds

usb_not_rot:
  CMP #$04
  BNE usb_standard_move
  LDY #$00
usb_find_enemy:
  LDA ENEMY_ACTIVE,y
  BNE usb_home_enemy
  INY
  CPY #$04
  BNE usb_find_enemy
  JMP usb_standard_move

usb_home_enemy:
  LDA ENEMY_X,y
  CMP SUB_X,x
  BCC usb_home_left
  INC SUB_X,x
  JMP usb_home_y
usb_home_left:
  DEC SUB_X,x

usb_home_y:
  LDA ENEMY_Y,y
  CMP SUB_Y,x
  BCC usb_home_up
  INC SUB_Y,x
  JMP usb_check_bounds
usb_home_up:
  DEC SUB_Y,x
  JMP usb_check_bounds

usb_standard_move:
  CLC
  LDA SUB_X,x
  ADC SUB_VX,x
  STA SUB_X,x

  CLC
  LDA SUB_Y,x
  ADC SUB_VY,x
  STA SUB_Y,x

usb_check_bounds:
  LDA SUB_X,x
  CMP #$04
  BCC usb_deactivate
  CMP #$F8
  BCS usb_deactivate

  LDA SUB_Y,x
  CMP #$04
  BCC usb_deactivate
  CMP #$F0
  BCS usb_deactivate
  JMP usb_next

usb_deactivate:
  LDA #$00
  STA SUB_ACTIVE,x

usb_next:
  INX
  CPX #$08
  BEQ usb_done
  JMP usb_loop
usb_done:
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
cc_m_loop:
  LDA MAIN_ACTIVE,x
  BEQ cc_m_next_jmp
  JMP cc_m_active
cc_m_next_jmp:
  JMP cc_m_next

cc_m_active:
  LDY #$00
cc_me_loop:
  LDA ENEMY_ACTIVE,y
  BEQ cc_me_next

  LDA MAIN_X,x
  SEC
  SBC ENEMY_X,y
  BCS cc_mx_pos
  EOR #$FF
  ADC #$01
cc_mx_pos:
  CMP #$0C
  BCS cc_me_next

  LDA MAIN_Y,x
  SEC
  SBC ENEMY_Y,y
  BCS cc_my_pos
  EOR #$FF
  ADC #$01
cc_my_pos:
  CMP #$0C
  BCS cc_me_next

  LDA #$00
  STA MAIN_ACTIVE,x
  STA ENEMY_ACTIVE,y
  JMP cc_m_next

cc_me_next:
  INY
  CPY #$04
  BNE cc_me_loop

cc_m_next:
  INX
  CPX #$04
  BEQ cc_sub_check
  JMP cc_m_loop

cc_sub_check:
  LDX #$00
cc_s_loop:
  LDA SUB_ACTIVE,x
  BEQ cc_s_next_jmp
  JMP cc_s_active
cc_s_next_jmp:
  JMP cc_s_next

cc_s_active:
  LDY #$00
cc_se_loop:
  LDA ENEMY_ACTIVE,y
  BEQ cc_se_next

  LDA SUB_X,x
  SEC
  SBC ENEMY_X,y
  BCS cc_sx_pos
  EOR #$FF
  ADC #$01
cc_sx_pos:
  CMP #$0C
  BCS cc_se_next

  LDA SUB_Y,x
  SEC
  SBC ENEMY_Y,y
  BCS cc_sy_pos
  EOR #$FF
  ADC #$01
cc_sy_pos:
  CMP #$0C
  BCS cc_se_next

  LDA #$00
  STA ENEMY_ACTIVE,y
  LDA SUB_FLAGS,x
  AND #$01
  BNE cc_se_next

  LDA #$00
  STA SUB_ACTIVE,x
  JMP cc_s_next

cc_se_next:
  INY
  CPY #$04
  BNE cc_se_loop

cc_s_next:
  INX
  CPX #$08
  BEQ cc_barrier_check
  JMP cc_s_loop

cc_barrier_check:
  LDA BARRIER_ACTIVE
  BEQ cc_done

  LDY #$00
cc_be_loop:
  LDA ENEMY_ACTIVE,y
  BEQ cc_be_next

  LDA POS_X_HI
  SEC
  SBC ENEMY_X,y
  BCS cc_bx_pos
  EOR #$FF
  ADC #$01
cc_bx_pos:
  CMP #$10
  BCS cc_be_next

  LDA POS_Y_HI
  SEC
  SBC ENEMY_Y,y
  BCS cc_by_pos
  EOR #$FF
  ADC #$01
cc_by_pos:
  CMP #$10
  BCS cc_be_next

  LDA #$00
  STA ENEMY_ACTIVE,y
  DEC BARRIER_ACTIVE

cc_be_next:
  INY
  CPY #$04
  BNE cc_be_loop

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
draw_main_loop:
  LDA MAIN_ACTIVE,x
  BEQ hide_main
  LDA MAIN_Y,x
  STA $0200,y
  LDA #$01
  STA $0201,y
  LDA #$00
  STA $0202,y
  LDA MAIN_X,x
  STA $0203,y
  JMP next_main_draw
hide_main:
  LDA #$FE
  STA $0200,y
next_main_draw:
  INY
  INY
  INY
  INY
  INX
  CPX #$04
  BNE draw_main_loop

  LDX #$00
  LDY #$20
draw_sub_loop:
  LDA SUB_ACTIVE,x
  BEQ hide_sub
  LDA SUB_Y,x
  STA $0200,y
  LDA #$02
  STA $0201,y
  LDA #$02
  STA $0202,y
  LDA SUB_X,x
  STA $0203,y
  JMP next_sub_draw
hide_sub:
  LDA #$FE
  STA $0200,y
next_sub_draw:
  INY
  INY
  INY
  INY
  INX
  CPX #$08
  BNE draw_sub_loop

  LDA BARRIER_ACTIVE
  BEQ hide_barrier
  LDA POS_Y_HI
  STA $0240
  LDA #$01
  STA $0241
  LDA #$03
  STA $0242
  LDA POS_X_HI
  STA $0243
  JMP draw_enemies_start
hide_barrier:
  LDA #$FE
  STA $0240

draw_enemies_start:
  LDX #$00
  LDY #$50
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
