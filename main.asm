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
	# Ustawianie wskaŸnika na bufor pliku na jego pocz¹tek - musi siê to wydarzyæ przed procedur¹ getc, aby zapobiec niepoprawnemu wykonaniu w sytuacji,
	# gdy s³owo zostanie rozdzielone przez ograniczenie w rozmiarze bufora
	la	t2, word_buf
	# Ustawienie flagi informuj¹cej, ¿e przeszukiwane s³owo zaczyna siê w pierwszej kolumnie tekstu - podobnie jak wskaŸnik na bufor s³owa, musi to siê znaleŸæ przed getc
	li	a6, 1
getc:
	# £adowanie do buforu fragmentu pliku o wielkoœci okreœlonej w sta³ej FILE_BUFSIZE
	# Jeœli nie zosta³y odczytane wszystkie znaki z buforu, czytaj nastêpny znak
	bne	a3, a4, nextchar
	# Jeœli liczba wczeœniej wczytanych znaków by³a ró¿na od 0, zlicz liczbê znaków w buforze wyjœciowym, a nastêpnie zapisz go do pliku
	bnez	a4, count_result
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
	li	a5, 1	# Licznik linijek w pliku tekstowym
	la	s9, result_buf	# Ustaw wskaŸnik na bufor wyjœciowy
	# Ustawianie wskaŸnika na bufor pliku na jego pocz¹tek
	la	t0, file_buf
	b	nextchar
reset_word_buf_position:
	# Ustawianie wskaŸnika na bufor pliku na jego pocz¹tek
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
	mv	s11, t0	# Zapamiêtaj pozycjê w buforze wejœciowym
	beq	t1, t6, verify_space	# Jeœli znak jest spacj¹, dodaj go do buforu wyjœciowego
	beq	t1, t5, verify_new_line	# To samo dla znaku nowej linii
	addi	s8, s8, 1
	sb	t1, (t2)
	addi	t2, t2, 1
	bne	t1, t4, getc	# Czy znaleziono etykietê
	b	pre_save_label
verify_space:
	# Sprawdzanie, czy znak spacji jest poprzedzony s³owem
	beqz	s8, put_space	# Jeœli d³ugoœæ s³owa wynosi 0, znak spacji wystêpuje samodzielnie i nale¿y go przepisaæ do bufora wyjœciowego
	sb	zero, (t2)	# Dopisanie nulla na koniec s³owa w buforze
	la	t0, label_buf
	la	t2, word_buf
	b	check_label	# PrzejdŸ do sprawdzania, czy s³owo jest etykiet¹
verify_new_line:
	# Sprawdzanie, czy znak nowej linii jest poprzedzony s³owem
	addi	a5, a5, 1	# Inkrementacja wartoœci numeru linijki
	beqz	s8, put_new_line	# Jeœli d³ugoœæ s³owa wynosi 0, znak nowej linii wystêpuje samodzielnie i nale¿y go przepisaæ do bufora wyjœciowego
	sb	zero, (t2)	# Dopisanie nulla na koniec s³owa w buforze
	la	t0, label_buf
	la	t2, word_buf
check_label:
	# SprawdŸ, czy s³owo jest zdefiniowan¹ etykiet¹
	lbu	t1, (t0)
	lbu	t3, (t2)
	beqz	t1, put_word	# Jeœli w buforze etykiet wyst¹pi null, s³owo nie jest etykiet¹ i nale¿y je przepisaæ do bufora wyjœciowego
	beqz	t3, verify_label	# Jeœli w buforze s³owa wyst¹pi null, nale¿y sprawdziæ, czy jest to definicja etykiety
	addi	t0, t0, 1
	addi	t2, t2, 1
	beq	t1, t3, check_label	# Jeœli znaki w obu buforach siê zgadzaj¹, mo¿liwe, ¿e znaleziono etykietê
