; ==================================================================
; TechOS -- The Technology Operating System kernel
; Based on the MikeOS and TachyonOS Kernel
; Copyright (C) 2006 - 2012 MikeOS Developers -- see doc/MikeOS/LICENSE.TXT
; Copyright (C) 2013 TachyonOS Developers -- see doc/TachyonOS/LICENCE.TXT
; Copyright (C) 2016 TechOS Developers -- see doc/LICENSE.TXT
;
; Copyright (C) 2016 The Firefox Foundation.  All rights reserved.
;
; COMMAND LINE INTERFACE
; ==================================================================


os_command_line:
	call os_clear_screen

	mov si, version_msg
	call os_print_string
	mov si, copyright_msg
	call os_print_string
	mov si, separate_msg
	call os_print_string
	mov si, help_textfirst
	call os_print_string
	mov si, separate_msg
	call os_print_string


get_cmd:				; Main processing loop
	mov di, input			; Clear input buffer each time
	mov al, 0
	mov cx, 256
	rep stosb

	mov di, command			; And single command buffer
	mov cx, 32
	rep stosb

	mov si, prompt			; Main loop; prompt for input
	call os_print_string

	mov ax, input			; Get command string from user
	call os_input_string

	call os_print_newline

	mov ax, input			; Remove trailing spaces
	call os_string_chomp

	mov si, input			; If just enter pressed, prompt again
	cmp byte [si], 0
	je get_cmd

	mov si, input			; Separate out the individual command
	mov al, ' '
	call os_string_tokenize

	mov word [param_list], di	; Store location of full parameters

	mov si, input			; Store copy of command for later modifications
	mov di, command
	call os_string_copy



	; First, let's check to see if it's an internal command...

	mov ax, input
	call os_string_uppercase

	mov si, input

	mov di, exit_string		; 'EXIT' entered?
	call os_string_compare
	jc near exit

	mov di, help_string		; 'HELP' entered?
	call os_string_compare
	jc near print_help

	mov di, cls_string		; 'CLS' entered?
	call os_string_compare
	jc near clear_screen

	mov di, dir_string		; 'DIR' entered?
	call os_string_compare
	jc near list_directory

	mov di, ver_string		; 'VER' entered?
	call os_string_compare
	jc near print_ver

	mov di, time_string		; 'TIME' entered?
	call os_string_compare
	jc near print_time

	mov di, date_string		; 'DATE' entered?
	call os_string_compare
	jc near print_date

	mov di, cat_string		; 'CAT' entered?
	call os_string_compare
	jc near cat_file

	mov di, del_string		; 'DEL' entered?
	call os_string_compare
	jc near del_file

	mov di, copy_string		; 'COPY' entered?
	call os_string_compare
	jc near copy_file

	mov di, ren_string		; 'REN' entered?
	call os_string_compare
	jc near ren_file

	mov di, size_string		; 'SIZE' entered?
	call os_string_compare
	jc near size_file
	
	mov di, reboot_cli_string	; 'REBOOT' entered?
	call os_string_compare
	jc near reboot_cli
	
	mov di, shutdown_cli_string	; 'SHUTDOWN' entered?
	call os_string_compare
	jc near shutdown_cli


	; If the user hasn't entered any of the above commands, then we
	; need to check for an executable file -- .BIN or .BAS, and the
	; user may not have provided the extension

	mov ax, command
	call os_string_uppercase
	call os_string_length


	; If the user has entered, say, MEGACOOL.BIN, we want to find that .BIN
	; bit, so we get the length of the command, go four characters back to
	; the full stop, and start searching from there

	mov si, command
	add si, ax

	sub si, 4

	mov di, bin_extension		; Is there a .BIN extension?
	call os_string_compare
	jc bin_file

	mov di, bas_extension		; Or is there a .BAS extension?
	call os_string_compare
	jc bas_file

	jmp no_extension


bin_file:
	mov ax, command
	mov bx, 0
	mov cx, 32768
	call os_load_file
	jc total_fail

execute_bin:
	mov si, command
	mov di, kern_file_string
	mov cx, 6
	call os_string_strincmp
	jc no_kernel_allowed

	mov ax, 0			; Clear all registers
	mov bx, 0
	mov cx, 0
	mov dx, 0
	mov word si, [param_list]
	mov di, 0

	call 32768			; Call the external program

	mov si, separate_msg
	call os_print_string
	jmp get_cmd			; When program has finished, start again



bas_file:
	mov ax, command
	mov bx, 0
	mov cx, 32768
	call os_load_file
	jc total_fail

	mov ax, 32768
	mov word si, [param_list]
	call os_run_basic
	mov si, separate_msg
	call os_print_string

	jmp get_cmd



