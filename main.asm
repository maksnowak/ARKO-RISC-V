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
getc:
	# �adowanie do buforu fragmentu pliku o wielko�ci okre�lonej w sta�ej FILE_BUFSIZE
	# Je�li nie zosta�y odczytane wszystkie znaki z buforu, czytaj nast�pny znak
	bne	a3, a4, nextchar
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
	li	a5, 0	# Licznik linijek w pliku tekstowym
	la	s9, result_buf	# Ustaw wska�nik na bufor wyj�ciowy
	# Ustawianie wska�nika na bufor pliku na jego pocz�tek
	la	t0, file_buf
	# Inkrementacja warto�ci aktualnej linijki pliku
	addi	a5, a5, 1
	# Ustawianie wska�nika na bufor pliku na jego koniec
	la	t2, word_buf
new_line:
	# Inkrementacja warto�ci aktualnej linijki pliku
	addi	a5, a5, 1
reset_word_buf_position:
	# Ustawianie wska�nika na bufor pliku na jego koniec
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
	beq	t1, t6, reset_word_buf_position	# Je�li znak jest spacj�, ustaw wska�nik na pocz�tek bufora s�owa
	beq	t1, t5, new_line	# To samo dla znaku nowej linii
	sb	t1, (t2)
	addi	t2, t2, 1
	bne	t1, t4, getc	# Czy znaleziono etykiet�
	sb	zero, -1(t2)
	mv	s11, t0	# Zapami�taj pozycj� w buforze wej�ciowym
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
	# Kod procedury b�dzie tutaj
pre_save_label:
	# Przesu� wska�nik bufora s�owa na pocz�tek
	la	t2, word_buf
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
add_line_number:
	# Dodanie numeru linijki pliku (numer b�dzie zapisany odwrotnie - cyfra jedno�ci po lewej)
	li	t6, 10	# Dzielnik
	beqz	t4, pre_reverse	# Je�li dzielna b�dzie r�wna zero, odwr�� numer linijki
	remu	t5, t4, t6	# Zapisz pojedyncz� cyfr� z linijki do rejestru
	divu	t4, t4, t6	# Dzielenie ca�kowite przez 10
add_character:
	addi	t5, t5, '0'	# Zamie� cyfr� na odpowiadaj�cy kod ASCII
	sb	t5, (t0)
	addi	t0, t0, 1
	b	add_line_number
pre_reverse: 
	addi	t0, t0, -1
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
post_reverse:
	# Dodaj znak spacji na ko�cu zapisanego ci�gu etykiety i numeru linijki
	addi	t2, t2, 1
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
	mv	t2, s11	# Za�aduj pozycj� bufora wej�ciowego
	lbu	t1, (t2)
	sb	t1, (t0)	# Dodaj znak, kt�ry znajdowa� si� po definicji etykiety
	addi	t0, t0, 1
	mv	s9, t0	# Zapami�taj adres buforu wyj�ciowego
	mv	t0, s11
	b	getc
end_of_file:
	# Kod procedury b�dzie tutaj
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

