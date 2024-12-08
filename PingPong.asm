[org 0x0100]
jmp start
paddle_1: db '   '
paddle_2: db '   '
paddle_1_pos: db 0,0
paddle_2_pos: db 0,0
wall_top: db ' '
ball: db ' '
ball_position: db 0,0
ball_position_change: db 0,0
player_1_score: db 0      ; Score for Player 1
player_2_score: db 0      ; Score for Player 2
footer_text: db 'Aman: 23F-0605, Ahmad: 23F-0707, Farquleet: 23F-0849', 0
footer_length: dw 52
winner_message_1: db 'Player 1 Wins!', 0
winner_length_1: dw 14
winner_message_2: db 'Player 2 Wins!', 0
winner_length_2: dw 14

initialize:
pusha
call initial_clr
call print_wall
mov byte[ball_position_change], 1
mov byte[ball_position_change+1], 1
mov al, 0x0C
mov [ball_position], al
mov al, 0x28
mov [ball_position+1], al
mov al, 0x0B
mov [paddle_1_pos], al
mov al, 0x2 
mov [paddle_1_pos+1], al
mov al, 0x0B
mov [paddle_2_pos], a
mov al, 0x4D
mov [paddle_2_pos+1], al
popa
ret

draw:
    call delay
    call clrscr
    call draw_scores          ; Draw the scores at the top corners
    call print_ball
    call print_paddle_1
    call print_paddle_2
    call print_footer         ; Add footer text
    ret

logic:
    call check_winner              ; Check if a player has won
    call check_reflection
    call move_ball
    call check_for_char
    jz skip
    call move_paddle
skip:
    ret

print_footer:
    pusha
    push es
    mov ax, 0xB800          ; Set ES to video memory segment
    mov es, ax
    mov di, 3840            ; Start of the last line (row 25)
    
    ; String "23F-0605, 23F-0707, 23F-0849"
    mov si, footer_text
    mov cx, [footer_length]
    
print_footer_loop:
    lodsb                   ; Load a byte from DS:SI
    mov ah, 0x07            ; Attribute byte (white text)
    stosw                   ; Write character to video memory
    loop print_footer_loop  ; Repeat for all characters

    pop es
    popa
    ret

move_ball:
pusha
mov al, [ball_position_change]
add [ball_position], al
mov al, [ball_position_change+1]
add [ball_position+1], al
popa
ret

check_reflection:
pusha
mov ah, [ball_position]
mov al, [ball_position+1]
add ah, [ball_position_change]
add al, [ball_position_change+1]
mov dl, [paddle_1_pos+1]
add dl, 1
cmp al, dl
jne no_left
mov dh, [paddle_1_pos]
sub dh, 1
cmp dh, ah
je left_collision
add dh, 1
cmp dh, ah
je left_collision
add dh, 1
cmp dh, ah
je left_collision

no_left:
mov dl, [paddle_2_pos+1]
sub dl, 1
cmp al, dl
jne no_right
mov dh, [paddle_2_pos]
sub dh, 1
cmp dh, ah
je right_collision
add dh, 1
cmp dh, ah
je right_collision
add dh, 1
cmp dh, ah
je right_collision

no_right:
cmp ah, 1
jne no_up
jmp up_collision 

no_up:
cmp ah, 24
jne no_down
jmp down_collision

no_down:
cmp al, 1
jne no_left_wall
jmp reset

no_left_wall:
cmp al, 79
jne return4
jmp reset

reset:
    ; Check which side the ball went out on
    cmp byte [ball_position+1], 2      ; Left side
    jle player_2_point
    cmp byte [ball_position+1], 78     ; Right side
    jae player_1_point
    jmp reset_ball

player_1_point:
    inc byte [player_1_score]          ; Increment Player 1's score
    jmp reset_ball

player_2_point:
    inc byte [player_2_score]          ; Increment Player 2's score
    jmp reset_ball

