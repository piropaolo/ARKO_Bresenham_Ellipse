.data
	prompt: .asciiz "Enter major axis: "
	prompt2:	.asciiz	"Enter minor axis: "
	nazwa_pliku: .asciiz "Ellipse.bmp"
	.align 2
	header: .space 56
.text

#$s0 - image width
#$s1 - image height
#$s2 - image width with excess
#$s3 - image buffer adress
#$s4 - file beginning adress
#$s5 - image size
#$s6 - semi-major axis
#$s7 - semi-minor axis

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
	add $s5, $t1, $zero	#Remember for later

	li $v0, 9		#Allocate memory (nr of bytes)
	add $a0, $t1, $zero
	syscall
	add $s3, $v0, $zero	#Remember the adress to the allocated memory

	addi $t1, $t1, 54	#Rozmiar ca�ego pliku czyli rozmiar obrazka i naglowek w $t1
	sw $t1, 4($t0)		#Wpisz rozmiar ca�ego pliku do nag��wka

	li $t1, 54		#54 - offset danych (rozmiar nag��wka)
	sw $t1, 12($t0)
	li $t1, 40		#40 - d�ugo�� do ko�ca nag��wka
	sw $t1, 16($t0)
	add $t1, $s0, $zero	#Skopiuj szeroko��/wysoko�� obrazka
	sw $t1, 20($t0)		#szeroko��
	add $t1, $s1, $zero
	sw $t1, 24($t0)		#wysoko��
	li $t1, 1		#1 - ilo�� wartstw kolor�w
	sw $t1, 28($t0)
	li $t1, 24		#24 - liczba bit�w na piksel (3 kolory po 8 bit�w ka�dy)
	sb $t1, 30($t0)
#Otw�rz plik do zapisu
	li $v0, 13		#Otwieranie pliku
	la $a0, nazwa_pliku	#Wczytanie adresu na nazw� p	liku
	li $a1, 1		#1 - bo plik do odczytu
	li $a2, 0		#0 - flaga
	syscall
	add $s4, $v0, $zero	#Zapami�tanie wska�nika na plik w $s3
#Zapisz nag��wek
	li $v0, 15
	add $a0, $s4, $zero	#Skopowianie wska�nika na plik
	la $a1, header+2	#Pocz�tek zapisywanych danych
	li $a2, 54		#Ilo�� bit�w do zapisania (rozmiar nag��wka)
	syscall

#Bresenham's algorithm
	move $t0, $s6	#x0
	move $t1, $s7 #y0

	mul $t2, $t0, $t0 #a2 = a * a
	mul $t3, $t1, $t1 #b2 = b * b

	sll $t4, $t2, 2	#4 * a2
	sll $t5, $t3, 2	#4 * b2
	mul $t4, $t4, $s7 #4 * b * a2

	sub $t6, $t5, $t4	#4 * b2 - 4 * b * a2
	add $t6, $t6, $t2	#d = 4 * b2 - 4 * b * a2 + $t2

	mul $t7, $t5, 3	#delta_A = 12 * b2

	sll $t4, $t4, 1	#8 * b * a2
	sub $t8, $t7, $t4
	add $t8, $t8, $t2
	add $t8, $t8, $t2	#delta_B

	add $t3, $t3, $t2
	mul $t2, $t2, $t2

	div $t5, $t2, $t3

	move $t2, $zero
	move $t3, $s7

petla:
#Ustawianie kolor�w pikseli:
#Ustaw kolor piksela 1
sub $a0, $t0, $t2	# x0 - x
sub $a1, $t1, $t3	# y0 - y
add $a2, $a0, $zero	# *= 3 (bo po 3 piksele na jeden punkt)
sll $a0, $a0, 1
add $a0, $a0, $a2
mul $a1, $a1, $s2	# *= wielko��_wiersza (bo przesuni�cie o ile�tam linii w d��)
add $a0, $a0, $a1	# Obecna pozycja piksela
add $a0, $a0, $s3	# Pozycja piksela wzgl�dem pocz�tku pliku (dodaj� do adresu pocz�tku pliku)
li $v0, 0xff		#Kolor na czarny
sb $v0, ($a0)		#Kolor niebieski
sb $v0, 1($a0)		#Kolor zielony
sb $v0, 2($a0)		#Kolor czerwony  (255,255,255)

