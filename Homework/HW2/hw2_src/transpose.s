	.arch armv8.5-a
	.build_version macos,  26, 0
	.text
	.align	2
	.p2align 5,,15
	.globl _transpose_naive
_transpose_naive:
LFB0:
	cmp	w1, 0
	ble	L1
	cmp	w0, 0
	ble	L1
	ubfiz	x7, x0, 3, 32
	mov	w6, 0
	add	x4, x2, x7
	ubfiz	x5, x1, 3, 32
	.p2align 5,,15
L3:
	sub	x2, x4, x7
	mov	x0, x3
	.p2align 5,,15
L4:
	ldr	d31, [x2], 8
	str	d31, [x0]
	add	x0, x0, x5
	cmp	x4, x2
	bne	L4
	add	w6, w6, 1
	add	x3, x3, 8
	add	x4, x4, x7
	cmp	w1, w6
	bne	L3
L1:
	ret
LFE0:
	.align	2
	.p2align 5,,15
	.globl _transpose_blocked
_transpose_blocked:
LFB1:
	cmp	w1, 0
	ble	L19
	cmp	w0, 0
	ble	L19
	stp	x29, x30, [sp, -32]!
LCFI0:
	lsl	w16, w1, 3
	mov	x29, sp
	mov	x15, 0
	sxtw	x16, w16
	ubfiz	x13, x0, 3, 32
	ubfiz	x8, x1, 3, 32
	str	x19, [sp, 16]
LCFI1:
	mov	x19, x2
	mov	w2, 0
L14:
	add	w12, w15, 8
	cmp	w12, w1
	csel	w12, w12, w1, le
	cmp	w12, w15
	ble	L9
	mov	x14, 0
	mov	x11, 0
	add	x17, x19, w2, sxtw 3
	mov	w30, w15
	.p2align 5,,15
L13:
	add	w7, w11, 8
	cmp	w7, w0
	csel	w7, w7, w0, le
	cmp	w7, w11
	ble	L10
	add	x9, x15, w14, sxtw
	add	x9, x3, x9, lsl 3
	mov	x6, x17
	mov	w10, w30
	.p2align 5,,15
L11:
	mov	x5, x9
	mov	x4, x11
	.p2align 5,,15
L12:
	ldr	d31, [x6, x4, lsl 3]
	add	x4, x4, 1
	str	d31, [x5]
	add	x5, x5, x8
	cmp	w7, w4
	bgt	L12
	add	w10, w10, 1
	add	x9, x9, 8
	add	x6, x6, x13
	cmp	w12, w10
	bne	L11
L10:
	add	x11, x11, 8
	add	x14, x14, x16
	cmp	w0, w11
	bgt	L13
L9:
	add	x15, x15, 8
	add	w2, w2, w0, lsl 3
	cmp	w1, w15
	bgt	L14
	ldr	x19, [sp, 16]
	ldp	x29, x30, [sp], 32
LCFI2:
	ret
L19:
	ret
LFE1:
	.cstring
	.align	3
lC0:
	.ascii "rank %d: transpose_parallel_dealer(m=%d, n=%d, local_m=%d, local_n=%d)\12\0"
	.text
	.align	2
	.p2align 5,,15
	.globl _transpose_parallel_dealer
_transpose_parallel_dealer:
LFB3:
	sub	sp, sp, #240
LCFI3:
	stp	x29, x30, [sp, 48]
LCFI4:
	add	x29, sp, 48
LCFI5:
	stp	x19, x20, [sp, 64]
	stp	x23, x24, [sp, 96]
LCFI6:
	mov	w23, w2
	mov	w24, w0
	stp	x25, x26, [sp, 112]
LCFI7:
	mov	w26, w1
	mov	w25, w3
	stp	x5, x4, [x29, 120]
	stp	x27, x28, [sp, 128]
LCFI8:
	bl	_msg_rank
	mov	w19, w0
	bl	_num_ranks
	str	w0, [x29, 184]
	adrp	x0, lC0@PAGE
	add	x0, x0, lC0@PAGEOFF;
	str	w19, [sp]
	str	w24, [sp, 8]
	str	w26, [sp, 16]
	str	w23, [sp, 24]
	str	w25, [sp, 32]
	str	w19, [x29, 148]
	bl	_printf
	ldr	w4, [x29, 184]
	add	w19, w4, w24
	add	w0, w4, w26
	str	w4, [x29, 184]
	sub	w19, w19, #1
	sub	w0, w0, #1
	sdiv	w19, w19, w4
	sdiv	w0, w0, w4
	smull	x19, w19, w0
	lsl	x0, x19, 3
	bl	_malloc
	mov	x20, x0
	lsl	x0, x19, 3
	bl	_malloc
	cmp	x20, 0
	mov	x27, x0
	ccmp	x0, 0, 4, ne
	beq	L23
	ldr	w4, [x29, 184]
	cmp	w4, 0
	ble	L23
	sdiv	w13, w26, w4
	ldr	w19, [x29, 148]
	mov	w28, w25
	stp	x21, x22, [x29, 32]
