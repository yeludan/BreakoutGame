################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Ludan Ye, 1006904325
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    512
# - Display height in pixels:   512
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

##############################################################################
# Mutable Data
##############################################################################
wall_colour_gray: .word 0x808080	# gray colour of the walls
wall_thickness: .word 8				# thickness of the walls (number of pixels * 4)
brick_colour_array: .word 0xff0000, 0x00ff00, 0x0000ff, 0xff0000, 0x00ff00	# brick colour array
brick_width: .word 16				# width of one brick (number of pixels * 4)
brick_height: .word 4				# height of one brick (number of pixels * 4)
num_rows: .word 5					# number of rows of bricks
num_cols: .word 15					# number of columns of bricks
paddle_colour_yellow: .word 0xffff00		# yellow colour of the paddle
paddle_width: .word 20				# width of the paddle (number of pixels * 4)
ball_colour_yellow: .word 0xffff00	# yellow colour of the ball
##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Brick Breaker game.
main:
    # Initialize the game
    addi $s7, $zero, 3 			# $s7 = the number of lives
    jal initialization			# Initialize the black screen of bitmap
    jal draw_walls
    jal draw_bricks
    jal draw_paddle
    jal draw_ball
    add $s1, $zero, $zero 		# $s1 = previous x coordinate of the ball
	add $s2, $zero, $zero 		# $s2 = previous y coordinate of the ball
	add $s3, $zero, 61	 		# $s3 = current x coordinate of the ball
	add $s4, $zero, 32	 		# $s4 = current y coordinate of the ball
	add $a2, $zero, $zero		# $a2 is the counter for speed
	add $a3, $zero, $zero		# $a3 is the counter for time limit
    jal game_loop
    
    Exit:
	li $v0, 10		# terminate the program gracefully
	syscall

# Initialize the black screen of bitmap     
initialization:
	lw $t2, ADDR_DSPL              	# $t2 = base address for bitmap
	add $t3, $zero, $zero			# $t3 = RGB value of black
	add $t9, $t2, $zero				# $t9 stores the current operating position
	initialization_loop:
	addi $t4, $t2, 16384			# $t4 stores the end of the position for initialization
	beq $t9, $t4, end_initialization_loop
	sw $t3 0($t9)
	addi $t9, $t9, 4
	j initialization_loop
	end_initialization_loop:
	jr $ra
	
# Draw the walls
draw_walls:
# $t0 stores the beginning of the drawing position
# $t1 stores the RGB value of the gray colour of the wall
# $t2 stores position offset
# $t3 stores current drawing position
# $t9 stores the row number (top 2 lines excluded)
	addi $sp, $sp, -4
	sw $ra, 0($sp)				# push $ra in the stack
	lw $t0, ADDR_DSPL			# $t0 stores the beginning of the drawing position
	lw $t1, wall_colour_gray	# $t1 stores the RGB value of the gray colour of the wall
	add $t2, $zero, $zero		# $t2 stores position offset
	draw_top_two_lines:
	beq $t2, 512, end_draw_line
	add $t3, $t0, $t2			# $t3 stores current drawing position
	sw $t1, 0($t3)
	addi $t2, $t2, 4
	j draw_top_two_lines
	end_draw_line:
	
	jal draw_vertical_line
	
	addi $t2, $zero, 4
	jal draw_vertical_line
	
	addi $t2, $zero, 244
	jal draw_vertical_line
	
	addi $t2, $zero, 4
	jal draw_vertical_line
	
	lw $ra, 0($sp)				# pop $ra off the stack
	addi $sp, $sp, 4
	jr $ra

# helper function of drawing one vertical line of the wall	
draw_vertical_line:
	add $t9, $zero, $zero		# $t9 stores the row number (top 2 lines excluded)
	add $t0, $t0, $t2			# set $t0 at the first position of vertical line3
	add $t2, $zero, $zero		# set position offset $t2 be zero
	draw_vertical_line2:
	beq $t9, 62, end_draw_vertical_line2
	add $t3, $t0, $t2
	sw $t1, 0($t3)
	addi $t2, $t2, 256
	addi $t9, $t9, 1
	j draw_vertical_line2
	end_draw_vertical_line2:
	jr $ra