add $a0, $t0, $t2	# x0 - x
sub $a1, $t1, $t3	# y0 - y
add $a2, $a0, $zero	# *= 3 (bo po 3 piksele na jeden punkt)
sll $a0, $a0, 1
add $a0, $a0, $a2
mul $a1, $a1, $s2	# *= wielko��_wiersza (bo przesuni�cie o ile�tam linii w d��)
add $a0, $a0, $a1	# Obecna pozycja piksela
add $a0, $a0, $s3	# Pozycja piksela wzgl�dem pocz�tku pliku (dodaj� do adresu pocz�tku pliku)
li $v0, 0xff		#Kolor na czarny
sb $v0, ($a0)		#Kolor niebieski
sb $v0, 1($a0)		#Kolor zielony
sb $v0, 2($a0)		#Kolor czerwony  (255,255,255)

sub $a0, $t0, $t2	# x0 - x
add $a1, $t1, $t3	# y0 - y
add $a2, $a0, $zero	# *= 3 (bo po 3 piksele na jeden punkt)
sll $a0, $a0, 1
add $a0, $a0, $a2
mul $a1, $a1, $s2	# *= wielko��_wiersza (bo przesuni�cie o ile�tam linii w d��)
add $a0, $a0, $a1	# Obecna pozycja piksela
add $a0, $a0, $s3	# Pozycja piksela wzgl�dem pocz�tku pliku (dodaj� do adresu pocz�tku pliku)
li $v0, 0xff		#Kolor na czarny
sb $v0, ($a0)		#Kolor niebieski
sb $v0, 1($a0)		#Kolor zielony
sb $v0, 2($a0)		#Kolor czerwony  (255,255,255)

add $a0, $t0, $t2	# x0 - x
add $a1, $t1, $t3	# y0 - y
add $a2, $a0, $zero	# *= 3 (bo po 3 piksele na jeden punkt)
sll $a0, $a0, 1
add $a0, $a0, $a2
mul $a1, $a1, $s2	# *= wielko��_wiersza (bo przesuni�cie o ile�tam linii w d��)
add $a0, $a0, $a1	# Obecna pozycja piksela
add $a0, $a0, $s3	# Pozycja piksela wzgl�dem pocz�tku pliku (dodaj� do adresu pocz�tku pliku)
li $v0, 0xff		#Kolor na czarny
sb $v0, ($a0)		#Kolor niebieski
sb $v0, 1($a0)		#Kolor zielony
sb $v0, 2($a0)		#Kolor czerwony  (255,255,255)

mul $t4, $t2, $t2
bge $t4, $t5, koniec

bltz $t6, d0

	add $t6, $t6, $t8

	mul $a0, $s6, $s6
	sll $a0, $a0, 3

	mul $a1, $s7, $s7
	sll $a1, $a1, 3

	add $t7, $t7, $a1
	add $t8, $t8, $a0
	add $t8, $t8, $a1

	addi $t2, $t2, 1
	addi $t3, $t3, -1
	b dalej
d0:
	add $t6, $t6, $t7

	mul $a1, $s7, $s7
	sll $a1, $a1, 3

	add $t7, $t7, $a1
	add $t8, $t8, $a1
	addi $t2, $t2, 1

dalej:
	b petla

koniec:
#Zapisz reszt� pliku
	li $v0, 15		#zapis
	add $a0, $s4, $zero	#Skopiowanie wska�nika na plik
	add $a1, $s3, $zero	#Skopiowanie adresu bufora
	add $a2, $s5, $zero	#Skopiowanie ilo�ci pikseli obrazka
	syscall
#Zamknij plik
	li $v0, 16
	add $a0, $s4, $zero	#Skopiowanie wska�nika na plik
	syscall
#Zako�cz program
	li $v0, 10
	syscall