reset_ball:
    mov byte [ball_position], 12       ; Reset ball to center row
    mov byte [ball_position+1], 40     ; Reset ball to center column
    jmp return3

return4:
jmp return3

left_collision:
cmp byte[ball_position_change],1
je left_diagonal_down
jmp right_diagonal_up
right_collision:
cmp byte[ball_position_change],1
je right_diagonal_down
jmp left_diagonal_up
up_collision:   
cmp byte[ball_position_change+1],1
je left_diagonal_down
jmp right_diagonal_down
down_collision:
cmp byte[ball_position_change+1],1
je right_diagonal_up
jmp left_diagonal_up
right_diagonal_up:
mov byte[ball_position_change],-1
mov byte[ball_position_change+1],1
jmp return3
right_diagonal_down:
mov byte[ball_position_change],1
mov byte[ball_position_change+1],-1
jmp return3
left_diagonal_up:
mov byte[ball_position_change],-1
mov byte[ball_position_change+1],-1
jmp return3
left_diagonal_down:
mov byte[ball_position_change],1
mov byte[ball_position_change+1],1
jmp return3
return3:
popa
ret

draw_scores:
    pusha
    push es
    mov ax, 0xB800          ; Set ES to video memory segment
    mov es, ax

    ; Draw Player 1 (left) score
    mov di, 0               ; Top-left corner
    mov al, [player_1_score]
    add al, '0'             ; Convert numeric value to ASCII
    mov ah, 0x17            ; Attribute byte (white text)
    stosw                   ; Write the score to video memory

    ; Draw Player 2 (right) score
    mov di, 158             ; Top-right corner (80 * 2 - 2 = 158)
    mov al, [player_2_score]
    add al, '0'             ; Convert numeric value to ASCII
    mov ah, 0x20            ; Attribute byte (white text)
    stosw                   ; Write the score to video memory

    pop es
    popa
    ret


pause_play:

pause_game:
call check_for_char
jz pause_game
mov ah, 0
int 0x16
cmp al, 'p'
jne pause_game
return_pause:
ret

move_paddle:
mov ah, 0
int 0x16
cmp ah , 0x11
je mov_paddle_1_up
cmp ah , 0x1F
je mov_paddle_1_down
cmp ah , 0x48
je mov_paddle_2_up
cmp ah , 0x50
je mov_paddle_2_down
cmp al, 'p'
je pause_label
jmp return
mov_paddle_1_up:
mov dl, [paddle_1_pos]
sub dl, 1
cmp dl, 1
je return
sub byte[paddle_1_pos],1
jmp return
mov_paddle_1_down:
mov dl, [paddle_1_pos]
add dl, 2
cmp dl, 24
je return
add byte[paddle_1_pos],1
jmp return
mov_paddle_2_up:
mov dl, [paddle_2_pos]
sub dl, 1
cmp dl, 1
je return
sub byte[paddle_2_pos],1
jmp return
mov_paddle_2_down:
mov dl, [paddle_2_pos]
add dl, 2
cmp dl, 24
je return
add byte[paddle_2_pos],1
jmp return
pause_label:
call pause_play
jmp return
return:
ret

check_for_char:
mov ah, 01
int 0x16
ret

initial_clr:
pusha
push es
mov ax, 0xb800
mov es, ax ; point es to video base
mov ax, 0x0720 ; space char in normal attribute
mov cx, 2000 ; number of screen locations
cld ; auto increment mode
rep stosw ; clear the whole screen
pop es
popa
ret

clrscr:
pusha
push es
mov ax, 0xb800
mov es, ax ; point es to video base
; mov ax, 0x0720 ; space char in normal attribute
; mov cx, 2000 ; number of screen locations
; cld ; auto increment mode
; rep stosw ; clear the whole screen
mov si, 0
mov bx, 160
loop_clr:
    mov di, 2
    loop_clr_inner:
    mov word[es:di+bx], 0x0720
    add di, 2
    cmp di, 158
    jl loop_clr_inner
add si, 1
add bx, 160
cmp si, 23
jl loop_clr
pop es
popa
ret

