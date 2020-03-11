; #########################################################################
;
;   projectiles.inc - Includes for CompEng205 Assignment 5
;
;
; #########################################################################
;EXTERNDEF projectileArraySize:DWORD 
EXTERNDEF projectileArrayLength:DWORD 
EXTERNDEF projectileArray:PROJECTILE
EXTERNDEF PI:DWORD
EXTERNDEF PI_HALF:DWORD
EXTERNDEF enemy_0_still:EECS205BITMAP
EXTERNDEF enemy0:ACTOR

DrawRotatedSprite PROTO lpBmp:PTR EECS205BITMAP, xcenter:DWORD, ycenter:DWORD, angle:DWORD
BasicBlit PROTO ptrBitmap:PTR EECS205BITMAP , xcenter:DWORD, ycenter:DWORD
SpawnProjectile PROTO STDCALL xcenter:DWORD, ycenter:DWORD, angle:DWORD
IterateProjectiles PROTO STDCALL
DrawProjectiles PROTO STDCALL
CheckIntersect PROTO STDCALL
ProjectileIntersect PROTO enemy:DWORD


