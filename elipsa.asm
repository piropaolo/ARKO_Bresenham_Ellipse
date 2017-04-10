.data
	prompt:	.asciiz "Enter major axis: "
	prompt2:	.asciiz	"Enter minor axis: "
	filename: .asciiz "Ellipse.bmp"
	.align 2
	header: .space 56
.text

#$s0 - image width
#$s1 - image height
#$s2 - image width with excess
#$s3 - image buffer address
#$s4 - file beginning address
#$s5 - image size
#$s6 - semi-major axis - a
#$s7 - semi-minor axis - b

#Output 1st prompt
	li $v0, 4
	la $a0, prompt
	syscall

#Input semi-major axis
	li $v0, 5
	syscall
	move $s6, $v0

#Counting image width
	add $s0, $v0, $v0	#Doubling semi-major axis
	addi $s0, $s0, 1	#Addition +1

#Output 2nd prompt2
	li $v0, 4
	la $a0, prompt2
	syscall

#Input semi-minor axis
	li $v0, 5
	syscall
	move $s7, $v0

#Counting image height
	add $s1, $v0, $v0	#Doubling semi-minor axis
	addi $s1, $s1, 1	#Addition +1

#Counting the excess
	sll $s2, $s0, 1		# *= 2
	add $s2, $s2, $s0	# + $s0 -> *= 3

	subi $s2, $s2, 1	#Subtract 1
	andi $s2, $s2, 0xfffffffc	#Mask
	addi $s2, $s2, 4

#Output with the excess
	li $v0, 1
	add $a0, $s2, $zero
	syscall #PÓKI CO DZIAŁA

#Preparing the header
	la $t0, header		#t0 is now 56bit
	li $t1, 0x42		#Preparing first char
	sb $t1, 2($t0)		#Store
	li $t1, 0x4D		#Second char
	sb $t1, 3($t0)

#Allocating memory for the image and header write
	mul $t1, $s2, $s1	#Pixels needed for the whole pic
	add $s5, $t1, $zero	#Remember for later - size

	li $v0, 9		#Allocate memory (nr of bytes)
	add $a0, $t1, $zero
	syscall
	add $s3, $v0, $zero	#Remember the address to the allocated memory

	addi $t1, $t1, 54	#Image size + header
	sw $t1, 4($t0)		#Size to the header
	li $t1, 54		#Offset
	sw $t1, 12($t0)
	li $t1, 40		#Till the end of header
	sw $t1, 16($t0)
	add $t1, $s0, $zero	#Copying image width
	sw $t1, 20($t0)
	add $t1, $s1, $zero	#Copying image height
	sw $t1, 24($t0)
	li $t1, 1		#The number of color planes
	sw $t1, 28($t0)
	li $t1, 24		#The number of bits per pixel
	sb $t1, 30($t0)

#Open up file to write
	li $v0, 13		#Open file syscall
	la $a0, filename
	li $a1, 1		#1 - write-only with create
	li $a2, 0		#0 - flag
	syscall
	add $s4, $v0, $zero	#Image pointer adress

#Save header
	li $v0, 15	#Write to file syscall
	add $a0, $s4, $zero	#File descriptor
	la $a1, header+2	#Input buffer
	li $a2, 54		#Number of characters to write
	syscall	#GIT GIT

#Bresenham's algorithm
#$t0 - x0
#$t1 - y0
#$t2 - x
#$t3 - y
#$t5 - limit
#$t6 - d
#$t7 - delta_A
#$t8 - delta_B

	move $t0, $s6	#x0
	move $t1, $s7	#y0

	mul $t2, $t0, $t0 #a2 = a * a
	mul $t3, $t1, $t1 #b2 = b * b

	sll $t4, $t2, 2		#4 * a2
	sll $t5, $t3, 2		#4 * b2
	mul $t4, $t4, $s7	 #4 * b * a2

	sub $t6, $t5, $t4	#4 * b2 - 4 * b * a2
	add $t6, $t6, $t2	#d = 4 * b2 - 4 * b * a2 + $t2

	sll $t7, $t5, 1
	add $t7, $t7, $t5	#delta_A = 12 * b2

	sll $t4, $t4, 1		#8 * b * a2
	sub $t8, $t7, $t4
	sll $t4, $t2, 3
	add $t8, $t8, $t4	#delta_B = 4 * (3 * b2 - 2 * b * a2 + 2 * a2)

	add $t3, $t3, $t2	#a2 + b2
	mul $t2, $t2, $s6	#a2 * a2

	divu $t5, $t2, $t3	#limit = (a2 * a2 / a2 + b2)
	mul $t5, $t5, $s6

	move $t2, $zero	#x = 0
	move $t3, $s7	#y = b

	li $a3, 0x00
	li $t4, 0x00