no_extension:
	mov ax, command
	call os_string_length

	mov si, command
	add si, ax

	mov byte [si], '.'
	mov byte [si+1], 'B'
	mov byte [si+2], 'I'
	mov byte [si+3], 'N'
	mov byte [si+4], 0

	mov ax, command
	mov bx, 0
	mov cx, 32768
	call os_load_file
	jc try_bas_ext

	jmp execute_bin


try_bas_ext:
	mov ax, command
	call os_string_length

	mov si, command
	add si, ax
	sub si, 4

	mov byte [si], '.'
	mov byte [si+1], 'B'
	mov byte [si+2], 'A'
	mov byte [si+3], 'S'
	mov byte [si+4], 0

	jmp bas_file



total_fail:
	mov si, invalid_msg
	call os_print_string
	mov si, separate_msg
	call os_print_string

	jmp get_cmd


no_kernel_allowed:
	mov si, kern_warn_msg
	call os_print_string
	mov si, separate_msg
	call os_print_string

	jmp get_cmd


; ------------------------------------------------------------------

print_help:
	mov si, help_text
	call os_print_string
	mov si, help_text1
	call os_print_string
	mov si, help_text2
	call os_print_string
	mov si, help_text3
	call os_print_string
	mov si, help_text4
	call os_print_string
	mov si, help_text5
	call os_print_string
	mov si, help_text6
	call os_print_string
	mov si, help_text7
	call os_print_string
	mov si, help_text8
	call os_print_string
	mov si, help_text9
	call os_print_string
	mov si, help_text10
	call os_print_string
	mov si, help_text11
	call os_print_string
	mov si, help_text12
	call os_print_string
	mov si, help_text13
	call os_print_string
	mov si, separate_msg
	call os_print_string
	jmp get_cmd


; ------------------------------------------------------------------

clear_screen:
	call os_clear_screen
	jmp get_cmd


; ------------------------------------------------------------------

print_time:
	mov bx, tmp_string
	call os_get_time_string
	mov si, bx
	call os_print_string
	mov si, separate_msg
	call os_print_string
	call os_print_newline
	jmp get_cmd


; ------------------------------------------------------------------

print_date:
	mov bx, tmp_string
	call os_get_date_string
	mov si, bx
	call os_print_string
	mov si, separate_msg
	call os_print_string
	call os_print_newline
	jmp get_cmd


; ------------------------------------------------------------------

print_ver:
	mov si, version_msg
	call os_print_string
	mov si, separate_msg
	call os_print_string
	jmp get_cmd


; ------------------------------------------------------------------

kern_warning:
	mov si, kern_warn_msg
	call os_print_string
	mov si, separate_msg
	call os_print_string
	jmp get_cmd


; ------------------------------------------------------------------

list_directory:
	mov cx,	0			; Counter

	mov ax, dirlist			; Get list of files on disk
	call os_get_file_list

	mov si, dirlist
	mov ah, 0Eh			; BIOS teletype function

.repeat:
	lodsb				; Start printing filenames
	cmp al, 0			; Quit if end of string
	je .done

	cmp al, ','			; If comma in list string, don't print it
	jne .nonewline
	pusha
	call os_print_newline		; But print a newline instead
	popa
	jmp .repeat

.nonewline:
	int 10h
	jmp .repeat

.done:
	mov si, separate_msg
	call os_print_string
	call os_print_newline
	jmp get_cmd


; ------------------------------------------------------------------

cat_file:
	mov word si, [param_list]
	call os_string_parse
	cmp ax, 0			; Was a filename provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call os_print_string
	mov si, separate_msg
	call os_print_string
	jmp get_cmd

.filename_provided:
	call os_file_exists		; Check if file exists
	jc .not_found

	mov cx, 32768			; Load file into second 32K
	call os_load_file

	mov word [file_size], bx

	cmp bx, 0			; Nothing in the file?
	je get_cmd

	mov si, 32768
	mov ah, 0Eh			; int 10h teletype function
.loop:
	lodsb				; Get byte from loaded file

	cmp al, 0Ah			; Move to start of line if we get a newline char
	jne .not_newline

	call os_get_cursor_pos
	mov dl, 0
	call os_move_cursor

.not_newline:
	int 10h				; Display it
	dec bx				; Count down file size
	cmp bx, 0			; End of file?
	jne .loop

	mov si, separate_msg
	call os_print_string
	jmp get_cmd

.not_found:
	mov si, notfound_msg
	call os_print_string
	mov si, separate_msg
	call os_print_string
	jmp get_cmd


