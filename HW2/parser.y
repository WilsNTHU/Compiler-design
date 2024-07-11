%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
extern int yylex();
void yyerror(const char *);
%}

%union {
    int int_val;
    double float_val;
    char *str_val;
}

/* keyword */
%token<str_val> FOR DO WHILE BREAK CONTINUE IF ELSE RETURN STRUCT SWITCH CASE DEFAULT VOID ID 
%token<str_val> INT DOUBLE FLOAT CHAR CONST SIGNED UNSIGNED SHORT LONG LONGLONG
%token<str_val> NULLKEY COUNTER LINE INTMAX INTMIN CHARMAX CHARMIN MAX MIN
%token<str_val> ASSIGN OR AND NOT EQUAL LESSER LESSER_EQUAL GREATER GREATER_EQUAL NOTEQUAL UOR UAND UNARY_NOT
%token<str_val> PLUS MINUS MUL DIV MOD LEFTSHIFT RIGHTSHIFT INC DEC XOR
%token<str_val> SEMICOLON COMMA DOT L_SBRACKET R_SBRACKET L_PAREN R_PAREN L_BRACKET R_BRACKET COLON
%token<str_val> CHARVAL STRING_VAL
%token<int_val> INTNUM
%token<float_val> FLOATNUM

/* precedence */
%right ASSIGN 
%left OR
%left AND
%left NOT
%left EQUAL LESSER LESSER_EQUAL GREATER GREATER_EQUAL NOTEQUAL
%left UOR
%left UAND
%left PLUS MINUS
%left MUL DIV MOD
%left LEFTSHIFT RIGHTSHIFT
%right INC DEC
%nonassoc UINC UDEC UPLUS UMINUS UAND_OP UMUL UNOT UNARY_NOT_OP

/* grammar type */
%type<str_val> primary_expression postfix_expression argument_expression_list unary_expression
%type<str_val> multiplicative_expression additive_expression shift_expression relational_expression relational_operator
%type<str_val> equality_expression and_expression exclusive_or_expression inclusive_or_expression logical_and_expression
%type<str_val> logical_or_expression assignment_expression expression
%type<str_val> parameter_list
%type<str_val> parameter_declaration 
%type<str_val> statement compound_statement 
%type<str_val> statement_list expression_statement selection_statement iteration_statement
%type<str_val> jump_statement translation_unit external_declaration function_declaration constant program 
%type<str_val> scalar_declaration datatype declaration_list declaration identifier array_declaration array_declaration_list array_declarator array_content
%type<str_val> array_unit switch_clause switch_clauses cast_expression unary_operator statement_declaration_list

%start program

%%

program: translation_unit {printf("%s", $1);}
;

translation_unit: external_declaration {$$ = $1;}
| translation_unit external_declaration {
	$$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($2) + 20));
	sprintf($$, "%s%s", $1, $2);
}
;

external_declaration: scalar_declaration {$$ = $1;}
| array_declaration {$$ = $1;}
| function_declaration {$$ = $1;}
;

/* expression */

primary_expression: identifier {
	$$ = (char *) malloc(sizeof(char) * (strlen($1) + 50));
	sprintf($$, "<expr>%s</expr>", $1);
}
| constant {
	$$ = (char *) malloc(sizeof(char) * (strlen($1) + 50));
	sprintf($$, "<expr>%s</expr>", $1);
}
| L_PAREN expression R_PAREN {
	$$ = (char *) malloc(sizeof(char) * (50 + strlen($2)));
	sprintf($$, "<expr>(%s)</expr>", $2);
}
;

constant: INTNUM {
    $$ = (char *) malloc(sizeof(char) * (100));
    sprintf($$, "%d", $1);
}
| FLOATNUM {
    $$ = (char *) malloc(sizeof(char) * (100));
    sprintf($$, "%f", $1);
}
| STRING_VAL {$$ = $1;}
| CHARVAL {$$ = $1;}
;

