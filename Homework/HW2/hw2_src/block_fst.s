	.arch armv8.5-a
	.build_version macos,  26, 0
	.text
	.align	2
	.p2align 5,,15
	.globl _block_fst_plan_free
_block_fst_plan_free:
LFB6:
	stp	x29, x30, [sp, -32]!
LCFI0:
	mov	x29, sp
LCFI1:
	str	x19, [sp, 16]
LCFI2:
	mov	x19, x0
	add	x0, x0, 16
	bl	_block_fft_plan_free
	ldr	x0, [x19, 64]
	bl	_free
	ldr	x0, [x19, 72]
	str	xzr, [x19, 64]
	bl	_free
	ldr	x0, [x19, 80]
	str	xzr, [x19, 72]
	bl	_free
	str	xzr, [x19, 80]
	ldr	x19, [sp, 16]
	ldp	x29, x30, [sp], 32
LCFI3:
	ret
LFE6:
	.cstring
	.align	3
lC0:
	.ascii "block_fst: require m,n >= 1\12\0"
	.align	3
lC1:
	.ascii "block_fst: require L=2*(n+1)=4^k; try n=31,127,511,2047,...\12\0"
	.text
	.align	2
	.p2align 5,,15
	.globl _block_fst_plan_init
_block_fst_plan_init:
LFB5:
	stp	x29, x30, [sp, -48]!
LCFI4:
	add	w3, w2, 1
	mov	x29, sp
LCFI5:
	stp	x19, x20, [sp, 16]
LCFI6:
	mov	w20, w2
	mov	w2, w1
	lsl	w1, w3, 1
	cmp	w2, 0
	ccmp	w20, 0, 4, gt
	mov	x19, x0
	stp	w2, w20, [x0]
	mov	w3, 1
	str	w1, [x0, 8]
	stp	xzr, xzr, [x0, 64]
	str	xzr, [x0, 80]
	ble	L19
	.p2align 5,,15
L5:
	lsl	w3, w3, 2
	cmp	w1, w3
	bgt	L5
	bne	L20
	umull	x0, w1, w2
	str	w1, [x29, 32]
	str	w2, [x29, 40]
	lsl	x0, x0, 4
	bl	_malloc
	ldr	w2, [x29, 40]
	mov	x3, x0
	str	x3, [x19, 64]
	str	x3, [x29, 40]
	umull	x20, w2, w20
	str	w2, [x29, 36]
	lsl	x0, x20, 3
	bl	_malloc
	ldr	x3, [x29, 40]
	cmp	x0, 0
	ldp	w1, w2, [x29, 32]
	str	x0, [x19, 80]
	ccmp	x3, 0, 4, ne
	beq	L21
	add	x0, x19, 16
	mov	w3, 4
	bl	_block_fft_plan_init
	cbnz	w0, L22
L4:
	ldp	x19, x20, [sp, 16]
	ldp	x29, x30, [sp], 48
LCFI7:
	ret
	.p2align 2,,3
L20:
LCFI8:
	adrp	x3, ___stderrp@GOTPAGE
	ldr	x3, [x3, ___stderrp@GOTPAGEOFF]
	adrp	x0, lC1@PAGE
	mov	x2, 60
	add	x0, x0, lC1@PAGEOFF;
	mov	x1, 1
	ldr	x3, [x3]
	bl	_fwrite
	mov	w0, 1
L23:
	ldp	x19, x20, [sp, 16]
	ldp	x29, x30, [sp], 48
LCFI9:
	ret
	.p2align 2,,3
L19:
LCFI10:
	adrp	x3, ___stderrp@GOTPAGE
	ldr	x3, [x3, ___stderrp@GOTPAGEOFF]
	adrp	x0, lC0@PAGE
	mov	x2, 28
	add	x0, x0, lC0@PAGEOFF;
	mov	x1, 1
	ldr	x3, [x3]
	bl	_fwrite
	mov	w0, 1
	b	L23
L22:
	add	x0, x19, 16
	bl	_block_fft_plan_free
	ldr	x0, [x19, 64]
	bl	_free
	ldr	x0, [x19, 72]
	str	xzr, [x19, 64]
	bl	_free
	ldr	x0, [x19, 80]
	str	xzr, [x19, 72]
	bl	_free
	mov	w0, 3
	str	xzr, [x19, 80]
	b	L4
L21:
	mov	x0, x19
	bl	_block_fst_plan_free
	mov	w0, 2
	b	L4
LFE5:
	.align	2
	.p2align 5,,15
	.globl _block_fst_apply
