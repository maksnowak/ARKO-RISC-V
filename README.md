# [PL] Architektura Komputerów - Projekt RISC-V

To repozytorium zawiera projekt napisany w asemblerze RISC-V, będący jednym z zadań na przedmiocie Architektura Komputerów na Wydziale Elektroniki i Technik Informacyjnych Politechniki Warszawskiej.

Do uruchomienia programu potrzebny jest symulator [RARS](https://github.com/TheThirdOne/rars).

Program wczytuje plik o budowie podobnej do programu asemblerowego i zamienia odwołania do poprawnych etykiet (zaczynają się od pierwszej kolumny, poprawna nazwa zmiennej języka C) na numer linijki, w której dana etykieta została zdefiniowana.

# [EN] Computer Architecture - RISC-V Project

This repository contains a RISC-V assembly project, which is one of the tasks of the Computer Architecture class at Faculty of Electronics and Information Technology at Warsaw University of Technology.

The program has to be launched in [RARS](https://github.com/TheThirdOne/rars) simulator.

The program loads a text file similar to assembly code and replaces all references to correct labels (the label starts in the first column, its name has to be a correct C variable name) with a line number, in which the label was defined.