postfix_expression
	: primary_expression  {$$ = $1;}
	| postfix_expression L_PAREN R_PAREN {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + 50));
		sprintf($$, "<expr>%s()</expr>", $1);
	}
	| postfix_expression L_PAREN argument_expression_list R_PAREN {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($3) + 50));
		sprintf($$, "<expr>%s(%s)</expr>", $1, $3);
	}
	| postfix_expression INC %prec UINC{
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + 50));
		sprintf($$, "<expr>%s++</expr>", $1);
	}
	| postfix_expression DEC %prec UDEC{
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + 50));
		sprintf($$, "<expr>%s--</expr>", $1);
	}
	| array_unit {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + 50));
		sprintf($$, "<expr>%s</expr>", $1);
	}
;


expression
	: assignment_expression {
		$$ = (char*) malloc(sizeof(char) * (strlen($1) + 50));
		sprintf($$, "%s", $1);
	}
	| expression COMMA assignment_expression {
		$$ = (char*) malloc(sizeof(char) * (strlen($1) + strlen($3) + 50));
		sprintf($$, "%s,%s", $1, $3);
	}
;

assignment_expression
	: logical_or_expression {$$ = $1;}
	| unary_expression ASSIGN assignment_expression {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($3) + 50));
		sprintf($$, "<expr>%s=%s</expr>", $1, $3);
	}
;

argument_expression_list
	: assignment_expression {$$ = $1;}
	| argument_expression_list COMMA assignment_expression {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($3) + 50));
		sprintf($$, "%s,%s", $1, $3);
	}
;

unary_expression
	: postfix_expression {$$ = $1;}
	| INC unary_expression  {
		$$ = (char *) malloc(sizeof(char) * (strlen($2) + 50));
		sprintf($$, "<expr>++%s</expr>", $2);
	}
	| DEC unary_expression  {
		$$ = (char *) malloc(sizeof(char) * (strlen($2) + 50));
		sprintf($$, "<expr>--%s</expr>", $2);
	}
	| unary_operator cast_expression{
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($2) + 50));
		sprintf($$, "<expr>%s%s</expr>", $1, $2);
	}
;

unary_operator: PLUS {$$ = strdup("+");}
| MINUS {$$ = strdup("-");}
| UAND {$$ = strdup("&");}
| MUL {$$ = strdup("*");}
| NOT {$$ = strdup("!");}
| UNARY_NOT {$$ = strdup("~");}
;

cast_expression
	: unary_expression {$$ = $1;}
	| L_PAREN datatype R_PAREN cast_expression {
		$$ = (char *) malloc(sizeof(char) * (strlen($2) + strlen($4) + 50));
		sprintf($$, "<expr>(%s)%s</expr>", $2, $4);
	}
	;

multiplicative_expression
	: cast_expression {$$ = $1;}
	| multiplicative_expression MUL cast_expression {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($3) + 50));
		sprintf($$, "<expr>%s*%s</expr>", $1, $3);
	}
	| multiplicative_expression DIV cast_expression {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($3) + 50));
		sprintf($$, "<expr>%s/%s</expr>", $1, $3);
	}
	| multiplicative_expression MOD cast_expression {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($3) + 50));
		sprintf($$, "<expr>%s%%%s</expr>", $1, $3);
	}
;

additive_expression
	: multiplicative_expression {$$ = $1;}
	| additive_expression PLUS multiplicative_expression {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($3) + 50));
		sprintf($$, "<expr>%s+%s</expr>", $1, $3);
	}
	| additive_expression MINUS multiplicative_expression {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($3) + 50));
		sprintf($$, "<expr>%s-%s</expr>", $1, $3);
	}
;

shift_expression
	: additive_expression {$$ = $1;}
	| shift_expression LEFTSHIFT additive_expression {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($3) + 50));
		sprintf($$, "<expr>%s<<%s</expr>", $1, $3);
	}
	| shift_expression RIGHTSHIFT additive_expression {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($3) + 50));
		sprintf($$, "<expr>%s>>%s</expr>", $1, $3);
	}
;

relational_expression
	: shift_expression {$$ = $1;}
	| relational_expression relational_operator shift_expression {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($3) + 50));
		sprintf($$, "<expr>%s%s%s</expr>", $1, $2, $3);
	}
;

relational_operator
	: LESSER {$$ = strdup("<");}
	| GREATER {$$ = strdup(">");}
	| LESSER_EQUAL {$$ = strdup("<=");}
	| GREATER_EQUAL {$$ = strdup(">=");}
