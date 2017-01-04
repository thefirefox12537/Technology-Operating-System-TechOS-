; ------------------------------------------------------------------
; Geography-based hangman game for TechOS
;
; At the end of this file you'll see a list of 256 cities, places in
; Indonesia (in lower-case to make the game code simpler). We get one
; city at random from the list and store it in a string.
;
; Next, we create another string of the same size, but with underscore
; characters instead of the real ones. We display this 'work' string to
; the player, who tries to guess characters. If s/he gets a char right,
; it is revealed in the work string.
;
; If s/he gets gets a char wrong, we add it to a list of misses, and
; draw more of the hanging man. Poor bloke.
; ------------------------------------------------------------------


	BITS 16
	%INCLUDE "techdev.inc"
	ORG 32768


start:
	call os_hide_cursor


	; First, reset values in case user is playing multiple games

	mov di, real_string			; Full city name
	mov al, 0
	mov cx, 50
	rep stosb

	mov di, work_string			; String that starts as '_' characters
	mov al, 0
	mov cx, 50
	rep stosb

	mov di, tried_chars			; Chars the user has tried, but aren't in the real string
	mov al, 0
	mov cx, 255
	rep stosb

	mov byte [tried_chars_pos], 0
	mov byte [misses], 1			; First miss is to show the platform


	mov ax, title_msg			; Set up the screen
	mov bx, footer_msg
	mov cx, 01100000b
	call os_draw_background

	mov ax, 0
	mov bx, 255
	call os_get_random			; Get a random number

	mov bl, cl				; Store in BL


	mov si, cities				; Skip number of lines stored in BL
skip_loop:
	cmp bl, 0
	je skip_finished
	dec bl
.inner:
	lodsb					; Find a zero to denote end of line
	cmp al, 0
	jne .inner
	jmp skip_loop


skip_finished:
	mov di, real_string			; Store the string from the city list
	call os_string_copy

	mov ax, si
	call os_string_length

	mov dx, ax				; DX = number of '_' characters to show

	call add_underscores


	cmp dx, 5				; Give first char if it's a short string
	ja no_hint

	mov ax, hint_msg_1			; Tell player about the hint
	mov bx, hint_msg_2
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	call os_hide_cursor

	mov ax, title_msg			; Redraw screen
	mov bx, footer_msg
	mov cx, 01100000b
	call os_draw_background

	mov byte al, [real_string]		; Copy first letter over
	mov byte [work_string], al


no_hint:
	call fix_spaces				; Add spaces to working string if necessary

main_loop:
	call show_tried_chars			; Update screen areas
	call show_hangman
	call show_main_box

	cmp byte [misses], 11			; See if the player has lost
	je lost_game

	call os_wait_for_key			; Get input

	cmp al, KEY_ESC
	je finish

	cmp al, 122				; Work with just "a" to "z" keys
	ja main_loop

	cmp al, 97
	jb main_loop

	mov bl, al				; Store character temporarily

	mov cx, 0				; Counter into string
	mov dl, 0				; Flag whether char was found
	mov si, real_string
find_loop:
	lodsb
	cmp al, 0				; End of string?
	je done_find
	cmp al, bl				; Find char entered in string
	je found_char
	inc cx					; Move on to next character
	jmp find_loop



found_char:
	inc dl					; Note that at least one char match was found
	mov di, work_string
	add di, cx				; Update our underscore string with char found
	mov byte [di], bl
	inc cx
	jmp find_loop


done_find:
	mov si, real_string			; If the strings match, the player has won!
	mov di, work_string
	call os_string_compare
	jc won_game

	cmp dl, 0				; If char was found, skip next bit
	jne main_loop

	call update_tried_chars			; Otherwise add char to list of misses

	jmp main_loop


won_game:
	call show_win_msg
.loop:
	call os_wait_for_key			; Wait for keypress
	cmp al, KEY_ESC
	je finish
	cmp al, KEY_ENTER
	jne .loop
	jmp start


lost_game:					; After too many misses...
	call show_lose_msg
.loop:						; Wait for keypress
	call os_wait_for_key
	cmp al, KEY_ESC
	je finish
	cmp al, KEY_ENTER
	jne .loop
	jmp start


finish:
	call os_show_cursor
	call os_clear_screen

	ret




add_underscores:				; Create string of underscores
	mov di, work_string
	mov al, '_'
	mov cx, dx				; Size of string
	rep stosb
	ret



	; Copy any spaces from the real string into the work string

fix_spaces:
	mov si, real_string
	mov di, work_string
.loop:
	lodsb
	cmp al, 0
	je .done
	cmp al, ' '
	jne .no_space
	mov byte [di], ' '
.no_space:
	inc di
	jmp .loop
.done:
	ret



	; Here we check the list of wrong chars that the player entered previously,
	; and see if the latest addition is already in there...