# Draw bricks
draw_bricks:
# $t0 stores the beginning of the drawing position
# $t1 stores the address of brick colour array
# $t2 stores the RGB value of this brick line
	addi $sp, $sp, -4
	sw $ra, 0($sp)				# push $ra in the stack
	
	lw $t0, ADDR_DSPL
	addi $t0, $t0, 1032			# $t0 stores the beginning of the drawing position
	la $t1, brick_colour_array	# $t1 stores the address of brick colour array
	lw $t2, 0($t1)				# $t2 stores the RGB value of this brick line
	jal draw_brick_line
	
	lw $t0, ADDR_DSPL
	addi $t0, $t0, 1288			# $t0 stores the beginning of the drawing position
	lw $t2, 4($t1)				# $t2 stores the RGB value of this brick line
	jal draw_brick_line
	
	lw $t0, ADDR_DSPL
	addi $t0, $t0, 1544			# $t0 stores the beginning of the drawing position
	lw $t2, 8($t1)				# $t2 stores the RGB value of this brick line
	jal draw_brick_line
	
	lw $t0, ADDR_DSPL
	addi $t0, $t0, 1800			# $t0 stores the beginning of the drawing position
	lw $t2, 12($t1)				# $t2 stores the RGB value of this brick line
	jal draw_brick_line
	
	lw $t0, ADDR_DSPL
	addi $t0, $t0, 2056			# $t0 stores the beginning of the drawing position
	lw $t2, 16($t1)				# $t2 stores the RGB value of this brick line
	jal draw_brick_line
	
	lw $ra, 0($sp)				# pop $ra off the stack
	addi $sp, $sp, 4
	jr $ra

# helper function of drawing one brick line
draw_brick_line:
# $t3 stores position offset
# $t4 stores current drawing position
# $t5 stores the brick width
# $t6 stores the number of columns
# $t7 stores position offset
	add $t3, $zero, $zero		# $t3 stores position offset
	lw $t5, brick_width			# $t5 stores the brick width
	lw $t6, num_cols			# $t6 stores the number of columns
	mult $t5, $t6
	mflo $t7					# $t7 stores position offset
	draw_one_brick:
	add $t4, $t0, $t3			# $t4 stores current drawing position
	beq $t3, $t7, end_draw_brick_line
	sw $t2, 0($t4)
	sw $t2, 4($t4)
	sw $t2, 8($t4)
	sw $t2, 12($t4)
	add $t3, $t3, $t5
	j draw_one_brick
	end_draw_brick_line:
	jr $ra
	
# Draw paddle
draw_paddle:
# $t0 stores the beginning of the drawing position
# $t1 stores the RGB value of the yellow colour of the paddle
# $t2 stores the position offset
# $t3 stores the drawing position
# $t4 stores the paddel width
# $s0 = position of the first pixel of the paddle (number of pixels * 4)
	lw $t0, ADDR_DSPL
	lw $t4, paddle_width
	addi $t0, $t0, 15992			# $t0 stores the beginning of the drawing position
	add $s0, $t0, $zero				# initialize $s0
	lw $t1, paddle_colour_yellow	# $t1 stores the RGB value of the yellow colour of the paddle
	add $t2, $zero, $zero			# $t2 stores the position offset
	add $t3, $t0, $t2				# $t3 stores the drawing position
	draw_loop:
	beq $t2, $t4, end_draw_loop
	add $t3, $t0, $t2
	sw $t1, 0($t3)
	add $t2, $t2, 4
	j draw_loop
	end_draw_loop:
	jr $ra

