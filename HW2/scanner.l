/*** Definition Section ***/
%{
#include <stdio.h>
#include <string.h>
#include "y.tab.h"
%}

%x Comment

/*** Rule Section ***/
%%

":" {return COLON;}
long[ \t]+long {return LONGLONG;}
[ \t\r\n]+ {}/*** Ignore blank character ***/


\"((\\[abfnrtv\\\'\"\?0esd])|(\\[01234567]{1,3})|(\\x[0123456789abcdef]{1,2})|([^\"\\](\\\n)?))*\" {yylval.str_val = strdup(yytext); return STRING_VAL;}
\'((\\[abfnrtv\\\'\"\?0esd])|[^\"\\])\' {yylval.str_val = strdup(yytext); return CHARVAL;}         /*** Normal char ***/
\'\\[01234567]+\' {yylval.str_val = strdup(yytext); return CHARVAL;}  /*** Octal char ***/
\'\\x[0123456789abcdef]+\' {yylval.str_val = strdup(yytext); return CHARVAL;}  /*** Hex char ***/
\'\\u[0123456789abcdef]+\' {yylval.str_val = strdup(yytext); return CHARVAL;}  /*** Hex char ***/
\'\\U[0123456789abcdefABCDEF]+\' {yylval.str_val = strdup(yytext); return CHARVAL;}  /*** Hex char ***/


";" {return SEMICOLON;}
"," {return COMMA;}
"." {return DOT;}
"[" {return L_SBRACKET;}
"]" {return R_SBRACKET;}
"(" {return L_PAREN;}
")" {return R_PAREN;}
"{" {return L_BRACKET;}
"}" {return R_BRACKET;}


([[:digit:]]*"."[[:digit:]]+)|([[:digit:]]+"."[[:digit:]]*) {yylval.float_val = atof(yytext); return FLOATNUM;}
[[:digit:]]+ {yylval.int_val = atoi(yytext); return INTNUM;}

"++" {return INC;}
"+" {return PLUS;}
"--" {return DEC;}
"-" {return MINUS;}
"*" {return MUL;}
"/" {return DIV;}
"%" {return MOD;}
"<<" {return LEFTSHIFT;}
">>" {return RIGHTSHIFT;}
"<" {return LESSER;}
"<=" {return LESSER_EQUAL;}
">" {return GREATER;}
">=" {return GREATER_EQUAL;}
"==" {return EQUAL;}
"!=" {return NOTEQUAL;}
"=" {return ASSIGN;}
"&&" {return AND;}
"||" {return OR;}
"!" {return NOT;}
"&" {return UAND;}
"|" {return UOR;}
"^" {return XOR;}
"~" {return UNARY_NOT;}

for {return FOR;}
do {return DO;}
while {return WHILE;}
break {return BREAK;}
continue {return CONTINUE;}
if {return IF;}
else {return ELSE;}
return {return RETURN;}
struct {return STRUCT;}
switch {return SWITCH;}
case {return CASE;}
default {return DEFAULT;}
void {return VOID;}
int {return INT;}
double {return DOUBLE;}
float {return FLOAT;}
char {return CHAR;}
const {return CONST;}
signed {return SIGNED;}
unsigned {return UNSIGNED;}
short {return SHORT;}
long {return LONG;}


NULL {return NULLKEY;}
__COUNTER__ {return COUNTER;}
__LINE__ {return LINE;}
INT_MAX {return INTMAX;}
INT_MIN {return INTMIN;}
CHAR_MAX {return CHARMAX;}
CHAR_MIN {return CHARMIN;}
MAX {return MAX;}
MIN {return MIN;}

[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_][abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_]* {yylval.str_val = strdup(yytext); return ID;}

%%


