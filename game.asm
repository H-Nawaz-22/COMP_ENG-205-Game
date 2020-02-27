; #########################################################################
;
;   game.asm - Assembly file for CompEng205 Assignment 4/5
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include stars.inc
include lines.inc
include trig.inc
include blit.inc
include game.inc


;; Has keycodes
include keys.inc

	
.DATA

;; If you need to, you can place global variables here


.CODE

ClearScreen PROC USES esi edi eax
	cld
	mov esi, ScreenBitsPtr
	mov ecx, 640*480
	mov eax, 0ffffh
	
	rep STOSD
	ret

CheckIntersect PROTO STDCALL oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP, twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP

CheckIntersect PROC STDCALL oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP, twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP

	ret 		;; Don't delete this line!!!
CheckIntersect ENDP

GameInit PROC USES ebx
	INVOKE DrawStarField
	mov ebx, fighter0.bitmapPtr
	mov ecx, OFFSET fighter0
	inc fighter0.xpos
	INVOKE BasicBlit, ebx, fighter0.xpos, fighter0.ypos
	inc fighter0.xpos
	inc fighter0.xpos
	inc fighter0.xpos
	inc fighter0.xpos
	inc fighter0.xpos
	inc fighter0.xpos
	inc fighter0.xpos
	inc fighter0.xpos
	inc fighter0.xpos
	inc fighter0.xpos
	inc fighter0.xpos
	inc fighter0.xpos
	inc fighter0.xpos
	INVOKE BasicBlit, ebx, fighter0.xpos, fighter0.ypos

	ret         ;; Do not delete this line!!!
GameInit ENDP


GamePlay PROC
	ret         ;; Do not delete this line!!!
GamePlay ENDP

END
