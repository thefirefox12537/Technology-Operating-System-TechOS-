start_shell:
	BOOTMSG 'Memeriksa untuk latar belakang kustom'
	call check_for_background
	BOOTOK
	
	BOOTMSG 'Memuat ikon kustom...'
	call os_add_custom_icons
	BOOTOK

	BOOTMSG 'Memuat data berkas menu...'
	mov ax, menu_file_name		; Load menu file for UI Shell
	mov cx, 32768
	call os_load_file
	BOOTFATAL_IFCARRY 'Kesalahan memuat berkas'
	
	mov dx, 2			; Allocate 1024 bytes (2*512) to the file
	call os_memory_allocate
	BOOTFATAL_IFCARRY 'Tidak dapat megalokasi memori'
	
	mov [menu_data_handle], bh	; Remember the memory handle
		
	mov si, 32768			; Write the menu file to the memory handle
	call os_memory_write
	BOOTOK
	
	BOOTMSG 'Memasuki TOSMUI...'
	mov ax, BOOT_DELAY		; Delay to show information
	call os_pause

load_menu:
	call get_menu_data		; Collect menu information
	call draw_background		; Draw menu bar and background picture
	
show_menu:
	mov ax, menu_list		; Present menu
	mov bx, menu_title
	mov cx, blank_string
	call os_list_dialog
	jc .escape
	
	mov si, menu_actions		; Execute program corrosponding to number
	
	cmp ax, 1
	je do_action
	
	mov cx, ax
	dec cx
.get_filename:
	lodsb
	cmp al, 0
	jne .get_filename
	
	loop .get_filename
	
	jmp do_action
	
.escape:
	mov si, menu_escape_action
	
do_action:
	lodsb
	
	cmp al, '*'
	je .run_program
	
	cmp al, '='
	je .system_command
	
	cmp al, '>'
	je .submenu
	
	jmp .invalid
	
.run_program:
	mov [file_tmp], si
	mov byte [para_tmp], 0		; run with no parameters
	jmp execute
	
.system_command:
	mov di, null_command
	call os_string_compare
	jc show_menu
	
	mov di, filelist_command
	call os_string_compare
	jc app_selector
	
	mov di, commandline_command
	call os_string_compare
	jc .commandline
	
	mov di, reboot_command
	call os_string_compare
	jc restart
	
	mov di, shutdown_command
	call os_string_compare
	jc shutdown
	
	jmp .invalid
	
.submenu:
	lodsb
	sub al, 48
	mov [menu_number], al
	
	jmp load_menu

.commandline:
	call os_command_line
	
	jmp load_menu
	
.invalid:
	dec si
	
	mov ax, invalid_action_message
	mov bx, si
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	jmp load_menu
	

app_selector:
	call draw_background

	call os_file_selector		; Get user to select a file, and store
					; the resulting string location in AX
					; (other registers are undetermined)

	jc load_menu			; Return to the CLI/menu choice screen if Esc pressed

	mov word [file_tmp], ax		; Save the filename for now

file_options:
	mov bl, [FS:CFG_DLG_OUTER_COLOUR]
	mov dl, 20			; Start X position
	mov dh, 23			; Start Y position
	mov si, 40			; Width
	mov di, 24			; Finish Y position
	call os_draw_block		; Draw option selector window
	
	mov dh, 23
	mov dl, 21
	call os_move_cursor
	
	mov si, modifyfile_msg
	call os_print_string
	mov word si, [file_tmp]
	call os_print_string
	
	mov byte [para_tmp], 0		; Set a blank string for the program parameters
	
	mov ax, fileoptions_list	; Ask the user what he/she wants to do with the file
	mov bx, fileoptions_msg1
	mov cx, fileoptions_msg2
	call os_list_dialog
	jc app_selector

	cmp ax, 1			; Execute it
	je near execute
	
	cmp ax, 2			; Delete it
	je near delete
	
	cmp ax, 3			; Rename it
	je near rename
	
	cmp ax, 4			; Copy it
	je near copy
	
	cmp ax, 5			; Get the size of it
	je near get_file_size
	
	cmp ax, 6			; Blank selection
	je near file_options
	
	cmp ax, 7			; Restart the computer
	je near restart	
	
	cmp ax, 8			; Shutdown the computer
	je near shutdown
	
	jmp file_options		; In case of OS screw up
	