;

equality_expression
	: relational_expression {$$ = $1;}
	| equality_expression EQUAL relational_expression {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($3) + 50));
		sprintf($$, "<expr>%s==%s</expr>", $1, $3);
	}
	| equality_expression NOTEQUAL relational_expression {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($3) + 50));
		sprintf($$, "<expr>%s!=%s</expr>", $1, $3);
	}
;

and_expression
	: equality_expression {$$ = $1;}
	| and_expression UAND equality_expression {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($3) + 50));
		sprintf($$, "<expr>%s&%s</expr>", $1, $3);
	}
;

exclusive_or_expression
	: and_expression {$$ = $1;}
	| exclusive_or_expression XOR and_expression {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($3) + 50));
		sprintf($$, "<expr>%s^%s</expr>", $1, $3);
	}
;

inclusive_or_expression
	: exclusive_or_expression {$$ = $1;}
	| inclusive_or_expression UOR exclusive_or_expression {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($3) + 50));
		sprintf($$, "<expr>%s|%s</expr>", $1, $3);
	}
;

logical_and_expression
	: inclusive_or_expression {$$ = $1;}
	| logical_and_expression AND inclusive_or_expression {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($3) + 50));
		sprintf($$, "<expr>%s&&%s</expr>", $1, $3);
	}
;

logical_or_expression
	: logical_and_expression {$$ = $1;}
	| logical_or_expression OR logical_and_expression {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($3) + 50));
		sprintf($$, "<expr>%s||%s</expr>", $1, $3);
	}
;

/* expression */

/* scalar declaration */

scalar_declaration: datatype declaration_list SEMICOLON {
    $$ = (char*) malloc(sizeof(char) * (strlen($1) + strlen($2) + 50));
    sprintf($$, "<scalar_decl>%s%s;</scalar_decl>", $1, $2);
}
;

declaration_list: declaration {$$ = $1;}
| declaration_list COMMA declaration {
    $$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($3) + 10));
    sprintf($$, "%s,%s", $1, $3);
}
;

declaration: identifier {$$ = $1;}
| identifier ASSIGN assignment_expression {
    $$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($3) + 10));
    sprintf($$, "%s=%s", $1, $3);
}
;

identifier: ID {$$ = $1;}
| MUL ID {
    $$ = (char *) malloc(sizeof(char) * (strlen($2)) + 10);
    sprintf($$, "*%s", $2);
}
;

datatype: INT {$$ = strdup("int");}
| DOUBLE {$$ = strdup("double");}
| FLOAT {$$ = strdup("float");} 
| CHAR {$$ = strdup("char");} 
| CONST {$$ = strdup("const");} 
| SIGNED  {$$ = strdup("signed");} 
| UNSIGNED  {$$ = strdup("unsigned");} 
| SHORT  {$$ = strdup("short");} 
| LONG {$$ = strdup("long");} 
| LONGLONG {$$ = strdup("longlong");} 
| VOID {$$ = strdup("void");}
| SIGNED datatype  {
    $$ = (char *) malloc(strlen($2) + 30);
    sprintf($$, "signed%s", $2);
}
| UNSIGNED datatype{
    $$ = (char *) malloc(strlen($2) + 30);
    sprintf($$, "unsigned%s", $2);
}
| CONST datatype{
    $$ = (char *) malloc(strlen($2) + 30);
    sprintf($$, "const%s", $2);
}
| datatype MUL{
	$$ = (char *) malloc(strlen($2) + 30);
    sprintf($$, "%s*", $2);
}
;

/* scalar declaration */

/* array declaration */

array_declaration: datatype array_declaration_list SEMICOLON {
    $$ = (char*) malloc(sizeof(char) * (strlen($1) + strlen($2) + 50));
    sprintf($$, "<array_decl>%s%s;</array_decl>", $1, $2);
}
| datatype array_declaration_list ASSIGN array_content SEMICOLON {
    $$ = (char*) malloc(sizeof(char) * (strlen($1) + strlen($2) + strlen($4) + 50));
    sprintf($$, "<array_decl>%s%s=%s;</array_decl>", $1, $2, $4);
}
;

