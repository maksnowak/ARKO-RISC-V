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
