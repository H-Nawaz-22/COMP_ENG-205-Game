; #########################################################################
;	
;   game.asm - Assembly file for CompEng205 Assignment 4/5
;	
;	INSTRUCTIONS - Control the fighter's position with the mouse, and use WASD to control the fighter's angle. 
;	Colliding the fighter with the asteroid should trigger a sound effect.
;	Sound credit: reliccastle.com/members/1
;
; #########################################################################


;;
;NOTES:
;(1) PRIMITIVE PROJECTILE SYSTEM WORKING
;CLEAN UP CODE, MAKE NEW .ASM AND ORGANIZE FUNCTIONS, MAKE NEW FUNCTIONS


;ADD 'ACTIVE' VARIABLE FOR PROJECTILES TO INDICATE IF THEY SHOULD BE DRAWN OR NOT, FIX PROJECTILES RESETTING AFTER 100

;ADD TIMER TO LIMIT SPEED OF PROJECTILES
;IMPLEMENT SOUND FOR PROJECTILES (2)

;SPAWNING SYSTEM FOR ENEMIES
;POWERUPS (3)

;EXTRA STUFF
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

include C:\masm32\include\windows.inc
include C:\masm32\include\winmm.inc
includelib C:\masm32\lib\winmm.lib
include \masm32\include\user32.inc
includelib \masm32\lib\user32.lib
include stars.inc
include lines.inc
include trig.inc
include blit.inc
include game.inc
include projectiles.inc

;; Has keycodes
include keys.inc

.DATA

;;  These are fixed point values that correspond to important angles

pauseFlag BYTE 0
intersectFlag DWORD 0

timeLow DWORD 0
timeHigh DWORD 0

stage DWORD 0
statusFlag DWORD 0
score DWORD 0

gameOverMessage BYTE "Game Over! Score: %d", 0
outStr BYTE 256 DUP(0)

speedMul DWORD 0400ffh
enemyspeedMul DWORD 0400ffh
lastKey DWORD 0

projectileArrayLength DWORD 0
projectileArray PROJECTILE 100 DUP(<20971520, 15728640, 100000 , , 1,1 , OFFSET nuke_001>)

SndPathSelect BYTE "select.wav",0
SndPathDamage BYTE "damage.wav",0

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

GameOver PROC
	INVOKE ClearScreen
	push score
	push offset gameOverMessage
	push offset outStr
	call wsprintf
	add esp, 12
	invoke DrawStr, offset outStr, 230, 200, 0ffh
GameOver ENDP

RotateFighter PROC USES ebx KeyValue:DWORD
	mov eax, 1
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
	ret
RotateFighter ENDP

DefeatEnemy PROC USES ebx ecx esi xpos:DWORD, ypos:DWORD
	inc stage
	inc score
	INVOKE FixMul, enemyspeedMul, 010f00h
	mov enemyspeedMul, eax
	rdtsc
	and eax, 01b
	cmp eax, 1
	jl noPowerup
	mov ebx, xpos
	mov ecx, ypos
	lea esi, speedPowerup
	mov [esi], ebx
	add esi, 4
	mov [esi], ecx
noPowerup:
	ret
DefeatEnemy ENDP

InflictDamage PROC
	dec fighter0.health
	INVOKE PlaySound ,offset SndPathDamage, 0, SND_FILENAME OR SND_ASYNC	; Plays damage.wav
	mov eax, 0
	cmp fighter0.health, 0
	jnz fighterAlive
	mov statusFlag, 1
fighterAlive:
	ret
InflictDamage ENDP

InverseSqrt PROTO x0:DWORD, x1:DWORD, y0:DWORD, y1:DWORD

MoveEnemies PROC USES ebx ecx
	LOCAL inverseSqrt:DWORD
	mov ebx, fighter0.xpos
	sub ebx, enemy0.xpos
	mov ecx, fighter0.ypos
	sub ecx, enemy0.ypos
	INVOKE InverseSqrt, fighter0.xpos, fighter0.ypos, enemy0.xpos, enemy0.ypos
	mov inverseSqrt, eax
	INVOKE FixMul, inverseSqrt, ebx ;Normalises delta x
	INVOKE FixMul, eax, enemyspeedMul	;Speed multiplier
	add enemy0.xpos, eax			;Updates position
enemy0Still1:
	INVOKE FixMul, inverseSqrt, ecx ; Normalises delta y
	INVOKE FixMul, eax, enemyspeedMul	; Speed multiplier
	add enemy0.ypos, eax			; Updates position
enemy0Still2:
	INVOKE ProjectileIntersect, OFFSET enemy0
	sub enemy0.health, eax
	cmp enemy0.health, 0
	jge enemy0Alive
	INVOKE DefeatEnemy, enemy0.xpos, enemy0.ypos
	mov enemy0.xpos, -10000000
	mov enemy0.ypos, -10000000
	mov enemy0.health, 5
