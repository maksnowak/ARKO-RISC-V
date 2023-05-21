#########################################################################################
# 20.	Program przetwarza plik tekstowy o budowie podobnej do programu asemblerowego,
# 	zawieraj�cy definicje symboli-etykiet i inny tekst, zawieraj�cy zdefiniowane symbole.
# 	Definicja rozpoczyna si� w pierwszej kolumnie tekstu i sk�ada si� z nazwy, po kt�rej
# 	nast�puje znak dwukropka. Definicja nadaje etykiecie warto�� r�wn� numerowi wiersza
# 	tekstu. Nazwa symbolu jest wa�nym identyfikatorem j�zyka C. Program tworzy plik
# 	wyj�ciowy, w kt�rym w pozosta�ym tek�cie zast�piono symbole zdefiniowane przed ich
# 	wyst�pieniem ich warto�ciami, np.:
# 	Wej�cie
# 		a:
# 		value a
# 		bbb: a + 6
# 		bbb + c * a
# 	Wyj�cie
# 		a:
# 		value 1
# 		bbb: 1 + 6
# 		3 + c * 1
#########################################################################################

	.eqv	SYS_EXIT0, 10
	.eqv	OPEN, 1024
	.eqv	CLOSE, 57
	.eqv	FILE_BUFSIZE, 512
	.eqv	PATH_BUFSIZE, 100
	.eqv	WORD_BUFSIZE, 32
	.eqv	LABEL_BUFSIZE, 512
	.eqv	READ, 63
	.eqv	WRITE, 64
	.eqv	CON_PRTSTR, 4
	.eqv	CON_RDSTR, 8
	.eqv	READ_FLAG, 0
	.eqv	WRITE_FLAG, 1
	.eqv	APPEND_FLAG, 9
	
	.data
input:	.asciz "Enter input path: "
output:	.asciz "Enter output path: "
error:	.asciz "Error - the input file does not exist"
input_buf:	.space PATH_BUFSIZE
output_buf:	.space PATH_BUFSIZE
file_buf:	.space FILE_BUFSIZE
word_buf:	.space WORD_BUFSIZE
label_buf:	.space LABEL_BUFSIZE

	.text
main:
	# Podawanie �cie�ki wej�ciowej
	la	a0, input
	li	a7, CON_PRTSTR
	ecall
	# �adowanie �cie�ki do bufora
	la	a0, input_buf
	li	a1, PATH_BUFSIZE
	li	a7, CON_RDSTR	
	ecall
	# Usuwanie znaku nowej linii z ko�ca �cie�ki
	li	t0, '\n'
	la	t1, input_buf
remove_input_newline:
	lbu	t2, (t1)
	addi	t1, t1, 1
	bne	t2, t0, remove_input_newline
	sb	zero, -1(t1)
open_input:
	# Otwieranie pliku wej�ciowego
	la	a0, input_buf
	li	a1, READ_FLAG
	li	a7, OPEN
	ecall
	li	t0, -1
	beq	a0, t0, error_fin	# Je�li plik nie istnieje, zwr�� b��d i zako�cz program
	mv	s0, a0	# Zapisz deskryptor pliku wej�ciowego do nowego rejestru
output_path:
	# Podawanie �cie�ki wyj�ciowej
	la	a0, output
	li	a7, CON_PRTSTR
	ecall
	# �adowanie �cie�ki do bufora
	la	a0, output_buf
	li	a1, PATH_BUFSIZE
	li	a7, CON_RDSTR
	ecall
	# Usuwanie znaku nowej linii z ko�ca �cie�ki
	li	t0, '\n'
	la	t1, output_buf
remove_output_newline:
	lbu	t2, (t1)
	addi	t1, t1, 1
	bne	t2, t0, remove_output_newline
	sb	zero, -1(t1)
open_output:
	# Otwieranie pliku wyj�ciowego
	la	a0, output_buf
	li	a1, WRITE_FLAG
	li	a7, OPEN
	ecall
	mv	s1, a0	# Zapisz deskryptor pliku wyj�ciowego do nowego rejestru
fin:
	# Zako�czenie programu
	li	a7, SYS_EXIT0
	ecall
error_fin:
	# Wypisanie komunikatu o b��dzie
	la	a0, error
	li	a7, CON_PRTSTR
	ecall
	# Zako�czenie programu
	li	a7, SYS_EXIT0
	ecall

