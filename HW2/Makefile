parser: lex.yy.c y.tab.c
	gcc -o parser lex.yy.c y.tab.c -lfl

y.tab.c y.tab.h: parser.y
	byacc -d parser.y

lex.yy.c: scanner.l 
	flex scanner.l

clean:
	rm -f scanner lex.yy.c