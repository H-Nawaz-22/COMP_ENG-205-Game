; #########################################################################
;
;   trig.asm - Assembly file for CompEng205 Assignment 3
;
;	Haroon Nawaz
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include trig.inc

.DATA

;;  These are some useful constants (fixed point values that correspond to important angles)
PI_HALF = 102943           	;;  PI / 2
PI =  205887	                ;;  PI 
TWO_PI	= 411774                ;;  2 * PI 
PI_INC_RECIP =  5340353        	;;  Use reciprocal to find the table entry for a given angle
	                        ;;              (It is easier to use than divison would be)


	;; If you need to, you can place global variables here
	
.CODE


FixedSin PROC USES ebx ecx edx angle:FXPT
; Returns (to eax) the sine of a fixed-point value
	LOCAL sign_flag:BYTE ; Flag to indicate whether the result should be positive or negative
mov sign_flag, 1		 ;Assumes sin(x) is positive	
mov eax, angle
begin:
	cmp eax, PI
	jge angle_minus_pi	;If the angle is greater than or equal to PI, subtract PI from the angle
	cmp eax, 0
	jl angle_plus_pi	;If the angle is less than or equal to 0, add PI to the angle
	cmp eax, PI_HALF 
	jg pi_minus_angle   ;If the angle is greater than PI/2, changer the angle to be (angle  - PI)
	jmp lookup			;Otherwise (angle is between 0 and PI/2), lookup value for sin(angle)
angle_minus_pi:
	sub eax, PI
	neg sign_flag		;Negates sign_flag because of a shift by PI
	jmp begin
angle_plus_pi:
	add eax, PI
	neg sign_flag		;Negates sign_flag because of a shift by PI
	jmp begin
pi_minus_angle:
	mov ebx, PI
	sub ebx, eax
	mov eax, ebx
lookup:
	mov ebx, PI_INC_RECIP
	imul ebx							; Moves integer value of index into edx
	movzx eax, WORD PTR[SINTAB + edx*2]	; Moves WORD of data at SINTAB[edx] with scaling factor of 2; zx to clear upper half of eax
	cmp sign_flag, 0					; If sin(angle) needs to be negative
	jl invert_result					; Negate the result
	jmp return
invert_result:
	neg eax	
return:
	ret
FixedSin ENDP 
	
FixedCos PROC angle:FXPT
; Returns (to eax) the cosine of a fixed-point value
	mov eax, angle
	add eax, PI_HALF	; cos(x) = sin(x + PI/2)
	invoke FixedSin, eax
	ret
FixedCos ENDP	
END