print_wall:
pusha
push es
mov ax, 0xb800
mov es, ax
mov bx, 0
outerloop_wall:
mov di, 0
loop_wall:
cmp bx, 0
je print
cmp bx, 3840
je print
cmp di, 0
je print
cmp di, 158
je print
jmp return2
print:
mov word[es:di + bx], 0xC720
jmp return2
return2:
add di, 2
cmp di, 160
jl loop_wall
add bx, 160
cmp bx, 4000
jl outerloop_wall
pop es
popa
ret

print_ball:
pusha
mov dh, [ball_position]
mov dl, [ball_position+1]
mov bp, paddle_1
add bp, bx
mov ah, 0x13 ; service 13 - print string
mov al, 1 ; subservice 01 – update cursor
mov bh, 0 ; output on page 0
; mov bl, 7 ; normal attrib
mov bx, 0xF0
mov cx, 1 ; length of string
push cs
pop es ; segment of string
int 0x10
popa
ret

print_paddle_1:
pusha
mov cx, 3
mov bx, 0
loop_print:
pusha
mov dh, [paddle_1_pos]
mov dl, [paddle_1_pos+1]
sub dh, 1
add dh, bl
mov bp, paddle_1
add bp, bx
mov ah, 0x13 ; service 13 - print string
mov al, 1 ; subservice 01 – update cursor
; mov bh, 0 ; output on page 0
; mov bl, 7 ; normal attrib
mov bx, 0x97
mov cx, 1 ; length of string
push cs
pop es ; segment of string
int 0x10
popa
add bx,1
loop loop_print
popa
ret

print_paddle_2:
pusha
mov cx, 3
mov bx, 0
loop_print2:
pusha
mov dh, [paddle_2_pos]
mov dl, [paddle_2_pos+1]
sub dh, 1
add dh, bl
mov bp, paddle_2
add bp, bx
mov ah, 0x13 ; service 13 - print string
mov al, 1 ; subservice 01 – update cursor
mov bx, 0xA7
mov cx, 1 ; length of string
push cs
pop es ; segment of string
int 0x10
popa
add bx,1
loop loop_print2
popa
ret

check_winner:
    pusha
    cmp byte [player_1_score], 5    ; Check if Player 1 has 5 points
    jne check_player_2
    call display_winner_message_1
    jmp game_over

check_player_2:
    cmp byte [player_2_score], 5    ; Check if Player 2 has 5 points
    jne return_winner_check
    call display_winner_message_2
    jmp game_over

return_winner_check:
    popa
    ret

display_winner_message_1:
    pusha
    push es
    mov ax, 0xB800                 ; Set ES to video memory segment
    mov es, ax
    mov di, 1960
    mov si, winner_message_1
    mov cx, [winner_length_1]
print_message_1:
    lodsb                          ; Load a byte from DS:SI
    mov ah, 0x47                   ; Attribute byte (white text)
    stosw                          ; Write character to video memory
    loop print_message_1
    pop es
    popa
    ret

display_winner_message_2:
    pusha
    push es
    mov ax, 0xB800                 ; Set ES to video memory segment
    mov es, ax
    mov di, 1960
    mov si, winner_message_2
    mov cx, [winner_length_2]
print_message_2:
    lodsb                          ; Load a byte from DS:SI
    mov ah, 0x47                   ; Attribute byte (white text)
    stosw                          ; Write character to video memory
    loop print_message_2
    pop es
    popa
    ret

game_over:
popa
add sp, 2
mov ax, 0x4c00
int 0x21

delay:
pusha
mov cx, 0xFFFF
loop_sleep:
loop loop_sleep
mov cx, 0xFFFF
loop_sleep2:
loop loop_sleep2
mov cx, 0xFFFF
loop_sleep3:
loop loop_sleep3
popa
ret

start:
call initialize
infinite_loop:
call draw
call logic
jmp infinite_loop
mov ax, 0x4c00
int 0x21 