enemy0Alive:	
	INVOKE CheckIntersect, fighter0.xpos, fighter0.ypos, fighter0.bitmapPtr, enemy0.xpos, enemy0.ypos, enemy0.bitmapPtr
	cmp eax, 0
	jz noDamage1
	INVOKE InflictDamage
	mov enemy0.xpos, -10000000
	mov enemy0.ypos, -10000000
	mov enemy0.health, 5
noDamage1:
	cmp stage, 2
	jle return

	mov ebx, fighter0.xpos
	sub ebx, enemy1.xpos
	mov ecx, fighter0.ypos
	sub ecx, enemy1.ypos
	INVOKE InverseSqrt, fighter0.xpos, fighter0.ypos, enemy1.xpos, enemy1.ypos
	mov inverseSqrt, eax
	INVOKE FixMul, inverseSqrt, ebx ;Normalises delta x
	INVOKE FixMul, eax, enemyspeedMul	;Speed multiplier
	add enemy1.xpos, eax			;Updates position
enemy1Still1:
	INVOKE FixMul, inverseSqrt, ecx ; Normalises delta y
	INVOKE FixMul, eax, enemyspeedMul	; Speed multiplier
	add enemy1.ypos, eax			; Updates position
enemy1Still2:
	INVOKE ProjectileIntersect, OFFSET enemy1
	sub enemy1.health, eax
	cmp enemy1.health, 0
	jge enemy1Alive
	INVOKE DefeatEnemy, enemy1.xpos, enemy1.ypos
	mov enemy1.xpos, 49457280
	mov enemy1.ypos, -10000000
	mov enemy1.health, 5
enemy1Alive:	
	INVOKE CheckIntersect, fighter0.xpos, fighter0.ypos, fighter0.bitmapPtr, enemy1.xpos, enemy1.ypos, enemy1.bitmapPtr
	cmp eax, 0
	jz noDamage2
	INVOKE InflictDamage
	mov enemy1.xpos, 49457280
	mov enemy1.ypos, -10000000
	mov enemy1.health, 5
noDamage2:
	cmp stage, 3
	jle return

	mov ebx, fighter0.xpos
	sub ebx, enemy2.xpos
	mov ecx, fighter0.ypos
	sub ecx, enemy2.ypos
	INVOKE InverseSqrt, fighter0.xpos, fighter0.ypos, enemy2.xpos, enemy2.ypos
	mov inverseSqrt, eax
	INVOKE FixMul, inverseSqrt, ebx ;Normalises delta x
	INVOKE FixMul, eax, enemyspeedMul	;Speed multiplier
	add enemy2.xpos, eax			;Updates position
enemy2Still1:
	INVOKE FixMul, inverseSqrt, ecx ; Normalises delta y
	INVOKE FixMul, eax, enemyspeedMul	; Speed multiplier
	add enemy2.ypos, eax			; Updates position
enemy2Still2:
	INVOKE ProjectileIntersect, OFFSET enemy2
	sub enemy2.health, eax
	cmp enemy2.health, 0
	jge enemy2Alive
	INVOKE DefeatEnemy, enemy2.xpos, enemy2.ypos
	mov enemy2.xpos, -10000000 
	mov enemy2.ypos, 49457280
	mov enemy2.health, 5
enemy2Alive:	
	INVOKE CheckIntersect, fighter0.xpos, fighter0.ypos, fighter0.bitmapPtr, enemy2.xpos, enemy2.ypos, enemy2.bitmapPtr
	cmp eax, 0
	jz noDamage3
	INVOKE InflictDamage
	mov enemy2.xpos, -10000000 
	mov enemy2.ypos, 49457280
	mov enemy2.health, 5
noDamage3:
	cmp stage, 5
	jle return

	mov ebx, fighter0.xpos
	sub ebx, enemy3.xpos
	mov ecx, fighter0.ypos
	sub ecx, enemy3.ypos
	INVOKE InverseSqrt, fighter0.xpos, fighter0.ypos, enemy3.xpos, enemy3.ypos
	mov inverseSqrt, eax
	INVOKE FixMul, inverseSqrt, ebx ;Normalises delta x
	INVOKE FixMul, eax, enemyspeedMul	;Speed multiplier
	add enemy3.xpos, eax			;Updates position
enemy3Still1:
	INVOKE FixMul, inverseSqrt, ecx ; Normalises delta y
	INVOKE FixMul, eax, enemyspeedMul	; Speed multiplier
	add enemy3.ypos, eax			; Updates position
enemy3Still2:
	INVOKE ProjectileIntersect, OFFSET enemy3
	sub enemy3.health, eax
	cmp enemy3.health, 0
	jge enemy3Alive
	INVOKE DefeatEnemy, enemy3.xpos, enemy3.ypos
	mov enemy3.xpos, 49457280 
	mov enemy3.ypos, 49457280
	mov enemy3.health, 5