next_label:
	# Pêtla przechodz¹ca do nastêpnej definicji etykiety zapisanej w buforze
	lbu	t1, (t0)
	addi	t0, t0, 1
	bne	t1, t6, next_label	# Jeœli dotarliœmy do spacji, przestañ iterowaæ
	la	t2, word_buf
	b	check_label	# Powrót do sprawdzania, czy etykieta
verify_label:
	beq	t1, t4, put_line_number	# Jeœli w buforze etykiet jest dwukropek, jest to zdefiniowana wczeœniej etykieta i nale¿y przepisaæ numer linijki
	b	next_label	# Jeœli nie, nie jest to etykieta, szukaj dalej
pre_save_label:
	# Dodaj nulla na koniec s³owa w buforze
	sb	zero, -1(t2)
	beqz	a6, put_word	# Jeœli potencjalna etykieta nie zaczyna siê w pierwszej kolumnie tekstu, przepisz j¹ jako zwyk³e s³owo
	# Ustaw wskaŸnik na bufor etykiet
	la	t0, label_buf
	# Przesuñ wskaŸnik bufora s³owa na pocz¹tek
	la	t2, word_buf
pre_save_loop:
	# PrzejdŸ na koniec bufora etykiet
	lbu	t1, (t0)
	addi	t0, t0, 1
	bnez	t1, pre_save_loop
	addi	t0, t0, -1
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
	# Przygotowanie do odwracania numeru linijki
	li	t2, 0	# D³ugoœæ numeru linijki
	li	t3, 1
add_line_number:
	# Dodanie numeru linijki pliku (numer bêdzie zapisany odwrotnie - cyfra jednoœci po lewej)
	li	t6, 10	# Dzielnik
	beqz	t4, pre_reverse	# Jeœli dzielna bêdzie równa zero, odwróæ numer linijki
	addi	t2, t2, 1
	remu	t5, t4, t6	# Zapisz pojedyncz¹ cyfrê z linijki do rejestru
	divu	t4, t4, t6	# Dzielenie ca³kowite przez 10
add_character:
	addi	t5, t5, '0'	# Zamieñ cyfrê na odpowiadaj¹cy kod ASCII
	sb	t5, (t0)
	addi	t0, t0, 1
	b	add_line_number
pre_reverse: 
	addi	t0, t0, -1
	# Przeniesienie wartoœci rejestrów do innych, ju¿ nie u¿ywanych
	mv	t4, t2
	mv	t5, t3
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
	beq	t4, t5, post_reverse	# Jeœli numer linijki sk³ada siê tylko z jednej cyfry, pomiñ przesuwanie wskaŸnika bufora o 1
	addi	t2, t2, 1
post_reverse:
	# Dodaj znak spacji na koñcu zapisanego ci¹gu etykiety i numeru linijki
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
	mv	s9, t0	# Zapamiêtaj adres buforu wyjœciowego
	mv	t0, s11	# Przywróæ adres buforu wejœciowego
	li	s8, 0	# Resetowanie d³ugoœci s³owa
	li	a6, 0	# Ustawienie flagi - nastêpne s³owo nie zaczyna siê od pierwszej kolumny
	b	getc
put_word:
	# Zapisz s³owo do bufora wyjœciowego
	mv	t0, s9	# Za³aduj adres bufora wyjœciowego
	la	t2, word_buf
put_word_loop:
	lbu	t3, (t2)
	sb	t3, (t0)
	addi	t0, t0, 1
	addi	t2, t2, 1
	bnez	t3, put_word_loop
	mv	t2, s11	# Za³aduj adres buforu wejœciowego
	lbu	t1, -1(t2)
	sb	t1, -1(t0)	# Zapisz znak po s³owie
	mv	s9, t0	# Zapisz adres bufora wyjœciowego
	mv	t0, s11	# Za³aduj adres buforu wejœciowego
	li	s8, 0	# Resetowanie d³ugoœci s³owa
	li	t6, '\n'
	beq	t1, t6, set_column_flag
	li	a6, 0	# Ustawienie flagi - nastêpne s³owo nie zaczyna siê od pierwszej kolumny
	b	reset_word_buf_position