_block_fst_apply:
LFB7:
	ldp	w10, w16, [x0]
	mov	x11, x1
	ldr	w3, [x0, 8]
	ldr	x1, [x0, 64]
	mul	w3, w10, w3
	cmp	w3, 0
	ble	L29
	movi	v31.4s, 0
	mov	x2, x1
	sub	w3, w3, #1
	add	x4, x1, 16
	add	x3, x4, w3, uxtw 4
	.p2align 5,,15
L28:
	str	q31, [x2], 16
	cmp	x2, x3
	bne	L28
L29:
	cmp	w16, 0
	ble	L30
	cmp	w10, 0
	ble	L30
	add	w2, w16, 1
	fmov	d3, 2.0e+0
	stp	x29, x30, [sp, -80]!
LCFI11:
	mov	x29, sp
LCFI12:
	sub	w6, w16, #1
	scvtf	d4, w2
	add	w7, w10, w10, lsl 1
	sxtw	x9, w10
	str	d15, [sp, 16]
LCFI13:
	fmov	d15, -5.0e-1
	mul	w6, w6, w10
	neg	w15, w10
	ubfiz	x12, x10, 3, 32
	neg	x5, x9, lsl 4
	sxtw	x15, w15
	add	x8, x11, x12
	add	w7, w7, w6
	sub	x15, x15, x9
	sxtw	x6, w6
	lsl	x7, x7, 4
	fdiv	d3, d3, d4
	mov	x13, x11
	mov	w14, 1
	fsqrt	d3, d3
	fmul	d15, d3, d15
	.p2align 5,,15
L32:
	sub	x2, x8, x12
	sub	x3, x1, x5
	.p2align 5,,15
L31:
	ldr	d2, [x2, x6, lsl 3]
	add	x4, x5, x3
	add	x2, x2, 8
	add	x3, x3, 16
	ldr	d31, [x2, -8]
	fneg	d2, d2
	str	d31, [x3, -16]
	str	d2, [x4, x7]
	cmp	x2, x8
	bne	L31
	sub	x5, x5, x9, lsl 4
	add	x6, x6, x15
	add	x8, x2, x12
	add	x7, x7, x9, lsl 4
	cmp	w16, w14
	beq	L53
	add	w14, w14, 1
	b	L32
	.p2align 2,,3
L53:
	mov	x2, x0
	add	x0, x0, 16
	stp	x11, x9, [x29, 32]
	stp	x13, x12, [x29, 48]
	stp	w14, w10, [x29, 64]
	str	x2, [x29, 72]
	bl	_block_fft_forward
	ldr	x2, [x29, 72]
	mov	x1, 0
	mov	w6, 1
	ldp	x11, x9, [x29, 32]
	ldp	x13, x12, [x29, 48]
	mov	x4, x9
	ldp	w14, w10, [x29, 64]
	ldr	x8, [x2, 64]
	sub	w7, w10, #1
	lsr	w15, w7, 1
	add	x5, x8, 8
	add	x5, x5, w10, uxtw 4
	cmp	w7, 1
	bls	L41
	.p2align 5,,15
L55:
	mov	x2, x5
	mov	x0, x13
	add	x3, x13, w15, uxtw 4
	.p2align 5,,15
L35:
	ld2	{v30.2d - v31.2d}, [x2], 32
	fmul	v30.2d, v30.2d, v15.d[0]
	str	q30, [x0], 16
	cmp	x3, x0
	bne	L35
	and	w0, w7, -2
L34:
	add	w2, w0, w4
	add	w3, w0, w1
	add	x2, x8, x2, lsl 4
	add	w0, w0, 1
	ldr	d1, [x2, 8]
	fmul	d1, d1, d15
	str	d1, [x11, x3, lsl 3]
	cmp	w0, w10
	bge	L39
	add	w2, w0, w4
	add	w0, w0, w1
	add	x2, x8, x2, lsl 4
	ldr	d0, [x2, 8]
	fmul	d0, d0, d15
	str	d0, [x11, x0, lsl 3]
L39:
	add	x4, x4, x9
	add	x1, x1, x9
	add	x5, x5, w10, uxtw 4
	add	x13, x13, x12
	cmp	w14, w6
	beq	L54
	add	w6, w6, 1
	cmp	w7, 1
	bhi	L55
L41:
	mov	w0, 0
	b	L34
	.p2align 2,,3
L54:
	ldr	d15, [sp, 16]
	ldp	x29, x30, [sp], 80
LCFI14:
	ret
L30:
	add	x0, x0, 16
	b	_block_fft_forward