background:
	bge $a3, $s0, loopello
	move $a0, $a3
	move $a1, $t4
	add $a2, $a0, $zero	#3 pixels per one point
	sll $a0, $a0, 1
	add $a0, $a0, $a2
	mul $a1, $a1, $s2	#Verse size
	add $a0, $a0, $a1	#Current pixel position
	add $a0, $a0, $s3	#Pixel position in file
	li $v0, 0xb9
	sb $v0, ($a0)
	li $v0, 0x42
	sb $v0, 1($a0)
	li $v0, 0xf4
	sb $v0, 2($a0)
	addi $a3, $a3, 1
	b background
loopello:
	addi $t4, $t4, 1
	li $a3, 0x00
	bge $t4, $s1, loop
	b background

loop:
	sub $a0, $t0, $t2	#x0 - x
	sub $a1, $t1, $t3	#y0 - y
	add $a2, $a0, $zero	#3 pixels per one point
	sll $a0, $a0, 1
	add $a0, $a0, $a2
	mul $a1, $a1, $s2	#Verse size
	add $a0, $a0, $a1	#Current pixel position
	add $a0, $a0, $s3	#Pixel position in file
	li $v0, 0x50
	sb $v0, ($a0)
	li $v0, 0xf4
	sb $v0, 1($a0)
	li $v0, 0x41
	sb $v0, 2($a0)

	add $a0, $t0, $t2	#x0 + x
	sub $a1, $t1, $t3	#y0 - y
	add $a2, $a0, $zero	#3 pixels per one point
	sll $a0, $a0, 1
	add $a0, $a0, $a2
	mul $a1, $a1, $s2	#Verse size
	add $a0, $a0, $a1	#Current pixel position
	add $a0, $a0, $s3	#Pixel position in file
	li $v0, 0x50
	sb $v0, ($a0)
	li $v0, 0xf4
	sb $v0, 1($a0)
	li $v0, 0x41
	sb $v0, 2($a0)

	sub $a0, $t0, $t2	#x0 - x
	add $a1, $t1, $t3	#y0 + y
	add $a2, $a0, $zero	#3 pixels per one point
	sll $a0, $a0, 1
	add $a0, $a0, $a2
	mul $a1, $a1, $s2	#Verse size
	add $a0, $a0, $a1	#Current pixel position
	add $a0, $a0, $s3	#Pixel position in file
	li $v0, 0x50
	sb $v0, ($a0)
	li $v0, 0xf4
	sb $v0, 1($a0)
	li $v0, 0x41
	sb $v0, 2($a0)

	add $a0, $t0, $t2	#x0 + x
	add $a1, $t1, $t3	#y0 + y
	add $a2, $a0, $zero	#3 pixels per one point
	sll $a0, $a0, 1
	add $a0, $a0, $a2
	mul $a1, $a1, $s2	#Verse size
	add $a0, $a0, $a1	#Current pixel position
	add $a0, $a0, $s3	#Pixel position in file
	li $v0, 0x50
	sb $v0, ($a0)
	li $v0, 0xf4
	sb $v0, 1($a0)
	li $v0, 0x41
	sb $v0, 2($a0)

#Bresenham's algorithm continue
	mul $t4, $t2, $t2	#x * x
	bge $t4, $t5, second	#if x * x >= limit

	ble $t6, $zero,	d0	#d > 0

	add $t6, $t6, $t8	#d += delta_B

	mul $a0, $s6, $s6	#a2 = a * a
	sll $a0, $a0, 3	#8 * a2

	mul $a1, $s7, $s7	#b2 = b * b
	sll $a1, $a1, 3	#8 * b2

	add $t7, $t7, $a1	#delta_A += 4 * 2 * b2
	add $t8, $t8, $a0	#delta_B += 4 * (2 * b2 + 2 * a2)
	add $t8, $t8, $a1

	addi $t2, $t2, 1	#x += 1
	addi $t3, $t3, -1	#y -= 1
	b next

d0:
	add $t6, $t6, $t7 #d += delta_A

	mul $a1, $s7, $s7 #b2 = b * b
	sll $a1, $a1, 3	#8 * b2

	add $t7, $t7, $a1	#delta_A += 4 * 2 * b2
	add $t8, $t8, $a1	#delta_B += 4 * 2 * b2
	addi $t2, $t2, 1	#x += 1

next:
	b loop

