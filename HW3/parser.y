%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "code.h"

#define MAX_TABLE_SIZE 5000
#define T_FUNCTION 0
#define T_GENERAL 1
#define T_POINTER 2
#define ARGUMENT_MODE 1
#define LOCAL_MODE 2

int yylex();
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
%token<str_val> DELAY DIGITALWRITE LOW HIGH
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
%type<str_val> multiplicative_expression additive_expression shift_expression relational_expression 
%type<str_val> equality_expression and_expression exclusive_or_expression inclusive_or_expression logical_and_expression
%type<str_val> logical_or_expression assignment_expression expression
%type<str_val> parameter_list
%type<str_val> parameter_declaration 
%type<str_val> statement compound_statement delay_statement_list
%type<str_val> statement_list expression_statement selection_statement iteration_statement
%type<str_val> jump_statement translation_unit external_declaration function_declaration constant program 
%type<str_val> scalar_declaration datatype declaration_list declaration identifier array_declaration array_declaration_list array_declarator array_content
%type<str_val> array_unit switch_clause switch_clauses cast_expression statement_declaration_list digital_write_statement delay_statement

%start program

%%

program: translation_unit {$$ = $1;}
;

translation_unit: external_declaration {$$ = $1;}
| translation_unit external_declaration {}
;

external_declaration: scalar_declaration {$$ = $1;}
| array_declaration {$$ = $1;}
| function_declaration {$$ = $1;}
;

/* expression */

primary_expression: identifier {
	int index = look_up_symbol($1);
	switch(table[index].mode) {
		case ARGUMENT_MODE:
		case LOCAL_MODE:
			fprintf(f_asm," lw t0, %d(s0)\n",table[index].offset*4 + 48);
			fprintf(f_asm," sw t0, 4(sp)\n");
			fprintf(f_asm," addi sp, sp, 4\n");
			break;
		default: /* Global Vars */
			// fprintf(f_asm," lw t0, %d(s0)\n",table[index].offset*4 + 48);
			// fprintf(f_asm," addi sp, sp, 4\n");
			// fprintf(f_asm," sw t0, 0(sp)\n");
			// break;
			fprintf(f_asm," lw t0, %d(s0)\n",table[index].offset*4 + 48);
			fprintf(f_asm," sw t0, 4(sp)\n");
			fprintf(f_asm," addi sp, sp, 4\n");
			break;
	}
}
| constant {

	// fprintf(f_asm," li, t0, %d\n",$1);
	// fprintf(f_asm," addi sp, sp, 4\n");
	// fprintf(f_asm," sw t0, 0(sp)\n");
}
| L_PAREN expression R_PAREN {}
| array_unit;
;

constant: INTNUM {}
| FLOATNUM {}
| STRING_VAL {}
| CHARVAL {}
;

postfix_expression
	: primary_expression  {$$ = $1;}
	| postfix_expression L_PAREN R_PAREN {}
	| postfix_expression L_PAREN argument_expression_list R_PAREN {}
	| postfix_expression INC %prec UINC{
		fprintf(f_asm," lw t0, 0(sp)\n");
		fprintf(f_asm," addi t0, t0, 1\n");
		fprintf(f_asm," sw t0, 0(sp)\n");
	}
	| postfix_expression DEC %prec UDEC{
		fprintf(f_asm," lw t0, 0(sp)\n");
		fprintf(f_asm," addi t0, t0, -1\n");
		fprintf(f_asm," sw t0, 0(sp)\n");
	}
;


expression
	: assignment_expression {$$ = $1;}
	| expression COMMA assignment_expression {}
;

assignment_expression
	: logical_or_expression {$$ = $1;}
	| unary_expression ASSIGN assignment_expression {
        int index = look_up_symbol($1);
		fprintf(f_asm, "\n assignment_expression\n");
        fprintf(f_asm, "    lw t0, 0(sp)\n");
        fprintf(f_asm, "    addi sp, sp, -4\n");
        fprintf(f_asm, "    sw t0, %d(s0)\n", table[index].offset * 4 + 48);
	}
