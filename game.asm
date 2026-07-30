.db "NES", $1a, 1, 1, $01, $00, 0, 0, 0, 0, 0, 0, 0, 0

.org $C000

player_x_lo = $00
player_x_hi = $01
player_y_lo = $02
player_y_hi = $03
pad_state   = $04
speed_lo    = $05
speed_hi    = $06
nmi_flag    = $07

RESET:
    SEI
    CLD
    LDX #$FF
    TXS
    INX
    STX $2000
    STX $2001
    STX $4010

vblank_wait1:
    BIT $2002
    BPL vblank_wait1

clear_ram:
    LDA #$00
    STA $0000, x
    STA $0100, x
    STA $0300, x
    STA $0400, x
    STA $0500, x
    STA $0600, x
    STA $0700, x
    LDA #$FE
    STA $0200, x
    INX
    BNE clear_ram

vblank_wait2:
    BIT $2002
    BPL vblank_wait2

    JSR load_palettes

    LDA #120
    STA player_x_hi
    LDA #0
    STA player_x_lo
    LDA #120
    STA player_y_hi
    LDA #0
    STA player_y_lo

    LDA #%10000000
    STA $2000
    LDA #%00010000
    STA $2001

main_loop:
    LDA nmi_flag
    BEQ main_loop
    LDA #0
    STA nmi_flag

    JSR read_controller
    JSR update_player
    JSR update_oam

    JMP main_loop

NMI:
    PHA
    TXA
    PHA
    TYA
    PHA

    LDA #$00
    STA $2003
    LDA #$02
    STA $4014

    LDA #1
    STA nmi_flag

    PLA
    TAY
    PLA
    TAX
    PLA
    RTI

IRQ:
    RTI

read_controller:
    LDA #$01
    STA $4016
    LDA #$00
    STA $4016
    LDX #$08
controller_loop:
    LDA $4016
    LSR A
    ROL pad_state
    DEX
    BNE controller_loop
    RTS

update_player:
    LDA pad_state
    AND #$C0
    BEQ set_speed_straight
    LDA pad_state
    AND #$30
    BEQ set_speed_straight

    LDA #$B5
    STA speed_lo
    LDA #$00
    STA speed_hi
    JMP apply_movement

set_speed_straight:
    LDA #$00
    STA speed_lo
    LDA #$01
    STA speed_hi

apply_movement:
    LDA pad_state
    AND #$10
    BEQ check_down
    LDA player_y_lo
    SEC
    SBC speed_lo
    STA player_y_lo
    LDA player_y_hi
    SBC speed_hi
    STA player_y_hi

check_down:
    LDA pad_state
    AND #$20
    BEQ check_left
    LDA player_y_lo
    CLC
    ADC speed_lo
    STA player_y_lo
    LDA player_y_hi
    ADC speed_hi
    STA player_y_hi

check_left:
    LDA pad_state
    AND #$40
    BEQ check_right
    LDA player_x_lo
    SEC
    SBC speed_lo
    STA player_x_lo
    LDA player_x_hi
    SBC speed_hi
    STA player_x_hi

check_right:
    LDA pad_state
    AND #$80
    BEQ clamp_position
    LDA player_x_lo
    CLC
    ADC speed_lo
    STA player_x_lo
    LDA player_x_hi
    ADC speed_hi
    STA player_x_hi

clamp_position:
    LDA player_x_hi
    CMP #16
    BCS check_x_max
    LDA #16
    STA player_x_hi
    LDA #0
    STA player_x_lo
    JMP check_y_min

check_x_max:
    CMP #224
    BCC check_y_min
    LDA #224
    STA player_x_hi
    LDA #0
    STA player_x_lo

check_y_min:
    LDA player_y_hi
    CMP #16
    BCS check_y_max
    LDA #16
    STA player_y_hi
    LDA #0
    STA player_y_lo
    JMP clamp_done

check_y_max:
    CMP #208
    BCC clamp_done
    LDA #208
    STA player_y_hi
    LDA #0
    STA player_y_lo

clamp_done:
    RTS

update_oam:
    LDA player_y_hi
    STA $0200
    STA $0204
    CLC
    ADC #8
    STA $0208
    STA $020C

    LDA #$00
    STA $0201
    LDA #$01
    STA $0205
    LDA #$02
    STA $0209
    LDA #$03
    STA $020D

    LDA #$00
    STA $0202
    STA $0206
    STA $020A
    STA $020E

    LDA player_x_hi
    STA $0203
    STA $020B
    CLC
    ADC #8
    STA $0207
    STA $020F
    RTS

load_palettes:
    LDA $2002
    LDA #$3F
    STA $2006
    LDA #$00
    STA $2006
    LDX #$00
load_palettes_loop:
    LDA palette_data, x
    STA $2007
    INX
    CPX #32
    BNE load_palettes_loop
    RTS

palette_data:
    .db $0F, $00, $10, $30, $0F, $00, $10, $30
    .db $0F, $00, $10, $30, $0F, $00, $10, $30
    .db $0F, $10, $20, $30, $0F, $00, $10, $30
    .db $0F, $00, $10, $30, $0F, $00, $10, $30

.pad $FFFA
.dw NMI, RESET, IRQ

.org $0000

.db $01, $01, $00, $00, $03, $1F, $7F, $FF
.db $00, $00, $01, $01, $00, $00, $00, $00
.db $80, $80, $00, $00, $C0, $F8, $FE, $FF
.db $00, $00, $80, $80, $00, $00, $00, $00
.db $FF, $0F, $1F, $3F, $7F, $4F, $03, $03
.db $00, $00, $10, $30, $20, $00, $03, $03
.db $FF, $F0, $F8, $FC, $FE, $F2, $C0, $C0
.db $00, $00, $08, $0C, $04, $00, $C0, $C0

.pad $2000, $00