put_line_number:
	# Zapisz numer linijki etykiety do bufora wyjœciowego
	addi	t0, t0, 1	# Nie zapisuj dwukropka
	mv	t2, s9	# Za³aduj adres bufora wyjœciowego
put_line_number_loop:
	li	t3, ' '
	lbu	t1, (t0)
	sb	t1, (t2)
	addi	t0, t0, 1
	addi	t2, t2, 1
	bne	t1, t3, put_line_number_loop
	mv	t0, s11	# Za³aduj adres buforu wejœciowego
	lbu	t1, -1(t0)
	sb	t1, -1(t2)	# Zapisz znak po s³owie
	mv	s9, t2	# Zapisz adres bufora wyjœciowego
	li	s8, 0	# Resetowanie d³ugoœci s³owa
	li	t6, '\n'
	beq	t1, t6, set_column_flag
	li	a6, 0	# Ustawienie flagi - nastêpne s³owo nie zaczyna siê od pierwszej kolumny
	b	reset_word_buf_position
put_space:
	# Zapisz spacjê do bufora wyjœciowego
	mv	t0, s9	# Za³aduj adres bufora wyjœciowego
	li	t2, ' '
	sb	t2, (t0)	# Dopisz spacjê
	addi	t0, t0, 1
	mv	s9, t0	# Zapamiêtaj adres bufora wyjœciowego
	mv	t0, s11	# Przywróæ adres bufora wejœciowego
	li	s8, 0	# Resetowanie d³ugoœci s³owa
	li	a6, 0	# Ustawienie flagi - nastêpne s³owo nie zaczyna siê od pierwszej kolumny
	b	reset_word_buf_position
put_new_line:
	# Zapisz znak nowej linii do bufora wyjœciowego
	mv	t0, s9	# Za³aduj adres bufora wyjœciowego
	li	t2, '\n'
	sb	t2, (t0)	# Dopisz znak nowej linii
	addi	t0, t0, 1
	mv	s9, t0	# Zapamiêtaj adres bufora wyjœciowego
	mv	t0, s11	# Przywróæ adres bufora wejœciowego
	li	s8, 0	# Resetowanie d³ugoœci s³owa
set_column_flag:
	li	a6, 1	# Ustawienie flagi - nastêpne s³owo zaczyna siê od pierwszej kolumny
	b	reset_word_buf_position
count_result:
	# Zlicz liczbê znaków w buforze wyjœciowym
	li	a2, 0	# Licznik znajduje siê w rejestrze a2, aby mo¿na by³o go od razu u¿yæ do zapisania zawartoœci bufora do pliku
	la	t0, result_buf
count_loop:
	# Iteruj, dopóki nie bêdzie nulla
	lbu	t1, (t0)
	addi	t0, t0, 1
	addi	a2, a2, 1
	bnez	t1, count_loop
	addi	a2, a2, -1	# Usuñ koñcowego nulla z licznika
putc:
	# Zapisz bufor wyjœciowy do pliku
	mv	a0, s1
	la	a1, result_buf
	li	a7, WRITE
	ecall
	# Zresetowanie licznika odczytanych znaków
	li	a3, 0
	li	a4, 0
clear:
	# Czyszczenie zawartoœci buforów wejœciowego i wyjœciowego
	la	t0, file_buf
	la	t1, result_buf
	li	t3, 0
	li	t4, FILE_BUFSIZE
clear_loop:
	# Zamiana wszystkich znaków na nulle
	sb	zero, (t0)
	sb	zero, (t1)
	addi	t0, t0, 1
	addi	t1, t1, 1
	addi	t3, t3, 1
	bne	t3, t4, clear_loop
	b	getc	# Za³aduj kolejn¹ czêœæ pliku
end_of_file:
	# Zamkniêcie wszystkich plików
	mv	a0, s0
	li	a7, CLOSE
	ecall
	mv	a0, s1
	li	a7, CLOSE
	ecall
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

