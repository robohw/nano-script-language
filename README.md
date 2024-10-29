Nano is a Turing-complete, general-purpose scripting language with minimalist, esoteric features. From now on, nano is just "language". The interpreter of the language is just over 300 lines of pascal code and can be easily integrated or even supplemented.
The language's mathematical support is minimal. This means that the language cannot use parentheses at all, and mathematical expressions can contain only one mathematical operator per line. Complex mathematical expressions must be broken down.
In the language, the value assignment operator is the "=" character. Example: B = 27, or B = C + 5
Nano is an absolute minimalist language, which is well emphasized by the few (five) keywords (IF, PRN, JMP, RET, INP) and the three logical operators (less than, greater than, equal to). Nano also knows only five arithmetic operators, modulo ("%") in addition to the four (add, sub, mul, div) basic operations.
The language supports labels. The first character of these must be a dot ("."). Subroutines can be formed with labels and the RET (return) instruction. Simple example:

.MYLABEL
B = B + 1
PRN B
RET

IF B < 10 JMP .MYLABEL

Front and back testing and incremental cycles can also be created with the help of labels and JMP. Example:

B = 0
.LOOP
B = B + 1
PRN B T
IF B < 10 JMP .LOOP

TRC
B = 0
U = "END of PROGRAM"
.PAIR
B = R
P = 1
N = B % 2
IF N < 1 P = 0
PRN B
PRN P
IF B > 20 JMP .END
JMP .PAIR
.END
PRN U

---------------------------------------------------------------------

A nano egy minimalista, ezoterikus jellegeket is felmutató, Turing teljes, általános célú script nyelv. A továbbiakban nano vagy csak "nyelv". A nyelv interpretere alig több mint 300 sor pascal kód és könnyen beépíthető illetve, akár ki is egészíthető.  
A nyelv matematikai támogatottsága minimális. Ez azt jelenti, hogy a nyelvben zárójelezést egyáltalán nem lehet alkalmazni, a matematikai kifejezések pedig soronként csak egy matematikai operátort tartalmazhatnak.  Az összetett matematikai kifejezéseket fel kell bontani. 
A nyelvben az értékadás operátora a "=" karakter. Példa: B = 27, vagy B = C + 5
A nano egy abszolút minimalista nyelv, amit jól hangsúlyoz a kevés (öt) kulcsszó (IF, PRN, JMP, RET, INP) és a három logikai operátor (kisebb, nagyobb, egyenlő). Aritmetikai operátorok közül is  csak ötöt ismer a nano, a négy alapművelet mellett a modulo-t ("%").
A nyelv támogatja a cimkéket. Ezek első karaktere kötelezően a pont ("."). A cimkékkel és a RET (return) utasítással szubrutinok képezhetők. Egyszerű példa:

.MYLABEL
B = B + 1
PRN B 
RET

IF B < 10 JMP .MYLABEL

Elöl és hátul tesztelős, illetve növekményes ciklusok is a cimkék és a JMP segítségével képezhetők. Példa: 

B = 0
.LOOP 
B = B + 1 
PRN B T
IF B < 10 JMP .LOOP

TRC
B = 0
U = "END of PROGRAM"
.PAIR
B = R
P = 1
N = B % 2
IF N < 1 P = 0
PRN B
PRN P
IF B > 20 JMP .END 
JMP .PAIR  
.END 
PRN U 
