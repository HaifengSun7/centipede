# Centipede CSC258 Winter 2020
# Haifeng Sun
# Bitmap Display Configuration:
# - Unit width in pixels: 4					     
# - Unit height in pixels: 4
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
.data
	numMush: .word 10
	mushLocation: .word 0:10
	displayAddress:	.word 0x10008000
	bgColor: .word 0x9e7a37
	mushColor0: .word 0xff003c
	mushColor1: .word 0x1500ff
	snakeColor0: .word 0x24ff41
	snakeColor1: .word 0xf35d00
	headColor: .word 0xff2100
	headLocation: .word 0:10
	numHead: .word 1
	numBody: .word 10
	snakeLocation: .word 0:10
	snakeLocationCopy: .word 0:10
	idk: .word 1
	cannonLocation: .word 1
	cannonColor0: .word 0x00d9ff
	cannonColor1: .word 0xbf00ff
	fleaColor: .word 0xa2ff00
	dartLocation: .word 99999999
	numDart: .word 0
	shotCount: .word 0
	fleaLocation: .word 0
	mushLocationCopy: .word 0:10
	snakeDead: .word 0
	fleaUpAmount: .word 0
	Downie: .word 0
	fleaDead: .word 0
	
	

############################################################################################
# Draw Background
.globl main
.text
main:
	li $t0, 0
	la $t1, fleaDead
	sw $t0, 0($t1)
	la $t1, snakeDead
	sw $t0, 0($t1)
	la $t1, shotCount
	sw $t0, 0($t1)
	li $t0, 10
	la $t1, numBody
	sw $t0, 0($t1)
	la $t1, numMush
	sw $t0, 0($t1)
draw_bg:
	lw $t0, displayAddress		# Location of current pixel data
	addi $t1, $t0, 16384			# Location of last pixel data.
	lw $t2, bgColor			# Colour of the background
	
draw_bg_loop:
	sw $t2, 0($t0)				# Store the colour
	addi $t0, $t0, 4			# Next pixel
	blt $t0, $t1, draw_bg_loop
	
############################################################################################
# initialize snake
	jal mush_init
	jal cannon_init
	jal snake_init
	jal flea_init
	jal draw_mush
	jal draw_snake
	jal draw_head
	jal draw_cannon

#############################
#gameing
#shroom should be updated first.
gaming_loop:

check_keystroke:

	lw $t8, 0xffff0000
	beq $t8, 1, keyboard_input # if key is pressed, jump to get this key
	addi $t8, $zero, 0
	j keyboard_input_done
keyboard_input:
	la $s0, cannonLocation
	lh $s1, 0($s0) # x
	lw $t8, 0xffff0004				# Read Key value into t8
	beq $t8, 0x6A, keyboard_left	# If `j`, move left
	beq $t8, 0x6B, keyboard_right	# If `k`, move right
	beq $t8, 0x78, shoot
	beq $t8, 0x73, keyboard_restart #ssssssss
	j keyboard_input_done
keyboard_restart: 
	j main
keyboard_left:
	jal draw_bg_s0
	addi $s1, $s1, -1
	beq $s1, -1, prevent_out0
	sh $s1, 0($s0)
	j keyboard_input_done
keyboard_right:
	jal draw_bg_s0
	addi $s1, $s1, 1
	beq $s1, 16, prevent_out15
	sh $s1, 0($s0)
	j keyboard_input_done
shoot:
	j init_dart
	j keyboard_input_done
	
prevent_out0:
	addi $s1, $s1, 1
	sh $s1, 0($s0)
	j keyboard_input_done
prevent_out15:
	addi $s1, $s1, -1
	sh $s1, 0($s0)
	j keyboard_input_done
keyboard_input_done:
	# do nothing

	lw $s0, cannonLocation # bye bye
	lw $t1, fleaLocation
	la $t2, headLocation
	lw $t3, 0($t2)
	beq $s0, $t1, Exit
	beq $s0, $t3, Exit
update_snake:
	li $s4, 0	# counter
	lw $s5, numBody #max
	la $s0, snakeLocation
	la $s1, snakeLocationCopy

	la $s3, mushLocation
	la $s6, idk
