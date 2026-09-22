	.arch armv8.5-a
	.build_version macos,  26, 0
	.text
	.align	2
	.p2align 5,,15
	.globl _poisson_plan_free
_poisson_plan_free:
LFB6:
	stp	x29, x30, [sp, -32]!
LCFI0:
	mov	x29, sp
LCFI1:
	str	x19, [sp, 16]
LCFI2:
	mov	x19, x0
	add	x0, x0, 64
	bl	_block_fst_plan_free
	add	x0, x19, 152
	bl	_block_fst_plan_free
	ldr	x0, [x19, 240]
	bl	_free
	ldr	x0, [x19, 248]
	str	xzr, [x19, 240]
	bl	_free
	ldr	x0, [x19, 256]
	str	xzr, [x19, 248]
	bl	_free
	ldr	x0, [x19, 264]
	str	xzr, [x19, 256]
	bl	_free
	str	xzr, [x19, 264]
	ldr	x19, [sp, 16]
	ldp	x29, x30, [sp], 32
LCFI3:
	ret
LFE6:
	.align	2
	.p2align 5,,15
	.globl _poisson_plan_init
_poisson_plan_init:
LFB5:
	stp	x29, x30, [sp, -128]!
LCFI4:
	mov	x29, sp
LCFI5:
	stp	x21, x22, [sp, 32]
LCFI6:
	mov	w21, w2
	add	w2, w1, 1
	stp	x19, x20, [sp, 16]
LCFI7:
	mov	w20, w1
	add	w1, w21, 1
	mov	x19, x0
	stp	d13, d14, [sp, 80]
LCFI8:
	scvtf	d13, w2
	str	d15, [sp, 96]
LCFI9:
	scvtf	d15, w1
	stp	x23, x24, [sp, 48]
	stp	d0, d1, [x0, 8]
	fdiv	d31, d0, d13
	stp	w20, w21, [x0]
	fdiv	d1, d1, d15
	stp	d31, d1, [x0, 24]
LCFI10:
	bl	_msg_rank
	str	w0, [x19, 40]
	bl	_num_ranks
	sdiv	w3, w20, w0
	ldr	w1, [x19, 40]
	str	w0, [x19, 44]
	msub	w2, w3, w0, w20
	add	w4, w3, 1
	cmp	w1, w2
	bge	L5
	mul	w2, w1, w4
L6:
	sdiv	w3, w21, w0
	stp	w4, w2, [x19, 48]
	msub	w0, w3, w0, w21
	add	w4, w3, 1
	cmp	w1, w0
	bge	L7
	mul	w3, w1, w4
L8:
	movi	v31.4s, 0
	add	x22, x19, 152
	mov	w2, w21
	mov	x0, x22
	mov	w1, w20
	stp	w4, w3, [x19, 56]
	stp	q31, q31, [x19, 240]
	bl	_block_fst_plan_init
	cbz	w0, L23
L9:
	mov	w23, 1
L4:
	ldr	d15, [sp, 96]
	mov	w0, w23
	ldp	x19, x20, [sp, 16]
	ldp	x21, x22, [sp, 32]
	ldp	x23, x24, [sp, 48]
	ldp	d13, d14, [sp, 80]
	ldp	x29, x30, [sp], 128
LCFI11:
	ret
	.p2align 2,,3
L7:
LCFI12:
	mul	w2, w0, w4
	sub	w1, w1, w0
	mov	w4, w3
	madd	w3, w1, w3, w2
	b	L8
	.p2align 2,,3
L5:
	mul	w5, w2, w4
	sub	w2, w1, w2
	mov	w4, w3
	madd	w2, w2, w3, w5
	b	L6
	.p2align 2,,3
L23:
	mov	w2, w20
	mov	w1, w21
	add	x0, x19, 64
	bl	_block_fst_plan_init
	mov	w23, w0
	cbnz	w0, L24
	sbfiz	x0, x20, 3, 32
	stp	x25, x26, [x29, 64]