LCFI9:
	sub	w21, w23, #1
	sbfiz	x22, x23, 3, 32
	add	x21, x21, 1
	lsl	x0, x21, 3
	sdiv	w3, w24, w4
	str	x0, [x29, 136]
	add	w0, w4, w19
	str	w0, [x29, 144]
	msub	w0, w13, w4, w26
	add	w1, w13, 1
	mov	x26, x27
	mov	w27, w23
	sbfiz	x23, x25, 3, 32
	str	w1, [x29, 104]
	str	w0, [x29, 160]
	madd	w0, w13, w0, w0
	add	w1, w3, 1
	stp	w13, w3, [x29, 96]
	str	w0, [x29, 108]
	msub	w0, w3, w4, w24
	str	w0, [x29, 164]
	madd	w0, w3, w0, w0
	mov	w3, 0
	stp	w0, w1, [x29, 112]
	.p2align 5,,15
L37:
	ldr	w0, [x29, 148]
	add	w2, w3, w0
	ldr	w0, [x29, 144]
	sdiv	w6, w2, w4
	sub	w1, w0, w3
	sdiv	w0, w1, w4
	msub	w6, w6, w4, w2
	msub	w0, w0, w4, w1
	ldr	w1, [x29, 160]
	cmp	w6, w1
	bge	L25
	ldr	w19, [x29, 104]
	ldr	w2, [x29, 164]
	mul	w1, w6, w19
	cmp	w0, w2
	bge	L27
L45:
	ldr	w9, [x29, 116]
	mul	w2, w0, w9
	str	w2, [x29, 168]
L28:
	cmp	w19, 0
	ble	L35
	cmp	w27, 0
	ble	L35
	mov	w24, 0
	str	x23, [x29, 184]
	mov	w23, 0
	ldp	x2, x21, [x29, 128]
	mul	w1, w27, w1
	add	x25, x2, w1, sxtw 3
	stp	w4, w9, [x29, 152]
	stp	w3, w0, [x29, 172]
	str	w6, [x29, 180]
	.p2align 5,,15
L34:
	mov	x1, x25
	mov	x2, x21
	add	x0, x20, w24, uxtw 3
	add	w23, w23, 1
	add	w24, w24, w27
	bl	_memcpy
	add	x25, x25, x22
	cmp	w23, w19
	bne	L34
	ldr	x23, [x29, 184]
	ldp	w4, w9, [x29, 152]
	ldp	w3, w0, [x29, 172]
	ldr	w6, [x29, 180]
L35:
	mul	w2, w28, w9
	mov	x1, x26
	stp	w9, w4, [x29, 172]
	stp	w6, w3, [x29, 180]
	mul	w19, w27, w19
	lsl	w2, w2, 3
	bl	_irecv
	ldr	w3, [x29, 184]
	lsl	w2, w19, 3
	mov	x1, x20
	ldr	w0, [x29, 180]
	str	w3, [x29, 184]
	bl	_isend
	bl	_msgwait
	cmp	w28, 0
	ldr	w4, [x29, 176]
	ldr	w3, [x29, 184]
	ble	L30
	ldr	w9, [x29, 172]
	cmp	w9, 0
	ble	L30
	ldr	w0, [x29, 168]
	mov	w7, 0
	mov	w12, 0
	sxtw	x13, w9
	mul	w6, w28, w0
	ldr	x0, [x29, 120]
	add	x6, x0, w6, sxtw 3
	.p2align 5,,15
L32:
	mov	x0, x6
	add	x2, x13, w7, sxtw
	add	x1, x26, w7, uxtw 3
	add	x2, x26, w2, uxtw 3
	.p2align 5,,15
L36:
	ldr	d31, [x1], 8
	str	d31, [x0]
	add	x0, x0, x23
	cmp	x2, x1
	bne	L36
	add	w12, w12, 1
	add	w7, w9, w7
	add	x6, x6, 8
	cmp	w28, w12
	bne	L32
L30:
	add	w3, w3, 1
	cmp	w4, w3
	bne	L37
	ldp	x21, x22, [x29, 32]