update_ptrs:
    	lw $t0, 0($s0)
    	sw $t0, 0($s1)
	addi $s4, $s4, 1
	addi $s0, $s0, 4
	addi $s1, $s1, 4
	blt $s4, $s5, update_ptrs
	li $s4, 0
	addi $s1, $s1, -4 # s1 is the one before
	addi $s0, $s0, -4 #yes
	addi $s1, $s1, -4
update_snake_loop:

	#call determinator
	#jal based on det
	jal is_head #s7 1 head 0 no
	beq $s7, 1, update_head
	beq $s7, 0, update_body
update_body:
	# go to last one before location
	jal draw_bg_s0
	lw $t2, 0($s1)
	sw $t2, 0($s0)
	j update_snake_leftover
update_head:
	# move to the correct direction
	# store hyp location
	# case 1: mush. down
	# case 2: bound. down
	# case 3: just move.
	# move whatever in the bodyLocation and whatever in headLocation
	# headLocation should be s2 0
	jal draw_bg_s0
	lw $t1, snakeDead
	beq $t1, 1, headDead
	lh $t3, 0($s0) # x
	lh $t4, 2($s0) # y
	li $a0, 2
	div $t4, $a0 # lo remainder. 0 right 1 left
	mfhi $a3
	beq $a3, 1, left
	beq $a3, 0, right
left:
	lh $t5, 2($s0) # y
	lh $t6, 0($s0) # x
	addi $t6, $t6, -1
	sh $t5, 2($s6)
	sh $t6, 0($s6)
	jal is_mush
	beq $s7, 1, down
	beq $t6, -1, down
	# go left then.
	lh $t5, 2($s0) # y
	lh $t6, 0($s0) # x
	addi $t6, $t6, -1
	sh $t5, 2($s0)
	sh $t6, 0($s0)
	sh $t5, 2($s2)
	sh $t6, 0($s2)
	j update_snake_leftover
right:
	lh $t5, 2($s0) # y
	lh $t6, 0($s0) # x
	addi $t6, $t6, 1
	sh $t5, 2($s6)
	sh $t6, 0($s6)
	jal is_mush
	beq $s7, 1, down
	beq $t6, 16, down
	# go right then.
	lh $t5, 2($s0) # y
	lh $t6, 0($s0) # x
	addi $t6, $t6, 1
	sh $t5, 2($s0)
	sh $t6, 0($s0)
	sh $t5, 2($s2)
	sh $t6, 0($s2)
	j update_snake_leftover
down: 
	lh $t5, 2($s0) # y
	lh $t6, 0($s0) # x
	addi $t5, $t5 1
	sh $t5, 2($s0)
	sh $t6, 0($s0)
	sh $t5, 2($s2)
	sh $t6, 0($s2)
	j update_snake_leftover
headDead:
	li $t5, 17 # y
	li $t6, 17 # x
	sh $t5, 2($s6)
	sh $t6, 0($s6)
	j update_snake_leftover
update_snake_leftover:
	addi $s4, $s4, 1
	addi $s0, $s0, -4 #yes
	addi $s1, $s1, -4
	blt $s4, $s5, update_snake_loop

	lw $s0, cannonLocation # bye bye
	lw $t1, fleaLocation
	la $t2, headLocation
	lw $t3, 0($t2)
	beq $s0, $t1, Exit
	beq $s0, $t3, Exit
update_flea:

	lw $t0, fleaDead
	beq $t0, 1, flea_fin
	la $s0, fleaLocation
	jal draw_bg_s0
	lw $t1, Downie
	beq $t1, 0, flea_up
	beq $t1, 1, flea_down
	
flea_down:
	la $t2, fleaLocation
	lh $t3, 2($t2)
	beq $t3, 15, flea_left_down
	addi $t3, $t3, 1
	sh $t3, 2($t2)
	j flea_fin
