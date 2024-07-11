/*** Definition Section ***/
%{
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
int lineCount = 1;
char lineBuffer[4096] = "";
bool SourceOn = true;
bool TokenOn = true;
%}

%x LineReaded
%x Comment

/*** Rule Section ***/
%%

<INITIAL,LineReaded>#pragma[ \t/]+source[ \t/]+on[ \t/]*\n {printf("%d:%s\n", lineCount++, yytext); SourceOn = true;}
<INITIAL,LineReaded>#pragma[ \t/]+source[ \t/]+off[ \t/]*\n {printf("%d:%s\n", lineCount++, yytext); SourceOn = false;}
<INITIAL,LineReaded>#pragma[ \t/]+token[ \t/]+on[ \t/]*\n {printf("%d:%s\n", lineCount++, yytext); TokenOn = true;}
<INITIAL,LineReaded>#pragma[ \t/]+token[ \t/]+off[ \t/]*\n {printf("%d:%s\n", lineCount++, yytext); TokenOn = false;}

"//".*\n {printf("%d:%s\n", lineCount++, yytext);} /*** this is a single comment line ***/
"/*".*\n {yyless(0); BEGIN Comment;} /*** this is a multiple comment line ***/

<Comment>{
    .*"*/"\n {printf("%d:%s", lineCount++, yytext); BEGIN INITIAL;}
    .*"*/" {printf("%d:%s", lineCount, yytext); BEGIN INITIAL;}
    .*\n {printf("%d:%s", lineCount++, yytext);}
}

<INITIAL>.*\n {strcat(lineBuffer, yytext); BEGIN LineReaded; yyless(0);}



<LineReaded>":" {if(TokenOn) printf("#punc:%s\n", yytext);}
<LineReaded>[ \t] {} /*** Ignore blank character ***/

<LineReaded>\"([^\\\"]|\\.)*\" {if(TokenOn) printf("#string:%s\n", yytext);}
<LineReaded>\'((\\[abfnrtv\\\'\"\?0esd])|[^\"\\])\' {if(TokenOn) printf("#char:%s\n", yytext);}         /*** Normal char ***/
<LineReaded>\'\\[01234567]+\' {if(TokenOn) printf("#char:%s\n", yytext);}  /*** Octal char ***/
<LineReaded>\'\\x[0123456789abcdef]+\' {if(TokenOn) printf("#char:%s\n", yytext);}  /*** Hex char ***/
<LineReaded>\'\\u[0123456789abcdef]+\' {if(TokenOn) printf("#char:%s\n", yytext);}  /*** Hex char ***/
<LineReaded>\'\\U[0123456789abcdefABCDEF]+\' {if(TokenOn) printf("#char:%s\n", yytext);}  /*** Hex char ***/


<LineReaded>";" {if(TokenOn) printf("#punc:%s\n", yytext);}
<LineReaded>"," {if(TokenOn) printf("#punc:%s\n", yytext);}
<LineReaded>"." {if(TokenOn) printf("#punc:%s\n", yytext);}
<LineReaded>"[" {if(TokenOn) printf("#punc:%s\n", yytext);}
<LineReaded>"]" {if(TokenOn) printf("#punc:%s\n", yytext);}
<LineReaded>"(" {if(TokenOn) printf("#punc:%s\n", yytext);}
<LineReaded>")" {if(TokenOn) printf("#punc:%s\n", yytext);}
<LineReaded>"{" {if(TokenOn) printf("#punc:%s\n", yytext);}
<LineReaded>"}" {if(TokenOn) printf("#punc:%s\n", yytext);}


<LineReaded>[-+]?[[:digit:]]*"."[[:digit:]]+ {if(TokenOn) printf("#float:%s\n", yytext);}
<LineReaded>[-+]?[[:digit:]]+"."[[:digit:]]* {if(TokenOn) printf("#float:%s\n", yytext);}

<LineReaded>[-+]?[[:digit:]]+ {if(TokenOn) printf("#integer:%s\n", yytext);}

<LineReaded>"++" {if(TokenOn) printf("#op:%s\n", yytext);}
<LineReaded>"+" {if(TokenOn) printf("#op:%s\n", yytext);}
<LineReaded>"--" {if(TokenOn) printf("#op:%s\n", yytext);}
<LineReaded>"-" {if(TokenOn) printf("#op:%s\n", yytext);}
<LineReaded>\* {if(TokenOn) printf("#op:%s\n", yytext);}
<LineReaded>"/" {if(TokenOn) printf("#op:%s\n", yytext);}
<LineReaded>"%" {if(TokenOn) printf("#op:%s\n", yytext);}
<LineReaded>"<" {if(TokenOn) printf("#op:%s\n", yytext);}
<LineReaded>"<=" {if(TokenOn) printf("#op:%s\n", yytext);}
<LineReaded>">" {if(TokenOn) printf("#op:%s\n", yytext);}
<LineReaded>">=" {if(TokenOn) printf("#op:%s\n", yytext);}
<LineReaded>"==" {if(TokenOn) printf("#op:%s\n", yytext);}
<LineReaded>"!=" {if(TokenOn) printf("#op:%s\n", yytext);}
<LineReaded>"=" {if(TokenOn) printf("#op:%s\n", yytext);}
<LineReaded>"&&" {if(TokenOn) printf("#op:%s\n", yytext);}
<LineReaded>"||" {if(TokenOn) printf("#op:%s\n", yytext);}
<LineReaded>"!" {if(TokenOn) printf("#op:%s\n", yytext);}
<LineReaded>"&" {if(TokenOn) printf("#op:%s\n", yytext);}
<LineReaded>"|" {if(TokenOn) printf("#op:%s\n", yytext);}

<LineReaded>for|do|while|break|continue|if|else|return|struct|switch|case|default|void|int|double|float|char|const|signed|unsigned|short|long {
    if(TokenOn) printf("#key:%s\n", yytext);
}

<LineReaded>NULL|__COUNTER__|__LINE__|INT_MAX|INT_MIN|CHAR_MAX|CHAR_MIN|MAX|MIN {
    if(TokenOn) printf("#macro:%s\n", yytext);
}

<LineReaded>[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_][abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_]* {if(TokenOn) printf("#id:%s\n", yytext);}
<LineReaded>\n {
    if(SourceOn){
        printf("%d:%s", lineCount, lineBuffer);
    }
    lineCount++;
    memset(lineBuffer, 0, sizeof(lineBuffer));
    BEGIN INITIAL;
}

%%

/*** Code Section ***/
int yywrap(){}
int main(void){
    yylex();
    return 0;
}
