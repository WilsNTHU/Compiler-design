#include <stdio.h>
#include <string.h>
#include <malloc.h>


#define MAX_TABLE_SIZE 5000

#define T_FUNCTION 0
#define T_GENERAL 1
#define T_POINTER 2

#define ARGUMENT_MODE 1
#define LOCAL_MODE 2

struct symbol_entry {
    char *name;
    int scope;
    int offset;
    int id;
    int variant;
    int type;
    int total_args;
    int total_locals;
    int mode;
};

extern FILE* f_asm;
extern int cur_scope;
extern int cur_counter;
extern int local_args;
extern struct symbol_entry table[MAX_TABLE_SIZE];

typedef struct symbol_entry *PTR_SYMB;

void initial();
char *install_symbol(char *s);
int look_up_symbol(char *s);
void pop_up_symbol(int scope);
void set_scope_and_offset_of_param(char *s);
void code_gen_func_header(char *functor);
void code_gen_at_end_of_function_body(char *functor);
char *copys(char *s);