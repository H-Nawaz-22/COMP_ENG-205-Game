; #########################################################################
;
;   game.asm - Assembly file for CompEng205 Assignment 4/5
;	
;	INSTRUCTIONS - Control the fighter's position with the mouse, and use WASD to control the fighter's angle. 
;	Colliding the fighter with the asteroid should trigger a sound effect.
;	Sound credit: reliccastle.com/members/1
;
; #########################################################################

.586
.MODEL FLAT,STDCALL
.STACK 4096
option casemap:none  ; case sensitive

;include C:\masm32\include\windows.inc
;include C:\masm32\include\winmm.inc
;includelib C:\masm32\lib\winmm.lib
include stars.inc
include lines.inc
include trig.inc
include blit.inc
include game.inc

;; Has keycodes
include keys.inc

.DATA

;;  These are fixed point values that correspond to important angles
PI_HALF DWORD 102943           	;;  PI / 2
PI DWORD 205887	                ;;  PI 
TWO_PI DWORD  411774                ;;  2 * PI 

intersectFlag DWORD 0
timeLow DWORD ?
timeHigh DWORD ?

SndPath BYTE "select.wav",0
.CODE

;; Makes every pixel on the screen black
ClearScreen PROC USES esi edi ebx
	mov esi, ScreenBitsPtr
	mov ecx, 640*480
	mov bl, 00h
	jmp cond
loop1:
	mov BYTE PTR [esi], bl
	inc esi
	dec ecx
cond:
	cmp ecx, 0
	jnz loop1
	ret
ClearScreen ENDP

DrawRotatedSprite PROC lpBmp:PTR EECS205BITMAP, xcenter:DWORD, ycenter:DWORD, angle:DWORD 
	shr xcenter, 16
	shr ycenter, 16
	INVOKE RotateBlit, lpBmp, xcenter, ycenter, angle
	ret
DrawRotatedSprite ENDP

;; Returns a non-zero value if the sprites specified by oneBitmap and twoBitmap overlap, and returns zero otherwise. The X and Y variables
;; specify the center of the respective sprite.
CheckIntersect PROTO STDCALL oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP, twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP
CheckIntersect PROC STDCALL USES ebx ecx esi oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP, twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP
LOCAL one_Left:DWORD, one_Right:DWORD, one_Top:DWORD, one_Bottom:DWORD, two_Left:DWORD, two_Right:DWORD, two_Top:DWORD, two_Bottom:DWORD

; --- Sprite 1 ---
mov esi, oneBitmap 
mov ebx, (EECS205BITMAP PTR [esi]).dwWidth	
shr ebx, 1
mov ecx, (EECS205BITMAP PTR [esi]).dwHeight 
shr ecx, 1
;Calculate bounds of sprite 1
mov eax, oneX
mov one_Left, eax
mov one_Right, eax
mov eax, oneY
mov one_Top, eax
mov one_Bottom, eax

sub one_Left, ebx
add one_Right, ebx
sub one_Top, ecx
add one_Bottom, ecx

; --- Sprite 2 ---
mov esi, twoBitmap
mov ebx, (EECS205BITMAP PTR [esi]).dwWidth
shr ebx, 1
mov ecx, (EECS205BITMAP PTR [esi]).dwHeight
shr ecx, 1
;Calculate bounds of sprite 2
mov eax, twoX
mov two_Left, eax
mov two_Right, eax
mov eax, twoY
mov two_Top, eax
mov two_Bottom, eax

sub two_Left, ebx
add two_Right, ebx
sub two_Top, ecx
add two_Bottom, ecx

; Check if the sprites overlap horizontally
mov eax, 0
mov ebx, one_Left
cmp ebx, two_Right
jge return
mov ebx, two_Left
cmp ebx, one_Right
jge return

; Check if the sprites overlap vertically
mov ebx, one_Top
cmp ebx, two_Bottom
jge return
mov ebx, two_Top
cmp ebx, one_Bottom
jge return

; Non-zero value to return
mov eax, 0ffffh
return:
	ret 
CheckIntersect ENDP

; Code to be run once when the game first starts up.
GameInit PROC USES ebx
	INVOKE DrawStarField
	rdtsc  ; Gets the time
	mov timeLow, eax
	mov timeHigh, edx
	ret
GameInit ENDP

<<<<<<< HEAD
; Code to be run repeatedly, multiple times a second, to update game.
GamePlay PROC USES esi ebx ecx edx eax

continue5:
	shl MouseStatus.horiz, 16
	shl MouseStatus.horiz, 16
	; Update fighter's position to mouse location
	mov ebx, MouseStatus.horiz
	mov ecx, MouseStatus.vert
	mov fighter0.xpos, ebx
	mov fighter0.ypos, ecx
	; Update fighter's direction to WASD input
	mov ebx, KeyPress
	cmp ebx, 0
	jz SkipRotate
	cmp ebx, 057h ; W
=======
RotateFighter PROC KeyValue:DWORD
	cmp KeyValue, 057h ; W
>>>>>>> Assignment-5-Attempt-1
	jnz continue1
	mov eax, 0
continue1:
	cmp ebx, 044h ; D
	cmp KeyValue, 044h ; D
	jnz continue2
	mov eax, PI_HALF
continue2:
	cmp ebx, 053h ; S
	cmp KeyValue, 053h ; S
	jnz continue3
	mov eax, PI
continue3:
	cmp ebx, 041h ; A
	cmp KeyValue, 041h ; A
	jnz continue4
	mov eax, PI
	add eax, PI_HALF
continue4:
	mov fighter0.direction, eax
	ret
RotateFighter ENDP

; Code to be run repeatedly, multiple times a second, to update game.
GamePlay PROC USES esi ebx ecx edx eax
	shl MouseStatus.horiz, 16
	shl MouseStatus.vert, 16
	; Update fighter's position to mouse location
	mov ebx, MouseStatus.horiz
	mov ecx, MouseStatus.vert
	mov fighter0.xpos, ebx
	mov fighter0.ypos, ecx
	; Update fighter's direction to WASD input
	mov ebx, KeyPress
	cmp ebx, 0
	jz SkipRotate
	INVOKE RotateFighter, ebx
	mov fighter0.direction, eax

SkipRotate:
	add asteroid1.direction, 10000 ; Increment asteroid's angle
	;Update screen
	INVOKE ClearScreen
	INVOKE DrawStarField
	INVOKE DrawRotatedSprite, fighter0.bitmapPtr, fighter0.xpos, fighter0.ypos, fighter0.direction	; fighter
	INVOKE DrawRotatedSprite, asteroid1.bitmapPtr, asteroid1.xpos, asteroid1.ypos, asteroid1.direction	;Asteroid
	INVOKE CheckIntersect, fighter0.xpos, fighter0.ypos, fighter0.bitmapPtr, asteroid1.xpos, asteroid1.ypos, asteroid1.bitmapPtr ; Check for fighter-Asteroid intersection
	cmp eax, 0
	jz reset_flag ; Exit if no intersection
	cmp intersectFlag, 0
	jnz return	  ; Exit if already intersecting on last call
	;INVOKE PlaySound, offset SndPath, 0, SND_FILENAME OR SND_ASYNC	; Plays select.wav
	mov intersectFlag, 1
	jmp return
reset_flag:
	mov intersectFlag, 0
return:
	ret
GamePlay ENDP

END