LFE7:
	.align	2
	.p2align 5,,15
	.globl _block_fst_direct_ortho
_block_fst_direct_ortho:
LFB8:
	cmp	w1, 0
	ble	L66
	cmp	w0, 0
	ble	L66
	stp	x29, x30, [sp, -128]!
LCFI15:
	mov	x29, sp
LCFI16:
	fmov	d30, 1.0e+0
	stp	x23, x24, [sp, 48]
LCFI17:
	mov	w24, w1
	add	w1, w1, 1
	ubfiz	x23, x0, 3, 32
	scvtf	d31, w1
	stp	d13, d14, [sp, 96]
	stp	x25, x26, [sp, 64]
LCFI18:
	mov	x26, x2
	adrp	x2, lC2@PAGE
	mov	x25, x3
	ldr	d29, [x2, #lC2@PAGEOFF]
	fdiv	d31, d30, d31
	stp	x21, x22, [sp, 32]
LCFI19:
	mov	w22, 0
	stp	x27, x28, [sp, 80]
LCFI20:
	sxtw	x27, w0
	stp	x19, x20, [sp, 16]
	str	d15, [sp, 112]
LCFI21:
	fadd	d13, d31, d31
	fmul	d14, d31, d29
	fsqrt	d13, d13
	.p2align 5,,15
L59:
	add	w22, w22, 1
	mov	x28, 0
	.p2align 5,,15
L62:
	movi	d15, #0
	mov	w20, w22
	mov	w19, 0
	add	x21, x26, w28, uxtw 3
	.p2align 5,,15
L60:
	scvtf	d0, w20
	add	w19, w19, 1
	add	w20, w20, w22
	fmul	d0, d0, d14
	bl	_sin
	ldr	d31, [x21]
	add	x21, x21, x23
	fmadd	d15, d31, d0, d15
	cmp	w19, w24
	bne	L60
	fmul	d15, d13, d15
	str	d15, [x25, x28, lsl 3]
	add	x28, x28, 1
	cmp	x27, x28
	bne	L62
	add	x25, x25, x23
	cmp	w24, w22
	bne	L59
	ldr	d15, [sp, 112]
	ldp	x19, x20, [sp, 16]
	ldp	x21, x22, [sp, 32]
	ldp	x23, x24, [sp, 48]
	ldp	x25, x26, [sp, 64]
	ldp	x27, x28, [sp, 80]
	ldp	d13, d14, [sp, 96]
	ldp	x29, x30, [sp], 128
LCFI22:
	ret
L66:
	ret
LFE8:
	.align	2
	.p2align 5,,15
	.globl _block_fst_build_matrix
_block_fst_build_matrix:
LFB9:
	stp	x29, x30, [sp, -80]!
LCFI23:
	mov	x29, sp
LCFI24:
	stp	x19, x20, [sp, 16]
LCFI25:
	mov	x19, x0
	ldr	x0, [x0, 72]
	cbz	x0, L79
L70:
	mov	w0, 0
L69:
	ldp	x19, x20, [sp, 16]
	ldp	x29, x30, [sp], 80
LCFI26:
	ret
	.p2align 2,,3
L79:
LCFI27:
	stp	x21, x22, [x29, 32]
LCFI28:
	stp	x23, x24, [x29, 48]
LCFI29:
	ldr	w24, [x19, 4]
	smull	x0, w24, w24
	lsl	x0, x0, 3
	bl	_malloc
	str	x0, [x19, 72]
	mov	x22, x0
	cbz	x0, L74
	cmp	w24, 0
	ble	L77
	add	w0, w24, 1
	fmov	d30, 1.0e+0
	stp	d14, d15, [x29, 64]
LCFI30:
	adrp	x1, lC2@PAGE
	sbfiz	x23, x24, 3, 32
	scvtf	d31, w0
	mov	w21, 0
	add	x22, x22, x23
	ldr	d29, [x1, #lC2@PAGEOFF]
	fdiv	d31, d30, d31
	fadd	d14, d31, d31
	fmul	d15, d31, d29
	fsqrt	d14, d14
	.p2align 5,,15
L72:
	add	w21, w21, 1
	sub	x20, x22, x23
	mov	w19, w21
	.p2align 5,,15
L73:
	scvtf	d0, w19
	add	w19, w19, w21
	fmul	d0, d0, d15
	bl	_sin
	fmul	d0, d0, d14
	str	d0, [x20], 8
	cmp	x22, x20
	bne	L73
	add	x22, x22, x23
	cmp	w24, w21
	bne	L72
	ldp	d14, d15, [x29, 64]
LCFI31:
	ldp	x21, x22, [x29, 32]
LCFI32:
	ldp	x23, x24, [x29, 48]
LCFI33:
	b	L70
L77:
LCFI34:
	ldp	x21, x22, [x29, 32]
LCFI35:
	ldp	x23, x24, [x29, 48]
LCFI36:
	b	L70
L74:
LCFI37:
	ldp	x21, x22, [x29, 32]
LCFI38:
	mov	w0, 1
	ldp	x23, x24, [x29, 48]
LCFI39:
	b	L69
LFE9:
	.cstring
	.align	3
lC3:
	.ascii "block_fst_apply_slow: could not build S\12\0"
	.text
	.align	2
	.p2align 5,,15
	.globl _block_fst_apply_slow
_block_fst_apply_slow:
LFB10:
	stp	x29, x30, [sp, -80]!
LCFI40:
	mov	x29, sp
LCFI41:
	stp	x19, x20, [sp, 16]
LCFI42:
	mov	x20, x1
	stp	x21, x22, [sp, 32]
	stp	x23, x24, [sp, 48]
LCFI43:
	mov	x23, x0
	ldp	w21, w19, [x0]
	bl	_block_fst_build_matrix
	cbnz	w0, L81
	cmp	w19, 0
	ble	L101
	cmp	w21, 0
	ble	L101
	str	x25, [x29, 64]
LCFI44:
	sxtw	x3, w21
	ubfiz	x22, x21, 3, 32
	ldp	x9, x1, [x23, 72]
	ubfiz	x30, x19, 3, 32
	sub	w13, w19, #1
	mov	w16, 0
	ubfiz	x5, x21, 4, 32
	mov	x15, 0
	mov	w8, 0
	mov	x14, 0
	and	w12, w19, 1
	lsr	w17, w19, 1
	.p2align 5,,15
L83:
	mov	x7, x20
	mov	x6, 0
	add	x11, x1, x14
	add	x10, x9, x15
	add	x4, x10, w17, uxtw 4
	.p2align 5,,15
L91:
	mov	w23, w6
	cmp	w13, 2
	bls	L92
L89:
	movi	v5.4s, 0
	mov	x2, x10
	mov	x0, x7
	.p2align 5,,15
L86:
	ldr	d31, [x0, x3, lsl 3]
	ldr	d4, [x0]
	add	x0, x0, x5
	ldr	q3, [x2], 16
	uzp1	v4.2d, v4.2d, v31.2d
	fmla	v5.2d, v4.2d, v3.2d
	cmp	x4, x2
	bne	L86
	faddp	d31, v5.2d
	cbz	w12, L84
	and	w0, w19, -2
L90:
	add	w24, w8, w0
	add	w25, w0, 1
	ldr	d2, [x9, x24, lsl 3]
	madd	w24, w21, w0, w23
	ldr	d29, [x20, x24, lsl 3]
	fmadd	d29, d2, d29, d31
	cmp	w19, w25
	ble	L85
	madd	w2, w21, w0, w21
	add	w25, w8, w25
	add	w0, w0, 2
	ldr	d0, [x9, x25, lsl 3]
	add	w24, w2, w23
	ldr	d1, [x20, x24, lsl 3]
	fmadd	d29, d1, d0, d29
	cmp	w0, w19
	bge	L85
	add	w2, w21, w2
	add	w0, w8, w0
	add	w2, w2, w23
	ldr	d30, [x9, x0, lsl 3]
	ldr	d28, [x20, x2, lsl 3]
	fmadd	d29, d28, d30, d29
L85:
	str	d29, [x11, x6, lsl 3]
	add	x6, x6, 1
	add	x7, x7, 8
	cmp	x3, x6
	bne	L91
L88:
	add	w16, w16, 1
	add	x14, x14, x22
	add	w8, w8, w19
	add	x15, x15, x30
	cmp	w19, w16
	bne	L83
	smull	x2, w21, w19
	ldr	x25, [x29, 64]
LCFI45:
	mov	x0, x20
	ldp	x21, x22, [sp, 32]
	lsl	x2, x2, 3
	ldp	x19, x20, [sp, 16]
	ldp	x23, x24, [sp, 48]
	ldp	x29, x30, [sp], 80
LCFI46:
	b	_memcpy
	.p2align 2,,3
L84:
LCFI47:
	str	d31, [x11, x6, lsl 3]
	add	x6, x6, 1
	cmp	x6, x3
	beq	L88
	add	x7, x7, 8
	mov	w23, w6
	b	L89
	.p2align 2,,3
L92:
	movi	d31, #0
	mov	w0, 0
	b	L90
L81:
LCFI48:
	adrp	x3, ___stderrp@GOTPAGE
	ldr	x3, [x3, ___stderrp@GOTPAGEOFF]
	adrp	x0, lC3@PAGE
	mov	x2, 40
	ldp	x19, x20, [sp, 16]
	add	x0, x0, lC3@PAGEOFF;
	mov	x1, 1
	ldp	x21, x22, [sp, 32]
	ldp	x23, x24, [sp, 48]
	ldp	x29, x30, [sp], 80
LCFI49:
	ldr	x3, [x3]
	b	_fwrite
L101:
LCFI50:
	smull	x2, w21, w19
	ldr	x1, [x23, 80]
	mov	x0, x20
	ldp	x21, x22, [sp, 32]
	lsl	x2, x2, 3
	ldp	x19, x20, [sp, 16]
	ldp	x23, x24, [sp, 48]
	ldp	x29, x30, [sp], 80
LCFI51:
	b	_memcpy
LFE10:
	.cstring
	.align	3
lC4:
	.ascii "block_fst_apply_matmul: could not build S\12\0"
	.text
	.align	2
	.p2align 5,,15
	.globl _block_fst_apply_matmul
_block_fst_apply_matmul:
LFB11:
	stp	x29, x30, [sp, -48]!
LCFI52:
	mov	x29, sp
LCFI53:
	stp	x19, x20, [sp, 16]
LCFI54:
	mov	x19, x1
	stp	x21, x22, [sp, 32]
LCFI55:
	mov	x22, x0
	ldp	w20, w21, [x0]
	bl	_block_fst_build_matrix
	cbnz	w0, L103
	mul	w2, w20, w21
	ldr	x6, [x22, 80]
	cmp	w2, 0
	ble	L107
	mov	x0, x6
	ubfiz	x2, x2, 3, 32
	mov	w1, 0
	bl	_memset
	mov	x6, x0
L107:
	cmp	w21, 0
	ble	L106
	cmp	w20, 0
	ble	L106
	ldr	x7, [x22, 72]
	ubfiz	x12, x21, 3, 32
	lsr	w3, w20, 1
	mov	w11, 0
	mov	x9, 0
	lsl	x3, x3, 4
	sxtw	x8, w20
	ubfiz	x13, x20, 3, 32
	mov	x1, x6
	and	w10, w20, 1
	add	x7, x7, x12
	.p2align 5,,15
L116:
	mov	x5, 0
	sub	x4, x7, x12
	.p2align 5,,15
L115:
	ldr	d31, [x4]
	cmp	w20, 1
	beq	L117
L113:
	dup	v30.2d, v31.d[0]
	add	x2, x19, x5, lsl 3
	mov	x0, 0
	.p2align 5,,15
L110:
	ldr	q0, [x1, x0]
	ldr	q1, [x2, x0]
	fmla	v0.2d, v30.2d, v1.2d
	str	q0, [x1, x0]
	add	x0, x0, 16
	cmp	x3, x0
	bne	L110
	cbz	w10, L114
	and	w2, w20, -2
L109:
	add	w0, w2, w9
	add	w2, w2, w5
	lsl	x0, x0, 3
	add	x4, x4, 8
	ldr	d29, [x19, x2, lsl 3]
	add	x5, x5, x8
	ldr	d28, [x6, x0]
	fmadd	d28, d31, d29, d28
	str	d28, [x6, x0]
	cmp	x4, x7
	bne	L115
L112:
	add	w11, w11, 1
	add	x7, x7, x12
	add	x9, x9, x8
	add	x1, x1, x13
	cmp	w21, w11
	bne	L116
L106:
	smull	x2, w20, w21
	mov	x0, x19
	ldp	x21, x22, [sp, 32]
	mov	x1, x6
	ldp	x19, x20, [sp, 16]
	lsl	x2, x2, 3
	ldp	x29, x30, [sp], 48
LCFI56:
	b	_memcpy
	.p2align 2,,3
L114:
LCFI57:
	add	x4, x4, 8
	cmp	x4, x7
	beq	L112
	ldr	d31, [x4]
	add	x5, x5, x8
	b	L113
L117:
	mov	w2, 0
	b	L109
L103:
	adrp	x3, ___stderrp@GOTPAGE
	ldr	x3, [x3, ___stderrp@GOTPAGEOFF]
	adrp	x0, lC4@PAGE
	mov	x2, 42
	ldp	x19, x20, [sp, 16]
	add	x0, x0, lC4@PAGEOFF;
	mov	x1, 1
	ldp	x21, x22, [sp, 32]
	ldp	x29, x30, [sp], 48
LCFI58:
	ldr	x3, [x3]
	b	_fwrite
LFE11:
	.literal8
	.align	3
lC2:
	.word	1413754136
	.word	1074340347
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
	.uleb128 0x30
	.byte	0x9d
	.uleb128 0x6
	.byte	0x9e
	.uleb128 0x5
	.byte	0x4
	.set L$set$10,LCFI5-LCFI4
	.long L$set$10
	.byte	0xd
	.uleb128 0x1d
	.byte	0x4
	.set L$set$11,LCFI6-LCFI5
	.long L$set$11
	.byte	0x93
	.uleb128 0x4
	.byte	0x94
	.uleb128 0x3
	.byte	0x4
	.set L$set$12,LCFI7-LCFI6
	.long L$set$12
	.byte	0xa
	.byte	0xde
	.byte	0xdd
	.byte	0xd3
	.byte	0xd4
	.byte	0xc
	.uleb128 0x1f
	.uleb128 0
	.byte	0x4
	.set L$set$13,LCFI8-LCFI7
	.long L$set$13
	.byte	0xb
	.byte	0x4
	.set L$set$14,LCFI9-LCFI8
	.long L$set$14
	.byte	0xa
	.byte	0xde
	.byte	0xdd
	.byte	0xd3
	.byte	0xd4
	.byte	0xc
	.uleb128 0x1f
	.uleb128 0
	.byte	0x4
	.set L$set$15,LCFI10-LCFI9
	.long L$set$15
	.byte	0xb
	.align	3
LEFDE3:
LSFDE5:
	.set L$set$16,LEFDE5-LASFDE5
	.long L$set$16
LASFDE5:
	.long	LASFDE5-EH_frame1
	.quad	LFB7-.
	.set L$set$17,LFE7-LFB7
	.quad L$set$17
	.uleb128 0
	.byte	0x4
	.set L$set$18,LCFI11-LFB7
	.long L$set$18
	.byte	0xe
	.uleb128 0x50
	.byte	0x9d
	.uleb128 0xa
	.byte	0x9e
	.uleb128 0x9
	.byte	0x4
	.set L$set$19,LCFI12-LCFI11
	.long L$set$19
	.byte	0xd
	.uleb128 0x1d
	.byte	0x4
	.set L$set$20,LCFI13-LCFI12
	.long L$set$20
	.byte	0x5
	.uleb128 0x4f
	.uleb128 0x8
	.byte	0x4
	.set L$set$21,LCFI14-LCFI13
	.long L$set$21
	.byte	0xde
	.byte	0xdd
	.byte	0x6
	.uleb128 0x4f
	.byte	0xc
	.uleb128 0x1f
	.uleb128 0
	.align	3
LEFDE5:
LSFDE7:
	.set L$set$22,LEFDE7-LASFDE7
	.long L$set$22
LASFDE7:
	.long	LASFDE7-EH_frame1
	.quad	LFB8-.
	.set L$set$23,LFE8-LFB8
	.quad L$set$23
	.uleb128 0
	.byte	0x4
	.set L$set$24,LCFI15-LFB8
	.long L$set$24
	.byte	0xe
	.uleb128 0x80
	.byte	0x9d
	.uleb128 0x10
	.byte	0x9e
	.uleb128 0xf
	.byte	0x4
	.set L$set$25,LCFI16-LCFI15
	.long L$set$25
	.byte	0xd
	.uleb128 0x1d
	.byte	0x4
	.set L$set$26,LCFI17-LCFI16
	.long L$set$26
	.byte	0x97
	.uleb128 0xa
	.byte	0x98
	.uleb128 0x9
	.byte	0x4
	.set L$set$27,LCFI18-LCFI17
	.long L$set$27
	.byte	0x5
	.uleb128 0x4d
	.uleb128 0x4
	.byte	0x5
	.uleb128 0x4e
	.uleb128 0x3
	.byte	0x99
	.uleb128 0x8
	.byte	0x9a
	.uleb128 0x7
	.byte	0x4
	.set L$set$28,LCFI19-LCFI18
	.long L$set$28
	.byte	0x95
	.uleb128 0xc
	.byte	0x96
	.uleb128 0xb
	.byte	0x4
	.set L$set$29,LCFI20-LCFI19
	.long L$set$29
	.byte	0x9b
	.uleb128 0x6
	.byte	0x9c
	.uleb128 0x5
	.byte	0x4
	.set L$set$30,LCFI21-LCFI20
	.long L$set$30
	.byte	0x93
	.uleb128 0xe
	.byte	0x94
	.uleb128 0xd
	.byte	0x5
	.uleb128 0x4f
	.uleb128 0x2
	.byte	0x4
	.set L$set$31,LCFI22-LCFI21
	.long L$set$31
	.byte	0xde
	.byte	0xdd
	.byte	0xdb
	.byte	0xdc
	.byte	0xd9
	.byte	0xda
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
	.align	3
LEFDE7:
LSFDE9:
	.set L$set$32,LEFDE9-LASFDE9
	.long L$set$32
LASFDE9:
	.long	LASFDE9-EH_frame1
	.quad	LFB9-.
	.set L$set$33,LFE9-LFB9
	.quad L$set$33
	.uleb128 0
	.byte	0x4
	.set L$set$34,LCFI23-LFB9
	.long L$set$34
	.byte	0xe
	.uleb128 0x50
	.byte	0x9d
	.uleb128 0xa
	.byte	0x9e
	.uleb128 0x9
	.byte	0x4
	.set L$set$35,LCFI24-LCFI23
	.long L$set$35
	.byte	0xd
	.uleb128 0x1d
	.byte	0x4
	.set L$set$36,LCFI25-LCFI24
	.long L$set$36
	.byte	0x93
	.uleb128 0x8
	.byte	0x94
	.uleb128 0x7
	.byte	0x4
	.set L$set$37,LCFI26-LCFI25
	.long L$set$37
	.byte	0xa
	.byte	0xde
	.byte	0xdd
	.byte	0xd3
	.byte	0xd4
	.byte	0xc
	.uleb128 0x1f
	.uleb128 0
	.byte	0x4
	.set L$set$38,LCFI27-LCFI26
	.long L$set$38
	.byte	0xb
	.byte	0x4
	.set L$set$39,LCFI28-LCFI27
	.long L$set$39
	.byte	0x96
	.uleb128 0x5
	.byte	0x95
	.uleb128 0x6
	.byte	0x4
	.set L$set$40,LCFI29-LCFI28
	.long L$set$40
	.byte	0x98
	.uleb128 0x3
	.byte	0x97
	.uleb128 0x4
	.byte	0x4
	.set L$set$41,LCFI30-LCFI29
	.long L$set$41
	.byte	0x5
	.uleb128 0x4f
	.uleb128 0x1
	.byte	0x5
	.uleb128 0x4e
	.uleb128 0x2
	.byte	0x4
	.set L$set$42,LCFI31-LCFI30
	.long L$set$42
	.byte	0x6
	.uleb128 0x4f
	.byte	0x6
	.uleb128 0x4e
	.byte	0x4
	.set L$set$43,LCFI32-LCFI31
	.long L$set$43
	.byte	0xd6
	.byte	0xd5
	.byte	0x4
	.set L$set$44,LCFI33-LCFI32
	.long L$set$44
	.byte	0xd8
	.byte	0xd7
	.byte	0x4
	.set L$set$45,LCFI34-LCFI33
	.long L$set$45
	.byte	0x95
	.uleb128 0x6
	.byte	0x96
	.uleb128 0x5
	.byte	0x97
	.uleb128 0x4
	.byte	0x98
	.uleb128 0x3
	.byte	0x4
	.set L$set$46,LCFI35-LCFI34
	.long L$set$46
	.byte	0xa
	.byte	0xd6
	.byte	0xd5
	.byte	0x4
	.set L$set$47,LCFI36-LCFI35
	.long L$set$47
	.byte	0xd8
	.byte	0xd7
	.byte	0x4
	.set L$set$48,LCFI37-LCFI36
	.long L$set$48
	.byte	0xb
	.byte	0x4
	.set L$set$49,LCFI38-LCFI37
	.long L$set$49
	.byte	0xd6
	.byte	0xd5
	.byte	0x4
	.set L$set$50,LCFI39-LCFI38
	.long L$set$50
	.byte	0xd8
	.byte	0xd7
	.align	3
LEFDE9:
LSFDE11:
	.set L$set$51,LEFDE11-LASFDE11
	.long L$set$51
LASFDE11:
	.long	LASFDE11-EH_frame1
	.quad	LFB10-.
	.set L$set$52,LFE10-LFB10
	.quad L$set$52
	.uleb128 0
	.byte	0x4
	.set L$set$53,LCFI40-LFB10
	.long L$set$53
	.byte	0xe
	.uleb128 0x50
	.byte	0x9d
	.uleb128 0xa
	.byte	0x9e
	.uleb128 0x9
	.byte	0x4
	.set L$set$54,LCFI41-LCFI40
	.long L$set$54
	.byte	0xd
	.uleb128 0x1d
	.byte	0x4
	.set L$set$55,LCFI42-LCFI41
	.long L$set$55
	.byte	0x93
	.uleb128 0x8
	.byte	0x94
	.uleb128 0x7
	.byte	0x4
	.set L$set$56,LCFI43-LCFI42
	.long L$set$56
	.byte	0x95
	.uleb128 0x6
	.byte	0x96
	.uleb128 0x5
	.byte	0x97
	.uleb128 0x4
	.byte	0x98
	.uleb128 0x3
	.byte	0x4
	.set L$set$57,LCFI44-LCFI43
	.long L$set$57
	.byte	0x99
	.uleb128 0x2
	.byte	0x4
	.set L$set$58,LCFI45-LCFI44
	.long L$set$58
	.byte	0xa
	.byte	0xd9
	.byte	0x4
	.set L$set$59,LCFI46-LCFI45
	.long L$set$59
	.byte	0xde
	.byte	0xdd
	.byte	0xd7
	.byte	0xd8
	.byte	0xd5
	.byte	0xd6
	.byte	0xd3
	.byte	0xd4
	.byte	0xc
	.uleb128 0x1f
	.uleb128 0
	.byte	0x4
	.set L$set$60,LCFI47-LCFI46
	.long L$set$60
	.byte	0xb
	.byte	0x4
	.set L$set$61,LCFI48-LCFI47
	.long L$set$61
	.byte	0xd9
	.byte	0x4
	.set L$set$62,LCFI49-LCFI48
	.long L$set$62
	.byte	0xa
	.byte	0xde
	.byte	0xdd
	.byte	0xd7
	.byte	0xd8
	.byte	0xd5
	.byte	0xd6
	.byte	0xd3
	.byte	0xd4
	.byte	0xc
	.uleb128 0x1f
	.uleb128 0
	.byte	0x4
	.set L$set$63,LCFI50-LCFI49
	.long L$set$63
	.byte	0xb
	.byte	0x4
	.set L$set$64,LCFI51-LCFI50
	.long L$set$64
	.byte	0xde
	.byte	0xdd
	.byte	0xd7
	.byte	0xd8
	.byte	0xd5
	.byte	0xd6
	.byte	0xd3
	.byte	0xd4
	.byte	0xc
	.uleb128 0x1f
	.uleb128 0
	.align	3
LEFDE11:
LSFDE13:
	.set L$set$65,LEFDE13-LASFDE13
	.long L$set$65
LASFDE13:
	.long	LASFDE13-EH_frame1
	.quad	LFB11-.
	.set L$set$66,LFE11-LFB11
	.quad L$set$66
	.uleb128 0
	.byte	0x4
	.set L$set$67,LCFI52-LFB11
	.long L$set$67
	.byte	0xe
	.uleb128 0x30
	.byte	0x9d
	.uleb128 0x6
	.byte	0x9e
	.uleb128 0x5
	.byte	0x4
	.set L$set$68,LCFI53-LCFI52
	.long L$set$68
	.byte	0xd
	.uleb128 0x1d
	.byte	0x4
	.set L$set$69,LCFI54-LCFI53
	.long L$set$69
	.byte	0x93
	.uleb128 0x4
	.byte	0x94
	.uleb128 0x3
	.byte	0x4
	.set L$set$70,LCFI55-LCFI54
	.long L$set$70
	.byte	0x95
	.uleb128 0x2
	.byte	0x96
	.uleb128 0x1
	.byte	0x4
	.set L$set$71,LCFI56-LCFI55
	.long L$set$71
	.byte	0xa
	.byte	0xde
	.byte	0xdd
	.byte	0xd5
	.byte	0xd6
	.byte	0xd3
	.byte	0xd4
	.byte	0xc
	.uleb128 0x1f
	.uleb128 0
	.byte	0x4
	.set L$set$72,LCFI57-LCFI56
	.long L$set$72
	.byte	0xb
	.byte	0x4
	.set L$set$73,LCFI58-LCFI57
	.long L$set$73
	.byte	0xde
	.byte	0xdd
	.byte	0xd5
	.byte	0xd6
	.byte	0xd3
	.byte	0xd4
	.byte	0xc
	.uleb128 0x1f
	.uleb128 0
	.align	3
LEFDE13:
	.ident	"GCC: (Homebrew GCC 15.2.0_1) 15.2.0"
	.subsections_via_symbols