flea_left_down:
	la $t0, Downie
	li $t1, 0
	sw $t1, 0($t0)
	la $t2, fleaLocation
	lh $t3, 0($t2)
	addi $t3, $t3, -1
	beq $t3, -1, flea_off_death
	sh $t3, 0($t2)
	la $t0, fleaLocation
	li $v0, 42         # Service 42, random int bounded
  	li $a0, 0          # Select random generator 0
  	li $a1, 6             
  	syscall             # Generate random int (returns in $a0)
  	addi $a0, $a0, 5
  	la $t5, fleaUpAmount
  	sw $a0, 0($t5)
	j flea_fin
	
flea_up:
	la $t2, fleaLocation
	
	lh $t3, 2($t2)
	la $t4, fleaUpAmount
	lw $t5, 0($t4)
	beq $t5, 0, flea_left_up
	addi $t3, $t3, -1
	addi $t5, $t5, -1
	sw $t5, 0($t4)
	sh $t3, 2($t2)
	j flea_fin
flea_left_up:
	la $t0, Downie
	li $t1, 1
	sw $t1, 0($t0)
	la $t2, fleaLocation
	lh $t3, 0($t2)
	addi $t3, $t3, -1
	beq $t3, -1, flea_off_death
	sh $t3, 0($t2)
	j flea_fin
flea_off_death:
	la $t0, fleaDead
	li $t1, 1
	sw $t1, 0($t0)
	la $t2, fleaLocation
	li $t3, 17
	sh $t3, 0($t2)
	sh $t3, 2($t2)
	j flea_fin
flea_fin:

#nonononono



boom:
# dart + mush = boom # no.
# dart + snkae = shotCount++
	la $s6, dartLocation
	la $s5, dartLocation
	li $s7, 0
	jal is_flea
	beq $s7, 1, boom_flea
	
	jal is_snake
	beq $s7, 1, boom_snake
	li $s7, 0
	jal is_mush
	beq $s7, 1, boom_mush
	j boom_fin

boom_mush:
	la $t0, numDart
	li $t1, 0
	sw $t1, 0($t0)
	j update_boomed_mush
update_boomed_mush:
	lw $s2, 0($s6) # s2 objective
	la $s0, mushLocation
	la $s1, mushLocationCopy
	li $s4, 0
	lw $s5, numMush
updateptrs:
    	lw $t0, 0($s0)
    	sw $t0, 0($s1)
	addi $s4, $s4, 1
	addi $s0, $s0, 4
	addi $s1, $s1, 4
	blt $s4, $s5, updateptrs
	la $s0, mushLocation
	la $s1, mushLocationCopy
	li $s4, 0
	lw $s5, numMush
first_half:
	lw $t0, 0($s0)
	beq $t0, $s2, middle
	addi $s0, $s0, 4
	addi $s1, $s1, 4
	addi $s4, $s4, 1
	j first_half
middle:
	addi $s1, $s1, 4 # later
	addi $s5, $s5, -1 # bye bye
	la $t4, numMush
	sw $s5, 0($t4) # why not
	jal draw_bg_s0
second_half:
	lw $t0, 0($s1)
	sw $t0, 0($s0)
	addi $s0, $s0, 4
	addi $s1, $s1, 4
	addi $s4, $s4, 1
	blt $s4, $s5, second_half
	la $t0, dartLocation
	li $t5, 90000
	sw $t5, 0($t0)
	j boom_fin

boom_snake:
	la $t0, numDart
	li $t1, 0
	sw $t1, 0($t0)
	la $t3, shotCount
	lw $t5, 0($t3)
	addi $t4, $t5, 1
	sw $t4, 0($t3)
	la $t0, dartLocation
	li $t5, 90000
	sw $t5, 0($t0)
	j boom_fin

boom_flea:
	la $t0, fleaDead
	li $t1, 1
	sw $t1, 0($t0)
	la $t2, fleaLocation
	li $t3, 17
	sh $t3, 0($t2)
	sh $t3, 2($t2)
	la $t0, numDart
	li $t1, 0
	sw $t1, 0($t0)
	la $s0, dartLocation
	jal draw_bg_s0
	la $t0, dartLocation
	li $t5, 90000
	sw $t5, 0($t0)
	j boom_fin
boom_fin:

	lw $t1, shotCount
	li $t2, 3
	beq $t1, $t2, kill
	j nokill
