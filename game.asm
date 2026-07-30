.db "NES",$1a,1,1,0,0,0,0,0,0,0,0,0,0
.org $C000

.enum $0000
pos_x_lo  .db 0
pos_x_hi  .db 0
pos_y_lo  .db 0
pos_y_hi  .db 0
pad1      .db 0
nmi_flag  .db 0
speed_lo  .db 0
speed_hi  .db 0
.ende

RESET:
    sei
    cld
    ldx #$FF
    txs
    inx
    stx $2000
    stx $2001
    stx $4010

@vblank1:
    lda $2002
    bpl @vblank1

    jsr clear_ram

@vblank2:
    lda $2002
    bpl @vblank2

    jsr load_palettes
    jsr init_variables

    lda #%10000000
    sta $2000
    lda #%00010000
    sta $2001

main_loop:
    jsr wait_nmi
    jsr read_controller
    jsr update_position
    jsr update_sprites
    jmp main_loop

clear_ram:
    lda #$00
    ldx #$00
@loop:
    sta $000,x
    sta $100,x
    sta $200,x
    sta $300,x
    sta $400,x
    sta $500,x
    sta $600,x
    sta $700,x
    inx
    bne @loop
    rts

load_palettes:
    lda $2002
    lda #$3F
    sta $2006
    lda #$00
    sta $2006
    ldx #$00
@loop:
    lda palette_data,x
    sta $2007
    inx
    cpx #32
    bcc @loop
    rts

init_variables:
    lda #120
    sta pos_x_hi
    lda #112
    sta pos_y_hi
    lda #0
    sta pos_x_lo
    sta pos_y_lo
    sta pad1
    sta nmi_flag
    rts

wait_nmi:
    lda #0
    sta nmi_flag
@loop:
    lda nmi_flag
    beq @loop
    rts

read_controller:
    lda #$01
    sta $4016
    lda #$00
    sta $4016
    ldx #$08
@loop:
    lda $4016
    lsr a
    rol pad1
    dex
    bne @loop
    rts

update_position:
    lda pad1
    and #$0C
    beq @not_diag
    lda pad1
    and #$03
    beq @not_diag

    lda #$10
    sta speed_lo
    lda #$01
    sta speed_hi
    jmp @do_move

@not_diag:
    lda #$80
    sta speed_lo
    lda #$01
    sta speed_hi

@do_move:
    lda pad1
    and #$08
    beq @check_down
    sec
    lda pos_y_lo
    sbc speed_lo
    sta pos_y_lo
    lda pos_y_hi
    sbc speed_hi
    sta pos_y_hi
    cmp #16
    bcs @check_down
    lda #16
    sta pos_y_hi
    lda #0
    sta pos_y_lo

@check_down:
    lda pad1
    and #$04
    beq @check_left
    clc
    lda pos_y_lo
    adc speed_lo
    sta pos_y_lo
    lda pos_y_hi
    adc speed_hi
    sta pos_y_hi
    cmp #208
    bcc @check_left
    lda #208
    sta pos_y_hi
    lda #0
    sta pos_y_lo

@check_left:
    lda pad1
    and #$02
    beq @check_right
    sec
    lda pos_x_lo
    sbc speed_lo
    sta pos_x_lo
    lda pos_x_hi
    sbc speed_hi
    sta pos_x_hi
    cmp #16
    bcs @check_right
    lda #16
    sta pos_x_hi
    lda #0
    sta pos_x_lo

@check_right:
    lda pad1
    and #$01
    beq @end_move
    clc
    lda pos_x_lo
    adc speed_lo
    sta pos_x_lo
    lda pos_x_hi
    adc speed_hi
    sta pos_x_hi
    cmp #224
    bcc @end_move
    lda #224
    sta pos_x_hi
    lda #0
    sta pos_x_lo

@end_move:
    rts

update_sprites:
    lda pos_y_hi
    sta $0200
    lda #$00
    sta $0201
    lda #$00
    sta $0202
    lda pos_x_hi
    sta $0203

    lda pos_y_hi
    sta $0204
    lda #$01
    sta $0205
    lda #$00
    sta $0206
    clc
    lda pos_x_hi
    adc #8
    sta $0207

    clc
    lda pos_y_hi
    adc #8
    sta $0208
    lda #$02
    sta $0209
    lda #$00
    sta $020A
    lda pos_x_hi
    sta $020B

    clc
    lda pos_y_hi
    adc #8
    sta $020C
    lda #$03
    sta $020D
    lda #$00
    sta $020E
    clc
    lda pos_x_hi
    adc #8
    sta $020F

    rts

NMI:
    pha
    txa
    pha
    tya
    pha

    lda #$00
    sta $2003
    lda #$02
    sta $4014

    lda #1
    sta nmi_flag

    pla
    tay
    pla
    tax
    pla
    rti

IRQ:
    rti

palette_data:
    .db $0F, $00, $10, $30, $0F, $00, $10, $30, $0F, $00, $10, $30, $0F, $00, $10, $30
    .db $0F, $0F, $10, $30, $0F, $0F, $10, $30, $0F, $0F, $10, $30, $0F, $0F, $10, $30

.pad $FFFA, $FF
.dw NMI
.dw RESET
.dw IRQ

.org $10000
    .db $01, $03, $07, $0F, $3F, $7F, $1F, $0F
    .db $01, $03, $07, $0F, $1F, $3F, $0F, $07
    .db $80, $C0, $E0, $F0, $FC, $FE, $F8, $F0
    .db $80, $C0, $E0, $F0, $F8, $FC, $F0, $E0
    .db $0F, $0F, $3F, $7F, $67, $43, $03, $01
    .db $07, $0F, $1F, $3F, $27, $03, $01, $00
    .db $F0, $F0, $FC, $FE, $E6, $C2, $C0, $80
    .db $E0, $F0, $F8, $FC, $E4, $C0, $80, $00
.pad $12000, $00
