; #########################################################################
;	Bismillahi rahmanir rahim
;   game.asm - Assembly file for CompEng205 Assignment 4/5
;	
;	INSTRUCTIONS - Control the fighter's position with the mouse, and use WASD to control the fighter's angle. 
;	Colliding the fighter with the asteroid should trigger a sound effect.
;	Sound credit: reliccastle.com/members/1
;
; #########################################################################


;;
;NOTES:
;INSHALLAH
;(1) PRIMITIVE PROJECTILE SYSTEM WORKING
;CLEAN UP CODE, MAKE NEW .ASM AND ORGANIZE FUNCTIONS, MAKE NEW FUNCTIONS
;ADD 'ACTIVE' VARIABLE FOR PROJECTILES TO INDICATE IF THEY SHOULD BE DRAWN OR NOT, FIX PROJECTILES RESETTING AFTER 100
;FIX PAUSE AND CONDITION FOR ROTATE/SHOOTING SO ONLY WASD (*)
;ADD TIMER TO LIMIT SPEED OF PROJECTILES
;IMPLEMENT COLLISION FOR PROJECTILES (*)
;HEALTH SYSTEM FOR AGENTS
;SPAWNING SYSTEM FOR ENEMIES
;BEHAVIOR FOR ENEMIES
;IMPLEMENT SOUND FOR SELECT, PROJECTILES, AND DAMAGE (2)
;SCORING (3)

;INSHALLAH EXTRA STUFF
;UPGRADE SPEED, HEATLH, POWER, RANGE, ETC
;PICKUPS
;TRICK PICKUPS (NUKE)
;USE PICKUPS TO BUY UPGRADES
;SCREEN WIPE EXPLOSION POWERUP
;SCREEN SHAKING
;FINAL BOSS
;PICK STARTER FIGHTER WITH DIFFERENT STARTING STATS


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

pauseFlag BYTE 0

intersectFlag DWORD 0

timeLow DWORD 0
timeHigh DWORD 0

lastKey DWORD 0


projectileArraySize DWORD 0
projectileArray PROJECTILE 100 DUP(<, , , , , , OFFSET nuke_001>)

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

DrawRotatedSprite PROC USES eax lpBmp:PTR EECS205BITMAP, xcenter:DWORD, ycenter:DWORD, angle:DWORD
	INVOKE FixMul, xcenter, 1
	mov xcenter, eax
	INVOKE FixMul, ycenter, 1
	mov ycenter, eax
	;shr xcenter, 16
	;shr ycenter, 16
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

RotateFighter PROC USES ebx KeyValue:DWORD
	mov eax, fighter0.direction
	cmp KeyValue, 057h ; W
	jnz continue1
	mov eax, 0
	jmp return
continue1:
	cmp ebx, 044h ; D
	cmp KeyValue, 044h ; D
	jnz continue2
	mov eax, PI_HALF
	jmp return
continue2:
	cmp ebx, 053h ; S
	cmp KeyValue, 053h ; S
	jnz continue3
	mov eax, PI
	jmp return
continue3:
	cmp ebx, 041h ; A
	cmp KeyValue, 041h ; A
	jnz return
	mov eax, PI
	add eax, PI_HALF
return:
	mov fighter0.direction, eax
	ret
RotateFighter ENDP

;Returns the inverse magnitude of a 2-D vector with initial point (x0,y0) and final point (x1,y1). The return value is FXPT.
InverseSqrt PROC USES ebx edx x0:DWORD, y0:DWORD, x1:DWORD, y1:DWORD
	LOCAL sumSquares:DWORD, sqrt:DWORD, scaling:DWORD, answer:DWORD, threshold:DWORD
	mov threshold, 50
	mov answer, 0
	mov ebx, x1
	sub ebx, x0
	mov eax, ebx
	imul ebx
	;INVOKE FixMul, eax, ebx
	mov sumSquares, edx
	mov ebx, y1
	sub ebx, y0
	mov eax, ebx
	imul ebx
	;INVOKE FixMul, eax, ebx
	add sumSquares, edx
	;shr sumSquares, 16
	mov ebx, threshold	
	cmp sumSquares, ebx
	jl return
	.XMM
	cvtsi2ss xmm0, sumSquares ;Moves (x^2 + y^2) to xmm0
	rsqrtss xmm1, xmm0		  ;Inverse square root
	movss sqrt, xmm1		  ;Moves square root value to memory
	mov scaling, 16			  ;Scaling for shift left of 16
	fild scaling			  
	fld sqrt
	fscale					  ;Multiplication by 2^16, forces floating point to be integer
	fistp answer				  ;Stores result
	fistp scaling
return:
	mov eax, answer
	ret
InverseSqrt ENDP

SpawnProjectile PROC USES eax ebx ecx esi edx xcenter:DWORD, ycenter:DWORD, angle:DWORD
	LOCAL direction1:DWORD
	mov eax, projectileArraySize
	mov ecx, 28
	mul ecx
	mov esi, OFFSET projectileArray
	add esi, eax
	mov ebx, angle
	cmp ebx, 0
	jnz continue1
	mov direction1, 1
	mov (PROJECTILE PTR[esi]).orientation, 1
	jmp continue4
continue1:
	cmp ebx, PI_HALF
	jnz continue2
	mov direction1, 0
	mov (PROJECTILE PTR[esi]).orientation, 0
	jmp continue4
continue2:
	cmp ebx, PI
	jnz continue3
	mov direction1, 0
	mov (PROJECTILE PTR[esi]).orientation, 1
	jmp continue4
