	.arch armv8.5-a
	.build_version macos,  26, 0
	.text
	.align	2
	.p2align 5,,15
	.globl _block_fft_plan_free
_block_fft_plan_free:
LFB7:
	stp	x29, x30, [sp, -32]!
LCFI0:
	mov	x29, sp
LCFI1:
	str	x19, [sp, 16]
LCFI2:
	mov	x19, x0
	ldr	x0, [x0, 16]
	bl	_free
	ldr	x0, [x19, 24]
	bl	_free
	ldr	x0, [x19, 32]
	bl	_free
	ldr	x0, [x19, 40]
	bl	_free
	movi	v31.4s, 0
	stp	q31, q31, [x19, 16]
	ldr	x19, [sp, 16]
	ldp	x29, x30, [sp], 32
LCFI3:
	ret
LFE7:
	.cstring
	.align	3
lC0:
	.ascii "block_fft: radix must be 4\12\0"
	.align	3
lC1:
	.ascii "block_fft: require n=4^k\12\0"
	.text
	.align	2
	.p2align 5,,15
	.globl _block_fft_plan_init
_block_fft_plan_init:
LFB6:
	stp	x29, x30, [sp, -176]!
LCFI4:
	mov	x29, sp
LCFI5:
	cmp	w1, 1
	stp	x19, x20, [sp, 16]
LCFI6:
	mov	x20, x0
	mov	w19, 0
	stp	x21, x22, [sp, 32]
LCFI7:
	mov	w21, w3
	stp	x23, x24, [sp, 48]
LCFI8:
	mov	w23, w1
	stp	w1, w2, [x0]
	mov	w1, 1
	str	w3, [x0, 8]
	ble	L5
	.p2align 5,,15
L6:
	mul	w1, w1, w21
	add	w19, w19, 1
	cmp	w23, w1
	bgt	L6
L5:
	movi	v31.4s, 0
	cmp	w23, w1
	bne	L7
	str	w19, [x20, 12]
	stp	q31, q31, [x20, 16]
	cmp	w21, 4
	bne	L10
	ubfiz	x0, x23, 2, 32
	stp	x25, x26, [x29, 64]
LCFI9:
	bl	_malloc
	mov	w2, 43691
	sub	w1, w23, #1
	movk	w2, 0xaaaa, lsl 16
	mov	x24, x0
	umull	x22, w1, w2
	str	x24, [x20, 16]
	lsr	x22, x22, 33
	lsl	x0, x22, 4
	bl	_malloc
	mov	x25, x0
	lsl	x0, x22, 4
	str	x25, [x20, 24]
	bl	_malloc
	mov	x26, x0
	lsl	x0, x22, 4
	str	x26, [x20, 32]
	bl	_malloc
	cmp	x24, 0
	mov	x2, x0
	ccmp	x25, 0, 4, ne
	cset	w1, eq
	cmp	x26, 0
	str	x2, [x20, 40]
	ccmp	x0, 0, 4, ne
	cset	w0, eq
	orr	w1, w1, w0
	str	x2, [x29, 168]
	cbnz	w1, L35
	stp	x27, x28, [x29, 80]
LCFI10:
	stp	d9, d10, [x29, 96]
LCFI11:
	stp	d11, d12, [x29, 112]
LCFI12:
	stp	d13, d14, [x29, 128]
LCFI13:
	str	d15, [x29, 144]
LCFI14:
	cbz	w19, L24
	mov	x5, 0
	mov	w2, 0
	.p2align 5,,15
L15:
	mov	w1, 0
	mov	w3, 0
	.p2align 5,,15
L13:
	and	w4, w2, 3
	add	w1, w1, 1
	add	w3, w4, w3, lsl 2
	asr	w2, w2, 2
	cmp	w1, w19
	bne	L13
	str	w3, [x24, x5, lsl 2]
	add	x5, x5, 1
	cmp	w23, w5
	ble	L14
	mov	w2, w5
	b	L15