LCFI10:
	mov	x27, x26
L23:
	mov	x0, x20
	bl	_free
	ldp	x29, x30, [sp, 48]
	mov	x0, x27
	ldp	x19, x20, [sp, 64]
	ldp	x23, x24, [sp, 96]
	ldp	x25, x26, [sp, 112]
	ldp	x27, x28, [sp, 128]
	add	sp, sp, 240
LCFI11:
	b	_free
L25:
LCFI12:
	ldr	w1, [x29, 160]
	ldr	w2, [x29, 96]
	ldr	w5, [x29, 108]
	sub	w1, w6, w1
	mov	w19, w2
	madd	w1, w1, w2, w5
	ldr	w2, [x29, 164]
	cmp	w0, w2
	blt	L45
L27:
	ldr	w2, [x29, 164]
	ldr	w5, [x29, 100]
	ldr	w7, [x29, 112]
	sub	w2, w0, w2
	mov	w9, w5
	madd	w2, w2, w5, w7
	str	w2, [x29, 168]
	b	L28
LFE3:
	.align	2
	.p2align 5,,15
	.globl _transpose_real
_transpose_real:
LFB4:
	cmp	w1, 0
	ble	L58
	cmp	w0, 0
	ble	L58
	stp	x29, x30, [sp, -32]!
LCFI13:
	lsl	w15, w1, 3
	mov	x29, sp
	mov	x14, 0
	sxtw	x15, w15
	ubfiz	x13, x0, 3, 32
	ubfiz	x16, x1, 3, 32
	str	x19, [sp, 16]
LCFI14:
	mov	x19, x2
	mov	w2, 0
L53:
	add	w12, w14, 8
	cmp	w12, w1
	csel	w12, w12, w1, le
	cmp	w12, w14
	ble	L48
	mov	x11, 0
	mov	x5, 0
	add	x17, x19, w2, sxtw 3
	mov	w30, w14
	.p2align 5,,15
L52:
	add	w6, w5, 8
	cmp	w6, w0
	csel	w6, w6, w0, le
	cmp	w6, w5
	ble	L49
	add	x4, x14, w11, sxtw
	add	x4, x3, x4, lsl 3
	mov	x9, x17
	mov	w8, w30
	.p2align 5,,15
L50:
	mov	x10, x4
	mov	x7, x5
	.p2align 5,,15
L51:
	ldr	d31, [x9, x7, lsl 3]
	add	x7, x7, 1
	str	d31, [x10]
	add	x10, x10, x16
	cmp	w6, w7
	bgt	L51
	add	w8, w8, 1
	add	x4, x4, 8
	add	x9, x9, x13
	cmp	w12, w8
	bne	L50
L49:
	add	x5, x5, 8
	add	x11, x11, x15
	cmp	w0, w5
	bgt	L52
L48:
	add	x14, x14, 8
	add	w2, w2, w0, lsl 3
	cmp	w1, w14
	bgt	L53
	ldr	x19, [sp, 16]
	ldp	x29, x30, [sp], 32
LCFI15:
	ret
L58:
	ret
LFE4:
	.section __TEXT,__eh_frame,coalesced,no_toc+strip_static_syms+live_support
EH_frame1:
	.set L$set$0,LECIE1-LSCIE1
	.long L$set$0
LSCIE1:
	.long	0
	.byte	0x3
	.ascii "zR\0"
	.uleb128 0x1
	.sleb128 -8
	.uleb128 0x1e
	.uleb128 0x1
	.byte	0x10
	.byte	0xc
	.uleb128 0x1f
	.uleb128 0
	.align	3
LECIE1:
LSFDE1:
	.set L$set$1,LEFDE1-LASFDE1
	.long L$set$1
LASFDE1:
	.long	LASFDE1-EH_frame1
	.quad	LFB0-.
	.set L$set$2,LFE0-LFB0
	.quad L$set$2
	.uleb128 0
	.align	3
LEFDE1:
LSFDE3:
	.set L$set$3,LEFDE3-LASFDE3
	.long L$set$3
LASFDE3:
	.long	LASFDE3-EH_frame1
	.quad	LFB1-.
	.set L$set$4,LFE1-LFB1
	.quad L$set$4
	.uleb128 0
	.byte	0x4
	.set L$set$5,LCFI0-LFB1
	.long L$set$5
	.byte	0xe
	.uleb128 0x20
	.byte	0x9d
	.uleb128 0x4
	.byte	0x9e
	.uleb128 0x3
	.byte	0x4
	.set L$set$6,LCFI1-LCFI0
	.long L$set$6
	.byte	0x93
	.uleb128 0x2
	.byte	0x4
	.set L$set$7,LCFI2-LCFI1
	.long L$set$7
	.byte	0xde
	.byte	0xdd
	.byte	0xd3
	.byte	0xe
	.uleb128 0
	.align	3
