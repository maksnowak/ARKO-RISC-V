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
result_buf:	.space FILE_BUFSIZE

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
	la	s9, result_buf	# Ustaw wskaŸnik na bufor wyjœciowy
	# Ustawianie wskaŸnika na bufor pliku na jego pocz¹tek
	la	t0, file_buf
	# Inkrementacja wartoœci aktualnej linijki pliku
	addi	a5, a5, 1
	# Ustawianie wskaŸnika na bufor pliku na jego koniec
	la	t2, word_buf
new_line:
	# Inkrementacja wartoœci aktualnej linijki pliku
	addi	a5, a5, 1
reset_word_buf_position:
	# Ustawianie wskaŸnika na bufor pliku na jego koniec
	la	t2, word_buf
	b 	getc
nextchar:
	# £adowanie rejestrów tymczasowych potrzebnymi wartoœciami
	li	t4, ':'	# Potrzebne do znajdowania etykiet
	li	t5, '\n'	# Potrzebne do poprawnego wypisywania numeru wiersza z etykiet¹
	li	t6, ' '	# Potrzebne do szukania pojedynczych s³ów
	# £adowanie kolejnego znaku z bufora
	lbu	t1, (t0)
	addi	t0, t0, 1
	addi	a3, a3, 1
	beq	t1, t6, reset_word_buf_position	# Jeœli znak jest spacj¹, ustaw wskaŸnik na pocz¹tek bufora s³owa
	beq	t1, t5, new_line	# To samo dla znaku nowej linii
	sb	t1, (t2)
	addi	t2, t2, 1
	bne	t1, t4, getc	# Czy znaleziono etykietê
	sb	zero, -1(t2)
	mv	s11, t0	# Zapamiêtaj pozycjê w buforze wejœciowym
pre_check_label:
	la	t0, label_buf
reset_word:
	la	t2, word_buf
check_label:
	# Sprawdzenie, czy etykieta w buforze
	lbu	t1, (t0)
	lbu	t3, (t2)
	beqz	t1, pre_save_label
	addi	t0, t0, 1
	addi	t2, t2, 1
	beq	t1, t3, check_label
	bne	t2, zero, reset_word
replace_label:
	# Kod procedury bêdzie tutaj
pre_save_label:
	# Przesuñ wskaŸnik bufora s³owa na pocz¹tek
	la	t2, word_buf
save_label:
	# Zapisz liczbê
	lbu	t3, (t2)
	sb	t3, (t0)
	addi	t0, t0, 1
	addi	t2, t2, 1
	bnez	t3, save_label
add_semicolon:
	# Dodanie dwukropka
	sb	t4, -1(t0)
	mv	s10, t0	# Zapamiêtanie adresu do powrotu przy odwracaniu numeru linijki
	mv	t4, a5
add_line_number:
	# Dodanie numeru linijki pliku (numer bêdzie zapisany odwrotnie - cyfra jednoœci po lewej)
	li	t6, 10	# Dzielnik
	beqz	t4, pre_reverse	# Jeœli dzielna bêdzie równa zero, odwróæ numer linijki
	remu	t5, t4, t6	# Zapisz pojedyncz¹ cyfrê z linijki do rejestru
	divu	t4, t4, t6	# Dzielenie ca³kowite przez 10
add_character:
	addi	t5, t5, '0'	# Zamieñ cyfrê na odpowiadaj¹cy kod ASCII
	sb	t5, (t0)
	addi	t0, t0, 1
	b	add_line_number
pre_reverse: 
	addi	t0, t0, -1
reverse:
	# Odwracanie numeru linijki do poprawnej wartoœci
	mv	t2, s10
	# Zamiana znaków miejscami
	lbu	t1, (t0)
	lbu	t3, (t2)
	sb	t1, (t2)
	sb	t3, (t0)
	addi	t0, t0, -1
	addi	t2, t2, 1
	ble	t2, t0, reverse	# Jeœli rejestr id¹cy do przodu wskazuje na adres mniejszy ni¿ rejestr id¹cy do ty³u, kontynnuj zamianê miejscami 
post_reverse:
	# Dodaj znak spacji na koñcu zapisanego ci¹gu etykiety i numeru linijki
	addi	t2, t2, 1
	li	t3, ' '
	sb	t3, (t2)
	# Przygotuj rejestry do zapisywania do buforu wyjœciowego
	mv	t0, s9
	la	t2, word_buf
put_label:
	# Zapisz zmodyfikowan¹ zawartoœæ do bufora wyjœciowego
	li	t1, ':'
	lbu	t3, (t2)
	sb	t3, (t0)	# Zachowanie zawartoœci bufora ze s³owem
	addi	t0, t0, 1
	addi	t2, t2, 1
	bne	t3, zero, put_label
	sb	t1, -1(t0)	# Dopisanie dwukropka
	mv	t2, s11	# Za³aduj pozycjê bufora wejœciowego
	lbu	t1, (t2)
	sb	t1, (t0)	# Dodaj znak, który znajdowa³ siê po definicji etykiety
	addi	t0, t0, 1
	mv	s9, t0	# Zapamiêtaj adres buforu wyjœciowego
	mv	t0, s11
	b	getc
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