kill:
	la $t1, shotCount
	addi $t1, $t1, -3
	
	la $t2, numHead
	li $t3, 0
	sw $t3, 0($t2)
	la $t2, snakeDead
	li $t3, 1
	sw $t3, 0($t2)
	jal body_to_bg
	la $t2, numBody
	li $t3, 0
	sw $t3, 0($t2)
nokill:

udate_dart:
	lw $t3, numDart
	beq $t3, 0, update_dart_no
	la $s0, dartLocation
	jal draw_bg_s0
	lh $t5, 2($s0)
	addi $t5, $t5, -1
	sh $t5, 2($s0)
update_dart_no:
dart_offscreen:
	la $t0, dartLocation
	lh $t1, 2($t0) 
	beq $t1, -1, deleteDart
	j dartoffend
deleteDart:
	la $t2, numDart
	li $t3, 0
	sw $t3, 0($t2)
dartoffend:
boom2:
# dart + mush = boom # no.
# dart + snkae = shotCount++
	la $s6, dartLocation
	la $s5, dartLocation
	li $s7, 0
	jal is_flea
	beq $s7, 1, boom_flea2
	
	jal is_snake
	beq $s7, 1, boom_snake2
	li $s7, 0
	jal is_mush
	beq $s7, 1, boom_mush2
	j boom_fin2

boom_mush2:
	la $t0, numDart
	li $t1, 0
	sw $t1, 0($t0)
	j update_boomed_mush2
update_boomed_mush2:
	lw $s2, 0($s6) # s2 objective
	la $s0, mushLocation
	la $s1, mushLocationCopy
	li $s4, 0
	lw $s5, numMush
updateptrs2:
    	lw $t0, 0($s0)
    	sw $t0, 0($s1)
	addi $s4, $s4, 1
	addi $s0, $s0, 4
	addi $s1, $s1, 4
	blt $s4, $s5, updateptrs2
	la $s0, mushLocation
	la $s1, mushLocationCopy
	li $s4, 0
	lw $s5, numMush
first_half2:
	lw $t0, 0($s0)
	beq $t0, $s2, middle2
	addi $s0, $s0, 4
	addi $s1, $s1, 4
	addi $s4, $s4, 1
	j first_half2
middle2:
	addi $s1, $s1, 4 # later
	addi $s5, $s5, -1 # bye bye
	la $t4, numMush
	sw $s5, 0($t4) # why not
	jal draw_bg_s0
second_half2:
	lw $t0, 0($s1)
	sw $t0, 0($s0)
	addi $s0, $s0, 4
	addi $s1, $s1, 4
	addi $s4, $s4, 1
	blt $s4, $s5, second_half2
	la $t0, dartLocation
	li $t5, 90000
	sw $t5, 0($t0)
	j boom_fin2

boom_snake2:
	la $t0, numDart
	li $t1, 0
	sw $t1, 0($t0)
	la $t3, shotCount
	lw $t5, 0($t3)
	addi $t4, $t5, 1
	sw $t4, 0($t3)
	la $t0, dartLocation
	li $t5, 90000
	sw $t5, 0($t0)
	j boom_fin2

boom_flea2:
	la $t0, fleaDead
	li $t1, 1
	sw $t1, 0($t0)
	la $t2, fleaLocation
	li $t3, 17
	sh $t3, 0($t2)
	sh $t3, 2($t2)
	la $t0, numDart
	li $t1, 0
	sw $t1, 0($t0)
	la $s0, dartLocation
	jal draw_bg_s0
	la $t0, dartLocation
	li $t5, 90000
	sw $t5, 0($t0)
	j boom_fin2
boom_fin2:

	lw $t1, shotCount
	li $t2, 3
	beq $t1, $t2, kill2
	j nokill2
kill2:
	la $t1, shotCount
	addi $t1, $t1, -3
	
	la $t2, numHead
	li $t3, 0
	sw $t3, 0($t2)
	la $t2, snakeDead
	li $t3, 1
	sw $t3, 0($t2)
	jal body_to_bg
	la $t2, numBody
	li $t3, 0
	sw $t3, 0($t2)
nokill2:



byebye:
	lw $s0, cannonLocation
	lw $t1, fleaLocation
	la $t2, headLocation
	lw $t3, 0($t2)
	beq $s0, $t1, Exit
	beq $s0, $t3, Exit




# call draws
jal draw_mush
jal draw_snake
jal draw_head
jal draw_cannon
jal draw_dart
jal draw_flea
waiting:
	li $v0, 32
	li $a0, 150
	syscall
	j gaming_loop
############################################################################################
# should be in gaming loop, or not i guess.
draw_mush:
#	addi $sp, $sp, -4
#	sw $ra, 0($sp)	
	li $t0, 0
	lw $a1, numMush
	la $a2, mushLocation
	
draw_mush_loop:

	lh $t1, 0($a2)	#load location x
	lh $t4, 2($a2) # y
	lw $t2, displayAddress #t2 gp
	sll $t1, $t1, 4 # change to 256
	sll $t4, $t4, 4
	sll $t4, $t4, 6 # idx = 64y + x
	add $t3, $t4, $t1
	add $t3, $t2, $t3 # t3 actual
	lw $s0, mushColor0 #s colors
	lw $s1, mushColor1
draw_mush_inner:
	sw $s0, 0($t3)
	addi $t3, $t3, 4
	sw $s1, 0($t3)
	addi $t3, $t3, 4
	sw $s0, 0($t3)
	addi $t3, $t3, 4
	sw $s1, 0($t3)
	
	addi $t3, $t3, 244
	sw $s1, 0($t3)
	addi $t3, $t3, 4
	sw $s0, 0($t3)
	addi $t3, $t3, 4
	sw $s1, 0($t3)
	addi $t3, $t3, 4
	sw $s0, 0($t3)
	
	addi $t3, $t3, 244
	addi $t3, $t3, 4
	sw $s1, 0($t3)
	addi $t3, $t3, 4
	sw $s0, 0($t3)
	
	addi $t3, $t3, 248
	addi $t3, $t3, 4
	sw $s1, 0($t3)
	addi $t3, $t3, 4
	sw $s0, 0($t3)
	
	addi $a2, $a2, 4
	addi $t0, $t0, 1
	blt $t0, $a1, draw_mush_loop
	# finished, double checked, bug free.
	jr $ra
draw_snake:
	lw $t0, snakeDead
	beq $t0, 1, noSnake
	li $t0, 0
	lw $a1, numBody
	la $a2, snakeLocation
draw_snake_loop:
	lh $t1, 0($a2)	#load location x
	lh $t4, 2($a2) # y
	bgt $t4, 15 last_line_display_snake# deepest = 15
draw_snake_remain:
	lw $t2, displayAddress #t2 gp
	sll $t1, $t1, 4 # change to 256
	sll $t4, $t4, 4
	sll $t4, $t4, 6 # idx = 64y + x
	add $t3, $t4, $t1
	add $t3, $t2, $t3 # t3 actual
	lw $s0, snakeColor0 #s colors
	lw $s1, snakeColor1
	addi $t3, $t3, 4

	
	addi $t3, $t3, 252
	addi $t3, $t3, 4
	sw $s0, 0($t3)
	addi $t3, $t3, 4
	sw $s1, 0($t3)
	addi $t3, $t3, 4


	
	addi $t3, $t3, 244
	sw $s1, 0($t3)
	addi $t3, $t3, 4
	sw $s0, 0($t3)
	addi $t3, $t3, 4
	sw $s1, 0($t3)
	addi $t3, $t3, 4
	sw $s0, 0($t3)
	
	addi $t3, $t3, 244
	addi $t3, $t3, 4
	addi $t3, $t3, 4
	
	addi $a2, $a2, 4
	addi $t0, $t0, 1
	blt $t0, $a1, draw_snake_loop
	#save
	jr $ra
noSnake:
	jr $ra
last_line_display_snake:
	li $t4, 15
	j draw_snake_remain
draw_head:
	lw $t0, snakeDead
	beq $t0, 1, noHead
	li $t0, 0 # contr
	lw $a1, numHead # max
	la $a2, headLocation
	lw $s0, headColor
