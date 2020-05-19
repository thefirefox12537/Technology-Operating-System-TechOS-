; ==================================================================
; TechOS -- The Technology Operating System kernel
; Based on the TachyonOS
; Copyright (C) 2013 TachyonOS Developers -- see doc/TachyonOS/LICENCE.TXT
; Copyright (C) 2016 TechOS Developers -- see doc/LICENSE.TXT
;
; Copyright (C) 2016 The Firefox Foundation.  All rights reserved.
;
; SPRITE MANIPULATION ROUTINES
; ==================================================================
 
; os_create_sprite --- create a new sprite
; IN: DH = size, rows; DL = size, columns
; OUT: CF = set if failed, cleared if success; If error AL = error code
os_create_sprite:
	pusha
	
	mov ax, 0x1000
	mov ds, ax
	mov es, ax
	
	mov si, sprite_used
	mov cx, 32
	
.find_unused_sprite:
	lodsb
	
	cmp al, 0
	je .found_unused_sprite
	
	loop .find_unused_sprite
	
	popa
 
	mov al, 1
	jmp os_return
	
.found_unused_sprite:
	sub si, sprite_used		; find the sprite number
	dec si
	mov bx, si
	
	mov al, dh
	mul dl
 
; sprite data
sprite_used					times 32	db 0
sprite_memory_handle		times 32	db 0
sprite_width				times 32	db 0
sprite_height				times 32	db 0
sprite_buffer				times 16384	db 0