enemy3Alive:	
	INVOKE CheckIntersect, fighter0.xpos, fighter0.ypos, fighter0.bitmapPtr, enemy3.xpos, enemy3.ypos, enemy3.bitmapPtr
	cmp eax, 0
	jz noDamage4
	INVOKE InflictDamage
	mov enemy3.xpos, 49457280
	mov enemy3.ypos, 49457280
	mov enemy3.health, 5
noDamage4:
return:
	ret
MoveEnemies ENDP

DrawRotatedSprite PROC USES ebx ecx edx lpBmp:PTR EECS205BITMAP, xcenter:DWORD, ycenter:DWORD, angle:DWORD
	mov ebx, eax ;stores eax
	INVOKE FixMul, xcenter, 1
	mov xcenter, eax
	INVOKE FixMul, ycenter, 1
	mov ycenter, eax
	INVOKE RotateBlit, lpBmp, xcenter, ycenter, angle
	mov eax, ebx
	ret
DrawRotatedSprite ENDP

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
 
; Code to be run once when the game first starts up.
GameInit PROC USES ebx
	INVOKE DrawStarField
	rdtsc  ; Gets the time
	mov timeLow, eax
	mov timeHigh, edx
	ret
GameInit ENDP

; Code to be run repeatedly, multiple times a second, to update game.
GamePlay PROC USES esi ebx ecx edx eax
	LOCAL mouseX:DWORD, mouseY:DWORD, inverseSqrt:DWORD
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

	cmp statusFlag, 0
	jz continueGame
	INVOKE GameOver
	jmp return
continueGame:

	mov fighter0.bitmapPtr, offset fighter_0_still

	;For debugging, force mouse location to constant value
	;mov MouseStatus.horiz, 500
	;mov MouseStatus.vert, 100
	;mov KeyPress, 044h

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
	mov ebx, KeyPress
	INVOKE RotateFighter, ebx
	cmp eax, 1			;If RotateFighter returns 1, WASD was not pressed
	jz SkipRotate
	mov fighter0.direction, eax 	; Update fighter's direction to WASD input
	rdtsc
	;cmp edx, timeHigh
	;jz SkipRotate
	INVOKE SpawnProjectile, fighter0.xpos, fighter0.ypos, fighter0.direction

SkipRotate:
	INVOKE MoveEnemies
	
	rdtsc
	mov timeHigh, edx
	add asteroid1.direction, 10000 ; Increment asteroid's angle
	INVOKE IterateProjectiles



	;Update screen
	INVOKE ClearScreen
	INVOKE DrawStarField
	INVOKE DrawRotatedSprite, fighter0.bitmapPtr, fighter0.xpos, fighter0.ypos, fighter0.direction	; fighter
	INVOKE DrawRotatedSprite, speedPowerup.bitmapPtr, speedPowerup.xpos, speedPowerup.ypos, 0
	INVOKE DrawRotatedSprite, enemy0.bitmapPtr, enemy0.xpos, enemy0.ypos, enemy0.direction	; enemy
	INVOKE DrawRotatedSprite, enemy1.bitmapPtr, enemy1.xpos, enemy1.ypos, enemy1.direction	; enemy
	INVOKE DrawRotatedSprite, enemy2.bitmapPtr, enemy2.xpos, enemy2.ypos, enemy2.direction	; enemy
	INVOKE DrawRotatedSprite, enemy3.bitmapPtr, enemy3.xpos, enemy3.ypos, enemy3.direction	; enemy
	;INVOKE DrawRotatedSprite, asteroid1.bitmapPtr, asteroid1.xpos, asteroid1.ypos, asteroid1.direction	;Asteroid

	INVOKE DrawProjectiles ;fighter's projectiles
	;mov esi, OFFSET projectileArray 
	;INVOKE DrawRotatedSprite, (PROJECTILE PTR[esi]).bitmapPtr, (PROJECTILE PTR[esi]).xpos, (PROJECTILE PTR[esi]).ypos, 0
	;add esi, 28
	;INVOKE DrawRotatedSprite, (PROJECTILE PTR[esi]).bitmapPtr, (PROJECTILE PTR[esi]).xpos, (PROJECTILE PTR[esi]).ypos, 0
	INVOKE CheckIntersect, fighter0.xpos, fighter0.ypos, fighter0.bitmapPtr, speedPowerup.xpos, speedPowerup.ypos, speedPowerup.bitmapPtr
	cmp eax, 0
	jz noPowerup
	;INVOKE PlaySound ,offset SndPathSelect, 0, SND_FILENAME OR SND_ASYNC	; Plays select.wav
	mov speedPowerup.xpos, 39457280
	mov speedPowerup.ypos, 39457280
	INVOKE FixMul, speedMul, 020f00h
	cmp eax, 0f00ffh
	jle fine
	mov eax, 0f00ffh
fine:
	mov speedMul, eax
noPowerup:
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