execute:
	mov word ax, [file_tmp]		; Get the filename back

	mov si, ax			; Did the user try to run 'KERNEL.BIN'?
	mov di, kern_file_name
	call os_string_compare
	jc no_kernel_execute		; Show an error message if so


	; Next, we need to check that the program we're attempting to run is
	; valid -- in other words, that it has a .BIN extension

	push si				; Save filename temporarily

	mov bx, si
	mov ax, si
	call os_string_length

	mov si, bx
	add si, ax			; SI now points to end of filename...

	dec si
	dec si
	dec si				; ...and now to start of extension!

	mov di, bin_ext
	mov cx, 3
	rep cmpsb			; Are final 3 chars 'BIN'?
	jne not_bin_extension		; If not, it might be a '.BAS'

	pop si				; Restore filename


	mov ax, si
	mov cx, 32768			; Where to load the program file
	call os_load_file		; Load filename pointed to by AX


execute_bin_program:
	call os_clear_screen		; Clear screen before running

	mov ax, 0			; Clear all registers
	mov bx, 0
	mov cx, 0
	mov dx, 0
	mov si, para_tmp
	mov di, 0

	call 32768			; Call the external program code,
					; loaded at second 32K of segment
					; (program must end with 'ret')

	call os_clear_screen		; When finished, clear screen
	jmp load_menu			; and go back to the program list


no_kernel_execute:			; Warn about trying to executing kernel!
	mov ax, kerndlg_string_1
	mov bx, kerndlg_string_2
	mov cx, kerndlg_string_3
	mov dx, 0			; One button for dialog box
	call os_dialog_box

	jmp load_menu			; Start over again...


not_bin_extension:
	pop si				; We pushed during the .BIN extension check

	push si				; Save it again in case of error...

	mov bx, si
	mov ax, si
	call os_string_length

	mov si, bx
	add si, ax			; SI now points to end of filename...

	dec si
	dec si
	dec si				; ...and now to start of extension!

	mov di, bas_ext
	mov cx, 3
	rep cmpsb			; Are final 3 chars 'BAS'?
	jne not_bas_extension		; If not, error out


	pop si

	mov ax, si
	mov cx, 32768			; Where to load the program file
	call os_load_file		; Load filename pointed to by AX

	call os_clear_screen		; Clear screen before running

	mov ax, 32768
	mov si, para_tmp
	call os_run_basic		; And run our BASIC interpreter on the code!

	call os_clear_screen
	jmp load_menu			; and go back to the options menu


not_bas_extension:
	pop si

	mov ax, ext_string_1
	mov bx, ext_string_2
	mov cx, 0
	mov dx, 0			; One button for dialog box
	call os_dialog_box

	jmp app_selector		; Start over again...
	
delete:
	mov ax, delsure_msg		; Are we sure we want to delete
	mov word bx, [file_tmp]
	mov cx, 0
	mov dx, 1
	call os_dialog_box
	jc near file_options		; If not, bail
	
	mov word ax, [file_tmp]		; If so, delete the file
	call os_remove_file
	jc near general_error		; Show error if failure
	jmp app_selector		; Return
	
rename:
	mov word ax, [name_tmp]		; Get filename to rename to
	mov bx, filename_string
	call os_input_dialog
	
	mov word ax, [name_tmp]		; Check if the file exists
	call os_file_exists
	jc near rename_sucess
	jmp file_exists			; Bail if so
	
rename_sucess:
	mov ax, [file_tmp]		; Rename the file
	mov bx, [name_tmp]
	call os_rename_file
	jc near general_error		; Bail if fail
	jmp app_selector		; Return
	
copy:
	mov word ax, [name_tmp]		; Get filename to rename to
	mov bx, filename_string
	call os_input_dialog
	
	mov word ax, [name_tmp]		; Check if the file exists
	call os_file_exists
	jc near copy_sucess
	jmp file_exists			; Bail if so
	
copy_sucess:
	mov word ax, [file_tmp]		; Load the first file into RAM
	mov cx, 32768
	call os_load_file
	jc general_error		; Bail if fail
	
	mov cx, bx			; Create the new file from the old one
	mov bx, 32768
	mov word ax, [name_tmp]
	call os_write_file
	jc general_error		; Bail if fail
	jmp app_selector		; Return

get_file_size:
	mov word ax, [file_tmp]
	call os_get_file_size

	mov ax, bx			; Move size into AX for conversion
	call os_int_to_string
	mov bx, ax			; Size into second line of dialog box...
	
	mov ax, size_msg
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	jmp app_selector

restart:
	mov ax, restart_string		; Are we sure?
	mov bx, 0
	mov cx, 0
	mov dx, 1
	call os_dialog_box

	cmp ax, 1			; If so, then restart
	jne near restart_sucess

	jmp load_menu		; Return if not

restart_sucess:
	mov        al, 0feh 
	out        64h, al
	jmp load_menu			; Return if error
	