; ------------------------------------------------------------------

del_file:
	mov word si, [param_list]
	call os_string_parse
	cmp ax, 0			; Was a filename provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call os_print_string
	mov si, separate_msg
	call os_print_string
	jmp get_cmd

.filename_provided:
	call os_remove_file
	jc .failure

	mov si, .success_msg
	call os_print_string
	mov si, ax
	call os_print_string
	mov si, separate_msg
	call os_print_string
	call os_print_newline
	jmp get_cmd

.failure:
	mov si, .failure_msg
	call os_print_string
	mov si, separate_msg
	call os_print_string
	jmp get_cmd


	.success_msg	db 'Hapus berkas: ', 0
	.failure_msg	db 'Tidak dapat menghapus berkas - tidak ada atau tulis yang dilindungi', 13, 10, 0


; ------------------------------------------------------------------

size_file:
	mov word si, [param_list]
	call os_string_parse
	cmp ax, 0			; Was a filename provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call os_print_string
	mov si, separate_msg
	call os_print_string
	jmp get_cmd

.filename_provided:
	call os_get_file_size
	jc .failure

	mov si, .size_msg
	call os_print_string

	mov ax, bx
	call os_int_to_string
	mov si, ax
	call os_print_string
	mov si, separate_msg
	call os_print_string
	call os_print_newline
	jmp get_cmd


.failure:
	mov si, notfound_msg
	call os_print_string
	mov si, separate_msg
	call os_print_string
	jmp get_cmd


	.size_msg	db 'Ukuran (dalam bytes) adalah: ', 0


; ------------------------------------------------------------------

copy_file:
	mov word si, [param_list]
	call os_string_parse
	mov word [.tmp], bx

	cmp bx, 0			; Were two filenames provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call os_print_string
	mov si, separate_msg
	call os_print_string
	jmp get_cmd

.filename_provided:
	mov dx, ax			; Store first filename temporarily
	mov ax, bx
	call os_file_exists
	jnc .already_exists

	mov ax, dx
	mov cx, 32768
	call os_load_file
	jc .load_fail

	mov cx, bx
	mov bx, 32768
	mov word ax, [.tmp]
	call os_write_file
	jc .write_fail

	mov si, .success_msg
	call os_print_string
	mov si, separate_msg
	call os_print_string
	jmp get_cmd

.load_fail:
	mov si, notfound_msg
	call os_print_string
	mov si, separate_msg
	call os_print_string
	jmp get_cmd

.write_fail:
	mov si, writefail_msg
	call os_print_string
	mov si, separate_msg
	call os_print_string
	jmp get_cmd

.already_exists:
	mov si, exists_msg
	call os_print_string
	mov si, separate_msg
	call os_print_string
	jmp get_cmd


	.tmp		dw 0
	.success_msg	db 'Berkas berhasil disalin', 13, 10, 0


; ------------------------------------------------------------------

ren_file:
	mov word si, [param_list]
	call os_string_parse

	cmp bx, 0			; Were two filenames provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call os_print_string
	mov si, separate_msg
	call os_print_string
	jmp get_cmd

.filename_provided:
	mov cx, ax			; Store first filename temporarily
	mov ax, bx			; Get destination
	call os_file_exists		; Check to see if it exists
	jnc .already_exists

	mov ax, cx			; Get first filename back
	call os_rename_file
	jc .failure

	mov si, .success_msg
	call os_print_string
	mov si, separate_msg
	call os_print_string
	jmp get_cmd

.already_exists:
	mov si, exists_msg
	call os_print_string
	mov si, separate_msg
	call os_print_string
	jmp get_cmd

.failure:
	mov si, .failure_msg
	call os_print_string
	mov si, separate_msg
	call os_print_string
	jmp get_cmd


	.success_msg	db 'Berkas berhasil diubah', 13, 10, 0
	.failure_msg	db 'Operasi gagal - berkas tidak ditemukan atau nama berkas tidak sah', 13, 10, 0


; ------------------------------------------------------------------

exit:
	ret


; ------------------------------------------------------------------

reboot_cli:
	mov        al, 0feh 
	out        64h, al
	mov si, rebooterr_msg
	call os_print_string
	mov si, separate_msg
	call os_print_string
	jmp get_cmd			; Return if error
	
	
; ------------------------------------------------------------------

shutdown_cli:
	mov ax, 5301h				; Connect to the APM
	xor bx, bx
	int 15h
	je near continue_connection_apm		; Pass if connected
	cmp ah, 2
	je near continue_connection_apm		; Pass if already connected
	jc connectapmerr				; Bail if fail