array_content: L_BRACKET expression R_BRACKET {
    $$ = (char*) malloc(sizeof(char) * (strlen($2) + 50));
    sprintf($$, "{%s}", $2);
}
| L_BRACKET array_content COMMA L_BRACKET expression R_BRACKET R_BRACKET{
    $$ = (char*) malloc(sizeof(char) * (strlen($2) + strlen($5) + 50));
    sprintf($$, "{%s,{%s}}", $2, $5);
}
;

array_declaration_list: array_unit {
	$$ = $1;
}
|  array_unit COMMA array_declaration_list {
    $$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($3) + 10));
    sprintf($$, "%s,%s", $1, $3);
}
;

array_unit: identifier array_declarator {
    $$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($2) + 10));
    sprintf($$, "%s%s", $1, $2);
}
| identifier array_declarator ASSIGN array_content{
    $$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($2) + strlen($4) + 10));
    sprintf($$, "%s%s=%s", $1, $2, $4);
}
;

array_declarator: L_SBRACKET expression R_SBRACKET {
    $$ = (char *) malloc(sizeof(char) * (strlen($2) + 20));
	sprintf($$, "[%s]", $2);
}
| array_declarator L_SBRACKET expression R_SBRACKET {
    $$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($3) + 20));
	sprintf($$, "%s[%s]", $1, $3);
}
;

/* array declaration */

/* function declaration */
function_declaration: datatype identifier L_PAREN parameter_list R_PAREN compound_statement {
    $$ = (char*) malloc(sizeof(char) * (strlen($1) + strlen($2) + strlen($4) + strlen($6) + 50));
    sprintf($$, "<func_def>%s%s(%s)%s</func_def>", $1, $2, $4, $6);
}
| datatype identifier L_PAREN parameter_list R_PAREN SEMICOLON {
    $$ = (char*) malloc(sizeof(char) * (strlen($1) + strlen($2) + strlen($4) + 50));
    sprintf($$, "<func_decl>%s%s(%s);</func_decl>", $1, $2, $4);
}
| datatype identifier L_PAREN R_PAREN compound_statement {
    $$ = (char*) malloc(sizeof(char) * (strlen($1) + strlen($2) + strlen($5) + 50));
    sprintf($$, "<func_def>%s%s()%s</func_def>", $1, $2, $5);
}
| datatype identifier L_PAREN R_PAREN SEMICOLON {
    $$ = (char*) malloc(sizeof(char) * (strlen($1) + strlen($2) + 50));
    sprintf($$, "<func_decl>%s%s();</func_decl>", $1, $2);
}
;

parameter_list
	: parameter_declaration {$$ = $1;}
	| parameter_list COMMA parameter_declaration {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($3) + 10));
		sprintf($$, "%s,%s", $1, $3);
	}
;

parameter_declaration
	: datatype identifier {
    $$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($2) + 10));
    sprintf($$, "%s%s", $1, $2);
}
;
/* function declaration */

/* statement */

statement
	: compound_statement {$$ = $1;}
	| expression_statement {$$ = $1;}
	| selection_statement {$$ = $1;}
	| iteration_statement {$$ = $1;}
	| jump_statement {$$ = $1;}
;

compound_statement
	: L_BRACKET R_BRACKET {$$ = strdup("{}");}
	| L_BRACKET statement_declaration_list R_BRACKET {
		$$ = (char *) malloc(sizeof(char) * (strlen($2) + 50));
		sprintf($$, "{%s}", $2);
	}
;

statement_declaration_list: statement {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + 50));
		sprintf($$, "<stmt>%s</stmt>", $1);
	}
	| statement_declaration_list statement {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($2) + 50));
		sprintf($$, "<stmt>%s%s</stmt>", $1, $2);
	}
	| declaration_list {$$ = $1;}
	| declaration_list statement_declaration_list {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($2) + 50));
		sprintf($$, "<stmt>%s%s</stmt>", $1, $2);
	}
;

statement_list
	: statement {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + 50));
		sprintf($$, "<stmt>%s</stmt>", $1);
	}
	| statement_list statement {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($2) + 50));
		sprintf($$, "<stmt>%s%s</stmt>", $1, $2);
	}
;

