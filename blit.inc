; #########################################################################
;
;   blit.inc - Includes for CompEng205 Assignment 3
;
;
; #########################################################################



_EECS205BITMAP STRUCT
 dwWidth      DWORD  ?
 dwHeight     DWORD  ?
 bTransparent BYTE   ?
              BYTE   3 DUP(?)
 lpBytes      DWORD  ?
_EECS205BITMAP ENDS

; ACTOR is for sprites on the screen that have dynamic motion and behavior
_ACTOR STRUCT
 xpos         DWORD  ?
 ypos         DWORD  ?
 xvel         DWORD  ?
 yvel         DWORD  ?
 direction    DWORD  0
 bitmapPtr    DWORD  ?
_ACTOR ENDS

EECS205BITMAP TYPEDEF _EECS205BITMAP
ACTOR TYPEDEF _ACTOR

EXTERNDEF ScreenBitsPtr:DWORD

BasicBlit PROTO STDCALL ptrBitmap:PTR EECS205BITMAP, xcenter:DWORD, ycenter:DWORD

RotateBlit PROTO STDCALL ptrBitmap:PTR EECS205BITMAP, xcenter:DWORD, ycenter:DWORD, angle:DWORD
	   