continue_connection_apm:
	mov ax, 530Eh				; Check APM Version
	xor bx, bx
	mov cx, 0102h				; v1.2 Required
 	int 15h
	jc apmvererr				; Bail if wrong version
	
	mov ax, 5307h				; Shutdown
	mov bx, 0001h
	mov cx, 0003h
	int 15h
	mov si, separate_msg
	call os_print_string
	jmp get_cmd
	
connectapmerr:
	mov si, connectapmerr_msg
	call os_print_string
	mov si, separate_msg
	call os_print_string
	jmp get_cmd
	
apmverserr:
	mov si, apmvererr_msg
	call os_print_string
	mov si, separate_msg
	call os_print_string
	jmp get_cmd
	
	
; ------------------------------------------------------------------

	input			times 256 db 0
	command			times 32 db 0

	dirlist			times 1024 db 0
	tmp_string		times 15 db 0

	file_size		dw 0
	param_list		dw 0

	bin_extension		db '.BIN', 0
	bas_extension		db '.BAS', 0

	prompt			db 'Shell:# ', 0

	help_textfirst		db 'Ketik BANTUAN untuk melihat perintah ', OS_NAME_SHORT, ' Command Line', 13, 10, 0

	separate_msg		db ' ', 13, 10, 0
	
	help_text		db 'Perintah:', 13, 10, 0
	help_text1		db '  - DIREKTORI      Menampilkan berkas pada direktori', 13, 10, 0
	help_text2		db '  - SALIN          Menyalin berkas', 13, 10, 0
	help_text3		db '  - UBAH           Mengubah nama berkas atau direktori', 13, 10, 0
	help_text4		db '  - HAPUS          Menghapus berkas', 13, 10, 0
	help_text5		db '  - LIHAT          Menampilkan teks di berkas', 13, 10, 0
	help_text6		db '  - UKURAN         Menampilkan ukuran berkas', 13, 10, 0
	help_text7		db '  - LAYAR          Menghapus layar monitor', 13, 10, 0
	help_text8		db '  - WAKTU          Memeriksa waktu sistem', 13, 10, 0
	help_text9		db '  - TANGGAL        Memeriksa tanggal sistem', 13, 10, 0
	help_text10		db '  - VERSI          Memeriksa versi kernel ', OS_NAME_SHORT, 13, 10, 0
	help_text11		db '  - KELUAR         Keluar dari sesi command line', 13, 10, 0
	help_text12		db '  - REBOOT         Mulai ulang sesi komputer', 13, 10, 0
	help_text13		db '  - MATIKAN        Matikan sesi komputer', 13, 10, 0
	
	invalid_msg		db 'Perintah atau program tidak mungkin', 13, 10, 0
	nofilename_msg		db 'Tidak ada nama berkas atau nama berkas tidak cukup', 13, 10, 0
	notfound_msg		db 'Berkas tidak ditemukan', 13, 10, 0
	writefail_msg		db 'Tidak dapat menulis berkas. Tulis telah dilindungi atau nama berkas tidak sah?', 13, 10, 0
	exists_msg		db 'Tujuan berkas sudah ada!', 13, 10, 0
	rebooterr_msg		db 'Tidak dapat memulai ulang. Gagal menghubungkan ke APM', 13, 10, 0
	connectapmerr_msg		db 'Tidak dapat mematikan. Gagal menghubungkan ke APM', 13, 10, 0
	apmverserr_msg		db 'Tidak dapat mematikan. Memperlukan APM v1.2', 13,10, 0
	version_msg		db OS_NAME_SHORT, ' Command Line(R) Versi ', OS_VERSION_STRING, 13, 10, 0
	copyright_msg		db 'Hak Cipta(C) 2016 The Firefox Foundation.  Semua hak terpelihara.', 13, 10, 0

	exit_string		db 'KELUAR', 0
	help_string		db 'BANTUAN', 0
	cls_string		db 'LAYAR', 0
	dir_string		db 'DIREKTORI', 0
	time_string		db 'WAKTU', 0
	date_string		db 'TANGGAL', 0
	ver_string		db 'VERSI', 0
	cat_string		db 'LIHAT', 0
	del_string		db 'HAPUS', 0
	ren_string		db 'UBAH', 0
	copy_string		db 'SALIN', 0
	size_string		db 'UKURAN', 0
	shutdown_cli_string		db 'MATIKAN',0
	reboot_cli_string		db 'REBOOT',0

	kern_file_string	db 'KERNEL', 0
	kern_warn_msg		db 'Tidak dapat mengeksekusi berkas kernel!', 13, 10, 0


; ==================================================================

