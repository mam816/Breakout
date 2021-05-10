# Makayla Miles
# mam816
# I have a function for wait_for_start, but I think the way I had went about doing certain parts of the project
# it would make my game paddle vigourously move back and forth, so I just commented it out in my main and play_game
 
.include "display_2211_0822.asm"

# change these to whatever you like.
.eqv BALL_COLOR COLOR_WHITE
.eqv PADDLE_COLOR COLOR_YELLOW 

.eqv BLOCK_WIDTH  8 # pixels wide
.eqv BLOCK_HEIGHT 4 # pixels tall

.eqv BOARD_BLOCK_WIDTH    8 # 8 blocks wide
.eqv BOARD_BLOCK_HEIGHT   6 # 6 blocks tall
.eqv BOARD_MAX_BLOCKS    48 # = BOARD_BLOCK_WIDTH * BOARD_BLOCK_HEIGHT
.eqv BOARD_BLOCK_BOTTOM  24 # = BLOCK_HEIGHT * BOARD_BLOCK_HEIGHT
                            # (the Y coordinate of the bottom of the blocks)

.eqv PADDLE_WIDTH  12 # pixels wide
.eqv PADDLE_HEIGHT  2 # pixels tall
.eqv PADDLE_Y      54 # fixed Y coordinate
.eqv PADDLE_MIN_X   0 # furthest left the left side can go
.eqv PADDLE_MAX_X  52 # furthest right the *left* side can go (= 64 - PADDLE_WIDTH)

.data
	off_screen:    .word 0 # bool, set to 1 when ball goes off-screen.
	paddle_x:      .word 0 # paddle's X coordinate
	paddle_vx:     .word 0 # paddle's X velocity (optional)

	ball_x:        .word 0 # ball's coordinates
	ball_y:        .word 0
	ball_vx:       .word 0 # ball's velocity
	ball_vy:       .word 0
	ball_old_x:    .word 0 # used during collision to back the ball up when it collides
	ball_old_y:    .word 0

	# the blocks to be broken! these are just colors from constants.asm. 0 is empty.
	blocks:
	.byte 0  2  3   4   5   6   7   0
	.byte 0  15 14  13  12  5   1   0
	.byte 0  9  1   2   3   4   2   0
	.byte 0  2  5   6   8   9   12  0
	.byte 0  1  2   3   4   5   6   0
	.byte 0  9  10  11  12  13  14  0
.text

# -------------------------------------------------------------------------------------------------

.globl main
main:
	_loop:
		# TODO:
		 jal setup_paddle
		 jal setup_ball
		 #jal wait_for_start
		 jal play_game		 
	jal count_blocks_left
	bnez v0, _loop

	# shorthand for li v0, 10; syscall
	syscall_exit

# -------------------------------------------------------------------------------------------------

# returns number of blocks in blocks array that are not 0.
count_blocks_left:
enter s0, s1
	# TODO: actually implement this!
	li t1, 0
	li v0, 0
	_loop:
		bge t1, BOARD_MAX_BLOCKS, _endif
		lb t0, blocks(t1)
		beq t0, 0, _endif_if_loop
			add v0, v0, 1
		        add t1, t1, 1
			j _loop
			
		_endif_if_loop:
			add t1, t1, 1
			j _loop
	        _endif:
		
leave s0, s1

 
setup_paddle:
enter 
	 
        li a0, 0
        lw t0, paddle_x
        li a1, PADDLE_MAX_X
        sub a1, a1, PADDLE_MIN_X
        move a0, a1
        syscall_rand_range
        add t0, v0, PADDLE_MIN_X
        sw t0, paddle_x
        
leave       
        
play_game:
enter 
	_loop:
		jal draw_paddle		
		jal draw_ball		
		jal display_update_and_clear		
		jal wait_for_next_frame		
		jal check_input					
		jal draw_blocks
		jal show_blocks_left
		#jal wait_for_start
		jal check_off_screen
		jal save_x_y_coords
		jal move_ball_x
		jal move_ball_y	
		lw t0, off_screen
		bne t0, 0, _return
		jal count_blocks_left	       	
		bne v0, 0, _loop 
	_return:	
leave 
        
draw_paddle:
enter 
	li t3, PADDLE_MAX_X
	li t4 , PADDLE_MIN_X
	lw a0, paddle_x
	li a1, PADDLE_Y
	li a3, COLOR_YELLOW
	jal display_set_pixel
	li a2, PADDLE_WIDTH
	li a3, PADDLE_HEIGHT
	li v1, 3
	jal display_fill_rect
leave       
	
check_input:
enter 
       
        _check_L:                
        	lw t1, DISPLAY_KEYS
        	and  t1, t1, KEY_L
        	beq t1, 0, _endif_L
        	lw t0, paddle_x
        	sub t0,t0,1
        	sw t0, paddle_x
        	move v0,t0
                jal input_get_keys_held
                lw t2, ball_vx
                lw t3, ball_vy
                bne t2, 0, _not_0
                jal intialize_velocities
                
        _not_0:  
        	lw t0, paddle_x
                mini t0, t0, PADDLE_MAX_X
                maxi t0, t0, PADDLE_MIN_X
                sw t0, paddle_x
                	
	_endif_L:
                
			
				
        _check_R:
        	lw t1, DISPLAY_KEYS
        	and  t1, t1, KEY_R
        	beq t1, 0, _endif_R
        	lw t0, paddle_x
        	add t0,t0,1
        	sw t0, paddle_x
        	move v0,t0				
        	jal input_get_keys_held
        	lw t2, ball_vx
        	bne t2, 0, _not_0_2
                jal intialize_velocities
                
        _not_0_2:             
        	lw t0, paddle_x
        	mini t0, t0 PADDLE_MAX_X
        	maxi t0, t0, PADDLE_MIN_X
        	sw t0, paddle_x
        	    	
	_endif_R:
       	
		