LEFDE3:
LSFDE5:
	.set L$set$8,LEFDE5-LASFDE5
	.long L$set$8
LASFDE5:
	.long	LASFDE5-EH_frame1
	.quad	LFB3-.
	.set L$set$9,LFE3-LFB3
	.quad L$set$9
	.uleb128 0
	.byte	0x4
	.set L$set$10,LCFI3-LFB3
	.long L$set$10
	.byte	0xe
	.uleb128 0xf0
	.byte	0x4
	.set L$set$11,LCFI4-LCFI3
	.long L$set$11
	.byte	0x9d
	.uleb128 0x18
	.byte	0x9e
	.uleb128 0x17
	.byte	0x4
	.set L$set$12,LCFI5-LCFI4
	.long L$set$12
	.byte	0xc
	.uleb128 0x1d
	.uleb128 0xc0
	.byte	0x4
	.set L$set$13,LCFI6-LCFI5
	.long L$set$13
	.byte	0x93
	.uleb128 0x16
	.byte	0x94
	.uleb128 0x15
	.byte	0x97
	.uleb128 0x12
	.byte	0x98
	.uleb128 0x11
	.byte	0x4
	.set L$set$14,LCFI7-LCFI6
	.long L$set$14
	.byte	0x99
	.uleb128 0x10
	.byte	0x9a
	.uleb128 0xf
	.byte	0x4
	.set L$set$15,LCFI8-LCFI7
	.long L$set$15
	.byte	0x9b
	.uleb128 0xe
	.byte	0x9c
	.uleb128 0xd
	.byte	0x4
	.set L$set$16,LCFI9-LCFI8
	.long L$set$16
	.byte	0x96
	.uleb128 0x13
	.byte	0x95
	.uleb128 0x14
	.byte	0x4
	.set L$set$17,LCFI10-LCFI9
	.long L$set$17
	.byte	0xd6
	.byte	0xd5
	.byte	0x4
	.set L$set$18,LCFI11-LCFI10
	.long L$set$18
	.byte	0xdb
	.byte	0xdc
	.byte	0xd9
	.byte	0xda
	.byte	0xd7
	.byte	0xd8
	.byte	0xd3
	.byte	0xd4
	.byte	0xdd
	.byte	0xde
	.byte	0xc
	.uleb128 0x1f
	.uleb128 0
	.byte	0x4
	.set L$set$19,LCFI12-LCFI11
	.long L$set$19
	.byte	0xc
	.uleb128 0x1d
	.uleb128 0xc0
	.byte	0x93
	.uleb128 0x16
	.byte	0x94
	.uleb128 0x15
	.byte	0x95
	.uleb128 0x14
	.byte	0x96
	.uleb128 0x13
	.byte	0x97
	.uleb128 0x12
	.byte	0x98
	.uleb128 0x11
	.byte	0x99
	.uleb128 0x10
	.byte	0x9a
	.uleb128 0xf
	.byte	0x9b
	.uleb128 0xe
	.byte	0x9c
	.uleb128 0xd
	.byte	0x9d
	.uleb128 0x18
	.byte	0x9e
	.uleb128 0x17
	.align	3
LEFDE5:
LSFDE7:
	.set L$set$20,LEFDE7-LASFDE7
	.long L$set$20
LASFDE7:
	.long	LASFDE7-EH_frame1
	.quad	LFB4-.
	.set L$set$21,LFE4-LFB4
	.quad L$set$21
	.uleb128 0
	.byte	0x4
	.set L$set$22,LCFI13-LFB4
	.long L$set$22
	.byte	0xe
	.uleb128 0x20
	.byte	0x9d
	.uleb128 0x4
	.byte	0x9e
	.uleb128 0x3
	.byte	0x4
	.set L$set$23,LCFI14-LCFI13
	.long L$set$23
	.byte	0x93
	.uleb128 0x2
	.byte	0x4
	.set L$set$24,LCFI15-LCFI14
	.long L$set$24
	.byte	0xde
	.byte	0xdd
	.byte	0xd3
	.byte	0xe
	.uleb128 0
	.align	3
LEFDE7:
	.ident	"GCC: (Homebrew GCC 15.2.0_1) 15.2.0"
	.subsections_via_symbols