LCFI13:
	sbfiz	x24, x21, 3, 32
	sxtw	x25, w20
	sxtw	x26, w21
	bl	_malloc
	mov	x22, x0
	mov	x0, x24
	str	x22, [x19, 240]
	bl	_malloc
	mul	x1, x25, x24
	mov	x24, x0
	str	x24, [x19, 248]
	mov	x0, x1
	str	x1, [x29, 120]
	bl	_malloc
	mov	x2, x0
	ldr	x0, [x29, 120]
	str	x2, [x19, 256]
	str	x2, [x29, 120]
	bl	_malloc
	ldr	x1, [x29, 120]
	cmp	x22, 0
	ccmp	x24, 0, 4, ne
	cset	w2, eq
	str	x0, [x19, 264]
	cmp	x1, 0
	ccmp	x0, 0, 4, ne
	cset	w1, eq
	orr	w1, w2, w1
	cbnz	w1, L12
	cmp	w20, 0
	ble	L17
	ldr	d31, [x19, 24]
	adrp	x0, lC0@PAGE
	fmov	d14, 4.0e+0
	sub	x22, x22, #8
	add	x25, x25, 1
	ldr	d30, [x0, #lC0@PAGEOFF]
	mov	x20, 1
	fmul	d31, d31, d31
	fdiv	d13, d30, d13
	fdiv	d14, d14, d31
	.p2align 5,,15
L16:
	scvtf	d0, w20
	fmul	d0, d0, d13
	bl	_sin
	fmul	d0, d0, d0
	fmul	d0, d0, d14
	str	d0, [x22, x20, lsl 3]
	add	x20, x20, 1
	cmp	x25, x20
	bne	L16
L17:
	cmp	w21, 0
	ble	L22
	ldr	d30, [x19, 32]
	adrp	x0, lC0@PAGE
	fmov	d31, 4.0e+0
	sub	x24, x24, #8
	add	x21, x26, 1
	ldr	d14, [x0, #lC0@PAGEOFF]
	mov	x19, 1
	fmul	d30, d30, d30
	fdiv	d14, d14, d15
	fdiv	d15, d31, d30
	.p2align 5,,15
L18:
	scvtf	d0, w19
	fmul	d0, d0, d14
	bl	_sin
	fmul	d0, d0, d0
	fmul	d0, d0, d15
	str	d0, [x24, x19, lsl 3]
	add	x19, x19, 1
	cmp	x21, x19
	bne	L18
L22:
	ldr	d15, [sp, 96]
	mov	w0, w23
	ldp	x25, x26, [x29, 64]
LCFI14:
	ldp	x19, x20, [sp, 16]
	ldp	x21, x22, [sp, 32]
	ldp	x23, x24, [sp, 48]
	ldp	d13, d14, [sp, 80]
	ldp	x29, x30, [sp], 128
LCFI15:
	ret
	.p2align 2,,3
L24:
LCFI16:
	mov	x0, x22
	bl	_block_fst_plan_free
	b	L9
L12:
LCFI17:
	mov	x0, x19
	mov	w23, 2
	bl	_poisson_plan_free
	ldp	x25, x26, [x29, 64]
LCFI18:
	b	L4
LFE5:
	.cstring
	.align	3
lC1:
	.ascii "poisson_solve: Nx %8d  Ny %8d  elapsed %12.6f s  GFLOPS %8.3f\12\0"
	.text
	.align	2
	.p2align 5,,15
	.globl _poisson_solve
_poisson_solve:
LFB7:
	sub	sp, sp, #160
LCFI19:
	stp	x29, x30, [sp, 32]
LCFI20:
	add	x29, sp, 32
LCFI21:
	stp	x19, x20, [sp, 48]
	stp	x21, x22, [sp, 64]
	stp	x23, x24, [sp, 80]
LCFI22:
	mov	x23, x0
	stp	x25, x26, [sp, 96]
	str	x27, [sp, 112]
LCFI23:
	mov	x27, x2
	stp	d14, d15, [sp, 128]
LCFI24:
	ldp	w20, w24, [x0]
	ldp	x19, x25, [x0, 256]
	mul	w21, w20, w24
	cmp	w21, 0
	ble	L26
	ubfiz	x2, x21, 3, 32
	mov	x0, x19
	bl	_memcpy
L26:
	bl	_msg_wtime
	fmov	d15, d0
	add	x22, x23, 152
	mov	x1, x19
	mov	x0, x22
	add	x26, x23, 64
	bl	_block_fst_apply
	mov	w1, w24
	mov	w0, w20
	mov	x3, x25
	mov	x2, x19
	bl	_transpose_real
	mov	x1, x25
	mov	x0, x26
	bl	_block_fst_apply
	cmp	w20, 0
	ble	L27
	cmp	w24, 0
	ble	L27
	lsr	w4, w24, 1
	mov	x7, 0
	ldp	x5, x3, [x23, 240]
	lsl	x4, x4, 4
	ubfiz	x6, x24, 3, 32
	add	x9, x5, w20, uxtw 3
	mov	x2, x25
	sub	w0, w24, #1
	and	w10, w24, -2
	and	x8, x24, 4294967294
L34:
	ldr	d28, [x5]
	cmp	w0, 2
	bls	L28
	sub	x1, x2, x3
	cmp	x1, 8
	beq	L28
L45:
	dup	v29.2d, v28.d[0]
	mov	x1, 0
	.p2align 5,,15
L29:
	ldr	q30, [x3, x1]
	ldr	q31, [x2, x1]
	fadd	v30.2d, v30.2d, v29.2d
	fdiv	v31.2d, v31.2d, v30.2d
	str	q31, [x2, x1]
	add	x1, x1, 16
	cmp	x4, x1
	bne	L29
	cmp	w24, w10
	beq	L30
	ldr	d30, [x3, x8, lsl 3]
	add	x1, x7, x8, lsl 3
	ldr	d31, [x25, x1]
	fadd	d28, d28, d30
	fdiv	d31, d31, d28
	str	d31, [x25, x1]
L30:
	add	x5, x5, 8
	cmp	x5, x9
	beq	L27
	add	x2, x2, x6
	ldr	d28, [x5]
	add	x7, x7, x6
	sub	x1, x2, x3
	cmp	x1, 8
	bne	L45
L28:
	mov	x1, 0
	.p2align 5,,15
L31:
	ldr	d30, [x3, x1]
	ldr	d31, [x2, x1]
	fadd	d30, d28, d30
	fdiv	d31, d31, d30
	str	d31, [x2, x1]
	add	x1, x1, 8
	cmp	x6, x1
	bne	L31
	add	x5, x5, 8
	add	x7, x7, x6
	add	x2, x2, x6
	cmp	x9, x5
	bne	L34
	.p2align 5,,15
L27:
	mov	x0, x26
	mov	x1, x25
	bl	_block_fst_apply
	mov	x3, x19
	mov	x2, x25
	mov	w1, w20
	mov	w0, w24
	bl	_transpose_real
	mov	x1, x19
	mov	x0, x22
	bl	_block_fst_apply
	bl	_msg_wtime
	fmov	d14, d0
	bl	_msg_rank
	cbz	w0, L46
	cmp	w21, 0
	ble	L25
L47:
	ldp	d14, d15, [sp, 128]
	ubfiz	x2, x21, 3, 32
	mov	x1, x19
	ldp	x29, x30, [sp, 32]
	mov	x0, x27
	ldp	x19, x20, [sp, 48]
	ldp	x21, x22, [sp, 64]
	ldp	x23, x24, [sp, 80]
	ldp	x25, x26, [sp, 96]
	ldr	x27, [sp, 112]
	add	sp, sp, 160
LCFI25:
	b	_memcpy
L46:
LCFI26:
	add	w23, w20, 1
	add	w22, w24, 1
	fsub	d30, d14, d15
	scvtf	d31, w22
	scvtf	d0, w23
	str	d30, [x29, 120]
	fmul	d0, d0, d31
	bl	_log2
	adrp	x0, lC2@PAGE
	scvtf	d31, w20
	scvtf	d28, w24
	ldr	d30, [x29, 120]
	str	w23, [sp]
	ldr	d29, [x0, #lC2@PAGEOFF]
	adrp	x0, lC1@PAGE
	add	x0, x0, lC1@PAGEOFF;
	str	w22, [sp, 8]
	fmul	d31, d31, d28
	fmul	d29, d0, d29
	fmul	d31, d31, d29
	fdiv	d31, d31, d30
	stp	d30, d31, [sp, 16]
	bl	_printf
	cmp	w21, 0
	bgt	L47
L25:
	ldr	x27, [sp, 112]
	ldp	x29, x30, [sp, 32]
	ldp	x19, x20, [sp, 48]
	ldp	x21, x22, [sp, 64]
	ldp	x23, x24, [sp, 80]
	ldp	x25, x26, [sp, 96]
	ldp	d14, d15, [sp, 128]
	add	sp, sp, 160
LCFI27:
	ret
LFE7:
	.align	2
	.p2align 5,,15
	.globl _poisson_residual_op
_poisson_residual_op:
LFB8:
	ldr	w16, [x0, 4]
	cmp	w16, 0
	ble	L122
	ldr	w6, [x0]
	cmp	w6, 0
	ble	L122
	ldp	d31, d29, [x0, 24]
	fmov	d30, 1.0e+0
	subs	w7, w16, #1
	neg	w17, w6
	ubfiz	x11, x6, 3, 32
	ldr	d2, [x1]
	mov	x8, x2
	add	x13, x2, 8
	mov	x14, x1
	add	x12, x1, 8
	sub	w4, w6, #1
	fmul	d31, d31, d31
	fmul	d29, d29, d29
	fdiv	d31, d30, d31
	fdiv	d29, d30, d29
	beq	L126
	add	x10, x1, x11
	cbz	w4, L65
	ldr	d1, [x1, x11]
	fmov	d0, 2.0e+0
	ldr	d21, [x1, 8]
	fnmsub	d21, d2, d0, d21
	fnmsub	d0, d2, d0, d1
	fmul	d0, d0, d29
	fmadd	d0, d31, d21, d0
L66:
	str	d0, [x2]
	cmp	w6, 1
	beq	L67
	cmp	w4, 2
	ble	L98
	fmov	d6, d2
	fmov	d7, 2.0e+0
	add	x15, x10, 8
	mov	x0, 1
	lsr	w9, w6, 1
	sub	w9, w9, #2
	mov	x3, 3
	add	x9, x3, w9, uxtw 1
L72:
	ldr	d27, [x1, x0, lsl 3]
	movi	d23, #0
	add	w5, w0, 1
	add	w3, w0, 1
	cmp	w4, w0
	ble	L69
	ldr	d23, [x1, x3, lsl 3]
L69:
	fnmsub	d23, d27, d7, d23
	movi	d16, #0
	add	w3, w0, 2
	ldr	d1, [x10, x0, lsl 3]
	fnmsub	d1, d27, d7, d1
	fsub	d23, d23, d6
	ldr	d6, [x12, x0, lsl 3]
	fmul	d1, d1, d29
	fmadd	d1, d31, d23, d1
	str	d1, [x2, x0, lsl 3]
	cmp	w4, w5
	ble	L71
	ldr	d16, [x1, w3, uxtw 3]
L71:
	fnmsub	d4, d6, d7, d27
	ldr	d3, [x15, x0, lsl 3]
	fnmsub	d3, d6, d7, d3
	fsub	d4, d4, d16
	fmul	d3, d3, d29
	fmadd	d3, d31, d4, d3
	str	d3, [x13, x0, lsl 3]
	add	x0, x0, 2
	cmp	x9, x0
	bne	L72
	mov	w0, w3
L68:
	ubfiz	x9, x0, 3, 32
	sub	w5, w0, #1
	movi	d19, #0
	add	w3, w0, 1
	ldr	d22, [x1, x9]
	ldr	d20, [x1, x5, lsl 3]
	cmp	w4, w0
	ble	L73
	ldr	d19, [x1, w3, uxtw 3]
L73:
	add	w5, w6, w0
	fmov	d30, 2.0e+0
	ldr	d18, [x1, x5, lsl 3]
	fnmsub	d20, d22, d30, d20
	fnmsub	d30, d22, d30, d18
	fsub	d20, d20, d19
	fmul	d30, d30, d29
	fmadd	d30, d31, d20, d30
	str	d30, [x2, x9]
	cmp	w6, w3
	ble	L67
	ubfiz	x5, x3, 3, 32
	movi	d0, #0
	ldr	d26, [x1, x5]
	cmp	w4, w3
	bgt	L127
L75:
	add	w3, w6, w3
	fmov	d25, 2.0e+0
	ldr	d24, [x1, x3, lsl 3]
	fnmsub	d22, d26, d25, d22
	fnmsub	d25, d26, d25, d24
	fsub	d22, d22, d0
	fmul	d25, d25, d29
	fmadd	d25, d31, d22, d25
	str	d25, [x2, x5]
L67:
	mov	w5, 0
	fmov	d19, 2.0e+0
	mov	w10, w6
	add	w5, w5, 1
	mov	w9, 0
	cmp	w16, w5
	beq	L122
L125:
	stp	x29, x30, [sp, -32]!
LCFI28:
	mov	x29, sp
	stp	x19, x20, [sp, 16]
LCFI29:
	.p2align 5,,15
L124:
	add	w17, w17, w6
	add	x14, x14, x11
	movi	d18, #0
	sbfiz	x0, x17, 3, 32
	add	w10, w10, w6
	ldr	d20, [x14]
	add	w9, w9, w6
	add	x13, x13, x11
	add	x8, x8, x11
	add	x12, x12, x11
	add	x15, x1, x0
	cbz	w4, L93
	add	w3, w9, 1
	ldr	d18, [x1, x3, lsl 3]
L93:
	movi	d26, #0
	ldr	d23, [x1, x0]
	cmp	w7, w5
	ble	L76
	ldr	d26, [x1, w10, uxtw 3]
L76:
	fnmsub	d23, d20, d19, d23
	fnmsub	d18, d20, d19, d18
	fsub	d23, d23, d26
	fmul	d23, d23, d29
	fmadd	d23, d18, d31, d23
	str	d23, [x8]
	cmp	w6, 1
	beq	L58
	cmp	w4, 2
	ble	L103
	mov	x0, 1
	fmov	d25, d20
	movi	d5, #0
	add	x19, x15, 8
	mov	w3, 2
	ldr	d17, [x14, x0, lsl 3]
	add	w30, w9, 1
	cmp	w4, w0
	ble	L79
L129:
	add	w20, w30, w0
	ldr	d5, [x1, x20, lsl 3]
L79:
	movi	d6, #0
	ldr	d4, [x15, x0, lsl 3]
	cmp	w7, w5
	ble	L80
	add	w20, w10, w0
	ldr	d6, [x1, x20, lsl 3]
L80:
	fnmsub	d4, d17, d19, d4
	fnmsub	d5, d17, d19, d5
	movi	d24, #0
	fsub	d4, d4, d6
	fsub	d5, d5, d25
	ldr	d25, [x12, x0, lsl 3]
	fmul	d4, d4, d29
	fmadd	d4, d31, d5, d4
	str	d4, [x8, x0, lsl 3]
	cmp	w4, w3
	ble	L82
	add	w20, w30, w3
	ldr	d24, [x1, x20, lsl 3]
L82:
	movi	d30, #0
	ldr	d22, [x19, x0, lsl 3]
	cmp	w7, w5
	ble	L83
	add	w20, w3, w10
	ldr	d30, [x1, x20, lsl 3]
L83:
	fnmsub	d7, d25, d19, d22
	fnmsub	d16, d25, d19, d17
	add	w3, w3, 2
	fsub	d7, d7, d30
	fsub	d16, d16, d24
	fmul	d7, d7, d29
	fmadd	d7, d31, d16, d7
	str	d7, [x13, x0, lsl 3]
	cmp	w4, w3
	ble	L128
	add	x0, x0, 2
	movi	d5, #0
	ldr	d17, [x14, x0, lsl 3]
	cmp	w4, w0
	ble	L79
	b	L129
L126:
LCFI30:
	cbz	w4, L52
	ldr	d26, [x1, 8]
	fadd	d4, d2, d2
	fsub	d26, d4, d26
	fmul	d4, d29, d4
	fmadd	d4, d31, d26, d4
L53:
	str	d4, [x2]
	cmp	w6, 1
	beq	L67
	cmp	w4, 2
	ble	L94
	mov	x0, 1
	lsr	w10, w6, 1
	sub	w10, w10, #2
	mov	x3, 3
	add	x10, x3, w10, uxtw 1
L61:
	ldr	d5, [x1, x0, lsl 3]
	movi	d21, #0
	add	w9, w0, 1
	add	w3, w0, 1
	cmp	w4, w0
	ble	L55
	ldr	d21, [x1, x3, lsl 3]
L55:
	fadd	d17, d5, d5
	add	w5, w0, 2
	mov	x3, x5
	fsub	d21, d17, d21
	fmul	d17, d29, d17
	fsub	d21, d21, d2
	ldr	d2, [x12, x0, lsl 3]
	fmadd	d17, d31, d21, d17
	fadd	d6, d2, d2
	str	d17, [x2, x0, lsl 3]
	cmp	w4, w9
	ble	L120
	ldr	d4, [x1, w5, uxtw 3]
	fsub	d5, d6, d5
	fmul	d6, d6, d29
	fsub	d4, d5, d4
	fmadd	d6, d31, d4, d6
	str	d6, [x13, x0, lsl 3]
	add	x0, x0, 2
	cmp	x0, x10
	bne	L61
L54:
	lsl	x5, x5, 3
	sub	w0, w3, #1
	movi	d1, #0
	add	w9, w3, 1
	ldr	d27, [x1, x5]
	ldr	d3, [x1, x0, lsl 3]
	cmp	w4, w3
	ble	L62
	ldr	d1, [x1, w9, uxtw 3]
L62:
	fadd	d0, d27, d27
	fsub	d3, d0, d3
	fmul	d0, d29, d0
	fsub	d3, d3, d1
	fmadd	d0, d31, d3, d0
	str	d0, [x2, x5]
	cmp	w6, w9
	ble	L67
	ubfiz	x0, x9, 3, 32
	movi	d2, #0
	ldr	d28, [x1, x0]
	cmp	w4, w9
	ble	L64
	add	w3, w3, 2
	ldr	d2, [x1, x3, lsl 3]
L64:
	fadd	d28, d28, d28
	mov	w5, 0
	fmov	d19, 2.0e+0
	add	w5, w5, 1
	mov	w10, w6
	mov	w9, 0
	fsub	d27, d28, d27
	fmul	d28, d29, d28
	fsub	d27, d27, d2
	fmadd	d28, d31, d27, d28
	str	d28, [x2, x0]
	cmp	w16, w5
	bne	L125
L122:
	ret
	.p2align 2,,3
L128:
LCFI31:
	add	w0, w0, 2
L78:
	add	w3, w0, w9
	sub	w15, w0, #1
	movi	d3, #0
	lsl	x3, x3, 3
	add	w15, w15, w9
	add	w30, w0, 1
	ldr	d21, [x1, x3]
	ldr	d1, [x1, x15, lsl 3]
	cmp	w4, w0
	ble	L85
	add	w15, w30, w9
	ldr	d3, [x1, x15, lsl 3]
L85:
	add	w15, w0, w17
	movi	d2, #0
	ldr	d0, [x1, x15, lsl 3]
	cmp	w7, w5
	ble	L86
	add	w15, w10, w0
	ldr	d2, [x1, x15, lsl 3]
L86:
	fnmsub	d0, d21, d19, d0
	fnmsub	d1, d21, d19, d1
	fsub	d0, d0, d2
	fsub	d1, d1, d3
	fmul	d0, d0, d29
	fmadd	d0, d31, d1, d0
	str	d0, [x2, x3]
	cmp	w6, w30
	ble	L58
	add	w3, w30, w9
	movi	d28, #0
	lsl	x3, x3, 3
	ldr	d18, [x1, x3]
	cmp	w4, w30
	ble	L88
	add	w0, w0, 2
	add	w0, w0, w9
	ldr	d28, [x1, x0, lsl 3]
L88:
	add	w0, w30, w17
	movi	d27, #0
	ldr	d26, [x1, x0, lsl 3]
	cmp	w7, w5
	ble	L89
	add	w30, w10, w30
	ldr	d27, [x1, x30, lsl 3]
L89:
	fmov	d23, 2.0e+0
	fnmsub	d21, d18, d23, d21
	fnmsub	d23, d18, d23, d26
	fsub	d23, d23, d27
	fsub	d21, d21, d28
	fmul	d23, d23, d29
	fmadd	d23, d31, d21, d23
	str	d23, [x2, x3]
L58:
	add	w5, w5, 1
	cmp	w16, w5
	bne	L124
	ldp	x19, x20, [sp, 16]
	ldp	x29, x30, [sp], 32
LCFI32:
	ret
	.p2align 2,,3
L52:
	fadd	d25, d2, d2
	fadd	d24, d31, d29
	fmul	d4, d25, d24
	b	L53
L65:
	ldr	d17, [x1, x11]
	fadd	d5, d2, d2
	fsub	d17, d5, d17
	fmul	d17, d17, d29
	fmadd	d0, d31, d5, d17
	b	L66
	.p2align 2,,3
L120:
	fadd	d7, d2, d2
	fsub	d16, d7, d5
	fmul	d7, d29, d7
	fmadd	d7, d31, d16, d7
	str	d7, [x13, x0, lsl 3]
	add	x0, x0, 2
	cmp	x10, x0
	bne	L61
	uxtw	x5, w5
	b	L54
L127:
	add	w0, w0, 2
	ldr	d0, [x1, x0, lsl 3]
	b	L75
L103:
LCFI33:
	mov	w0, 1
	b	L78
L98:
LCFI34:
	mov	w0, 1
	b	L68
L94:
	mov	w3, 1
	mov	x5, 1
	b	L54
LFE8:
	.literal8
	.align	3
lC0:
	.word	1413754136
	.word	1073291771
	.align	3
lC2:
	.word	-500134854
	.word	1045789070
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
	.quad	LFB6-.
	.set L$set$2,LFE6-LFB6
	.quad L$set$2
	.uleb128 0
	.byte	0x4
	.set L$set$3,LCFI0-LFB6
	.long L$set$3
	.byte	0xe
	.uleb128 0x20
	.byte	0x9d
	.uleb128 0x4
	.byte	0x9e
	.uleb128 0x3
	.byte	0x4
	.set L$set$4,LCFI1-LCFI0
	.long L$set$4
	.byte	0xd
	.uleb128 0x1d
	.byte	0x4
	.set L$set$5,LCFI2-LCFI1
	.long L$set$5
	.byte	0x93
	.uleb128 0x2
	.byte	0x4
	.set L$set$6,LCFI3-LCFI2
	.long L$set$6
	.byte	0xde
	.byte	0xdd
	.byte	0xd3
	.byte	0xc
	.uleb128 0x1f
	.uleb128 0
	.align	3
LEFDE1:
LSFDE3:
	.set L$set$7,LEFDE3-LASFDE3
	.long L$set$7
LASFDE3:
	.long	LASFDE3-EH_frame1
	.quad	LFB5-.
	.set L$set$8,LFE5-LFB5
	.quad L$set$8
	.uleb128 0
	.byte	0x4
	.set L$set$9,LCFI4-LFB5
	.long L$set$9
	.byte	0xe
	.uleb128 0x80
	.byte	0x9d
	.uleb128 0x10
	.byte	0x9e
	.uleb128 0xf
	.byte	0x4
	.set L$set$10,LCFI5-LCFI4
	.long L$set$10
	.byte	0xd
	.uleb128 0x1d
	.byte	0x4
	.set L$set$11,LCFI6-LCFI5
	.long L$set$11
	.byte	0x95
	.uleb128 0xc
	.byte	0x96
	.uleb128 0xb
	.byte	0x4
	.set L$set$12,LCFI7-LCFI6
	.long L$set$12
	.byte	0x93
	.uleb128 0xe
	.byte	0x94
	.uleb128 0xd
	.byte	0x4
	.set L$set$13,LCFI8-LCFI7
	.long L$set$13
	.byte	0x5
	.uleb128 0x4d
	.uleb128 0x6
	.byte	0x5
	.uleb128 0x4e
	.uleb128 0x5
	.byte	0x4
	.set L$set$14,LCFI9-LCFI8
	.long L$set$14
	.byte	0x5
	.uleb128 0x4f
	.uleb128 0x4
	.byte	0x4
	.set L$set$15,LCFI10-LCFI9
	.long L$set$15
	.byte	0x97
	.uleb128 0xa
	.byte	0x98
	.uleb128 0x9
	.byte	0x4
	.set L$set$16,LCFI11-LCFI10
	.long L$set$16
	.byte	0xa
	.byte	0xde
	.byte	0xdd
	.byte	0xd7
	.byte	0xd8
	.byte	0xd5
	.byte	0xd6
	.byte	0xd3
	.byte	0xd4
	.byte	0x6
	.uleb128 0x4f
	.byte	0x6
	.uleb128 0x4d
	.byte	0x6
	.uleb128 0x4e
	.byte	0xc
	.uleb128 0x1f
	.uleb128 0
	.byte	0x4
	.set L$set$17,LCFI12-LCFI11
	.long L$set$17
	.byte	0xb
	.byte	0x4
	.set L$set$18,LCFI13-LCFI12
	.long L$set$18
	.byte	0x9a
	.uleb128 0x7
	.byte	0x99
	.uleb128 0x8
	.byte	0x4
	.set L$set$19,LCFI14-LCFI13
	.long L$set$19
	.byte	0xda
	.byte	0xd9
	.byte	0x4
	.set L$set$20,LCFI15-LCFI14
	.long L$set$20
	.byte	0xde
	.byte	0xdd
	.byte	0xd7
	.byte	0xd8
	.byte	0xd5
	.byte	0xd6
	.byte	0xd3
	.byte	0xd4
	.byte	0x6
	.uleb128 0x4f
	.byte	0x6
	.uleb128 0x4d
	.byte	0x6
	.uleb128 0x4e
	.byte	0xc
	.uleb128 0x1f
	.uleb128 0
	.byte	0x4
	.set L$set$21,LCFI16-LCFI15
	.long L$set$21
	.byte	0xc
	.uleb128 0x1d
	.uleb128 0x80
	.byte	0x93
	.uleb128 0xe
	.byte	0x94
	.uleb128 0xd
	.byte	0x95
	.uleb128 0xc
	.byte	0x96
	.uleb128 0xb
	.byte	0x97
	.uleb128 0xa
	.byte	0x98
	.uleb128 0x9
	.byte	0x9d
	.uleb128 0x10
	.byte	0x9e
	.uleb128 0xf
	.byte	0x5
	.uleb128 0x4d
	.uleb128 0x6
	.byte	0x5
	.uleb128 0x4e
	.uleb128 0x5
	.byte	0x5
	.uleb128 0x4f
	.uleb128 0x4
	.byte	0x4
	.set L$set$22,LCFI17-LCFI16
	.long L$set$22
	.byte	0x99
	.uleb128 0x8
	.byte	0x9a
	.uleb128 0x7
	.byte	0x4
	.set L$set$23,LCFI18-LCFI17
	.long L$set$23
	.byte	0xda
	.byte	0xd9
	.align	3
LEFDE3:
LSFDE5:
	.set L$set$24,LEFDE5-LASFDE5
	.long L$set$24
LASFDE5:
	.long	LASFDE5-EH_frame1
	.quad	LFB7-.
	.set L$set$25,LFE7-LFB7
	.quad L$set$25
	.uleb128 0
	.byte	0x4
	.set L$set$26,LCFI19-LFB7
	.long L$set$26
	.byte	0xe
	.uleb128 0xa0
	.byte	0x4
	.set L$set$27,LCFI20-LCFI19
	.long L$set$27
	.byte	0x9d
	.uleb128 0x10
	.byte	0x9e
	.uleb128 0xf
	.byte	0x4
	.set L$set$28,LCFI21-LCFI20
	.long L$set$28
	.byte	0xc
	.uleb128 0x1d
	.uleb128 0x80
	.byte	0x4
	.set L$set$29,LCFI22-LCFI21
	.long L$set$29
	.byte	0x93
	.uleb128 0xe
	.byte	0x94
	.uleb128 0xd
	.byte	0x95
	.uleb128 0xc
	.byte	0x96
	.uleb128 0xb
	.byte	0x97
	.uleb128 0xa
	.byte	0x98
	.uleb128 0x9
	.byte	0x4
	.set L$set$30,LCFI23-LCFI22
	.long L$set$30
	.byte	0x99
	.uleb128 0x8
	.byte	0x9a
	.uleb128 0x7
	.byte	0x9b
	.uleb128 0x6
	.byte	0x4
	.set L$set$31,LCFI24-LCFI23
	.long L$set$31
	.byte	0x5
	.uleb128 0x4e
	.uleb128 0x4
	.byte	0x5
	.uleb128 0x4f
	.uleb128 0x3
	.byte	0x4
	.set L$set$32,LCFI25-LCFI24
	.long L$set$32
	.byte	0xa
	.byte	0xdb
	.byte	0xd9
	.byte	0xda
	.byte	0xd7
	.byte	0xd8
	.byte	0xd5
	.byte	0xd6
	.byte	0xd3
	.byte	0xd4
	.byte	0xdd
	.byte	0xde
	.byte	0x6
	.uleb128 0x4e
	.byte	0x6
	.uleb128 0x4f
	.byte	0xc
	.uleb128 0x1f
	.uleb128 0
	.byte	0x4
	.set L$set$33,LCFI26-LCFI25
	.long L$set$33
	.byte	0xb
	.byte	0x4
	.set L$set$34,LCFI27-LCFI26
	.long L$set$34
	.byte	0xdb
	.byte	0xd9
	.byte	0xda
	.byte	0xd7
	.byte	0xd8
	.byte	0xd5
	.byte	0xd6
	.byte	0xd3
	.byte	0xd4
	.byte	0xdd
	.byte	0xde
	.byte	0x6
	.uleb128 0x4e
	.byte	0x6
	.uleb128 0x4f
	.byte	0xc
	.uleb128 0x1f
	.uleb128 0
	.align	3
LEFDE5:
LSFDE7:
	.set L$set$35,LEFDE7-LASFDE7
	.long L$set$35
LASFDE7:
	.long	LASFDE7-EH_frame1
	.quad	LFB8-.
	.set L$set$36,LFE8-LFB8
	.quad L$set$36
	.uleb128 0
	.byte	0x4
	.set L$set$37,LCFI28-LFB8
	.long L$set$37
	.byte	0xe
	.uleb128 0x20
	.byte	0x9d
	.uleb128 0x4
	.byte	0x9e
	.uleb128 0x3
	.byte	0x4
	.set L$set$38,LCFI29-LCFI28
	.long L$set$38
	.byte	0x93
	.uleb128 0x2
	.byte	0x94
	.uleb128 0x1
	.byte	0x4
	.set L$set$39,LCFI30-LCFI29
	.long L$set$39
	.byte	0xe
	.uleb128 0
	.byte	0xd3
	.byte	0xd4
	.byte	0xdd
	.byte	0xde
	.byte	0x4
	.set L$set$40,LCFI31-LCFI30
	.long L$set$40
	.byte	0xe
	.uleb128 0x20
	.byte	0x93
	.uleb128 0x2
	.byte	0x94
	.uleb128 0x1
	.byte	0x9d
	.uleb128 0x4
	.byte	0x9e
	.uleb128 0x3
	.byte	0x4
	.set L$set$41,LCFI32-LCFI31
	.long L$set$41
	.byte	0xde
	.byte	0xdd
	.byte	0xd3
	.byte	0xd4
	.byte	0xe
	.uleb128 0
	.byte	0x4
	.set L$set$42,LCFI33-LCFI32
	.long L$set$42
	.byte	0xe
	.uleb128 0x20
	.byte	0x93
	.uleb128 0x2
	.byte	0x94
	.uleb128 0x1
	.byte	0x9d
	.uleb128 0x4
	.byte	0x9e
	.uleb128 0x3
	.byte	0x4
	.set L$set$43,LCFI34-LCFI33
	.long L$set$43
	.byte	0xe
	.uleb128 0
	.byte	0xd3
	.byte	0xd4
	.byte	0xdd
	.byte	0xde
	.align	3
LEFDE7:
	.ident	"GCC: (Homebrew GCC 15.2.0_1) 15.2.0"
	.subsections_via_symbols