leave 
	
       		
draw_blocks:   	       
enter s0, s1
    li s0, 0
    _row:
        
        li s1, 0

        _column:
            
              la  t0, blocks             
              mul t6, s0, BOARD_BLOCK_WIDTH          
              mul t7, s1, 1            
              add t0, t0, t6
              add t0, t0, t7 
              mul a0, s1, BLOCK_WIDTH 
              mul a1, s0, BLOCK_HEIGHT
              li a2, BLOCK_WIDTH
              li a3, BLOCK_HEIGHT
              lb v1, (t0) 
              jal display_fill_rect
              # Increment s1, if it's less than BBW, loop
              add s1, s1, 1
              blt s1, BOARD_BLOCK_WIDTH, _column
        
        # Increment s0, if it's less than BBH, loop
        add s0, s0, 1
        blt s0, BOARD_BLOCK_HEIGHT, _row
                   
        
leave s0, s1

show_blocks_left:
enter 
        jal count_blocks_left       
        li a0, 3
        li a1, 58
        move a2, v0
        jal display_draw_int 
leave 	 

setup_ball:
enter 
        li a0, 0
        lw t0, ball_x
        lw t1, paddle_x
        li t2, PADDLE_Y
        lw t3, ball_y
        lw t4, off_screen
        li t4, 0
        sw t4, off_screen
        add t1, t1, 5
        sub t2, t2, 1
        sw t1, ball_x
        sw t2, ball_y

        lw t1, ball_vx
		lw t2, ball_vy
		li t1, 0
		li t2, 0
		sw t1, ball_vx
		sw t2, ball_vy
        
       
leave 

draw_ball:
enter 
        lw t2, ball_x
        lw t3, ball_y
	move a0, t2
	move a1, t3
	li a2, 7
	jal display_set_pixel
	
	
leave 

wait_for_start:
enter 
	lw t0, ball_x
	lw t1, ball_y
	lw t2, ball_vx
	lw t3, ball_vy
	add t0, t0, t2
	add t1, t1, t3
	sw t0, ball_x
	sw t1, ball_y	        	 	 
leave 

intialize_velocities:
enter
	lw t2, ball_vx
	lw t3, ball_vy
	li t2, 1
        li t3, -1
        sw t2, ball_vx
        sw t3, ball_vy    
leave


move_ball_x:
enter
	lw t0, ball_x
	lw t1, ball_vx
	add t0, t0, t1
	sw t0, ball_x	
	ble t0, 0, _wall_x
        bge t0, 64, _wall_x
	j _check_blocks_x
	_check_blocks_x:
		jal destroy_blocks
		beq v0, 0, _return
			jal change_vle_x			
		j _return
	_wall_x:
		jal change_vle_x
	        
	_return:	
leave


move_ball_y:
enter
	lw t0, ball_y
	lw t1, ball_vy
	add t0, t0, t1
	sw t0, ball_y
	blt t0, 0, _wall_y
	bge t0, 64 , out_of_bounds
	beq t0, PADDLE_Y, _paddle_bounce
	j _check_blocks_y
	_wall_y:
		jal change_vle_y		
		j _endif
	_out_of_bounds_y:
		jal out_of_bounds
		j _endif
	_paddle_bounce:
		lw t0, ball_x
                lw t1, paddle_x
                blt t0, t1, _endif
                add t1, t1, PADDLE_WIDTH
                bgt t0, t1, _endif
                jal change_vle_y
                j _endif
	_check_blocks_y:
		jal destroy_blocks
		beq v0, 0, _endif
			jal change_vle_y
			
_endif:
leave


out_of_bounds:
enter
	li t0, 1
	sw t0, off_screen
	lw t0, ball_old_y
	sw t0, ball_y
leave

change_vle_x:
enter
	lw t0, ball_old_x
	sw t0, ball_x
	lw t0, ball_vx
	neg t0, t0
	sw t0, ball_vx	
leave


change_vle_y:
enter
	lw t0, ball_old_y
	sw t0, ball_y
	lw t0, ball_vy
	neg t0, t0
	sw t0, ball_vy
leave


save_x_y_coords:
enter
	lw t0, ball_x
	lw t1, ball_y
	lw t2, ball_old_x
	lw t3, ball_old_y
	move t2, t0
	move t3, t1
	sw t2, ball_old_x
	sw t3, ball_old_y
leave


check_off_screen:
enter
	lw t0, off_screen
        lw t1, ball_y
        bne t1, 63, _keep_0
    		li t0, 1
    		sw t0, off_screen
    _keep_0:
     
leave

destroy_blocks:
	
enter
	li v0, 0
	lw t0, ball_y
	bgt t0, BOARD_BLOCK_BOTTOM, _return

	div t0, t0, BLOCK_HEIGHT

	lw  t1, ball_x
	div t1, t1, BLOCK_WIDTH

	mul t0, t0, BOARD_BLOCK_WIDTH
	add t1, t1, t0

	lb  t0, blocks(t1)

	beq t0, 0, _return

		sb zero, blocks(t1)
		li v0, 1

	_return:
leave