shutdown:
	mov ax, shutdown_string		; Are we sure?
	mov bx, 0
	mov cx, 0
	mov dx, 1
	call os_dialog_box

	cmp ax, 1					; If so, then shutdown
	jne near shutdown_sucess

	jmp load_menu			; Return to Screen if not

shutdown_sucess:
	mov ax, 5301h				; Connect to the APM
	xor bx, bx
	int 15h
	je near continue_connection		; Pass if connected
	cmp ah, 2
	je near continue_connection		; Pass if already connected
	jc connecterr				; Bail if fail
	
continue_connection:
	mov ax, 530Eh				; Check APM Version
	xor bx, bx
	mov cx, 0102h				; v1.2 Required
 	int 15h
	jc apmvererr				; Bail if wrong version
	
	mov ax, 5307h				; Shutdown
	mov bx, 0001h
	mov cx, 0003h
	int 15h
	jmp load_menu			; Return to Operating System if error

connecterr:
	mov ax, connecterr_msg		; Failure to connect to APM
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	jmp load_menu			; Return to Operating System
	
apmvererr:
	mov ax, apmvererr_msg		; Requires APM v1.2
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	jmp load_menu			; Return to Operating System
	
file_exists:
	mov ax, exists_err			; Spit out error message
	mov word bx, [name_tmp]
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	jmp app_selector			; Return
	
general_error:
	mov ax, general_msg			; Show message
	mov word bx, [file_tmp]
	mov cx, writeonly_msg
	mov dx, 0
	call os_dialog_box
	jmp app_selector			; Return to OS

draw_background:
	mov ax, shell_msg.top		; Set up the welcome screen
	mov bx, shell_msg.bottom
	mov cx, 10011111b		; Colour: white text on light blue
	call os_draw_background

	cmp byte [user_background], 1
	je draw_user_background
	
	ret
	
check_for_background:
	mov ax, background_file_name	; Check if the file exists
	call os_file_exists		; otherwise ignore and resume boot
	jc .no_file			; errors after this will present a message

	mov ax, background_file_name	; Check the file is not too big for buffer
	call os_get_file_size		
	cmp bx, 4000
	jg .invalid_file
	
	mov ax, background_file_name	; Load the file
	mov cx, 32768
	call os_load_file
	
	mov si, 32768			; Check the file identifier
	mov di, aap_identifier
	call os_string_compare
	jnc .invalid_file
	
	add si, 4			; Check the subtype
	lodsw
	cmp ax, 0101h
	jne .invalid_file
	
	add si, 2			; Check the dimentions 
	lodsb
	cmp al, 76
	jne .invalid_file
	
	lodsb
	cmp al, 21
	jne .invalid_file
	
	mov byte [user_background], 1	; If everything is okay, make it the background
	
	push es
	mov ax, 0x1000
	mov es, ax
	
	mov si, 32768
	mov di, aap_file
	mov cx, 4000
	rep movsb
	
	pop es
	ret
	
.invalid_file:
	mov ax, .msg_invalid
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box
.no_file:	
	ret
	
.msg_invalid						db 'Berkas latar belakang tidak sah', 0


draw_user_background:
	mov si, aap_file				; Find the start of the file data
	mov word ax, [gs:si + 6]
	add si, ax
	
	mov ah, 09h					; Setup registers for VideoBIOS
	mov bh, 0
	mov cx, 1
	
	mov dh, 2					; Move cursor to starting position
	mov dl, 2
	call os_move_cursor

	mov byte [bg_rows_remaining], 21		; Set number of rows
	
.draw_row:
	mov byte [bg_columns_remaining], 76
	
.draw_char:
	mov bl, [gs:si]					; Load a colour...
	inc si
	mov al, [gs:si]					; then a character...
	inc si
	int 10h						; Now display
	
	inc dl						; Move cursor forward
	call os_move_cursor
	
	dec byte [bg_columns_remaining]
	cmp byte [bg_columns_remaining], 0
	jne .draw_char
	
	inc dh						; Next line
	mov dl, 2
	call os_move_cursor
	
	dec byte [bg_rows_remaining]
	cmp byte [bg_rows_remaining], 0
	jne .draw_row
	
	ret

get_menu_data:
	mov bh, [menu_data_handle]
	mov di, 32768
	call os_memory_read
	
	; Find the title section
	mov bh, 'T'
	call find_section
	
	; Copy the menu title and escape action
	mov di, menu_title
	call copy_line
	mov di, menu_escape_action
	call copy_line
	
	; Find the icon section
	mov bh, 'I'
	call find_section
	mov dx, si

	; Find the list section
	mov bh, 'L'
	call find_section
	
	; Copy the list section and make into a comma seperated list for os_list_dialog
	mov di, menu_list
	
	call add_icon
