#########################################################################################
# 20.	Program przetwarza plik tekstowy o budowie podobnej do programu asemblerowego,
# 	zawieraj¹cy definicje symboli-etykiet i inny tekst, zawieraj¹cy zdefiniowane symbole.
# 	Definicja rozpoczyna siê w pierwszej kolumnie tekstu i sk³ada siê z nazwy, po której
# 	nastêpuje znak dwukropka. Definicja nadaje etykiecie wartoœæ równ¹ numerowi wiersza
# 	tekstu. Nazwa symbolu jest wa¿nym identyfikatorem jêzyka C. Program tworzy plik
# 	wyjœciowy, w którym w pozosta³ym tekœcie zast¹piono symbole zdefiniowane przed ich
# 	wyst¹pieniem ich wartoœciami, np.:
# 	Wejœcie
# 		a:
# 		value a
# 		bbb: a + 6
# 		bbb + c * a
# 	Wyjœcie
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
	# Podawanie œcie¿ki wejœciowej
	la	a0, input
	li	a7, CON_PRTSTR
	ecall
	# £adowanie œcie¿ki do bufora
	la	a0, input_buf
	li	a1, PATH_BUFSIZE
	li	a7, CON_RDSTR	
	ecall
	# Usuwanie znaku nowej linii z koñca œcie¿ki
	li	t0, '\n'
	la	t1, input_buf
remove_input_newline:
	lbu	t2, (t1)
	addi	t1, t1, 1
	bne	t2, t0, remove_input_newline
	sb	zero, -1(t1)
open_input:
	# Otwieranie pliku wejœciowego
	la	a0, input_buf
	li	a1, READ_FLAG
	li	a7, OPEN
	ecall
	li	t0, -1
	beq	a0, t0, error_fin	# Jeœli plik nie istnieje, zwróæ b³¹d i zakoñcz program
	mv	s0, a0	# Zapisz deskryptor pliku wejœciowego do nowego rejestru
output_path:
	# Podawanie œcie¿ki wyjœciowej
	la	a0, output
	li	a7, CON_PRTSTR
	ecall
	# £adowanie œcie¿ki do bufora
	la	a0, output_buf
	li	a1, PATH_BUFSIZE
	li	a7, CON_RDSTR
	ecall
	# Usuwanie znaku nowej linii z koñca œcie¿ki
	li	t0, '\n'
	la	t1, output_buf
remove_output_newline:
	lbu	t2, (t1)
	addi	t1, t1, 1
	bne	t2, t0, remove_output_newline
	sb	zero, -1(t1)
open_output:
	# Otwieranie pliku wyjœciowego
	la	a0, output_buf
	li	a1, WRITE_FLAG
	li	a7, OPEN
	ecall
	mv	s1, a0	# Zapisz deskryptor pliku wyjœciowego do nowego rejestru
getc:
	# £adowanie do buforu fragmentu pliku o wielkoœci okreœlonej w sta³ej FILE_BUFSIZE
	# Jeœli nie zosta³y odczytane wszystkie znaki z buforu, czytaj nastêpny znak
	bne	a3, a4, nextchar
	# £adowanie do buforu
	mv	a0, s0
	la	a1, file_buf
	li	a2, FILE_BUFSIZE
	li	a7, READ
	ecall
	# Jeœli liczba za³adowanych znaków wynosi 0, przejdŸ do procedury koñcz¹cej czytanie pliku
	beqz	a0, end_of_file
	# Za³aduj rejestry do sprawdzania, czy nale¿y za³adowaæ kolejn¹ czêœæ pliku
	mv	a4, a0	# Zapisana liczba wczytanych znaków
	li	a3, 0	# Licznik przeczytanych plików
	li	a5, 0	# Licznik linijek w pliku tekstowym
nextchar:
	# Kod procedury bêdzie tutaj
end_of_file:
	# Kod procedury bêdzie tutaj
fin:
	# Zakoñczenie programu
	li	a7, SYS_EXIT0
	ecall
error_fin:
	# Wypisanie komunikatu o b³êdzie
	la	a0, error
	li	a7, CON_PRTSTR
	ecall
	# Zakoñczenie programu
	li	a7, SYS_EXIT0
	ecall

