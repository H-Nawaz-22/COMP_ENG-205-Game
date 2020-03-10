; #########################################################################
;
;   blit.asm - Assembly file for CompEng205 Assignment 3
;
;	Haroon Nawaz
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include stars.inc
include lines.inc
include trig.inc
include blit.inc


.DATA

	;; If you need to, you can place global variables here

.CODE

DrawPixel PROC USES eax ebx ecx x:DWORD, y:DWORD, color:DWORD
	cmp x, 640
	jae return				; Exits if out of x bounds
	cmp y, 480
	jae return				; Exits if out of y bounds

	mov eax, y				; y
	mov ebx, 640			; dwWidth
	mul ebx					; y*dwWidth
	mov ebx, ScreenBitsPtr	; ScreenBitsPtr
	add eax, ebx			; y*dwWidth + ScreenBitsPtr
	add eax, x				; x + y*dWidth + ScreenBitsPtr

	mov ecx, color
	mov BYTE PTR [eax], cl	; Moves smallest byte of DWORD color into the byte array at index corresponding to the pixel position
return:
	ret 			; Don't delete this line!!!
DrawPixel ENDP

BasicBlit PROC USES eax ebx ecx edx esi edi ptrBitmap:PTR EECS205BITMAP , xcenter:DWORD, ycenter:DWORD
	LOCAL transparent_color:BYTE, init_x:DWORD, final_x:DWORD, final_y:DWORD

	mov esi, ptrBitmap ; Pointer to beginning of EECS205BITMAP

	mov ecx, (EECS205BITMAP PTR [esi]).dwWidth
	mov edx, (EECS205BITMAP PTR [esi]).dwHeight
	sar ecx, 1		; divide by 2
	sar edx, 1		; divide by 2

	; Calculates upper limit (end) of x and y coordinates of blit
	mov eax, xcenter
	mov ebx, ycenter
	mov final_x, eax ; copies xn
	add final_x, ecx ; xn
	mov final_y, ebx ; copies xn
	add final_y, edx ; yn

	; Calculates lower limit (beginning) of x and y coordinates of blit
	sub eax, ecx	; x0
	mov edi, eax	; copies x0
	sub ebx, edx	; y0

	; Stores transparent color
	mov dl, (EECS205BITMAP PTR [esi]).bTransparent
	mov transparent_color, dl

	mov esi, (EECS205BITMAP PTR[esi]).lpBytes ; Beginning of array

	jmp eval_1

	loop_1:
		mov cl, [esi]				; Gets color at current pixel
		cmp cl, transparent_color	; If color matches transparent color
		jz skip_draw				; Don't draw the pixel
		INVOKE DrawPixel, eax, ebx, ecx	; Draws the pixel
	skip_draw:
		inc eax	; x
		inc esi	; pointer
	eval_2:
		cmp eax, 640
		jge return	; x out of bounds
		cmp eax, final_x
		jge next ; Skip to next row if end of this row has been reached
		jmp loop_1 ; Otherwise, continue drawing this row
	next:
		inc ebx ; y
	eval_1:
		mov eax, edi	; reset x to beginning of row
		cmp ebx, 480
		jge return	; y out of bounds
		cmp ebx, final_y
		jl loop_1    ; If then next row is the last row, return. Otherwise, continue on that row.
	return:
		ret
BasicBlit ENDP

;; Returns the product of two fixed point operands
FixMul PROTO STDCALL a:DWORD, b:DWORD
FixMul PROC USES edx a:DWORD, b:DWORD
	mov eax, a
	imul b
	shl edx, 16
	shr eax, 16
	add eax, edx
	ret
FixMul ENDP