;

argument_expression_list
	: assignment_expression {$$ = $1;}
	| argument_expression_list COMMA assignment_expression {}
;

unary_expression
	: postfix_expression {$$ = $1;}
	| INC unary_expression  {}
	| DEC unary_expression  {}
	| PLUS cast_expression{
		fprintf(f_asm, " lw t0, 0(sp)\n");
        // fprintf(f_asm, " sub t0, zero, t0\n");
        fprintf(f_asm, " sw t0, 0(sp)\n");
	}
	| MINUS cast_expression{
		fprintf(f_asm, " lw t0, 0(sp)\n");
        fprintf(f_asm, " sub t0, zero, t0\n");
        fprintf(f_asm, " sw t0, 0(sp)\n");
	}
	| UAND cast_expression{}
	| MUL cast_expression{}
	| NOT cast_expression{
		fprintf(f_asm, " lw t0, 0(sp)\n");
        fprintf(f_asm, " xori t0, t0, -1\n");
        fprintf(f_asm, " sw t0, 0(sp)\n");
	}
	| UNARY_NOT cast_expression{}
;

cast_expression
	: unary_expression {$$ = $1;}
	| L_PAREN datatype R_PAREN cast_expression {}
	;

multiplicative_expression
	: cast_expression {$$ = $1;}
	| multiplicative_expression MUL cast_expression {
		fprintf(f_asm," lw t0, 0(sp)\n");
		fprintf(f_asm," addi sp, sp, -4\n");
		fprintf(f_asm," lw t1, 0(sp)\n");
		fprintf(f_asm," addi sp, sp, -4\n");
		fprintf(f_asm," mul t0, t0, t1\n");
		fprintf(f_asm," addi sp, sp, 4\n");
		fprintf(f_asm," sw t0, 0(sp)\n");
		$$= NULL;
	}
	| multiplicative_expression DIV cast_expression {
		fprintf(f_asm," lw t0, 0(sp)\n");
		fprintf(f_asm," addi sp, sp, -4\n");
		fprintf(f_asm," lw t1, 0(sp)\n");
		fprintf(f_asm," addi sp, sp, -4\n");
		fprintf(f_asm," div t0, t1, t0\n");
		fprintf(f_asm," addi sp, sp, 4\n");
		fprintf(f_asm," sw t0, 0(sp)\n");
		$$= NULL;
	}
	| multiplicative_expression MOD cast_expression {
		fprintf(f_asm," lw t0, 0(sp)\n");
		fprintf(f_asm," addi sp, sp, -4\n");
		fprintf(f_asm," lw t1, 0(sp)\n");
		fprintf(f_asm," addi sp, sp, -4\n");
		fprintf(f_asm," rem t0, t1, t0\n");
		fprintf(f_asm," addi sp, sp, 4\n");
		fprintf(f_asm," sw t0, 0(sp)\n");
		$$= NULL;
	}
;

additive_expression
	: multiplicative_expression {$$ = $1;}
	| additive_expression PLUS multiplicative_expression {
		fprintf(f_asm," lw t0, 0(sp)\n");
		fprintf(f_asm," addi sp, sp, -4\n");
		fprintf(f_asm," lw t1, 0(sp)\n");
		fprintf(f_asm," addi sp, sp, -4\n");
		fprintf(f_asm," add t0, t0, t1\n");
		fprintf(f_asm," addi sp, sp, 4\n");
	}
	| additive_expression MINUS multiplicative_expression {
		fprintf(f_asm," lw t0, 0(sp)\n");
		fprintf(f_asm," addi sp, sp, -4\n");
		fprintf(f_asm," lw t1, 0(sp)\n");
		fprintf(f_asm," addi sp, sp, -4\n");
		fprintf(f_asm," sub t0, t0, t1\n");
		fprintf(f_asm," addi sp, sp, 4\n");
		fprintf(f_asm," sw t0, 0(sp)\n");
	}
;