second:
	move $t0, $s6	#x0
	move $t1, $s7	#y0

	move $v0, $s6
	move $s6, $s7
	move $s7, $v0

	mul $t2, $s6, $s6 #a2 = a * a
	mul $t3, $s7, $s7 #b2 = b * b

	sll $t4, $t2, 2		#4 * a2
	sll $t5, $t3, 2		#4 * b2
	mul $t4, $t4, $s7	 #4 * b * a2

	sub $t6, $t5, $t4	#4 * b2 - 4 * b * a2
	add $t6, $t6, $t2	#d = 4 * b2 - 4 * b * a2 + $t2

	sll $t7, $t5, 1
	add $t7, $t7, $t5	#delta_A = 12 * b2

	sll $t4, $t4, 1		#8 * b * a2
	sub $t8, $t7, $t4
	sll $t4, $t2, 3
	add $t8, $t8, $t4	#delta_B = 4 * (3 * b2 - 2 * b * a2 + 2 * a2)

	add $t3, $t3, $t2	#a2 + b2
	mul $t2, $t2, $s6	#a2 * a2

	divu $t5, $t2, $t3	#limit = (a2 * a2 / a2 + b2)
	mul $t5, $t5, $s6

	move $t2, $zero	#x = 0
	move $t3, $s7	#y = b

loop2:
	sub $a0, $t0, $t3	#x0 - y
	sub $a1, $t1, $t2	#y0 - x
	add $a2, $a0, $zero	#3 pixels per one point
	sll $a0, $a0, 1
	add $a0, $a0, $a2
	mul $a1, $a1, $s2	#Verse size
	add $a0, $a0, $a1	#Current pixel position
	add $a0, $a0, $s3	#Pixel position in file
	li $v0, 0x42
	sb $v0, ($a0)
	li $v0, 0xee
	sb $v0, 1($a0)
	li $v0, 0xf4
	sb $v0, 2($a0)

	add $a0, $t0, $t3	#x0 + y
	sub $a1, $t1, $t2	#y0 - x
	add $a2, $a0, $zero	#3 pixels per one point
	sll $a0, $a0, 1
	add $a0, $a0, $a2
	mul $a1, $a1, $s2	#Verse size
	add $a0, $a0, $a1	#Current pixel position
	add $a0, $a0, $s3	#Pixel position in file
	li $v0, 0x42
	sb $v0, ($a0)
	li $v0, 0xee
	sb $v0, 1($a0)
	li $v0, 0xf4
	sb $v0, 2($a0)

	sub $a0, $t0, $t3	#x0 - y
	add $a1, $t1, $t2	#y0 + x
	add $a2, $a0, $zero	#3 pixels per one point
	sll $a0, $a0, 1
	add $a0, $a0, $a2
	mul $a1, $a1, $s2	#Verse size
	add $a0, $a0, $a1	#Current pixel position
	add $a0, $a0, $s3	#Pixel position in file
	li $v0, 0x42
	sb $v0, ($a0)
	li $v0, 0xee
	sb $v0, 1($a0)
	li $v0, 0xf4
	sb $v0, 2($a0)

	add $a0, $t0, $t3	#x0 + y
	add $a1, $t1, $t2	#y0 + x
	add $a2, $a0, $zero	#3 pixels per one point
	sll $a0, $a0, 1
	add $a0, $a0, $a2
	mul $a1, $a1, $s2	#Verse size
	add $a0, $a0, $a1	#Current pixel position
	add $a0, $a0, $s3	#Pixel position in file
	li $v0, 0x42
	sb $v0, ($a0)
	li $v0, 0xee
	sb $v0, 1($a0)
	li $v0, 0xf4
	sb $v0, 2($a0)

#Bresenham's algorithm continue
	mul $t4, $t2, $t2	#x * x
	bge $t4, $t5, end	#if x * x >= limit

	ble $t6, $zero,	d02	#d > 0

	add $t6, $t6, $t8	#d += delta_B

	mul $a0, $s6, $s6	#a2 = a * a
	sll $a0, $a0, 3	#8 * a2

	mul $a1, $s7, $s7	#b2 = b * b
	sll $a1, $a1, 3	#8 * b2

	add $t7, $t7, $a1	#delta_A += 4 * 2 * b2
	add $t8, $t8, $a0	#delta_B += 4 * (2 * b2 + 2 * a2)
	add $t8, $t8, $a1

	addi $t2, $t2, 1	#x += 1
	addi $t3, $t3, -1	#y -= 1
	b next2

d02:
	add $t6, $t6, $t7 #d += delta_A

	mul $a1, $s7, $s7 #b2 = b * b
	sll $a1, $a1, 3	#8 * b2

	add $t7, $t7, $a1	#delta_A += 4 * 2 * b2
	add $t8, $t8, $a1	#delta_B += 4 * 2 * b2
	addi $t2, $t2, 1	#x += 1

next2:
	b loop2

end: #JEST GIT
#Save the rest of the file
	li $v0, 15	#Write to file syscall
	add $a0, $s4, $zero	#File descriptor
	add $a1, $s3, $zero	#Address of input buffer
	add $a2, $s5, $zero	#Number of characters to write
	syscall

#Close file
	li $v0, 16
	add $a0, $s4, $zero	#Copying file pointer
	syscall

#Finish programme
	li $v0, 10
	syscall