.create_list:
	lodsb
	cmp al, 10
	je .finished_line
	stosb
	jmp .create_list
.finished_line:
	lodsb
	cmp al, '}'
	je .finished_list

	mov al, ','
	stosb
	
	dec si
	
	call add_icon
	jmp .create_list
	
.finished_list:
	dec si
	mov al, 0
	stosb
	
	; Copy the actions section
	mov bh, 'A'
	call find_section
	
	mov di, menu_actions

.copy_actions:
	call copy_line
	
	lodsb
	cmp al, '}'
	je .done
	
	dec si
	jmp .copy_actions
	
.done:
	ret
	
	
	
find_section:
	; IN: BH = section letter
	; OUT: SI = section pointer
	
	mov si, 32768
	
.find_start:
	; find an opening bracket
	lodsb
	cmp al, '{'
	je .check_letter
	
	jmp .find_start
	
.check_letter:
	lodsb
	cmp al, bh
	jne .find_start

.check_number:
	; get the current menu number and make it into an ASCII number
	mov bl, [menu_number]
	add bl, 48
	
	; check the number is equal to the section number
	lodsb
	cmp al, bl
	jne .find_start
	
	; move over line feed
	inc si
	
	ret
	
copy_line:
	; copy a LF terminated string to a NULL terminated string
	lodsb
	cmp al, 10
	je .finished
	stosb
	jmp copy_line	
.finished:
	mov al, 0
	stosb
	ret
	
add_icon:
	push si
	push di
	mov si, dx
	mov di, icon_buffer
	call copy_line
	
	mov dx, si
	mov si, icon_buffer
	call os_string_to_int
	
	pop di
	stosb
	mov al, 32
	stosb
	pop si
	ret
	
shell_data:
	user_background		db 0
	bg_columns_remaining	db 0
	bg_rows_remaining	db 0
	aap_identifier		db 'AAP', 0

	file_tmp		times 15 db 0
	name_tmp		times 15 db 0
	para_tmp		times 128 db 0

	shell_msg:
		.top 		db OS_TUI_TOP, 0
		.bottom 	db OS_TUI_BOTTOM, 0

	
	fileoptions_list	db 'Buka berkas,Hapus berkas,Ubah nama berkas,Salin berkas,Lihat ukuran berkas,,Mulai ulang komputer,Matikan komputer', 0
	fileoptions_msg1	db 'Opsi Berkas, pilih opsi,', 0
	fileoptions_msg2	db 'atau tekan ESC untuk kembali', 0
	modifyfile_msg		db 'Opsi berkas untuk: ', 0
	
	delsure_msg			db 'Anda yakin ingin menghapus berkas:', 0
	filename_string		db 'Masukkan nama berkas 8.3 baru', 0
	size_msg			db 'Ukuran berkas (dalam bytes):', 0
	
	general_msg			db 'Tidak dapat mengubah berkas:', 0
	writeonly_msg		db '(Media hanya-tulis?)', 0
	big_err				db 'Berkas terlalu besar kedalam RAM', 0
	exists_err			db 'Berkas sudah ada', 0
	
	connecterr_msg		db 'Gagal menghubungkan ke APM', 0
	apmvererr_msg		db 'Memperlukan APM v1.2', 0
	
	restart_string		db 'Anda yakin ingin memulai ulang?', 0
	shutdown_string		db 'Anda yakin ingin mematikan?', 0

	bin_ext				db 'BIN'
	bas_ext				db 'BAS'

	kerndlg_string_1	db 'Tidak dapat memuat dan mengeksekusi', 0
	kerndlg_string_2	db 'kernel!', OS_KERNEL_FILENAME, ' adalah inti dari', 0
	kerndlg_string_3	db OS_NAME_SHORT, ' dan bukan program sejati.', 0

	ext_string_1		db 'Ekstensi nama berkas tak sah! Anda hanya', 0
	ext_string_2		db 'bisa mengeksekusi program .BIN atau .BAS.', 0
	
	null_command		db 'NULL', 0
	filelist_command	db 'FILELIST', 0
	commandline_command	db 'CMDLINE', 0
	reboot_command		db 'REBOOT', 0
	shutdown_command	db 'SHUTDOWN', 0
	
	invalid_action_message	db 'Permintaan menu aksi tidak sah.', 0
	
	blank_string		db 0
	
	menu_data_handle	db 0
	menu_number			db 0
	menu_title			times 40 db 0
	menu_escape_action	times 20 db 0
	menu_list			times 256 db 0
	menu_actions		times 128 db 0
	icon_buffer			times 5 db 0
	