shift_expression
	: additive_expression {$$ = $1;}
	| shift_expression LEFTSHIFT additive_expression {
		fprintf(f_asm," lw t0, 0(sp)\n");
		fprintf(f_asm," addi sp, sp, -4\n");
		fprintf(f_asm," lw t1, 0(sp)\n");
		fprintf(f_asm," addi sp, sp, -4\n");
		fprintf(f_asm," sll t0, t0, t1\n"); // a << b (logically)
		fprintf(f_asm," addi sp, sp, 4\n");
		fprintf(f_asm," sw t0, 0(sp)\n");
	}
	| shift_expression RIGHTSHIFT additive_expression {
		fprintf(f_asm," lw t0, 0(sp)\n");
		fprintf(f_asm," addi sp, sp, -4\n");
		fprintf(f_asm," lw t1, 0(sp)\n");
		fprintf(f_asm," addi sp, sp, -4\n");
		fprintf(f_asm," sra t0, t0, t1\n"); // a >> b (arithmetically)
		fprintf(f_asm," addi sp, sp, 4\n");
		fprintf(f_asm," sw t0, 0(sp)\n");
	}
;

relational_expression
	: shift_expression {$$ = $1;}
	| relational_expression LESSER shift_expression {
		fprintf(f_asm," lw t0, 0(sp)\n");
		fprintf(f_asm," addi sp, sp, -4\n");
		fprintf(f_asm," lw t1, 0(sp)\n");
		fprintf(f_asm," addi sp, sp, -4\n");
		fprintf(f_asm," slt t0, t0, t1\n"); // a < b
		fprintf(f_asm," addi sp, sp, 4\n");
		fprintf(f_asm," sw t0, 0(sp)\n");
	}
	| relational_expression GREATER shift_expression {
		fprintf(f_asm," lw t0, 0(sp)\n");
		fprintf(f_asm," addi sp, sp, -4\n");
		fprintf(f_asm," lw t1, 0(sp)\n");
		fprintf(f_asm," addi sp, sp, -4\n");
		fprintf(f_asm," slt t0, t1, t0\n"); // a > b
		fprintf(f_asm," addi sp, sp, 4\n");
		fprintf(f_asm," sw t0, 0(sp)\n");
	}
	| relational_expression LESSER_EQUAL shift_expression {
		fprintf(f_asm," lw t0, 0(sp)\n");
		fprintf(f_asm," addi sp, sp, -4\n");
		fprintf(f_asm," lw t1, 0(sp)\n");
		fprintf(f_asm," addi sp, sp, -4\n");
		fprintf(f_asm," slt t0, t1, t0\n"); // a > b
		fprintf(f_asm," xori t0, t0, -1\n"); // !(a > b) == (a <= b)
		fprintf(f_asm," addi sp, sp, 4\n");
		fprintf(f_asm," sw t0, 0(sp)\n");
	}
	| relational_expression GREATER_EQUAL shift_expression {
		fprintf(f_asm," lw t0, 0(sp)\n");
		fprintf(f_asm," addi sp, sp, -4\n");
		fprintf(f_asm," lw t1, 0(sp)\n");
		fprintf(f_asm," addi sp, sp, -4\n");
		fprintf(f_asm," slt t0, t0, t1\n"); // a < b
		fprintf(f_asm," xori t0, t0, -1\n"); // !(a < b) == (a >= b)
		fprintf(f_asm," addi sp, sp, 4\n");
		fprintf(f_asm," sw t0, 0(sp)\n");
	}
;

equality_expression
	: relational_expression {$$ = $1;}
	| equality_expression EQUAL relational_expression {}
	| equality_expression NOTEQUAL relational_expression {}
;

and_expression
	: equality_expression {$$ = $1;}
	| and_expression UAND equality_expression {}
;

exclusive_or_expression
	: and_expression {$$ = $1;}
	| exclusive_or_expression XOR and_expression {}
;

inclusive_or_expression
	: exclusive_or_expression {$$ = $1;}
	| inclusive_or_expression UOR exclusive_or_expression {}
;

logical_and_expression
	: inclusive_or_expression {$$ = $1;}
	| logical_and_expression AND inclusive_or_expression {}