RotateBlit PROC USES eax ebx ecx edx esi edi lpBmp:PTR EECS205BITMAP, xcenter:DWORD, ycenter:DWORD, angle:DWORD
	LOCAL sin_a:FXPT, cos_a:FXPT, shift_X:DWORD, shift_Y:DWORD, dstWidth:DWORD, dstHeight:DWORD, srcX:DWORD, srcY:DWORD
	LOCAL bwidth:DWORD, bheight:DWORD, transparent:BYTE, sumX:DWORD, sumY:DWORD, dstX:DWORD, dstY:DWORD

	mov esi, lpBmp

	mov eax, (EECS205BITMAP PTR [esi]).dwWidth
	mov ebx, (EECS205BITMAP PTR [esi]).dwHeight
	mov bwidth, eax			; bwidth
	mov bheight, ebx		; bheight

	add ebx, eax
	mov dstWidth, ebx		; dstWidth
	mov dstHeight, ebx		; dstHeight

	; sin_a
	INVOKE FixedSin, angle
	mov sin_a, eax
	; cos_a
	INVOKE FixedCos, angle
	mov cos_a, eax

	; shift_X
	mov ebx, bwidth
	shr ebx, 1
	INVOKE FixMul, ebx, cos_a
	mov shift_X, eax
	mov ebx, bheight
  shr ebx, 1
	INVOKE FixMul, ebx, sin_a
	sub shift_X, eax

	; shift_Y
	mov ebx, bheight
	shr ebx, 1
	INVOKE FixMul, ebx, cos_a
	mov shift_Y, eax
	mov ebx, bwidth
  shr ebx, 1
	INVOKE FixMul, ebx, sin_a

	add shift_Y, eax

	mov dl, (EECS205BITMAP PTR [esi]).bTransparent
	mov transparent, dl		; transparent

	;; Loops Begin

	mov eax, dstHeight
	neg eax
	mov dstY, eax

	jmp eval_1

	loop_2:
		; Calculates srcX
		mov eax, dstX
		mul cos_a
		sar eax, 16
		mov ebx, eax
		mov eax, dstY
		mul sin_a
		sar eax, 16
		add eax, ebx
		mov srcX, eax

		; Calculates srcY
		mov eax, dstY
		mul cos_a
		sar eax, 16
		mov ebx, eax
		mov eax, dstX
		mul sin_a
		sar eax, 16
		sub ebx, eax
		mov srcY, ebx

		cmp srcX, 0		; srcX >= 0 check
		jl skip

		mov eax, bwidth
		cmp srcX, eax	; srcX < dwWidth check
		jge skip

		cmp srcY, 0		; srcY >= 0 check
		jl skip

		mov eax, bheight
		cmp srcY, eax	; srcY < dwHeight check
		jge skip

  		mov eax, xcenter
  		add eax, dstX
  		sub eax, shift_X
  		mov sumX, eax
  		cmp sumX, 0		; sumX >- 0 check
  		jl skip

  		cmp eax, 639	; x in bounds check
  		jge skip

  		mov eax, ycenter
  		add eax, dstY
  		sub eax, shift_Y
  		mov sumY, eax
  		cmp sumY, 0		; sumY >- 0 check
  		jl skip

  		cmp eax, 479 ; y in bounds check
  		jge skip

		mov eax, srcY
		mov ebx, bwidth
		mul ebx
		add eax, srcX
		mov ebx, (EECS205BITMAP PTR [esi]).lpBytes
		add eax, ebx						; eax <- address of color byte in bitmap
		mov cl, BYTE PTR [eax]
		cmp cl, transparent					; If color matches transparent color
		je skip								; Don't draw the pixel
		INVOKE DrawPixel, sumX, sumY, cl	; Draws pixel

	skip:
		inc dstX			; increment column
		mov ebx, dstX
		cmp ebx, dstWidth	; dstX < dstWidth check
		jl loop_2
		inc dstY			; increment row
		jmp eval_1			; Continue to next row
	loop_1:
		mov eax, dstWidth
		neg eax
		mov dstX, eax
		jmp loop_2
	eval_1:
		mov ebx, dstY
		cmp ebx, dstHeight	; dstY < dstWidth check
		jl loop_1

	ret
RotateBlit ENDP

END
