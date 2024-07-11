codegen: lex.yy.c y.tab.c
	gcc -o codegen lex.yy.c y.tab.c code.c -lfl

y.tab.c y.tab.h: parser.y
	byacc -d parser.y

lex.yy.c: scanner.l 
	flex scanner.l

clean:
	rm -f parser lex.yy.c