draw_head_inner:
	lh $t1, 0($a2)	#load location x
	lh $t4, 2($a2) # y
	bgt $t4, 15 last_line_display_head# deepest = 15
draw_head_remain:
	lw $t2, displayAddress #t2 gp
	sll $t1, $t1, 4 # change to 256
	sll $t4, $t4, 4
	sll $t4, $t4, 6 # idx = 64y + x
	add $t3, $t4, $t1
	add $t3, $t2, $t3 # t3 actual
	
	sw $s0, 0($t3)
	addi $t3, $t3, 4
	sw $s0, 0($t3)
	addi $t3, $t3, 4
	sw $s0, 0($t3)
	addi $t3, $t3, 4
	sw $s0, 0($t3)
	
	addi $t3, $t3, 244
	sw $s0, 0($t3)
	addi $t3, $t3, 4
	sw $s0, 0($t3)
	addi $t3, $t3, 4
	sw $s0, 0($t3)
	addi $t3, $t3, 4
	sw $s0, 0($t3)
	
	addi $t3, $t3, 244
	sw $s0, 0($t3)
	addi $t3, $t3, 4
	sw $s0, 0($t3)
	addi $t3, $t3, 4
	sw $s0, 0($t3)
	addi $t3, $t3, 4
	sw $s0, 0($t3)
	
	addi $t3, $t3, 244

	addi $t0, $t0, 1
	addi $a2, $a2, 4
	blt $t0, $a1, draw_head_inner
	#save
	jr $ra
last_line_display_head:
	li $t4, 15
	j draw_head_remain
noHead:
	jr $ra
draw_cannon:
#	addi $sp, $sp, -4
#	sw $ra, 0($sp)	

	la $a2, cannonLocation
	lh $t1, 0($a2)	#load location x
	lh $t4, 2($a2) # y
	lw $t2, displayAddress #t2 gp
	sll $t1, $t1, 4 # change to 256
	sll $t4, $t4, 4
	sll $t4, $t4, 6 # idx = 64y + x
	add $t3, $t4, $t1
	add $t3, $t2, $t3 # t3 actual
	lw $s0, cannonColor0 #s colors
	lw $s1, cannonColor1
draw_cannon_inner:

	addi $t3, $t3, 4
	sw $s1, 0($t3)
	addi $t3, $t3, 4
	sw $s1, 0($t3)
	addi $t3, $t3, 4

	
	addi $t3, $t3, 244

	addi $t3, $t3, 4
	sw $s1, 0($t3)
	addi $t3, $t3, 4
	sw $s1, 0($t3)
	addi $t3, $t3, 4

	
	addi $t3, $t3, 244
	sw $s0, 0($t3)
	addi $t3, $t3, 4
	sw $s1, 0($t3)
	addi $t3, $t3, 4
	sw $s1, 0($t3)
	addi $t3, $t3, 4
	sw $s0, 0($t3)
	
	addi $t3, $t3, 244
	sw $s0, 0($t3)
	addi $t3, $t3, 4

	addi $t3, $t3, 4

	addi $t3, $t3, 4
	sw $s0, 0($t3)
	
	jr $ra

draw_dart:
	lw $t0, numDart
	beq $t0, 0, draw_dart_no
	la $a2, dartLocation
	lw $s0, headColor
	lh $t1, 0($a2)	#load location x
	lh $t4, 2($a2) # y
	lw $t2, displayAddress #t2 gp
	sll $t1, $t1, 4 # change to 256
	sll $t4, $t4, 4
	sll $t4, $t4, 6 # idx = 64y + x
	add $t3, $t4, $t1
	add $t3, $t2, $t3 # t3 actual
	addi $t3, $t3, 4
	addi $t3, $t3, 4
	addi $t3, $t3, 4
	
	addi $t3, $t3, 244

	addi $t3, $t3, 4

	addi $t3, $t3, 4
	sw $s0, 0($t3)
	addi $t3, $t3, 4

	
	addi $t3, $t3, 244

	addi $t3, $t3, 4

	addi $t3, $t3, 4
	sw $s0, 0($t3)
	addi $t3, $t3, 4

	#save
	jr $ra
draw_dart_no:
	jr $ra