;

logical_or_expression
	: logical_and_expression {$$ = $1;}
	| logical_or_expression OR logical_and_expression {}
;

/* expression */

/* scalar declaration */

scalar_declaration: datatype declaration_list SEMICOLON {}
;

declaration_list: declaration {}
| declaration_list COMMA declaration {}
;

declaration: identifier {	
	$$ = install_symbol($1);
	int index = look_up_symbol($1);
	fprintf(f_asm, " addi sp, sp, 4\n");
	fprintf(f_asm, " sw zero, %d(s0)\n", table[index].offset * (4) + 48);
}
| identifier ASSIGN assignment_expression {
	$$ = install_symbol($1);
	int index = look_up_symbol($1);
	fprintf(f_asm, " lw t0, 0(sp)\n");
	fprintf(f_asm, " addi sp, sp, -4\n");
	fprintf(f_asm, " sw t0, %d(s0)\n", table[index].offset * (4) + 48);
	fprintf(f_asm, " addi sp, sp, 4\n");
}
;

identifier: ID {$$ = $1;}
| MUL ID {$$ = $2;}
;

datatype: INT {}
| DOUBLE {}
| FLOAT {} 
| CHAR {} 
| CONST {} 
| SIGNED  {} 
| UNSIGNED  {} 
| SHORT  {} 
| LONG {} 
| LONGLONG {} 
| VOID {}
| SIGNED datatype  {}
| UNSIGNED datatype{}
| CONST datatype{}
| datatype MUL{}
;

/* scalar declaration */

/* array declaration */

array_declaration: datatype array_declaration_list SEMICOLON {}
| datatype array_declaration_list ASSIGN array_content SEMICOLON {}
;

array_content: L_BRACKET expression R_BRACKET {}
| L_BRACKET array_content COMMA L_BRACKET expression R_BRACKET R_BRACKET{}
;

array_declaration_list: array_unit {$$ = $1;}
|  array_unit COMMA array_declaration_list {}
;

array_unit: identifier array_declarator {}
| identifier array_declarator ASSIGN array_content{}
;

array_declarator: L_SBRACKET expression R_SBRACKET {}
| array_declarator L_SBRACKET expression R_SBRACKET {}
;

/* array declaration */

/* function declaration */
function_declaration: datatype identifier L_PAREN parameter_list R_PAREN {
	cur_scope++;
	set_scope_and_offset_of_param($4);
	code_gen_func_header($2);
} compound_statement {
	pop_up_symbol(cur_scope);
	cur_scope--;
	code_gen_at_end_of_function_body($2);
}
| datatype identifier L_PAREN parameter_list R_PAREN SEMICOLON {
	// function declaration with parameters

}
| datatype identifier L_PAREN R_PAREN SEMICOLON {
	// function declaration without parameters

}
| datatype identifier L_PAREN R_PAREN {
	cur_scope++;
	code_gen_func_header($2);
} compound_statement {
	pop_up_symbol(cur_scope);
	cur_scope--;
	code_gen_at_end_of_function_body($2);
}
| identifier L_PAREN parameter_list R_PAREN SEMICOLON {
	// function calling with parameters
    fprintf(f_asm, ".global %s\n", $1);
}
| identifier L_PAREN R_PAREN SEMICOLON {
	// function calling  without parameters
    fprintf(f_asm, ".global %s\n", $1);
}
;

parameter_list
	: parameter_declaration {$$ = $1;}
	| parameter_list COMMA parameter_declaration {}
;

parameter_declaration
	: datatype identifier {}
;
/* function declaration */

/* statement */

statement
	: compound_statement {$$ = $1;}
	| expression_statement {$$ = $1;}
	| selection_statement {$$ = $1;}
	| iteration_statement {$$ = $1;}
	| jump_statement {$$ = $1;}
	| delay_statement {}
	| digital_write_statement {}
;

compound_statement
	: L_BRACKET R_BRACKET {}
	| L_BRACKET statement_declaration_list R_BRACKET {}
