; #########################################################################
;
;   lines.asm - Assembly file for CompEng205 Assignment 2
;
;   Haroon Nawaz
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include stars.inc
include lines.inc

.DATA

	;; If you need to, you can place global variables here
	
.CODE

DrawLine PROC USES eax ecx edx x0:DWORD, y0:DWORD, x1:DWORD, y1:DWORD, color:DWORD
	LOCAL delta_x:DWORD, delta_y:DWORD, inc_x:DWORD, inc_y:DWORD, curr_x:DWORD, curr_y:DWORD
        ;; eax = temp variable
        ;; ecx = error
        ;; edx = prev_error
        
        ; Initially sets increments to be positive
        mov inc_x, 1
        mov inc_y, 1
        
        mov eax, x1
        sub eax, x0
        jle LOWERX
;; if (x0 < x1)
        mov delta_x, eax
        jmp CONTINUEX
    LOWERX:
;; else
        neg eax
        neg inc_x ;; Makes increment negative
        mov delta_x, eax
        
    CONTINUEX:
        mov eax, y1
        sub eax, y0
        jle LOWERY
;; if (y0 < y1)
        mov delta_y, eax
        jmp CONTINUEY
    LOWERY:
;; else
        neg eax
        neg inc_y ;; Makes increment negative
        mov delta_y, eax
    
    CONTINUEY:
        mov eax, delta_y
        cmp delta_x, eax
        jg ERRORX
 ;; else
        mov eax, delta_y
        shr eax, 1      ;; delta_y/2
        mov ecx, eax
        neg ecx         ;; -delta_y/2
        jmp CONTINUE_ERROR
    ERRORX:
 ;; if (deltax > deltay)
        mov eax, delta_x
        shr eax, 1  ;; delta_x/2
        mov ecx, eax
    CONTINUE_ERROR:
        mov eax, x0
        mov curr_x, eax
        mov eax, y0
        mov curr_y, eax
        INVOKE DrawPixel, curr_x, curr_y, color
        jmp EVAL

     DO:
 ;; while (curr_x != x1 OR curr_y != y1)
        INVOKE DrawPixel, curr_x, curr_y, color
        mov edx, ecx        ;; prev_error = error
        mov eax, delta_x
        neg eax
        cmp edx, eax
        jle CONTINUE_LOOP
 ;; if (prev_error > - delta_x)
        sub ecx, delta_y
        mov eax, inc_x
        add curr_x, eax
    CONTINUE_LOOP:
        cmp edx, delta_y
        jge EVAL
 ;; if (prev_error < delta_y)
        add ecx, delta_x
        mov eax, inc_y
        add curr_y, eax
    EVAL:
        mov eax, x1
        cmp curr_x, eax
        jne DO      ;; curr_x != x1
        mov eax, y1
        cmp curr_y, eax
        jne DO      ;; curr_y != y1
    ret
DrawLine ENDP


END
