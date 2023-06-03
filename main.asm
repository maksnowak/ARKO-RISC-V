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
result_buf:	.space FILE_BUFSIZE

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
	# Ustawianie wska�nika na bufor pliku na jego pocz�tek - musi si� to wydarzy� przed procedur� getc, aby zapobiec niepoprawnemu wykonaniu w sytuacji,
	# gdy s�owo zostanie rozdzielone przez ograniczenie w rozmiarze bufora
	la	t2, word_buf
	# Ustawienie flagi informuj�cej, �e przeszukiwane s�owo zaczyna si� w pierwszej kolumnie tekstu - podobnie jak wska�nik na bufor s�owa, musi to si� znale�� przed getc
	li	a6, 1
getc:
	# �adowanie do buforu fragmentu pliku o wielko�ci okre�lonej w sta�ej FILE_BUFSIZE
	# Je�li nie zosta�y odczytane wszystkie znaki z buforu, czytaj nast�pny znak
	bne	a3, a4, nextchar
	# Je�li liczba wcze�niej wczytanych znak�w by�a r�na od 0, zlicz liczb� znak�w w buforze wyj�ciowym, a nast�pnie zapisz go do pliku
	bnez	a4, count_result
	# �adowanie do buforu
	mv	a0, s0
	la	a1, file_buf
	li	a2, FILE_BUFSIZE
	li	a7, READ
	ecall
	# Je�li liczba za�adowanych znak�w wynosi 0, przejd� do procedury ko�cz�cej czytanie pliku
	beqz	a0, end_of_file
	# Za�aduj rejestry do sprawdzania, czy nale�y za�adowa� kolejn� cz�� pliku
	mv	a4, a0	# Zapisana liczba wczytanych znak�w
	li	a3, 0	# Licznik przeczytanych plik�w
	li	a5, 1	# Licznik linijek w pliku tekstowym
	la	s9, result_buf	# Ustaw wska�nik na bufor wyj�ciowy
	# Ustawianie wska�nika na bufor pliku na jego pocz�tek
	la	t0, file_buf
	b	nextchar
reset_word_buf_position:
	# Ustawianie wska�nika na bufor pliku na jego pocz�tek
	la	t2, word_buf
	b 	getc
nextchar:
	# �adowanie rejestr�w tymczasowych potrzebnymi warto�ciami
	li	t4, ':'	# Potrzebne do znajdowania etykiet
	li	t5, '\n'	# Potrzebne do poprawnego wypisywania numeru wiersza z etykiet�
	li	t6, ' '	# Potrzebne do szukania pojedynczych s��w
	# �adowanie kolejnego znaku z bufora
	lbu	t1, (t0)
	addi	t0, t0, 1
	addi	a3, a3, 1
	mv	s11, t0	# Zapami�taj pozycj� w buforze wej�ciowym
	beq	t1, t6, verify_space	# Je�li znak jest spacj�, dodaj go do buforu wyj�ciowego
	beq	t1, t5, verify_new_line	# To samo dla znaku nowej linii
	addi	s8, s8, 1
	sb	t1, (t2)
	addi	t2, t2, 1
	bne	t1, t4, getc	# Czy znaleziono etykiet�
	b	pre_save_label
verify_space:
	# Sprawdzanie, czy znak spacji jest poprzedzony s�owem
	beqz	s8, put_space	# Je�li d�ugo�� s�owa wynosi 0, znak spacji wyst�puje samodzielnie i nale�y go przepisa� do bufora wyj�ciowego
	sb	zero, (t2)	# Dopisanie nulla na koniec s�owa w buforze
	la	t0, label_buf
	la	t2, word_buf
	b	check_label	# Przejd� do sprawdzania, czy s�owo jest etykiet�
verify_new_line:
	# Sprawdzanie, czy znak nowej linii jest poprzedzony s�owem
	addi	a5, a5, 1	# Inkrementacja warto�ci numeru linijki
	beqz	s8, put_new_line	# Je�li d�ugo�� s�owa wynosi 0, znak nowej linii wyst�puje samodzielnie i nale�y go przepisa� do bufora wyj�ciowego
	sb	zero, (t2)	# Dopisanie nulla na koniec s�owa w buforze
	la	t0, label_buf
	la	t2, word_buf
check_label:
	# Sprawd�, czy s�owo jest zdefiniowan� etykiet�
	lbu	t1, (t0)
	lbu	t3, (t2)
	beqz	t1, put_word	# Je�li w buforze etykiet wyst�pi null, s�owo nie jest etykiet� i nale�y je przepisa� do bufora wyj�ciowego
	beqz	t3, verify_label	# Je�li w buforze s�owa wyst�pi null, nale�y sprawdzi�, czy jest to definicja etykiety
	addi	t0, t0, 1
	addi	t2, t2, 1
	beq	t1, t3, check_label	# Je�li znaki w obu buforach si� zgadzaj�, mo�liwe, �e znaleziono etykiet�
next_label:
	# P�tla przechodz�ca do nast�pnej definicji etykiety zapisanej w buforze
	lbu	t1, (t0)
	addi	t0, t0, 1
	bne	t1, t6, next_label	# Je�li dotarli�my do spacji, przesta� iterowa�
	la	t2, word_buf
	b	check_label	# Powr�t do sprawdzania, czy etykieta
verify_label:
	beq	t1, t4, put_line_number	# Je�li w buforze etykiet jest dwukropek, jest to zdefiniowana wcze�niej etykieta i nale�y przepisa� numer linijki
	b	next_label	# Je�li nie, nie jest to etykieta, szukaj dalej
pre_save_label:
	# Dodaj nulla na koniec s�owa w buforze
	sb	zero, -1(t2)
	beqz	a6, put_word	# Je�li potencjalna etykieta nie zaczyna si� w pierwszej kolumnie tekstu, przepisz j� jako zwyk�e s�owo
	# Ustaw wska�nik na bufor etykiet
	la	t0, label_buf
	# Przesu� wska�nik bufora s�owa na pocz�tek
	la	t2, word_buf
pre_save_loop:
	# Przejd� na koniec bufora etykiet
	lbu	t1, (t0)
	addi	t0, t0, 1
	bnez	t1, pre_save_loop
	addi	t0, t0, -1
save_label:
	# Zapisz liczb�
	lbu	t3, (t2)
	sb	t3, (t0)
	addi	t0, t0, 1
	addi	t2, t2, 1
	bnez	t3, save_label
add_semicolon:
	# Dodanie dwukropka
	sb	t4, -1(t0)
	mv	s10, t0	# Zapami�tanie adresu do powrotu przy odwracaniu numeru linijki
	mv	t4, a5
	# Przygotowanie do odwracania numeru linijki
	li	t2, 0	# D�ugo�� numeru linijki
	li	t3, 1
add_line_number:
	# Dodanie numeru linijki pliku (numer b�dzie zapisany odwrotnie - cyfra jedno�ci po lewej)
	li	t6, 10	# Dzielnik
	beqz	t4, pre_reverse	# Je�li dzielna b�dzie r�wna zero, odwr�� numer linijki
	addi	t2, t2, 1
	remu	t5, t4, t6	# Zapisz pojedyncz� cyfr� z linijki do rejestru
	divu	t4, t4, t6	# Dzielenie ca�kowite przez 10
add_character:
	addi	t5, t5, '0'	# Zamie� cyfr� na odpowiadaj�cy kod ASCII
	sb	t5, (t0)
	addi	t0, t0, 1
	b	add_line_number
pre_reverse: 
	addi	t0, t0, -1
	# Przeniesienie warto�ci rejestr�w do innych, ju� nie u�ywanych
	mv	t4, t2
	mv	t5, t3
reverse:
	# Odwracanie numeru linijki do poprawnej warto�ci
	mv	t2, s10
	# Zamiana znak�w miejscami
	lbu	t1, (t0)
	lbu	t3, (t2)
	sb	t1, (t2)
	sb	t3, (t0)
	addi	t0, t0, -1
	addi	t2, t2, 1
	ble	t2, t0, reverse	# Je�li rejestr id�cy do przodu wskazuje na adres mniejszy ni� rejestr id�cy do ty�u, kontynnuj zamian� miejscami
	beq	t4, t5, post_reverse	# Je�li numer linijki sk�ada si� tylko z jednej cyfry, pomi� przesuwanie wska�nika bufora o 1
	addi	t2, t2, 1
post_reverse:
	# Dodaj znak spacji na ko�cu zapisanego ci�gu etykiety i numeru linijki
	li	t3, ' '
	sb	t3, (t2)
	# Przygotuj rejestry do zapisywania do buforu wyj�ciowego
	mv	t0, s9
	la	t2, word_buf
put_label:
	# Zapisz zmodyfikowan� zawarto�� do bufora wyj�ciowego
	li	t1, ':'
	lbu	t3, (t2)
	sb	t3, (t0)	# Zachowanie zawarto�ci bufora ze s�owem
	addi	t0, t0, 1
	addi	t2, t2, 1
	bne	t3, zero, put_label
	sb	t1, -1(t0)	# Dopisanie dwukropka
	mv	s9, t0	# Zapami�taj adres buforu wyj�ciowego
	mv	t0, s11	# Przywr�� adres buforu wej�ciowego
	li	s8, 0	# Resetowanie d�ugo�ci s�owa
	li	a6, 0	# Ustawienie flagi - nast�pne s�owo nie zaczyna si� od pierwszej kolumny
	b	getc
put_word:
	# Zapisz s�owo do bufora wyj�ciowego
	mv	t0, s9	# Za�aduj adres bufora wyj�ciowego
	la	t2, word_buf
