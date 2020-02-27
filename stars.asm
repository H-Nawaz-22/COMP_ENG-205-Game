; #########################################################################
;
;   stars.asm - Assembly file for CompEng205 Assignment 1
;   Haroon Nawaz
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive


include stars.inc

.DATA

	;; If you need to, you can place global variables here

.CODE

DrawStarField proc
; Draws stars at specified locations on a 640 x 480 grid

 ;   Ursa Major  
	invoke DrawStar, 24, 372
      invoke DrawStar, 76, 375
      invoke DrawStar, 107, 401
      invoke DrawStar, 143, 425
      invoke DrawStar, 149, 463
      invoke DrawStar, 228, 431 
      invoke DrawStar, 216, 472
    
  ;  Ursa Minor
      invoke DrawStar, 284, 207
      invoke DrawStar, 246, 201
      invoke DrawStar, 212, 218
      invoke DrawStar, 186, 247
      invoke DrawStar, 165, 228
      invoke DrawStar, 305, 220 ; Polaris
        
  ;  Draco
      invoke DrawStar, 36, 56
      invoke DrawStar, 26, 87
      invoke DrawStar, 86, 174
      invoke DrawStar, 56, 40
      invoke DrawStar, 131, 144
      invoke DrawStar, 122, 300
      invoke DrawStar, 201, 327
      invoke DrawStar, 238, 256
      invoke DrawStar, 222, 2
      invoke DrawStar, 56, 236
      invoke DrawStar, 50, 200

      invoke DrawStar, 620, 363 ; Capella
      
  ;  Perseus
      invoke DrawStar, 621, 198
      invoke DrawStar, 590, 172
      
  ;  Cassiopeia
      invoke DrawStar, 452,18
      invoke DrawStar, 492, 26
      invoke DrawStar, 479, 64
      invoke DrawStar, 500, 85

  ;  Misc
      invoke DrawStar, 373, 296
      invoke DrawStar, 383, 420
      invoke DrawStar, 322, 418
      invoke DrawStar, 316, 364
      invoke DrawStar, 19, 319
      invoke DrawStar, 577, 20
      invoke DrawStar, 346, 119
      invoke DrawStar, 284, 56
      invoke DrawStar, 345, 23
      invoke DrawStar, 500, 200
      invoke DrawStar, 638, 27
      invoke DrawStar, 480, 385
      invoke DrawStar, 223, 257
      invoke DrawStar, 116, 252
      invoke DrawStar, 373, 277
      invoke DrawStar, 259, 120
      invoke DrawStar, 221, 51
      invoke DrawStar, 307, 450
      invoke DrawStar, 27, 334
      invoke DrawStar, 637, 138
      invoke DrawStar, 337, 96
      invoke DrawStar, 373, 296
      invoke DrawStar, 485, 291
      invoke DrawStar, 529, 273
      invoke DrawStar, 426, 138
      invoke DrawStar, 590, 127
      invoke DrawStar, 615, 105
      invoke DrawStar, 618, 139

      
      
      
	ret  			; Careful! Don't remove this line

DrawStarField endp



END