# Draw ball
draw_ball:
# $t0 stores the beginning of the drawing position
# $t1 stores the RGB value of the yellow colour of the ball
# $t2 stores the position offset
# $t3 stores the drawing position
# $t4 stores the paddel width
# $s1 = previous x coordinate of the ball
# $s2 = previous y coordinate of the ball
# $s3 = current x coordinate of the ball
# $s4 = current y coordinate of the ball
	lw $t0, ADDR_DSPL
	addi $t0, $t0, 15744			# $t0 stores the beginning of the drawing position
	add $s1, $zero, $zero			# initialize $s1
	add $s2, $zero, $zero			# initialize $s2
	addi $s3, $zero, 61				# initialize $s3
	addi $s4, $zero, 32				# initialize $s4
	lw $t1, ball_colour_yellow		# $t1 stores the RGB value of the yellow colour of the ball
	sw $t1, 0($t0)
	jr $ra
	
game_loop:
# $a2 is the counter for speed
# $a3 is the counter for time limit
# $t0 = base address for keyboard
# $t2 = base address for bitmap display
# Load first word from keyboard into $t8
# Load second word from keyboard into $a0
# $t1 = 1 when a was pressed, 2 when d was pressed
# $s0 = position of the first pixel of the paddle (number of pixels * 4)
# $s1 = previous x coordinate of the ball
# $s2 = previous y coordinate of the ball
# $s3 = current x coordinate of the ball
# $s4 = current y coordinate of the ball
# $t9 = position being checked
# $t7 stores the value of memory address of $t9
# $s5 = 1 when collide with wall, 2 when collide with paddle, 
#		3 when top of the ball collide with brick, 4 when bottom of the ball collide with brick,
#		5 when left of the ball collide with brick, 6 when right of the ball collide with brick,
#		0 no collision happens (priority brick > paddle > wall)
# $s6 = position of brick collided (number of pixels * 4)
# $s7 = the number of lives
	# 1a. Check if key has been pressed
	lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
	lw $t2, ADDR_DSPL              	# $t2 = base address for bitmap
    lw $t8, 0($t0)                  # Load first word from keyboard into $t8
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    b check_collisions
    
    # 1b. Check which key has been pressed
    keyboard_input:                 # A key is pressed
    lw $a0, 4($t0)                  # Load second word from keyboard into $a0
    beq $a0, 0x71, respond_to_Q     # Check if the key q was pressed
    beq $a0, 0x70, respond_to_p     # Check if the key p was pressed
    beq $a0, 0x61, respond_to_a		# Check if the key a was pressed
    beq $a0, 0x64, respond_to_d		# Check if the key d was pressed
    add $t1, $zero, $zero			# if none of q, a, or d was pressed, set $t1 = 0
    b check_collisions
    
    respond_to_Q:
    addi $t3, $zero, 0x00ff00		# $t3 = RGB value of green
	add $t9, $t2, $zero				# $t9 stores the current operating position
	quit_loop:
	addi $t4, $t2, 16384			# $t4 stores the end of the position for initialization
	beq $t9, $t4, end_quit_loop
	sw $t3 0($t9)
	addi $t9, $t9, 4
	j quit_loop
	end_quit_loop:
	li $v0, 10                      # Quit gracefully
	syscall
	
	respond_to_p:
	check_any_key_pressed_loop:
	lw $t8, 0($t0)                  # Load first word from keyboard into $t8
    bne $t8, 1, check_any_key_pressed_loop      	# If first word 1, a key is pressed
    beq $a0, 0x71, respond_to_Q
    end_check_any_key_pressed_loop:
    add $t1, $zero, $zero
    b check_collisions
	
	respond_to_a:
	addi $t1, $zero, 1				# $t1 = 1 when a was pressed
	b check_collisions
	respond_to_d:
	addi $t1, $zero, 2				# $t1 = 2 when d was pressed
    
    # 2a. Check for collisions
    check_collisions:
    beq $s3, 62, next_life			# when ball reaches the bottom of the screen, you lose one live, start with the next live
    b check_collision_with_bricks
    
	next_life:						# Initialize paddle and ball
	addi $s7, $s7, -1				# lose one life
	beq $s7, $zero, game_over		# if the number of lives is 0, game over and restart the game
	addi $t9, $t2, 15880			# $t9 stores the current operating position
	add $t3, $zero, $zero			# $t3 = RGB value of black
	next_life_loop:
	addi $t4, $t2, 16120			# $t4 stores the end of the position for initialization
	beq $t9, $t4, end_next_life_loop
	sw $t3 0($t9)
	addi $t9, $t9, 4
	j next_life_loop
	end_next_life_loop: 
	jal draw_paddle
	jal draw_ball
	add $s1, $zero, $zero 			# $s1 = previous x coordinate of the ball
	add $s2, $zero, $zero 			# $s2 = previous y coordinate of the ball
	add $s3, $zero, 61	 			# $s3 = current x coordinate of the ball
	add $s4, $zero, 32	 			# $s4 = current y coordinate of the ball
	add $a2, $zero, $zero			# $a2 is the counter for loop
	b update_locations
	
	game_over:
	addi $t3, $zero, 0x00ff00		# $t3 = RGB value of green
	add $t9, $t2, $zero				# $t9 stores the current operating position
	game_over_loop:
	addi $t4, $t2, 16384			# $t4 stores the end of the position for initialization
	beq $t9, $t4, end_game_over_loop
	sw $t3 0($t9)
	addi $t9, $t9, 4
	j game_over_loop
	end_game_over_loop:
	restart_loop:
	lw $t8, 0($t0)                  # Load first word from keyboard into $t8
    bne $t8, 1, restart_loop  	# If first word 1, a key is pressed
    lw $a0, 4($t0)
    beq $a0, 0x71, respond_to_Q		# check_r_pressed
    beq $a0, 0x72, main				# restart the game
    b restart_loop
	
    check_collision_with_bricks:
    jal translate_coordinate_into_position
    addi $t9, $t9, -256				# check if the brick on the top of the ball is collided
    lw $t7, 0($t9)
    beq $t7, 0, next
    beq $t7, 0xffff00, next
    bne $t7, 0x808080, top_collide_with_brick
    next: addi $t9, $t9, 252		# check if the brick on the left of the ball is collided
    lw $t7, 0($t9)
    beq $t7, 0, next1
    beq $t7, 0xffff00, next1
    bne $t7, 0x808080, left_collide_with_brick
    next1: addi $t9, $t9, 8			# check if the brick on the right of the ball is collided
    lw $t7, 0($t9)
    beq $t7, 0, next2
    beq $t7, 0xffff00, next2
    bne $t7, 0x808080, right_collide_with_brick
    next2: addi $t9, $t9, 252		# check if the brick on the bottom of the ball is collided
    lw $t7, 0($t9)
    beq $t7, 0, next3
    beq $t7, 0xffff00, next3
    bne $t7, 0x808080, bottom_collide_with_brick
    next3: addi $t9, $t9, -4		# check if the brick on the bottom left corner of the ball is collided
    lw $t7, 0($t9)
    beq $t7, 0, next4
    beq $t7, 0xffff00, next4
    bne $t7, 0x808080, top_collide_with_brick
    next4: addi $t9, $t9, -512		# check if the brick on the top left corner of the ball is collided
    lw $t7, 0($t9)
    beq $t7, 0, next5
    beq $t7, 0xffff00, next5
    bne $t7, 0x808080, top_collide_with_brick
    next5: addi $t9, $t9, 8			# check if the brick on the top right corner of the ball is collided
    lw $t7, 0($t9)
    beq $t7, 0, next6
    beq $t7, 0xffff00, next6
    bne $t7, 0x808080, bottom_collide_with_brick
    next6: addi $t9, $t9, 256		# check if the brick on the bottom right corner of the ball is collided
    lw $t7, 0($t9)
    beq $t7, 0, check_collision_with_paddle
    beq $t7, 0xffff00, check_collision_with_paddle
    bne $t7, 0x808080, bottom_collide_with_brick
    b check_collision_with_paddle
    
    top_collide_with_brick:
    addi $s5, $zero, 3				# $s5 = 3 when top collide with brick
    add $s6, $t9, $zero 			# $s6 = position of brick collided (number of pixels * 4)
    b update_locations
    
    bottom_collide_with_brick:
    addi $s5, $zero, 4				# $s5 = 4 when bottom collide with brick
    add $s6, $t9, $zero 			# $s6 = position of brick collided (number of pixels * 4)
    b update_locations
    
    left_collide_with_brick:
    addi $s5, $zero, 5				# $s5 = 5 when left collide with brick
    add $s6, $t9, $zero 			# $s6 = position of brick collided (number of pixels * 4)
    b update_locations
    
    right_collide_with_brick:
    addi $s5, $zero, 6				# $s5 = 6 when right collide with brick
    add $s6, $t9, $zero 			# $s6 = position of brick collided (number of pixels * 4)
    b update_locations
    
    check_collision_with_paddle:
    bne $s3, 61, check_collision_with_walls
    
    sll $t9, $s4, 2
    add $t9, $t2, $t9
    add $t9, $t9, 15616 
    add $t9, $t9, 256				# $t9 = position being checked
    lw $t7, 0($t9)					# $t7 stores the value of memory address of $t9
    bne $t7, 0, collide_with_paddle
    add $t9, $t9, -4
    lw $t7, 0($t9)
    bne $t7, 0, collide_with_paddle
    add $t9, $t9, 8
    lw $t7, 0($t9)
    bne $t7, 0, collide_with_paddle
    b check_collision_with_walls
    
    collide_with_paddle:
    addi $s5, $zero, 2				# $s5 = 2 when collide with paddle
    b update_locations
    
    check_collision_with_walls:
    beq $s4, 2, collide_with_walls
    beq $s4, 61, collide_with_walls
    beq $s3, 2, collide_with_walls
    add $s5, $zero, $zero			# $s5 = 0 no collision happens
    b update_locations
    
    collide_with_walls:
    addi $s5, $zero, 1				# $s5 = 1 when collide with wall
    
	# 2b. Update locations (paddle, ball)
	update_locations:
	lw $t2, ADDR_DSPL
	update_paddle:
	bne $t8, 1, update_ball
	beq $t1, 1, check_left_most
	beq $t1, 2, check_right_most
	b update_ball
	check_left_most: 
	add $t6, $t2, 15880
	beq $s0, $t6, update_ball
	addi $s0, $s0, -4
	b update_ball
	check_right_most:
	add $t6, $t2, 16100
	beq $s0, $t6, update_ball
	addi $s0, $s0, 4
	b update_ball
	
	update_ball:
	beq $s1, 0, move_top_right		# when ball is at initial position
	beq $s5, 3, top_check_y			# when top side of the ball collided with brick
	beq $s5, 4, bottom_check_y		# when bottom side of the ball collided with brick
	beq $s5, 5, move_bottom_right	# when left side of the ball collided with brick
	beq $s5, 6, move_bottom_left	# when right side of the ball collided with brick
	beq $s5, 2, bottom_check_y		# when ball collided with paddle
	beq $s4, 2, check_previous_x_left_wall		# when ball collided with left wall
	beq $s4, 61, check_previous_x_right_wall	# when ball collided with right wall
	beq $s3, 2, top_check_y			# when ball collided with top wall
	b update_ball_no_collision		# no collision happened
	
	top_check_y:
	beq $s4, 2, move_bottom_right
	beq $s4, 61, move_bottom_left
	sub $t6, $s2, $s4
	blez $t6, move_bottom_right
	b move_bottom_left
	
	bottom_check_y:
	beq $s4, 2, move_top_right
	beq $s4, 61, move_top_left
	sub $t6, $s2, $s4
	blez $t6, move_top_right
	b move_top_left
	
	check_previous_x_left_wall:
	sub $t6, $s1, $s3
	blez $t6, move_bottom_right
	b move_top_right
	
	check_previous_x_right_wall:
	sub $t6, $s1, $s3
	blez $t6, move_bottom_left
	b move_top_left
	
	move_top_right:
	li $v0, 42 
	li $a0, 0 
	li $a1, 3 
	syscall
	beq $a0, 0, move_top_right_45_degree
	beq $a0, 1, move_top_right_60_degree
	b move_top_right_30_degree
	
	move_top_right_45_degree:
	add $s1, $s3, $zero
	add $s2, $s4, $zero
	addi $s3, $s3, -1
	addi $s4, $s4, 1
	b draw_screen
	
	move_top_right_60_degree:
	add $s1, $s3, $zero
	add $s2, $s4, $zero
	addi $s3, $s3, -2
	addi $s4, $s4, 1
	b draw_screen
	
	move_top_right_30_degree:
	add $s1, $s3, $zero
	add $s2, $s4, $zero
	addi $s3, $s3, -1
	addi $s4, $s4, 2
	b draw_screen
	
	move_top_left:
	li $v0, 42 
	li $a0, 0 
	li $a1, 3 
	syscall
	beq $a0, 0, move_top_left_45_degree
	beq $a0, 1, move_top_left_60_degree
	b move_top_left_30_degree
	
	move_top_left_45_degree:
	add $s1, $s3, $zero
	add $s2, $s4, $zero
	addi $s3, $s3, -1
	addi $s4, $s4, -1
	b draw_screen
	
	move_top_left_60_degree:
	add $s1, $s3, $zero
	add $s2, $s4, $zero
	addi $s3, $s3, -2
	addi $s4, $s4, -1
	b draw_screen
	
	move_top_left_30_degree:
	add $s1, $s3, $zero
	add $s2, $s4, $zero
	addi $s3, $s3, -1
	addi $s4, $s4, -2
	b draw_screen
	
	move_bottom_right:
	li $v0, 42 
	li $a0, 0 
	li $a1, 3 
	syscall
	beq $a0, 0, move_bottom_right_45_degree
	beq $a0, 1, move_bottom_right_60_degree
	b move_bottom_right_30_degree
	
	move_bottom_right_45_degree:
	add $s1, $s3, $zero
	add $s2, $s4, $zero
	addi $s3, $s3, 1
	addi $s4, $s4, 1
	b draw_screen
	
	move_bottom_right_60_degree:
	add $s1, $s3, $zero
	add $s2, $s4, $zero
	addi $s3, $s3, 1
	addi $s4, $s4, 2
	b draw_screen
	
	move_bottom_right_30_degree:
	add $s1, $s3, $zero
	add $s2, $s4, $zero
	addi $s3, $s3, 2
	addi $s4, $s4, 1
	b draw_screen
	
	move_bottom_left:
	li $v0, 42 
	li $a0, 0 
	li $a1, 3 
	syscall
	beq $a0, 0, move_bottom_left_45_degree
	beq $a0, 1, move_bottom_left_60_degree
	b move_bottom_left_30_degree
	
	move_bottom_left_45_degree:
	add $s1, $s3, $zero
	add $s2, $s4, $zero
	addi $s3, $s3, 1
	addi $s4, $s4, -1
	b draw_screen
	
	move_bottom_left_60_degree:
	add $s1, $s3, $zero
	add $s2, $s4, $zero
	addi $s3, $s3, 1
	addi $s4, $s4, -2
	b draw_screen
	
	move_bottom_left_30_degree:
	add $s1, $s3, $zero
	add $s2, $s4, $zero
	addi $s3, $s3, 2
	addi $s4, $s4, -1
	b draw_screen
	
	update_ball_no_collision:
	update_x:
	sub $t6, $s3, $s1
	add $s1, $s3, $zero			# update previous x coordinate
	add $s3, $s3, $t6			# update current x coordinate
	beq $s3, 1, add_one_x		# if current x exceeds the top frame limit, make it inside the limit
	beq $s3, 63, minus_one_x	# if current x exceeds the bottom frame limit, make it inside the limit
	update_y:
	sub $t5, $s4, $s2
	add $s2, $s4, $zero			# update previous y coordinate
	add $s4, $s4, $t5			# update current y coordinate
	beq $s4, 1, add_one_y		# if y exceeds the left frame limit, make it inside the limit
	beq $s4, 62, minus_one_y	# if y exceeds the right frame limit, make it inside the limit
	b check_exceed_limit
	
	add_one_x: addi $s3, $s3, 1
	b update_y
	minus_one_x: addi $s3, $s3, -1
	b update_y
	add_one_y: addi $s4, $s4, 1
	b check_exceed_limit
	minus_one_y: addi $s4, $s4, -1
	b check_exceed_limit
	
	check_exceed_limit:
	beq $t6, -2, check_overlap_1
	beq $t6, 2, check_overlap_2
	beq $t5, -2, check_overlap_3
	beq $t5, 2, check_overlap_4
	b draw_screen
	
	check_overlap_1:
	jal translate_coordinate_into_position
	lw $t7, 0($t9)
	beq $t7, 0, draw_screen
	addi $s3, $s3, 1
	b draw_screen
	
	check_overlap_2:
	jal translate_coordinate_into_position
	lw $t7, 0($t9)
	beq $t7, 0, draw_screen
	addi $s3, $s3, -1
	b draw_screen
	
	check_overlap_3:
	jal translate_coordinate_into_position
	lw $t7, 0($t9)
	beq $t7, 0, draw_screen
	addi $s3, $s3, 1
	b draw_screen
	
	check_overlap_4:
	jal translate_coordinate_into_position
	lw $t7, 0($t9)
	beq $t7, 0, draw_screen
	addi $s3, $s3, -1
	b draw_screen
	
	# 3. Draw the screen
	# $t2 = base address for bitmap display
	# $t3 = RGB value of black/light gray/dark gray
	# $t5 = RGB value of yellow
	# Load first word from keyboard into $t8
	# $t1 = 1 when a was pressed, 2 when d was pressed
	# $s0 = position of the first pixel of the paddle (number of pixels * 4)
	# $s1 = previous x coordinate of the ball
	# $s2 = previous y coordinate of the ball
	# $s3 = current x coordinate of the ball
	# $s4 = current y coordinate of the ball
	# $s5 = 1 when collide with wall, 2 when collide with paddle, 
	#		3 when top of the ball collide with brick, 4 when bottom of the ball collide with brick,
	#		5 when left of the ball collide with brick, 6 when right of the ball collide with brick,
	#		0 no collision happens (priority brick > paddle > wall)
	# $s6 = position of brick collided (number of pixels * 4)
	# $t9 = the first pixel of the brick (number of pixels * 4)
	# $t7 stores the value of memory address of $t9
	draw_screen:
	lw $t2, ADDR_DSPL				# $t2 = base address for bitmap display
	lw $t5, paddle_colour_yellow	# $t5 = RGB value of yellow
	beq $s5, 3, continue_brick_update
	beq $s5, 4, continue_brick_update
	beq $s5, 5, continue_brick_update
	beq $s5, 6, continue_brick_update
	b check_draw_new_paddle
	continue_brick_update:
	sub $t6, $s6, $t2				# check $s6 is the first, second, third, or fourth pixel
	srl $t6, $t6, 2
	addi $t0, $zero, 64
	div $t6, $t0
	mfhi $t6
	addi $t6, $t6, -2
	addi $t0, $zero, 4
	div $t6, $t0
	mfhi $t6
	beq $t6, 0, update_first_pixel_with_first_pixel
	beq $t6, 1, update_first_pixel_with_second_pixel
	beq $t6, 2, update_first_pixel_with_third_pixel
	beq $t6, 3, update_first_pixel_with_fourth_pixel
	
	update_first_pixel_with_first_pixel:		# $s6 is the first pixel, update $t9 as the first pixel
	add $t9, $s6, $zero
	b update_brick
	
	update_first_pixel_with_second_pixel:		# $s6 is the second pixel, update $t9 as the first pixel
	addi $t9, $s6, -4
	b update_brick
	
	update_first_pixel_with_third_pixel:		# $s6 is the third pixel, update $t9 as the first pixel
	addi $t9, $s6, -8
	b update_brick
	
	update_first_pixel_with_fourth_pixel:		# $s6 is the fourth pixel, update $t9 as the first pixel
	addi $t9, $s6, -12
	b update_brick
	
	update_brick:
	lw $t7, 0($t9)
	addi $t3, $zero, 0x9E9E9E		# $t3 = RGB value of light gray
	beq $t7, $t3, make_brick_dark_gray
	addi $t3, $zero, 0x626262		# $t3 = RGB value of dark gray
	beq $t7, $t3, make_brick_black
	b make_brick_light_gray
	
	make_brick_light_gray:
	addi $t3, $zero, 0x9E9E9E		# $t3 = RGB value of light gray
	b change_brick_colour
	
	make_brick_dark_gray:
	addi $t3, $zero, 0x626262		# $t3 = RGB value of dark gray
	b change_brick_colour
	
	make_brick_black:
	add $t3, $zero, $zero			# $t3 = RGB value of black
	b change_brick_colour
	
	change_brick_colour:
	sw $t3, 0($t9)
	sw $t3, 4($t9)
	sw $t3, 8($t9)
	sw $t3, 12($t9)
	
	check_draw_new_paddle:
	bne $t8, 1, draw_new_ball
	beq $t1, 1, draw_new_paddle_left
	beq $t1, 2, draw_new_paddle_right
	b draw_new_ball
	
	draw_new_paddle_left:
	add $t3, $zero, $zero			# $t3 = RGB value of black
	sw $t5, 0($s0)
	sw $t5, 4($s0)
	sw $t5, 8($s0)
	sw $t5, 12($s0)
	sw $t5, 16($s0)
	sw $t3, 20($s0)
	b draw_new_ball
	
	draw_new_paddle_right:
	add $t3, $zero, $zero			# $t3 = RGB value of black
	sw $t3, -4($s0)
	sw $t5, 0($s0)
	sw $t5, 4($s0)
	sw $t5, 8($s0)
	sw $t5, 12($s0)
	sw $t5, 16($s0)
	b draw_new_ball
	
	draw_new_ball:
	add $t3, $zero, $zero		# $t3 = RGB value of black
	addi $t0, $zero, 256
	mult $s1, $t0
	mflo $t6
	add $t6, $t2, $t6
	sll $t0, $s2, 2
	add $t6, $t6, $t0
	sw $t3, 0($t6)				# make the previous ball position be black
	addi $t0, $zero, 256
	mult $s3, $t0
	mflo $t6
	add $t6, $t2, $t6
	sll $t0, $s4, 2
	add $t6, $t6, $t0
	sw $t5, 0($t6)				# make the new ball position be yellow
	
	add $t8, $zero, $zero		# reset $t8
	
	# 4. Sleep
	addi $a2, $a2, 1			# update counter $a2
	bgt $a2, 400, triple_speed
	bgt $a2, 200, double_speed
	li $v0, 32
	li $a0, 200
	syscall
	b go_back
	
	double_speed:
	li $v0, 32
	li $a0, 140
	syscall
	b go_back
	
	triple_speed:
	li $v0, 32
	li $a0, 80
	syscall
	
    #5. Go back to 1
	go_back:
	addi $a3, $a3, 1			# update counter $a3
	addi $t6, $zero, 5000		# $t6 is the time limit
	beq $a3, $t6, respond_to_Q 	# if it exceeds time limit, quit the game
	b game_loop

	
	translate_coordinate_into_position:
	sll $t9, $s4, 2
    add $t9, $t2, $t9
    addi $t5, $zero, 256
    mult $s3, $t5
    mflo $t5
    add $t9, $t9, $t5
    jr $ra