draw_flea:
	lw $t0, fleaDead
	beq $t0, 1, draw_flea_no
	la $a2, fleaLocation
	lw $s0, fleaColor
	lh $t1, 0($a2)	#load location x
	lh $t4, 2($a2) # y
	lw $t2, displayAddress #t2 gp
	sll $t1, $t1, 4 # change to 256
	sll $t4, $t4, 4
	sll $t4, $t4, 6 # idx = 64y + x
	add $t3, $t4, $t1
	add $t3, $t2, $t3 # t3 actual
	
	sw $s0, 0($t3)
	addi $t3, $t3, 4
	
	addi $t3, $t3, 4
	
	addi $t3, $t3, 4
	sw $s0, 0($t3)
	
	addi $t3, $t3, 244
	
	addi $t3, $t3, 4
	sw $s0, 0($t3)
	addi $t3, $t3, 4
	sw $s0, 0($t3)
	addi $t3, $t3, 4
	
	
	addi $t3, $t3, 244
	
	addi $t3, $t3, 4
	sw $s0, 0($t3)
	addi $t3, $t3, 4
	sw $s0, 0($t3)
	addi $t3, $t3, 4
	
	addi $t3, $t3, 244
	sw $s0, 0($t3)
	addi $t3, $t3, 4
	
	addi $t3, $t3, 4
	
	addi $t3, $t3, 4
	sw $s0, 0($t3)

	#save
	jr $ra
draw_flea_no:
	jr $ra











############################################################################################
get_random_number:
  	li $v0, 42         # Service 42, random int bounded
  	li $a0, 0          # Select random generator 0
  	li $a1, 16             
  	syscall             # Generate random int (returns in $a0)
  	jr $ra
 
get_random_number2:
  	li $v0, 42         # Service 42, random int bounded
  	li $a0, 0          # Select random generator 0
  	li $a1, 14             
  	syscall             # Generate random int (returns in $a0)
  	addi $a0, $a0, 1
  	jr $ra

#################################
is_head: # given location at s0, headLocation at s2 0, return at s7 1 if is head
	lw $t7, 0($s0)
	la $s2, headLocation
	li $t8, 0
	lw $t9, numHead
head_loop:
	lw $t5, 0($s2)
	beq $t7, $t5, yes_head
	addi $s2, $s2, 4
	addi $t8, $t8, 1
	blt $t8, $t9, head_loop
	j no_head
yes_head:
	li $s7, 1
	jr $ra
no_head:
	li $s7, 0
	jr $ra
is_flea:
	la $t4, fleaLocation
	lw $t5, 0($t4)
	lw $t7, 0($s6)
	beq $t5, $t7, yes_flea
	li $s7, 0
	jr $ra #??
yes_flea:
	li $s7, 1
	jr $ra #??
is_mush: # test at s6, mushLocation at t4, return at s7 1 if is mush
	la $t4, mushLocation
	lw $t7, 0($s6)
	li $t8, 0
	lw $t9, numMush
mush_loop:
	lw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t8, $t8, 1
	beq $t5, $t7, yes_mush
	blt $t8, $t9, mush_loop
	j no_mush
yes_mush:
	li $s7, 1
	jr $ra #??
no_mush:
	li $s7, 0
	jr $ra #??
	
is_snake: # test at s5,  return at s7 1 if is mush
	la $t4, snakeLocation
	lw $t7, 0($s5)
	li $t8, 0
	lw $t9, numBody
snake_loop:
	lw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t8, $t8, 1
	beq $t5, $t7, yes_snake
	blt $t8, $t9, snake_loop
	j no_snake
yes_snake:
	li $s7, 1
	jr $ra #??
no_snake:
	li $s7, 0
	jr $ra #??
	

draw_bg_s0: # draw bg at s0, used for snake bg update

	lw $t5, bgColor			# Colour of the background
	lh $t1, 0($s0)	#load location x
	lh $t4, 2($s0) # y
	bgt $t4, 15 last_line_bg_update
