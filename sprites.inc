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


DrawRotatedSprite PROTO lpBmp:PTR EECS205BITMAP, xcenter:DWORD, ycenter:DWORD, angle:DWORD
BasicBlit PROTO ptrBitmap:PTR EECS205BITMAP , xcenter:DWORD, ycenter:DWORD
SpawnProjectile PROTO STDCALL xcenter:DWORD, ycenter:DWORD, angle:DWORD
IterateProjectiles PROTO STDCALL
DrawProjectiles PROTO STDCALL
CheckIntersect PROTO STDCALL