L10:
LCFI15:
	adrp	x3, ___stderrp@GOTPAGE
	ldr	x3, [x3, ___stderrp@GOTPAGEOFF]
	adrp	x0, lC0@PAGE
	mov	x2, 27
	add	x0, x0, lC0@PAGEOFF;
	mov	x1, 1
	ldr	x3, [x3]
	bl	_fwrite
	mov	w0, 1
L4:
	ldp	x19, x20, [sp, 16]
	ldp	x21, x22, [sp, 32]
	ldp	x23, x24, [sp, 48]
	ldp	x29, x30, [sp], 176
LCFI16:
	ret
L24:
LCFI17:
	mov	x1, 0
L12:
	add	x0, x1, 1
	str	wzr, [x24, x1, lsl 2]
	add	x1, x1, 2
	cmp	w23, w0
	ble	L14
	str	wzr, [x24, x0, lsl 2]
	cmp	w23, w1
	bgt	L12
	.p2align 5,,15
L14:
	mov	w24, 0
	cmp	w23, 3
	ble	L21
	adrp	x0, lC2@PAGE
	fmov	d12, 3.0e+0
	ldr	d11, [x0, #lC2@PAGEOFF]
L16:
	asr	w22, w21, 2
	cmp	w21, 0
	ble	L17
L36:
	adrp	x0, lC3@PAGE
	sbfiz	x19, x24, 4, 32
	ldr	q31, [x0, #lC3@PAGEOFF]
	ldr	x0, [x29, 168]
	str	q31, [x25, x19]
	str	q31, [x26, x19]
	str	q31, [x0, x19]
	cmp	w21, 4
	beq	L18
	scvtf	d13, w21
	add	x27, x25, x19
	add	x28, x26, x19
	mov	w20, 1
	add	x19, x0, x19
	fdiv	d13, d11, d13
	.p2align 5,,15
L19:
	scvtf	d15, w20
	add	w20, w20, 1
	movi	d0, #0
	fmul	d15, d13, d15
	fmov	d1, d15
	bl	_cexp
	fmov	d10, d0
	movi	d0, #0
	fmov	d9, d1
	fadd	d1, d15, d15
	bl	_cexp
	fmov	d31, d0
	movi	d0, #0
	fmov	d14, d1
	fmul	d1, d15, d12
	fmov	d15, d31
	bl	_cexp
	stp	d10, d9, [x27, 16]!
	stp	d15, d14, [x28, 16]!
	stp	d0, d1, [x19, 16]!
	cmp	w22, w20
	bgt	L19
L18:
	lsl	w21, w21, 2
	cmp	w23, w21
	blt	L21
	add	w24, w24, w22
	asr	w22, w21, 2
	cmp	w21, 0
	bgt	L36
L17:
	add	w24, w24, w22
	lsl	w21, w21, 2
	b	L16
	.p2align 2,,3
L21:
	ldr	d15, [x29, 144]
LCFI18:
	mov	w0, 0
	ldp	x25, x26, [x29, 64]
LCFI19:
	ldp	x27, x28, [x29, 80]
LCFI20:
	ldp	x19, x20, [sp, 16]
	ldp	x21, x22, [sp, 32]
	ldp	x23, x24, [sp, 48]
	ldp	d9, d10, [x29, 96]
LCFI21:
	ldp	d11, d12, [x29, 112]
LCFI22:
	ldp	d13, d14, [x29, 128]
LCFI23:
	ldp	x29, x30, [sp], 176
LCFI24:
	ret
L7:
LCFI25:
	mov	w0, -1
	stp	q31, q31, [x20, 16]
	str	w0, [x20, 12]
	cmp	w21, 4
	bne	L10
	adrp	x3, ___stderrp@GOTPAGE
	ldr	x3, [x3, ___stderrp@GOTPAGEOFF]
	adrp	x0, lC1@PAGE
	mov	x2, 25
	add	x0, x0, lC1@PAGEOFF;
	mov	x1, 1
	ldr	x3, [x3]
	bl	_fwrite
	mov	w0, 2
	b	L4
L35:
LCFI26:
	mov	x0, x20
	bl	_block_fft_plan_free
	mov	w0, 3
	ldp	x25, x26, [x29, 64]
LCFI27:
	b	L4
LFE6:
	.align	2
	.p2align 5,,15
	.globl _block_fft_forward
_block_fft_forward:
LFB9:
	ldr	w14, [x0]
	cmp	w14, 0
	ble	L81
	stp	x29, x30, [sp, -224]!
LCFI28:
	mov	x29, sp
	mov	w6, 0
	sxtw	x8, w14
	stp	x19, x20, [sp, 16]
	stp	x21, x22, [sp, 32]
	stp	x23, x24, [sp, 48]
LCFI29:
	mov	x23, x1
	mov	x1, 0
	stp	x25, x26, [sp, 64]
	stp	x27, x28, [sp, 80]
	stp	d12, d13, [sp, 96]
	stp	d14, d15, [sp, 112]
LCFI30:
	ldr	w5, [x0, 4]
	ldr	x9, [x0, 16]
	mov	w7, w5
	sxtw	x10, w5
	b	L40
L44:
	add	x1, x1, 1
	add	w6, w6, w5
	cmp	x1, x8
	beq	L41
L40:
	ldr	w2, [x9, x1, lsl 2]
	cmp	w2, w1
	ble	L44
	cmp	w5, 0
	ble	L43
L42:
	add	x4, x10, w6, sxtw
	add	x4, x23, x4, lsl 4
	add	x3, x23, w6, sxtw 4
	mul	w2, w5, w2
	add	x2, x23, w2, sxtw 4
L45:
	ldr	q31, [x3]
	ldp	x12, x13, [x2]
	stp	x12, x13, [x3], 16
	str	q31, [x2], 16
	cmp	x3, x4
	bne	L45
	add	x1, x1, 1
	cmp	x1, x8
	beq	L41
	ldr	w2, [x9, x1, lsl 2]
	add	w6, w6, w5
	cmp	w2, w1
	bgt	L42
	add	x1, x1, 1
	add	w6, w6, w5
	cmp	x1, x8
	bne	L40
L41:
	cmp	w14, 3
	ble	L37
	mov	w27, w7
	mov	w1, 0
	str	w14, [sp, 180]
	sbfiz	x24, x7, 4, 32
	sub	w22, w7, #1
	lsr	w28, w7, 1
	and	w30, w7, -2
	and	x25, x27, 4294967294
	mov	w11, 4
L58:
	asr	w26, w11, 2
	cmp	w11, 0
	ble	L47
L85:
	cmp	w27, 0
	ble	L48
	ldp	x3, x4, [x0, 24]
	mul	w2, w27, w26
	sbfiz	x21, x1, 4, 32
	mul	w15, w27, w11
	mov	x17, 0
	mov	w14, 0
	stp	w11, w1, [sp, 208]
	ubfiz	x12, x2, 4, 32
	mov	x13, x12
	str	x0, [sp, 216]
	stp	x3, x4, [sp, 184]
	lsl	w3, w2, 1
	add	w2, w3, w2
	sbfiz	x19, x3, 4, 32
	sbfiz	x12, x2, 4, 32
	ldr	x4, [x0, 40]
	str	x4, [sp, 200]
	.p2align 5,,15
L49:
	ldr	x0, [sp, 184]
	mov	w16, 0
	add	x20, x23, x17
	add	x7, x17, 32
	add	x6, x13, 32
	str	w14, [sp, 132]
	add	x5, x19, 32
	add	x4, x12, 32
	stp	x21, x17, [sp, 136]
	mov	x2, x12
	mov	x1, x19
	mov	x3, x17
	add	x10, x0, x21
	ldr	x0, [sp, 192]
	stp	x13, x19, [sp, 152]
	str	x12, [sp, 168]
	add	x9, x0, x21
	ldr	x0, [sp, 200]
	str	w15, [sp, 176]
	add	x8, x0, x21
	mov	x0, x13
	.p2align 5,,15
L53:
	ldp	d20, d19, [x10]
	ldp	d18, d17, [x9]
	ldp	d16, d7, [x8]
	cmp	w22, 1
	bls	L50
	cmp	x3, x5
	ccmp	x7, x1, 4, lt
	cset	w12, le
	cmp	x3, x6
	ccmp	x0, x7, 0, lt
	cset	w11, ge
	and	w11, w12, w11
	cmp	x3, x4
	ccmp	x7, x2, 4, lt
	cset	w12, le
	and	w11, w12, w11
	cmp	x0, x5
	ccmp	x6, x1, 4, lt
	cset	w12, le
	and	w11, w12, w11
	cmp	x0, x4
	ccmp	x6, x2, 4, lt
	cset	w12, le
	and	w11, w12, w11
	cmp	x1, x4
	ccmp	x5, x2, 4, lt
	cset	w12, le
	tst	w12, w11
	beq	L50
	mov	w11, 32
	dup	v6.2d, v20.d[0]
	dup	v5.2d, v18.d[0]
	dup	v4.2d, v16.d[0]
	add	x14, x23, x0
	add	x13, x23, x1
	umaddl	x15, w28, w11, x20
	add	x12, x23, x2
	mov	x11, x20
	.p2align 5,,15
L51:
	ld2	{v21.2d - v22.2d}, [x13]
	ld2	{v25.2d - v26.2d}, [x14]
	ld2	{v29.2d - v30.2d}, [x12]
	ld2	{v27.2d - v28.2d}, [x11]
	fmul	v15.2d, v22.2d, v17.d[0]
	fmul	v2.2d, v5.2d, v22.2d
	fmul	v24.2d, v26.2d, v19.d[0]
	fmul	v3.2d, v6.2d, v26.2d
	fmul	v31.2d, v4.2d, v30.2d
	fmul	v30.2d, v30.2d, v7.d[0]
	mov	v14.16b, v15.16b
	fneg	v15.2d, v15.2d
	fmla	v2.2d, v21.2d, v17.d[0]
	mov	v26.16b, v24.16b
	fneg	v24.2d, v24.2d
	fmls	v14.2d, v5.2d, v21.2d
	fmla	v15.2d, v5.2d, v21.2d
	mov	v21.16b, v30.16b
	fneg	v30.2d, v30.2d
	fmla	v3.2d, v25.2d, v19.d[0]
	fmla	v31.2d, v29.2d, v7.d[0]
	fmls	v26.2d, v6.2d, v25.2d
	fmla	v24.2d, v6.2d, v25.2d
	fmla	v30.2d, v4.2d, v29.2d
	fmls	v21.2d, v4.2d, v29.2d
	fadd	v12.2d, v15.2d, v26.2d
	fadd	v13.2d, v3.2d, v14.2d
	fsub	v25.2d, v27.2d, v31.2d
	fadd	v14.2d, v31.2d, v14.2d
	fadd	v0.2d, v3.2d, v2.2d
	fadd	v15.2d, v24.2d, v15.2d
	fadd	v26.2d, v30.2d, v26.2d
	fadd	v22.2d, v3.2d, v31.2d
	fadd	v30.2d, v30.2d, v27.2d
	fadd	v31.2d, v31.2d, v28.2d
	fadd	v1.2d, v2.2d, v28.2d
	fsub	v2.2d, v28.2d, v2.2d
	fadd	v24.2d, v24.2d, v21.2d
	fadd	v21.2d, v21.2d, v27.2d
	fsub	v23.2d, v27.2d, v3.2d
	fadd	v30.2d, v30.2d, v15.2d
	fadd	v31.2d, v31.2d, v0.2d
	fadd	v25.2d, v25.2d, v13.2d
	fadd	v26.2d, v26.2d, v2.2d
	fadd	v21.2d, v21.2d, v12.2d
	fsub	v22.2d, v1.2d, v22.2d
	fadd	v23.2d, v14.2d, v23.2d
	fadd	v24.2d, v24.2d, v2.2d
	st2	{v30.2d - v31.2d}, [x11], 32
	st2	{v25.2d - v26.2d}, [x14], 32
	st2	{v21.2d - v22.2d}, [x13], 32
	st2	{v23.2d - v24.2d}, [x12], 32
	cmp	x15, x11
	bne	L51
	add	x11, x20, x24
	cmp	w30, w27
	beq	L57
	add	x14, x0, x25, lsl 4
	add	x13, x1, x25, lsl 4
	add	x20, x23, x14
	add	x12, x2, x25, lsl 4
	add	x19, x23, x13
	ldr	d27, [x23, x14]
	add	x15, x3, x25, lsl 4
	add	x17, x23, x12
	ldr	d3, [x20, 8]
	add	x21, x23, x15
	ldr	d15, [x19, 8]
	ldr	d12, [x23, x13]
	fmul	d13, d19, d27
	fmul	d1, d19, d3
	ldr	d31, [x17, 8]
	fmul	d29, d17, d15
	ldr	d30, [x23, x12]
	fmadd	d13, d20, d3, d13
	ldr	d4, [x23, x15]
	fmul	d2, d17, d12
	fnmsub	d0, d20, d27, d1
	fmsub	d1, d20, d27, d1
	fmul	d25, d7, d31
	ldr	d28, [x21, 8]
	fnmsub	d14, d18, d12, d29
	fmsub	d29, d18, d12, d29
	fmadd	d2, d18, d15, d2
	fmul	d21, d7, d30
	fnmsub	d26, d16, d30, d25
	fmsub	d25, d16, d30, d25
	fmadd	d21, d16, d31, d21
	fadd	d22, d14, d0
	fadd	d24, d29, d13
	fadd	d23, d2, d13
	fadd	d3, d2, d28
	fadd	d22, d22, d4
	fadd	d24, d24, d4
	fadd	d29, d29, d21
	fadd	d23, d23, d28
	fsub	d3, d3, d13
	fadd	d22, d22, d26
	fadd	d26, d1, d26
	fadd	d1, d1, d14
	fsub	d24, d24, d21
	fadd	d29, d29, d4
	fadd	d23, d23, d21
	fsub	d3, d3, d21
	fadd	d26, d26, d28
	str	d22, [x23, x15]
	fadd	d1, d1, d4
	fsub	d29, d29, d13
	str	d23, [x21, 8]
	str	d24, [x23, x14]
	fsub	d26, d26, d2
	fadd	d1, d25, d1
	fadd	d25, d25, d0
	str	d26, [x20, 8]
	fadd	d25, d25, d28
	str	d1, [x23, x13]
	str	d3, [x19, 8]
	str	d29, [x23, x12]
	fsub	d25, d25, d2
	str	d25, [x17, 8]
L57:
	add	w16, w16, 1
	add	x10, x10, 16
	add	x9, x9, 16
	add	x8, x8, 16
	mov	x20, x11
	add	x3, x3, x24
	add	x0, x0, x24
	add	x1, x1, x24
	add	x2, x2, x24
	add	x7, x7, x24
	add	x6, x6, x24
	add	x5, x5, x24
	add	x4, x4, x24
	cmp	w26, w16
	bgt	L53
	ldr	w0, [sp, 208]
	ldp	x13, x19, [sp, 152]
	ldp	x21, x17, [sp, 136]
	ldr	w14, [sp, 132]
	ldr	x12, [sp, 168]
	ldr	w15, [sp, 176]
	add	x17, x17, w15, uxtw 4
	add	x13, x13, w15, uxtw 4
	add	w14, w14, w0
	add	x19, x19, w15, uxtw 4
	add	x12, x12, w15, uxtw 4
	ldr	w0, [sp, 180]
	cmp	w0, w14
	bgt	L49
	ldr	x0, [sp, 216]
	ldp	w11, w1, [sp, 208]
L48:
	lsl	w11, w11, 2
	ldr	w2, [sp, 180]
	cmp	w2, w11
	blt	L37
	add	w1, w1, w26
	asr	w26, w11, 2
	cmp	w11, 0
	bgt	L85
L47:
	add	w1, w1, w26
	lsl	w11, w11, 2
	b	L58
	.p2align 2,,3
L50:
	add	x14, x23, x0
	add	x13, x23, x1
	add	x12, x23, x2
	add	x11, x20, x24
	.p2align 5,,15
L56:
	ldp	d22, d23, [x13]
	add	x13, x13, 16
	ldp	d14, d2, [x14]
	ldp	d3, d29, [x12]
	fmul	d24, d17, d23
	fmul	d1, d17, d22
	ldp	d12, d15, [x20]
	add	x20, x20, 16
	fmul	d30, d19, d2
	fmul	d21, d19, d14
	fmul	d25, d7, d29
	fnmsub	d26, d18, d22, d24
	fmadd	d1, d18, d23, d1
	fmul	d23, d7, d3
	fmsub	d24, d18, d22, d24
	fnmsub	d31, d20, d14, d30
	fmadd	d21, d20, d2, d21
	fnmsub	d2, d16, d3, d25
	fmadd	d23, d16, d29, d23
	fmsub	d30, d20, d14, d30
	fmsub	d25, d16, d3, d25
	fadd	d29, d26, d31
	fadd	d29, d29, d12
	fadd	d29, d29, d2
	fadd	d2, d30, d2
	fadd	d30, d30, d26
	str	d29, [x20, -16]
	fadd	d29, d1, d21
	fadd	d2, d2, d15
	fadd	d30, d30, d12
	fadd	d29, d29, d15
	fsub	d2, d2, d1
	fadd	d30, d25, d30
	fadd	d25, d25, d31
	fadd	d29, d29, d23
	fadd	d25, d25, d15
	str	d29, [x20, -8]
	fadd	d29, d24, d21
	fadd	d24, d24, d23
	fsub	d25, d25, d1
	fadd	d29, d29, d12
	fadd	d24, d24, d12
	fsub	d29, d29, d23
	fsub	d24, d24, d21
	stp	d29, d2, [x14], 16
	str	d30, [x13, -16]
	fadd	d30, d1, d15
	fsub	d30, d30, d21
	fsub	d30, d30, d23
	str	d30, [x13, -8]
	stp	d24, d25, [x12], 16
	cmp	x20, x11
	bne	L56
	b	L57
L37:
	ldp	d12, d13, [sp, 96]
	ldp	x19, x20, [sp, 16]
	ldp	x21, x22, [sp, 32]
	ldp	x23, x24, [sp, 48]
	ldp	x25, x26, [sp, 64]
	ldp	x27, x28, [sp, 80]
	ldp	d14, d15, [sp, 112]
	ldp	x29, x30, [sp], 224
LCFI31:
	ret
L86:
LCFI32:
	ldr	w2, [x9, x1, lsl 2]
	cmp	w2, w1
	ble	L44
L43:
	add	x2, x1, 1
	add	w6, w6, w5, lsl 1
	add	x1, x1, 2
	cmp	x2, x8
	beq	L41
	cmp	x1, x8
	bne	L86
	b	L41
L81:
LCFI33:
	ret
LFE9:
	.literal8
	.align	3
lC2:
	.word	1413754136
	.word	-1072094725
	.literal16
	.align	4
lC3:
	.word	0
	.word	1072693248
	.word	0
	.word	0
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
	.quad	LFB7-.
	.set L$set$2,LFE7-LFB7
	.quad L$set$2
	.uleb128 0
	.byte	0x4
	.set L$set$3,LCFI0-LFB7
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
	.quad	LFB6-.
	.set L$set$8,LFE6-LFB6
	.quad L$set$8
	.uleb128 0
	.byte	0x4
	.set L$set$9,LCFI4-LFB6
	.long L$set$9
	.byte	0xe
	.uleb128 0xb0
	.byte	0x9d
	.uleb128 0x16
	.byte	0x9e
	.uleb128 0x15
	.byte	0x4
	.set L$set$10,LCFI5-LCFI4
	.long L$set$10
	.byte	0xd
	.uleb128 0x1d
	.byte	0x4
	.set L$set$11,LCFI6-LCFI5
	.long L$set$11
	.byte	0x93
	.uleb128 0x14
	.byte	0x94
	.uleb128 0x13
	.byte	0x4
	.set L$set$12,LCFI7-LCFI6
	.long L$set$12
	.byte	0x95
	.uleb128 0x12
	.byte	0x96
	.uleb128 0x11
	.byte	0x4
	.set L$set$13,LCFI8-LCFI7
	.long L$set$13
	.byte	0x97
	.uleb128 0x10
	.byte	0x98
	.uleb128 0xf
	.byte	0x4
	.set L$set$14,LCFI9-LCFI8
	.long L$set$14
	.byte	0x9a
	.uleb128 0xd
	.byte	0x99
	.uleb128 0xe
	.byte	0x4
	.set L$set$15,LCFI10-LCFI9
	.long L$set$15
	.byte	0x9c
	.uleb128 0xb
	.byte	0x9b
	.uleb128 0xc
	.byte	0x4
	.set L$set$16,LCFI11-LCFI10
	.long L$set$16
	.byte	0x5
	.uleb128 0x4a
	.uleb128 0x9
	.byte	0x5
	.uleb128 0x49
	.uleb128 0xa
	.byte	0x4
	.set L$set$17,LCFI12-LCFI11
	.long L$set$17
	.byte	0x5
	.uleb128 0x4c
	.uleb128 0x7
	.byte	0x5
	.uleb128 0x4b
	.uleb128 0x8
	.byte	0x4
	.set L$set$18,LCFI13-LCFI12
	.long L$set$18
	.byte	0x5
	.uleb128 0x4e
	.uleb128 0x5
	.byte	0x5
	.uleb128 0x4d
	.uleb128 0x6
	.byte	0x4
	.set L$set$19,LCFI14-LCFI13
	.long L$set$19
	.byte	0x5
	.uleb128 0x4f
	.uleb128 0x4
	.byte	0x4
	.set L$set$20,LCFI15-LCFI14
	.long L$set$20
	.byte	0xd9
	.byte	0xda
	.byte	0xdb
	.byte	0xdc
	.byte	0x6
	.uleb128 0x49
	.byte	0x6
	.uleb128 0x4a
	.byte	0x6
	.uleb128 0x4b
	.byte	0x6
	.uleb128 0x4c
	.byte	0x6
	.uleb128 0x4d
	.byte	0x6
	.uleb128 0x4e
	.byte	0x6
	.uleb128 0x4f
	.byte	0x4
	.set L$set$21,LCFI16-LCFI15
	.long L$set$21
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
	.set L$set$22,LCFI17-LCFI16
	.long L$set$22
	.byte	0xc
	.uleb128 0x1d
	.uleb128 0xb0
	.byte	0x93
	.uleb128 0x14
	.byte	0x94
	.uleb128 0x13
	.byte	0x95
	.uleb128 0x12
	.byte	0x96
	.uleb128 0x11
	.byte	0x97
	.uleb128 0x10
	.byte	0x98
	.uleb128 0xf
	.byte	0x99
	.uleb128 0xe
	.byte	0x9a
	.uleb128 0xd
	.byte	0x9b
	.uleb128 0xc
	.byte	0x9c
	.uleb128 0xb
	.byte	0x9d
	.uleb128 0x16
	.byte	0x9e
	.uleb128 0x15
	.byte	0x5
	.uleb128 0x49
	.uleb128 0xa
	.byte	0x5
	.uleb128 0x4a
	.uleb128 0x9
	.byte	0x5
	.uleb128 0x4b
	.uleb128 0x8
	.byte	0x5
	.uleb128 0x4c
	.uleb128 0x7
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
	.set L$set$23,LCFI18-LCFI17
	.long L$set$23
	.byte	0x6
	.uleb128 0x4f
	.byte	0x4
	.set L$set$24,LCFI19-LCFI18
	.long L$set$24
	.byte	0xda
	.byte	0xd9
	.byte	0x4
	.set L$set$25,LCFI20-LCFI19
	.long L$set$25
	.byte	0xdc
	.byte	0xdb
	.byte	0x4
	.set L$set$26,LCFI21-LCFI20
	.long L$set$26
	.byte	0x6
	.uleb128 0x4a
	.byte	0x6
	.uleb128 0x49
	.byte	0x4
	.set L$set$27,LCFI22-LCFI21
	.long L$set$27
	.byte	0x6
	.uleb128 0x4c
	.byte	0x6
	.uleb128 0x4b
	.byte	0x4
	.set L$set$28,LCFI23-LCFI22
	.long L$set$28
	.byte	0x6
	.uleb128 0x4e
	.byte	0x6
	.uleb128 0x4d
	.byte	0x4
	.set L$set$29,LCFI24-LCFI23
	.long L$set$29
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
	.set L$set$30,LCFI25-LCFI24
	.long L$set$30
	.byte	0xc
	.uleb128 0x1d
	.uleb128 0xb0
	.byte	0x93
	.uleb128 0x14
	.byte	0x94
	.uleb128 0x13
	.byte	0x95
	.uleb128 0x12
	.byte	0x96
	.uleb128 0x11
	.byte	0x97
	.uleb128 0x10
	.byte	0x98
	.uleb128 0xf
	.byte	0x9d
	.uleb128 0x16
	.byte	0x9e
	.uleb128 0x15
	.byte	0x4
	.set L$set$31,LCFI26-LCFI25
	.long L$set$31
	.byte	0x99
	.uleb128 0xe
	.byte	0x9a
	.uleb128 0xd
	.byte	0x4
	.set L$set$32,LCFI27-LCFI26
	.long L$set$32
	.byte	0xda
	.byte	0xd9
	.align	3
LEFDE3:
LSFDE5:
	.set L$set$33,LEFDE5-LASFDE5
	.long L$set$33
LASFDE5:
	.long	LASFDE5-EH_frame1
	.quad	LFB9-.
	.set L$set$34,LFE9-LFB9
	.quad L$set$34
	.uleb128 0
	.byte	0x4
	.set L$set$35,LCFI28-LFB9
	.long L$set$35
	.byte	0xe
	.uleb128 0xe0
	.byte	0x9d
	.uleb128 0x1c
	.byte	0x9e
	.uleb128 0x1b
	.byte	0x4
	.set L$set$36,LCFI29-LCFI28
	.long L$set$36
	.byte	0x93
	.uleb128 0x1a
	.byte	0x94
	.uleb128 0x19
	.byte	0x95
	.uleb128 0x18
	.byte	0x96
	.uleb128 0x17
	.byte	0x97
	.uleb128 0x16
	.byte	0x98
	.uleb128 0x15
	.byte	0x4
	.set L$set$37,LCFI30-LCFI29
	.long L$set$37
	.byte	0x99
	.uleb128 0x14
	.byte	0x9a
	.uleb128 0x13
	.byte	0x9b
	.uleb128 0x12
	.byte	0x9c
	.uleb128 0x11
	.byte	0x5
	.uleb128 0x4c
	.uleb128 0x10
	.byte	0x5
	.uleb128 0x4d
	.uleb128 0xf
	.byte	0x5
	.uleb128 0x4e
	.uleb128 0xe
	.byte	0x5
	.uleb128 0x4f
	.uleb128 0xd
	.byte	0x4
	.set L$set$38,LCFI31-LCFI30
	.long L$set$38
	.byte	0xa
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
	.uleb128 0x4e
	.byte	0x6
	.uleb128 0x4f
	.byte	0x6
	.uleb128 0x4c
	.byte	0x6
	.uleb128 0x4d
	.byte	0xe
	.uleb128 0
	.byte	0x4
	.set L$set$39,LCFI32-LCFI31
	.long L$set$39
	.byte	0xb
	.byte	0x4
	.set L$set$40,LCFI33-LCFI32
	.long L$set$40
	.byte	0xe
	.uleb128 0
	.byte	0xd3
	.byte	0xd4
	.byte	0xd5
	.byte	0xd6
	.byte	0xd7
	.byte	0xd8
	.byte	0xd9
	.byte	0xda
	.byte	0xdb
	.byte	0xdc
	.byte	0xdd
	.byte	0xde
	.byte	0x6
	.uleb128 0x4c
	.byte	0x6
	.uleb128 0x4d
	.byte	0x6
	.uleb128 0x4e
	.byte	0x6
	.uleb128 0x4f
	.align	3
LEFDE5:
	.ident	"GCC: (Homebrew GCC 15.2.0_1) 15.2.0"
	.subsections_via_symbols