;

statement_declaration_list: statement {$$ = $1;}
	| statement_declaration_list statement {}
	| declaration_list {$$ = $1;}
	| declaration_list statement_declaration_list {}
;

statement_list
	: statement {$$ = $1;}
	| statement_list statement {}
;

selection_statement
	: IF L_PAREN expression R_PAREN compound_statement {}
	| IF L_PAREN expression R_PAREN compound_statement ELSE compound_statement {}
	| SWITCH L_PAREN expression R_PAREN L_BRACKET switch_clauses R_BRACKET{}
	| SWITCH L_PAREN expression R_PAREN L_BRACKET R_BRACKET{}
;

switch_clauses: switch_clause {$$ = $1;}
| switch_clause switch_clauses {}

switch_clause: CASE expression COLON statement_list {}
| CASE expression COLON  {}
| DEFAULT COLON {}
| DEFAULT COLON statement_list {}
;


iteration_statement
	: WHILE L_PAREN expression R_PAREN statement {}
	| DO statement WHILE L_PAREN expression R_PAREN SEMICOLON {}
	| FOR L_PAREN expression_statement expression_statement R_PAREN statement {}
	| FOR L_PAREN expression_statement expression_statement expression R_PAREN statement {}
;

expression_statement
	: SEMICOLON {}
	| expression SEMICOLON {}
;

jump_statement
	: CONTINUE SEMICOLON {}
	| BREAK SEMICOLON {}
	| RETURN SEMICOLON {}
	| RETURN expression SEMICOLON {}
;

delay_statement: DELAY L_PAREN INTNUM R_PAREN SEMICOLON{
	fprintf(f_asm, " \n//begin delay_statement_high \n");
	fprintf(f_asm, " addi sp, sp, -4\n");
	fprintf(f_asm, " sw ra, 0(sp)\n");
	fprintf(f_asm, " li a0, %d\n", $3);
	fprintf(f_asm, " jal ra, delay\n");
	fprintf(f_asm, " lw ra, 0(sp)\n");
	fprintf(f_asm, " addi sp, sp, 4\n");
	fprintf(f_asm, " //end delay_statement_high \n");
}
;

digital_write_statement: DIGITALWRITE L_PAREN INTNUM COMMA LOW R_PAREN SEMICOLON{
	fprintf(f_asm, " \n//begin digital_write_statement_low \n");
	fprintf(f_asm, " addi sp, sp, -4\n");
	fprintf(f_asm, " sw ra, 0(sp)\n");
	fprintf(f_asm, " li a0, %d\n", $3);
	fprintf(f_asm, " li a1, 0\n"); // LOW signal
	fprintf(f_asm, " jal ra, digitalWrite\n");
	fprintf(f_asm, " lw ra, 0(sp)\n");
	fprintf(f_asm, " addi sp, sp, 4\n");
	fprintf(f_asm, " //end digital_write_statement_low \n");
}
| DIGITALWRITE L_PAREN INTNUM COMMA HIGH R_PAREN SEMICOLON{
	fprintf(f_asm, " \n//begin digital_write_statement_high \n");
	fprintf(f_asm, " addi sp, sp, -4\n");
	fprintf(f_asm, " sw ra, 0(sp)\n");
	fprintf(f_asm, " li a0, %d\n", $3);
	fprintf(f_asm, " li a1, 1\n"); // HIGH signal
	fprintf(f_asm, " jal ra, digitalWrite\n");
	fprintf(f_asm, " lw ra, 0(sp)\n");
	fprintf(f_asm, " addi sp, sp, 4\n");
	fprintf(f_asm, " //end digital_write_statement_high \n");
}
;

/* statement */

%%

int main(int argc, char **argv){
	if ((f_asm = fopen("codegen.S", "w")) == NULL) {
        perror("Error opening file: codeGen.S");
    }
	initial();
    yyparse();
    return 0;
}

void yyerror(const char *s){
    fprintf(stderr, "Error: %s , content: %s\n", s, yylval.str_val);
}

int yywrap(){
  return 1;
}