update_tried_chars:
	mov si, tried_chars
	mov al, bl
	call os_find_char_in_string
	cmp ax, 0
	jne .nothing_to_add			; Skip next bit if char was already in list

	mov si, tried_chars
	mov ax, 0
	mov byte al, [tried_chars_pos]		; Move into the list
	add si, ax
	mov byte [si], bl
	inc byte [tried_chars_pos]

	inc byte [misses]			; Knock up the score
.nothing_to_add:
	ret


show_main_box:
	pusha
	mov bl, BLACK_ON_WHITE
	mov dh, 5
	mov dl, 2
	mov si, 36
	mov di, 21
	call os_draw_block

	mov dh, 7
	mov dl, 4
	call os_move_cursor
	mov si, help_msg_1
	call os_print_string

	mov dh, 8
	mov dl, 4
	call os_move_cursor
	mov si, help_msg_2
	call os_print_string

	mov dh, 9
	mov dl, 4
	call os_move_cursor
	mov si, help_msg_3
	call os_print_string

	mov dh, 17
	mov dl, 4
	call os_move_cursor
	mov si, help_msg_4
	call os_print_string

	mov dh, 18
	mov dl, 4
	call os_move_cursor
	mov si, help_msg_5
	call os_print_string

	mov dh, 12
	mov dl, 6
	call os_move_cursor
	mov si, work_string
	call os_print_string

	popa
	ret


show_tried_chars:
	pusha
	mov bl, BLACK_ON_WHITE
	mov dh, 18
	mov dl, 40
	mov si, 39
	mov di, 23
	call os_draw_block

	mov dh, 19
	mov dl, 41
	call os_move_cursor

	mov si, tried_chars_msg
	call os_print_string

	mov dh, 21
	mov dl, 41
	call os_move_cursor

	mov si, tried_chars
	call os_print_string

	popa
	ret



show_win_msg:
	mov bl, WHITE_ON_GREEN
	mov dh, 14
	mov dl, 5
	mov si, 30
	mov di, 15
	call os_draw_block

	mov dh, 14
	mov dl, 6
	call os_move_cursor

	mov si, .win_msg
	call os_print_string

	mov dh, 12
	mov dl, 6
	call os_move_cursor
	mov si, real_string
	call os_print_string

	ret


	.win_msg	db 'Yes! Tekan enter bermain lagi', 0



show_lose_msg:
	mov bl, WHITE_ON_LIGHT_RED
	mov dh, 14
	mov dl, 5
	mov si, 30
	mov di, 15
	call os_draw_block

	mov dh, 14
	mov dl, 6
	call os_move_cursor

	mov si, .lose_msg
	call os_print_string

	mov dh, 12
	mov dl, 6
	call os_move_cursor
	mov si, real_string
	call os_print_string

	ret


	.lose_msg	db 'Duh! Tekan enter bermain lagi', 0



	; Draw the hangman box and appropriate bits depending on the number of misses

show_hangman:
	pusha

	mov bl, BLACK_ON_WHITE
	mov dh, 2
	mov dl, 42
	mov si, 35
	mov di, 17
	call os_draw_block


	cmp byte [misses], 0
	je near .0
	cmp byte [misses], 1
	je near .1
	cmp byte [misses], 2
	je near .2
	cmp byte [misses], 3
	je near .3
	cmp byte [misses], 4
	je near .4
	cmp byte [misses], 5
	je near .5
	cmp byte [misses], 6
	je near .6
	cmp byte [misses], 7
	je near .7
	cmp byte [misses], 8
	je near .8
	cmp byte [misses], 9
	je near .9
	cmp byte [misses], 10
	je near .10
	cmp byte [misses], 11
	je near .11

.11:					; Right leg
	mov dh, 10
	mov dl, 64
	call os_move_cursor
	mov si, .11_t
	call os_print_string

.10:					; Left leg
	mov dh, 10
	mov dl, 62
	call os_move_cursor
	mov si, .10_t
	call os_print_string

.9:					; Torso
	mov dh, 9
	mov dl, 63
	call os_move_cursor
	mov si, .9_t
	call os_print_string

.8:					; Arms
	mov dh, 8
	mov dl, 62
	call os_move_cursor
	mov si, .8_t
	call os_print_string

.7:					; Head
	mov dh, 7
	mov dl, 63
	call os_move_cursor
	mov si, .7_t
	call os_print_string

.6:					; Rope
	mov dh, 6
	mov dl, 63
	call os_move_cursor
	mov si, .6_t
	call os_print_string

.5:					; Beam
	mov dh, 5
	mov dl, 56
	call os_move_cursor
	mov si, .5_t
	call os_print_string

.4:					; Support for beam
	mov dh, 6
	mov dl, 57
	call os_move_cursor
	mov si, .4_t
	call os_print_string

