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
player_1_score: db 0      
player_2_score: db 0      
footer_text: db '23F-0605, 23F-0707, 23F-0849', 0
footer_length: dw 28
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
mov [paddle_2_pos], al
mov al, 0x4D
mov [paddle_2_pos+1], al
popa
ret

draw:
call delay
call clrscr
call draw_scores 
call print_ball
call print_paddle_1
call print_paddle_2
call print_footer         
ret

logic:
call check_winner 
call check_reflection
call move_ball
call check_for_char
jz skip
call move_paddle
skip:
ret

print_footer:
pusha
mov ah, 0x13
mov al, 1
mov bh, 0
mov bl, 7
mov dx, 0x1901
mov bp, footer_text
mov cx, [footer_length]
int 0x10
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
cmp byte [ball_position+1], 1
jle player_2_point
cmp byte [ball_position+1], 79    
jae player_1_point
jmp reset_ball

player_1_point:
inc byte [player_1_score]
jmp reset_ball

player_2_point:
inc byte [player_2_score]

reset_ball:
mov byte [ball_position], 12   
mov byte [ball_position+1], 40
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
mov ax, 0xB800  
mov es, ax

mov di, 0     
mov al, [player_1_score]
add al, '0'   
mov ah, 0x07  
stosw 

mov di, 158          
mov al, [player_2_score]
add al, '0'          
mov ah, 0x07         
stosw 

pop es
popa
ret

move_paddle:
cmp ah , 0x11
je mov_paddle_1_up
cmp ah , 0x1F
je mov_paddle_1_down
cmp ah , 0x48
je mov_paddle_2_up
cmp ah , 0x50
je mov_paddle_2_down
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
return:
mov ah, 0
int 0x16
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
cmp byte [player_1_score], 5 
jne check_player_2
call display_winner_message_1
jmp game_over

check_player_2:
cmp byte [player_2_score], 5
jne return_winner_check
call display_winner_message_2
jmp game_over

return_winner_check:
popa
ret

display_winner_message_1:
pusha
mov ah, 0x13
mov al, 1
mov bh, 0
mov bl, 7
mov dx, 0x0C14
mov bp, winner_message_1
mov cx, [winner_length_1]
int 0x10
popa
ret

display_winner_message_2:
pusha
mov ah, 0x13
mov al, 1
mov bh, 0
mov bl, 7
mov dx, 0x0C14
mov bp, winner_message_2
mov cx, [winner_length_2]
int 0x10
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