selection_statement
	: IF L_PAREN expression R_PAREN compound_statement {
		$$ = (char *) malloc(sizeof(char) * (100 + strlen($3) + strlen($5)));
		sprintf($$, "if(%s)<stmt>%s</stmt>", $3, $5);
	}
	| IF L_PAREN expression R_PAREN compound_statement ELSE compound_statement {
		$$ = (char *) malloc(sizeof(char) * (200 + strlen($3) + strlen($5) + strlen($7)));
		sprintf($$, "if(%s)<stmt>%s</stmt>else<stmt>%s</stmt>", $3, $5, $7);
	}
	| SWITCH L_PAREN expression R_PAREN L_BRACKET switch_clauses R_BRACKET{
		$$ = (char *) malloc(sizeof(char) * (200 + strlen($3) + strlen($6)));
		sprintf($$, "switch(%s){<stmt>%s</stmt>}", $3, $6);
	}
	| SWITCH L_PAREN expression R_PAREN L_BRACKET R_BRACKET{
		$$ = (char *) malloc(sizeof(char) * (100 + strlen($3)));
		sprintf($$, "switch(%s){}", $3);
	}
;

switch_clauses: switch_clause {$$ = $1;}
| switch_clause switch_clauses {
	$$ = (char *) malloc(sizeof(char) * (strlen($1) + strlen($2) + 50));
	sprintf($$, "%s%s", $1, $2);
}

switch_clause: CASE expression COLON statement_list {
	$$ = (char *) malloc(sizeof(char) * (strlen($2) + strlen($4) + 200));
	sprintf($$, "case%s:%s", $2, $4);
}
| CASE expression COLON  {
	$$ = (char *) malloc(sizeof(char) * (strlen($2) + 100));
	sprintf($$, "case%s:", $2);
}
| DEFAULT COLON {$$ = strdup("default:");}
| DEFAULT COLON statement_list {
	$$ = (char *) malloc(sizeof(char) * (strlen($3) + 200));
	sprintf($$, "default:%s", $3);
}
;


iteration_statement
	: WHILE L_PAREN expression R_PAREN statement {
		$$ = (char *) malloc(sizeof(char) * (strlen($3) + strlen($5) + 100));
		sprintf($$, "while(%s)<stmt>%s</stmt>", $3, $5);
	}
	| DO statement WHILE L_PAREN expression R_PAREN SEMICOLON {
		$$ = (char *) malloc(sizeof(char) * (strlen($2) + strlen($5) + 100));
		sprintf($$, "do<stmt>%s</stmt>while(%s);", $2, $5);
	}
	| FOR L_PAREN expression_statement expression_statement R_PAREN statement {
		$$ = (char *) malloc(sizeof(char) * (strlen($3) + strlen($4) + strlen($6) + 100));
		sprintf($$, "for(%s%s)<stmt>%s</stmt>", $3, $4, $6);
	}
	| FOR L_PAREN expression_statement expression_statement expression R_PAREN statement {
		$$ = (char *) malloc(sizeof(char) * (strlen($3) + strlen($4) + strlen($5) + strlen($7) + 100));
		sprintf($$, "for(%s%s%s)<stmt>%s</stmt>", $3, $4, $5, $7);
	}
;

expression_statement
	: SEMICOLON {$$ = strdup(";");}
	| expression SEMICOLON {
		$$ = (char *) malloc(sizeof(char) * (strlen($1) + 50));
		sprintf($$, "%s;", $1);
	}
;

jump_statement
	: CONTINUE SEMICOLON {
		$$ = (char *) malloc(sizeof(char) * (50));
		sprintf($$, "continue;");
	}
	| BREAK SEMICOLON {
		$$ = (char *) malloc(sizeof(char) * (50));
		sprintf($$, "break;");
	}
	| RETURN SEMICOLON {
		$$ = (char *) malloc(sizeof(char) * (50));
		sprintf($$, "return;");
	}
	| RETURN expression SEMICOLON {
		$$ = (char *) malloc(sizeof(char) * (strlen($2) + 50));
		sprintf($$, "return%s;", $2);
	}
;
/* statement */

%%

int main(int argc, char **argv){
    yyparse();
    return 0;
}

void yyerror(const char *s){
    fprintf(stderr, "Error: %s , content: %s\n", s, yylval.str_val);
}

int yywrap(){
  return 1;
}