put_word_loop:
	lbu	t3, (t2)
	sb	t3, (t0)
	addi	t0, t0, 1
	addi	t2, t2, 1
	bnez	t3, put_word_loop
	mv	t2, s11	# Za�aduj adres buforu wej�ciowego
	lbu	t1, -1(t2)
	sb	t1, -1(t0)	# Zapisz znak po s�owie
	mv	s9, t0	# Zapisz adres bufora wyj�ciowego
	mv	t0, s11	# Za�aduj adres buforu wej�ciowego
	li	s8, 0	# Resetowanie d�ugo�ci s�owa
	li	t6, '\n'
	beq	t1, t6, set_column_flag
	li	a6, 0	# Ustawienie flagi - nast�pne s�owo nie zaczyna si� od pierwszej kolumny
	b	reset_word_buf_position
put_line_number:
	# Zapisz numer linijki etykiety do bufora wyj�ciowego
	addi	t0, t0, 1	# Nie zapisuj dwukropka
	mv	t2, s9	# Za�aduj adres bufora wyj�ciowego
put_line_number_loop:
	li	t3, ' '
	lbu	t1, (t0)
	sb	t1, (t2)
	addi	t0, t0, 1
	addi	t2, t2, 1
	bne	t1, t3, put_line_number_loop
	mv	t0, s11	# Za�aduj adres buforu wej�ciowego
	lbu	t1, -1(t0)
	sb	t1, -1(t2)	# Zapisz znak po s�owie
	mv	s9, t2	# Zapisz adres bufora wyj�ciowego
	li	s8, 0	# Resetowanie d�ugo�ci s�owa
	li	t6, '\n'
	beq	t1, t6, set_column_flag
	li	a6, 0	# Ustawienie flagi - nast�pne s�owo nie zaczyna si� od pierwszej kolumny
	b	reset_word_buf_position
put_space:
	# Zapisz spacj� do bufora wyj�ciowego
	mv	t0, s9	# Za�aduj adres bufora wyj�ciowego
	li	t2, ' '
	sb	t2, (t0)	# Dopisz spacj�
	addi	t0, t0, 1
	mv	s9, t0	# Zapami�taj adres bufora wyj�ciowego
	mv	t0, s11	# Przywr�� adres bufora wej�ciowego
	li	s8, 0	# Resetowanie d�ugo�ci s�owa
	li	a6, 0	# Ustawienie flagi - nast�pne s�owo nie zaczyna si� od pierwszej kolumny
	b	reset_word_buf_position
put_new_line:
	# Zapisz znak nowej linii do bufora wyj�ciowego
	mv	t0, s9	# Za�aduj adres bufora wyj�ciowego
	li	t2, '\n'
	sb	t2, (t0)	# Dopisz znak nowej linii
	addi	t0, t0, 1
	mv	s9, t0	# Zapami�taj adres bufora wyj�ciowego
	mv	t0, s11	# Przywr�� adres bufora wej�ciowego
	li	s8, 0	# Resetowanie d�ugo�ci s�owa
set_column_flag:
	li	a6, 1	# Ustawienie flagi - nast�pne s�owo zaczyna si� od pierwszej kolumny
	b	reset_word_buf_position
count_result:
	# Zlicz liczb� znak�w w buforze wyj�ciowym
	li	a2, 0	# Licznik znajduje si� w rejestrze a2, aby mo�na by�o go od razu u�y� do zapisania zawarto�ci bufora do pliku
	la	t0, result_buf
count_loop:
	# Iteruj, dop�ki nie b�dzie nulla
	lbu	t1, (t0)
	addi	t0, t0, 1
	addi	a2, a2, 1
	bnez	t1, count_loop
	addi	a2, a2, -1	# Usu� ko�cowego nulla z licznika
putc:
	# Zapisz bufor wyj�ciowy do pliku
	mv	a0, s1
	la	a1, result_buf
	li	a7, WRITE
	ecall
	# Zresetowanie licznika odczytanych znak�w
	li	a3, 0
	li	a4, 0
clear:
	# Czyszczenie zawarto�ci bufor�w wej�ciowego i wyj�ciowego
	la	t0, file_buf
	la	t1, result_buf
	li	t3, 0
	li	t4, FILE_BUFSIZE
clear_loop:
	# Zamiana wszystkich znak�w na nulle
	sb	zero, (t0)
	sb	zero, (t1)
	addi	t0, t0, 1
	addi	t1, t1, 1
	addi	t3, t3, 1
	bne	t3, t4, clear_loop
	b	getc	# Za�aduj kolejn� cz�� pliku
end_of_file:
	# Zamkni�cie wszystkich plik�w
	mv	a0, s0
	li	a7, CLOSE
	ecall
	mv	a0, s1
	li	a7, CLOSE
	ecall
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

