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
	.align	2
	.p2align 5,,15
	.globl _transpose_real
_transpose_real:
LFB2:
	cmp	w1, 0
	ble	L34
	cmp	w0, 0
	ble	L34
	stp	x29, x30, [sp, -32]!
LCFI3:
	lsl	w15, w1, 3
	mov	x29, sp
	mov	x14, 0
	sxtw	x15, w15
	ubfiz	x13, x0, 3, 32
	ubfiz	x16, x1, 3, 32
	str	x19, [sp, 16]
LCFI4:
	mov	x19, x2
	mov	w2, 0
L29:
	add	w12, w14, 8
	cmp	w12, w1
	csel	w12, w12, w1, le
	cmp	w12, w14
	ble	L24
	mov	x11, 0
	mov	x5, 0
	add	x17, x19, w2, sxtw 3
	mov	w30, w14
	.p2align 5,,15
L28:
	add	w6, w5, 8
	cmp	w6, w0
	csel	w6, w6, w0, le
	cmp	w6, w5
	ble	L25
	add	x4, x14, w11, sxtw
	add	x4, x3, x4, lsl 3
	mov	x9, x17
	mov	w8, w30
	.p2align 5,,15
L26:
	mov	x10, x4
	mov	x7, x5
	.p2align 5,,15
L27:
	ldr	d31, [x9, x7, lsl 3]
	add	x7, x7, 1
	str	d31, [x10]
	add	x10, x10, x16
	cmp	w6, w7
	bgt	L27
	add	w8, w8, 1
	add	x4, x4, 8
	add	x9, x9, x13
	cmp	w12, w8
	bne	L26
L25:
	add	x5, x5, 8
	add	x11, x11, x15
	cmp	w0, w5
	bgt	L28
L24:
	add	x14, x14, 8
	add	w2, w2, w0, lsl 3
	cmp	w1, w14
	bgt	L29
	ldr	x19, [sp, 16]
	ldp	x29, x30, [sp], 32
LCFI5:
	ret
L34:
	ret
LFE2:
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
	.quad	LFB2-.
	.set L$set$9,LFE2-LFB2
	.quad L$set$9
	.uleb128 0
	.byte	0x4
	.set L$set$10,LCFI3-LFB2
	.long L$set$10
	.byte	0xe
	.uleb128 0x20
	.byte	0x9d
	.uleb128 0x4
	.byte	0x9e
	.uleb128 0x3
	.byte	0x4
	.set L$set$11,LCFI4-LCFI3
	.long L$set$11
	.byte	0x93
	.uleb128 0x2
	.byte	0x4
	.set L$set$12,LCFI5-LCFI4
	.long L$set$12
	.byte	0xde
	.byte	0xdd
	.byte	0xd3
	.byte	0xe
	.uleb128 0
	.align	3
LEFDE5:
	.ident	"GCC: (Homebrew GCC 15.2.0_1) 15.2.0"
	.subsections_via_symbols