.3:					; Pole
	mov dh, 12
	mov dl, 56
	call os_move_cursor
	mov si, .3_t
	call os_print_string
	mov dh, 11
	mov dl, 56
	call os_move_cursor
	call os_print_string
	mov dh, 10
	mov dl, 56
	call os_move_cursor
	call os_print_string
	mov dh, 9
	mov dl, 56
	call os_move_cursor
	call os_print_string
	mov dh, 8
	mov dl, 56
	call os_move_cursor
	call os_print_string
	mov dh, 7
	mov dl, 56
	call os_move_cursor
	call os_print_string
	mov dh, 6
	mov dl, 56
	call os_move_cursor
	call os_print_string

.2:					; Support for pole
	mov dh, 13
	mov dl, 55
	call os_move_cursor
	mov si, .2_t
	call os_print_string

.1:					; Ground
	mov dh, 14
	mov dl, 53
	call os_move_cursor
	mov si, .1_t
	call os_print_string
	

.0:
	popa
	ret


	.1_t		db '-------------', 0
	.2_t		db '/|\', 0
	.3_t		db '|', 0
	.4_t		db '/', 0
	.5_t		db '________', 0
	.6_t		db '|', 0
	.7_t		db 'O', 0
	.8_t		db '---', 0
	.9_t		db '|', 0
	.10_t		db '/', 0
	.11_t		db '\', 0



	title_msg	db 'TechOS Hangman', 0
	footer_msg	db 'Tekan Esc untuk keluar', 0

	hint_msg_1	db 'Kata pendek kali ini, anda peroleh huruf', 0
	hint_msg_2	db 'pertama secara bebas!', 0

	help_msg_1	db 'Bisa anda tebak nama kota dan', 0
	help_msg_2	db 'kabupaten itu di Indonesia yang', 0
	help_msg_3	db 'cocok pada tempat dibawah ini?', 0
	help_msg_4	db 'Tekan tombol untuk menebak huruf,', 0
	help_msg_5	db 'tapi hanya diberi 10 kesempatan!', 0

	real_string	times 50 db 0
	work_string	times 50 db 0

	tried_chars_msg	db 'Mencoba karakter...', 0
	tried_chars_pos	db 0
	tried_chars	times 255 db 0

	misses		db 1



cities:

db 'jakarta', 0
db 'bogor', 0
db 'depok', 0
db 'tangerang', 0
db 'bekasi', 0
db 'kepulauan seribu', 0
db 'cianjur', 0
db 'cirebon', 0
db 'sukabumi', 0
db 'kuningan', 0
db 'indramayu', 0
db 'ciamis', 0
db 'purwakarta', 0
db 'karawang', 0
db 'rengasdengklok', 0
db 'garut', 0
db 'cimahi', 0
db 'rangkasbitung', 0
db 'pandeglang', 0
db 'cibinong', 0
db 'majalengka', 0
db 'bandung', 0
db 'soreang', 0
db 'tasikmalaya', 0
db 'serang', 0
db 'cilegon', 0
db 'merak', 0
db 'anyer', 0
db 'ujung kulon', 0
db 'subang', 0
db 'pangandaran', 0
db 'sumedang', 0
db 'kendal', 0
db 'tegal', 0
db 'brebes', 0
db 'batang', 0
db 'banjarnegara', 0
db 'purwokerto', 0
db 'banyumas', 0
db 'klaten', 0
db 'grobogan', 0
db 'magelang', 0
db 'purbalingga', 0
db 'semarang', 0
db 'kepulauan karimunjawa', 0
db 'demak', 0
db 'kebumen', 0
db 'kudus', 0
db 'jepara', 0
db 'pati', 0
db 'sleman', 0
db 'salatiga', 0
db 'ambarawa', 0
db 'pekalongan', 0
db 'wonogiri', 0
db 'bantul', 0
db 'gunung kidul', 0
db 'blora', 0
db 'rembang', 0
db 'purworejo', 0
db 'temanggung', 0
db 'cilacap', 0
db 'pemalang', 0
db 'yogyakarta', 0
db 'kulonprogo', 0
db 'sragen', 0
db 'karanganyar', 0
db 'surakarta', 0
db 'sukoharjo', 0
db 'boyolali', 0
db 'wonosobo', 0
db 'pacitan', 0
db 'ngawi', 0
db 'magetan', 0
db 'trenggalek', 0
db 'madiun', 0
db 'kediri', 0
db 'bojonegoro', 0
db 'tuban', 0
db 'ponorogo', 0
db 'blitar', 0
db 'surabaya', 0
db 'lamongan', 0
db 'gresik', 0
db 'jombang', 0
db 'nganjuk', 0
db 'tulungangung', 0
db 'lumajang', 0
db 'jember', 0
db 'malang', 0
db 'kota batu', 0
db 'mojokerto', 0
db 'sidoarjo', 0
db 'pulau bawean', 0
db 'pasuruan', 0
db 'probolinggo', 0
db 'pandaan', 0
db 'situbondo', 0
db 'panarukan', 0
db 'bondowoso', 0
db 'besuki', 0
db 'banyuwangi', 0
db 'blambangan', 0
db 'bangkalan', 0
db 'sampang', 0
db 'pamekasan', 0
db 'sumenep', 0
db 'sabang', 0
db 'simeulue', 0
db 'banda aceh', 0
db 'lhokseumawe', 0
db 'meulaboh', 0
db 'pidie jaya', 0
db 'langsa', 0
db 'medan', 0
db 'deli serdang', 0
db 'tanjungbalai', 0
db 'langkat', 0
db 'sibolga', 0
db 'binjai', 0
db 'gunungsitoli', 0
db 'pulau nias', 0
db 'balige', 0
db 'pematangsiantar', 0
db 'padangsidempuan', 0
db 'padang', 0
db 'bukittinggi', 0
db 'agam', 0
db 'padang pariaman', 0
db 'pulau mentawai', 0
db 'padangpanjang', 0
db 'singkarak', 0
db 'sawahlunto', 0
db 'solok', 0
db 'payakumbuh', 0
db 'pekanbaru', 0
db 'dumai', 0
db 'siak', 0
db 'batam', 0
db 'tanjungpinang', 0
db 'bintan', 0
db 'kepulauan natuna', 0
db 'lingga', 0
db 'jambi', 0
db 'kerinci', 0
db 'bengkulu', 0
db 'palembang', 0
db 'prabumulih', 0
db 'muara enim', 0
db 'ogan ilir', 0
db 'bangka belitung', 0
db 'pangkalpinang', 0
db 'manggar', 0
db 'bandar lampung', 0
db 'kota bumi', 0
db 'mesuji', 0
db 'kota metro', 0
db 'pontianak', 0
db 'singkawang', 0
db 'ketapang', 0
db 'sambas', 0
db 'sukadana', 0
db 'sanggau', 0
db 'kuala kapuas', 0
db 'palangkaraya', 0
db 'buntok', 0
db 'sampit', 0
db 'pangkalan bun', 0
db 'banjarmasin', 0
db 'banjarbaru', 0
db 'martapura', 0
db 'kotabaru', 0
db 'samarinda', 0
db 'balikpapan', 0
db 'kutai kartanegara', 0
db 'bontang', 0
db 'penajam', 0
db 'tarakan', 0
db 'tanjung selor', 0
db 'nunukan', 0
db 'pulau miangas', 0
db 'manado', 0
db 'tondano', 0
db 'bolaang mongondow', 0
db 'tomohon', 0
db 'gorontallo', 0
db 'limboto', 0
db 'boalemo', 0
db 'palu', 0
db 'poso', 0
db 'kendari', 0
db 'buton', 0
db 'bau bau', 0
db 'bone', 0
db 'pangkajene', 0
db 'pinrang', 0
db 'bantaeng', 0
db 'makassar', 0
db 'sinjai', 0
db 'parepare', 0
db 'bulukumba', 0
db 'mamuju', 0
db 'mamasa', 0
db 'polewali mandar', 0
db 'majene', 0
db 'denpasar', 0
db 'badung', 0
db 'bangli', 0
db 'singaraja', 0
db 'jembrana', 0
db 'klungkung', 0
db 'nusa dua', 0
db 'tabanan', 0
db 'gianyar', 0
db 'pulau lombok', 0
db 'mataram', 0
db 'bima', 0
db 'dompu', 0
db 'pulau sumbawa', 0
db 'kepulauan flores', 0
db 'alor', 0
db 'ende', 0
db 'kupang', 0
db 'maumere', 0
db 'labuan bajo', 0
db 'larantuka', 0
db 'manggarai', 0
db 'lewoleba', 0
db 'atambua', 0
db 'pulau rote', 0
db 'ternate', 0
db 'pulau morotai', 0
db 'sofifi', 0
db 'halmahera', 0
db 'tidore', 0
db 'sanana', 0
db 'ambon', 0
db 'kepulauan aru', 0
db 'tual', 0
db 'pulau buru', 0
db 'saumlaki', 0
db 'pulau seram', 0
db 'manokwari', 0
db 'waisai', 0
db 'kaimana', 0
db 'fakfak', 0
db 'sorong', 0
db 'biak', 0
db 'timika', 0
db 'sentani', 0
db 'nabire', 0
db 'merauke', 0
db 'puncak jayawijaya', 0
db 'jayapura', 0
db 'asmat', 0
db 'raja ampat', 0
db 'wamena', 0



; ------------------------------------------------------------------

