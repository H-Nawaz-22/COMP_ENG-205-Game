; #########################################################################
;
;   projectiles.asm - Assembly file for CompEng205 Assignment 5
;
;	Haroon Nawaz
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
include projectiles.inc
;; Has keycodes
include keys.inc
.DATA
.CODE

; NOTE:Most of these functions use the same code to loop through projectileArray,
; consider making a helper function for that

;Increases the number of projectiles by one, and places that projectile where the fighter is, with a 
;velocity with direction "angle"
SpawnProjectile PROC USES ebx ecx esi edx edi xcenter:DWORD, ycenter:DWORD, angle:DWORD
	LOCAL direction1:DWORD
	mov edi, eax
	mov eax, projectileArrayLength
	mov ecx, 28	;28 is the number of bytes in one PROJECTILE STRUCT
	mul ecx
	mov esi, OFFSET projectileArray
	add esi, eax
	;Converts angle (in radians) to an orientation and direction
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
	inc projectileArrayLength	
	cmp projectileArrayLength, 100 ;If the number of projectiles has reached 100
	jl return
	mov projectileArrayLength, 0	;Reset the array
	
return:
	mov eax, edi
	ret
SpawnProjectile ENDP

;Increments all projectiles' positions according to their velocity
IterateProjectiles PROC USES ebx ecx edx esi edi
	mov edi, eax
	mov esi, OFFSET projectileArray
	mov eax, projectileArrayLength
	mov ecx, 28
	imul ecx
	add eax, esi
	jmp eval
body:
	mov ecx, (PROJECTILE PTR[esi]).vel
	mov ebx, (PROJECTILE PTR[esi]).direction
	mov edx, (PROJECTILE PTR[esi]).orientation
	cmp ebx, 0
	jz dontNegate	
	neg ecx	;A direction of 1 indicates a velocity in the negative x or y direction
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
	mov eax, edi
	ret
IterateProjectiles ENDP

;Draws all of the projectiles in projectileArray with an index lest than projectileArrayLength
DrawProjectiles PROC USES ebx ecx edx esi
	mov ebx, eax
	lea esi, projectileArray
	mov eax, projectileArrayLength
	mov ecx, 28
	imul ecx
	add eax, esi
	jmp eval
body:
	INVOKE DrawRotatedSprite, (PROJECTILE PTR[esi]).bitmapPtr, (PROJECTILE PTR[esi]).xpos, (PROJECTILE PTR[esi]).ypos, 0
	add esi, 28
eval:
	cmp esi, eax
	jl body
	mov eax, ebx
	ret
DrawProjectiles ENDP

;; Returns a non-zero value if the sprites specified by oneBitmap and twoBitmap overlap, and returns zero otherwise. The X and Y variables
;; specify the center of the respective sprite.
CheckIntersect PROTO STDCALL oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP, twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP
CheckIntersect PROC STDCALL USES ebx ecx esi oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP, twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP
LOCAL one_Left:DWORD, one_Right:DWORD, one_Top:DWORD, one_Bottom:DWORD, two_Left:DWORD, two_Right:DWORD, two_Top:DWORD, two_Bottom:DWORD

INVOKE FixMul, oneX, 1
mov oneX, eax
INVOKE FixMul, oneY, 1
mov oneY, eax
INVOKE FixMul, twoX, 1
mov twoX, eax
INVOKE FixMul, twoY, 1
mov twoY, eax

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

;Returns the number of projectiles that are currently intersecting with "enemy"
ProjectileIntersect PROC USES ebx ecx edx esi enemy:DWORD
	mov esi, OFFSET projectileArray
	mov edi, enemy
	mov eax, projectileArrayLength
	mov ecx, 28
	imul ecx
	add eax, esi
	mov ebx, eax
	mov ecx, 0
	jmp eval
body:
	INVOKE CheckIntersect, (PROJECTILE PTR[esi]).xpos, (PROJECTILE PTR[esi]).ypos, (PROJECTILE PTR[esi]).bitmapPtr, (ACTOR PTR[edi]).xpos, (ACTOR PTR[edi]).ypos, (ACTOR PTR[edi]).bitmapPtr
	cmp eax, 0
	jz noCollide
	inc ecx

noCollide:
	add esi, 28
eval:
	cmp esi, ebx
	jl body
	mov eax, ecx
	ret
ProjectileIntersect ENDP
END