draw_bg_remain:
	lw $t2, displayAddress #t2 gp
	sll $t1, $t1, 4 # change to 256
	sll $t4, $t4, 4
	sll $t4, $t4, 6 # idx = 64y + x
	add $t3, $t4, $t1
	add $t3, $t2, $t3 # t3 actual
	
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 244
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 244
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 244
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	jr $ra
last_line_bg_update:
	li $t4, 15
	j draw_bg_remain
	
	
body_to_bg:
	la $s0, snakeLocation
	lw $s2, numBody
	li $s1, 0 # ctr
bgbgloop:
	lw $t5, bgColor			# Colour of the background
	lh $t1, 0($s0)	#load location x
	lh $t4, 2($s0) # y
	lw $t2, displayAddress #t2 gp
	sll $t1, $t1, 4 # change to 256
	sll $t4, $t4, 4
	sll $t4, $t4, 6 # idx = 64y + x
	add $t3, $t4, $t1
	add $t3, $t2, $t3 # t3 actual
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 244
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 244
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 244
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	
	addi $s0, $s0, 4
	addi $s1, $s1, 1
	blt $s1, $s2, bgbgloop
	jr $ra
##########################################################################
# dart and stuff
init_dart:
	lw $t1, numDart
	beq $t1, 1, dontDart
	la $t2, cannonLocation
	la $t3, dartLocation
	lh $t5, 0($t2)	#load location x
	lh $t6, 2($t2) # y
	addi $t6, $t6, 0 # try this first
	sh $t5, 0($t3)
	sh $t6, 2($t3)
	la $t1, numDart
	li $t2, 1
	sw $t2, 0($t1)
	
	
dontDart:
	j keyboard_input_done


#####################inits
############################################################################################
# Initialize Game Data

mush_init:
	li $t0, 0	# counter
	lw $t1, numMush
	la $t2, mushLocation
	
mush_init_loop:
	li $v0, 42         # Service 42, random int bounded
  	li $a0, 0          # Select random generator 0
  	li $a1, 16             
  	syscall             # Generate random int (returns in $a0)
	sh $a0, 0($t2) # x
	li $v0, 42         # Service 42, random int bounded
  	li $a0, 0          # Select random generator 0
  	li $a1, 14             
  	syscall             # Generate random int (returns in $a0)
  	addi $a0, $a0, 1
	sh $a0, 2($t2) # y
	addi $t0, $t0, 1
	addi $t2, $t2, 4
	blt $t0, $t1, mush_init_loop
	jr $ra
	
cannon_init:
	la $t0, cannonLocation
	li $t1, 15 # deepest y
	li $t2, 7 # mid x
	sh $t2, 0($t0)
	sh $t1, 2($t0)
	jr $ra
	
snake_init:
	li $t0, 0
	la $t1, headLocation
	
	li $t3, 9 #x
	li $t4, 0 #y
	sh $t3, 0($t1)
	sh $t4, 2($t1)

	li $t5, 0 # contr
	li $t6, 10 # max cnt
	la $t2, snakeLocation
	li $t3, 9 #x
	li $t4, 0 #y
	
snake_init_loop:
	sh $t3, 0($t2)
	sh $t4, 2($t2)
	addi $t3, $t3, -1
	addi $t2, $t2, 4
	addi $t5, $t5, 1
	blt $t5, $t6, snake_init_loop
	jr $ra

flea_init:
	la $t0, fleaLocation
	li $v0, 42         # Service 42, random int bounded
  	li $a0, 0          # Select random generator 0
  	li $a1, 3             
  	syscall             # Generate random int (returns in $a0)
  	addi $a0, $a0, 12
	sh $a0, 0($t0) # x
	li $v0, 42         # Service 42, random int bounded
  	li $a0, 0          # Select random generator 0
  	li $a1, 2
  	syscall             # Generate random int (returns in $a0)
  	addi $a0, $a0, 12   
	sh $a0, 2($t0) # y
	li $v0, 42         # Service 42, random int bounded
  	li $a0, 0          # Select random generator 0
  	li $a1, 9             
  	syscall
  	addi $a1, $a1, 1
  	la $t3, fleaUpAmount
  	sw $a1, 0($t3)
	jr $ra






Exit:
	li $v0, 10 # terminate the program gracefully
	syscall