continue3:
	mov edx, PI
	add edx, PI_HALF
	cmp ebx, edx
	jnz continue4
	mov direction1, 1
	mov (PROJECTILE PTR[esi]).orientation, 0
continue4:
	mov eax, xcenter
	mov (PROJECTILE PTR[esi]).xpos, eax
	mov eax, ycenter
	mov (PROJECTILE PTR[esi]).ypos, eax
	mov eax, 01fffffh
	mov (PROJECTILE PTR[esi]).vel, eax
	mov eax, direction1
	mov (PROJECTILE PTR[esi]).direction, eax
	inc projectileArraySize	
	cmp projectileArraySize, 100
	jl return
	mov projectileArraySize, 0
return:
	ret
SpawnProjectile ENDP

IterateProjectiles PROC USES eax ebx ecx edx esi
	mov esi, OFFSET projectileArray
	mov eax, projectileArraySize
	mov ecx, 28
	mul ecx
	add eax, esi
	jmp eval
body:
	mov ecx, (PROJECTILE PTR[esi]).vel
	mov ebx, (PROJECTILE PTR[esi]).direction
	mov edx, (PROJECTILE PTR[esi]).orientation
	cmp ebx, 0
	jz dontNegate
	neg ecx
dontNegate:
	cmp edx, 0
	jnz continue1
	add (PROJECTILE PTR[esi]).xpos, ecx
	jmp continue2
continue1:
	add (PROJECTILE PTR[esi]).ypos, ecx
continue2:
	add esi, 28
eval:
	cmp esi, eax
	jl body
	ret
IterateProjectiles ENDP

DrawProjectiles PROC USES eax ebx ecx edx esi
	mov esi, OFFSET projectileArray
	mov eax, projectileArraySize
	mov ecx, 28
	mul ecx
	add eax, esi
	jmp eval
body:
	INVOKE DrawRotatedSprite, (PROJECTILE PTR[esi]).bitmapPtr, (PROJECTILE PTR[esi]).xpos, (PROJECTILE PTR[esi]).ypos, 0
	add esi, 28
eval:
	cmp esi, eax
	jl body
	ret
DrawProjectiles ENDP

; Code to be run repeatedly, multiple times a second, to update game.
GamePlay PROC USES esi ebx ecx edx eax
	LOCAL mouseX:DWORD, mouseY:DWORD, inverseSqrt:DWORD, fighterXTrue:DWORD, fighterYTrue:DWORD, speedMul:DWORD
	mov eax, KeyPress
	cmp eax, 050h
	jnz dontTogglePause
	cmp eax, lastKey
	jz dontTogglePause
	not pauseFlag
dontTogglePause:
	mov lastKey, eax
	cmp pauseFlag, 0
	jnz return


	mov speedMul, 0800ffh
	mov fighter0.bitmapPtr, offset fighter_0_still

	;For debugging, calculates integer pixel position for fighter
	mov eax, fighter0.xpos
	shr eax, 16
	mov fighterXTrue, eax
	mov eax, fighter0.xpos
	shr eax, 16
	mov fighterYTrue, eax

	;For debugging, force mouse location to constant value
	;mov MouseStatus.horiz, 500
	;mov MouseStatus.vert, 100
	

	;Sets mouseX and mouseY; also sets ebx to delta x and ecx to delta y
	mov ebx, MouseStatus.horiz
	shl ebx, 16
	mov mouseX, ebx
	sub ebx, fighter0.xpos
	mov ecx, MouseStatus.vert
	shl ecx, 16
	mov mouseY, ecx
	sub ecx, fighter0.ypos

	INVOKE InverseSqrt, fighter0.xpos, fighter0.ypos, mouseX, mouseY	;Gets inverse square root of (delta x)^2 + (delta y)^2
	mov inverseSqrt, eax

	INVOKE FixMul, inverseSqrt, ebx ;Normalises delta x
	INVOKE FixMul, eax, speedMul	;Speed multiplier
	add fighter0.xpos, eax			;Updates position
	cmp eax, 0
	jz fighterStill1
	mov fighter0.bitmapPtr, offset fighter_0_moving
fighterStill1:
	INVOKE FixMul, inverseSqrt, ecx ; Normalises delta y
	INVOKE FixMul, eax, speedMul	; Speed multiplier
	add fighter0.ypos, eax			; Updates position
	cmp eax, 0
	jz fighterStill2
	mov fighter0.bitmapPtr, offset fighter_0_moving
fighterStill2:

	; Update fighter's direction to WASD input

	mov ebx, KeyPress
	cmp ebx, 0
	jz SkipRotate
	INVOKE RotateFighter, ebx
	mov fighter0.direction, eax
	rdtsc
	;cmp edx, timeHigh
	;jz SkipRotate
	INVOKE SpawnProjectile, fighter0.xpos, fighter0.ypos, fighter0.direction
SkipRotate:
	rdtsc
	mov timeHigh, edx
	add asteroid1.direction, 10000 ; Increment asteroid's angle
	INVOKE IterateProjectiles
	;Update screen
	INVOKE ClearScreen
	INVOKE DrawStarField
	INVOKE DrawRotatedSprite, fighter0.bitmapPtr, fighter0.xpos, fighter0.ypos, fighter0.direction	; fighter
	INVOKE DrawRotatedSprite, asteroid1.bitmapPtr, asteroid1.xpos, asteroid1.ypos, asteroid1.direction	;Asteroid
	INVOKE CheckIntersect, fighter0.xpos, fighter0.ypos, fighter0.bitmapPtr, asteroid1.xpos, asteroid1.ypos, asteroid1.bitmapPtr ; Check for fighter-Asteroid intersection
	INVOKE DrawProjectiles
	;Checks for intersection
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
