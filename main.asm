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
