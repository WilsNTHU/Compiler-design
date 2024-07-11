#include "code.h"

int cur_counter;
int cur_scope;
int local_args;
int total_args;
FILE *f_asm;
struct symbol_entry table[MAX_TABLE_SIZE];

void initial(){
    cur_counter = 0;
    cur_scope = 0;
    total_args = 0;
    local_args = 0;
}

// To install a symbol in the symbol table 
char *install_symbol(char *s){ 
    if (cur_counter >= MAX_TABLE_SIZE)
        perror("Symbol Table Full");
    else {
        table[cur_counter].scope = cur_scope;
        table[cur_counter].name = copys(s);
        table[cur_counter].offset = ++local_args;
        table[cur_counter].mode = LOCAL_MODE;
        table[cur_counter].type = T_GENERAL;
        cur_counter++;
    }
    return s;
}


// Maintaining only visible variables
int look_up_symbol(char *s){
    int i;
    if (cur_counter == 0) return -1;
    for (i = cur_counter-1; i >= 0; i--){
        if (!strcmp(s,table[i].name))
        return i;
    }
    return -1;
}

/* Pop up symbols of the given scope 
from the symbol table upon the
exit of a given scope */
void pop_up_symbol(int scope){
    int i;
    if (cur_counter == 0) return;
    for (i = cur_counter-1; i >= 0; i--){
        if (table[i].scope !=scope) 
            break;
        local_args--;
    }
    if (i<0) cur_counter = 0;
    cur_counter = i+1;
}

/* Set up parameter scope and offset */
void set_scope_and_offset_of_param(char *s) { 
    int i,j,index;
    int total_args;
    index = look_up_symbol(s);
    if (index<0) perror("Error in function header");
    else {
        table[index].type = T_FUNCTION;
        total_args = cur_counter -index -1;
        table[index].total_args=total_args;
        for (j=total_args, i=cur_counter-1; i>index; i--,j--){
            table[i].scope= cur_scope;
            table[i].offset= j;
            table[i].mode = ARGUMENT_MODE;
            local_args++;
        }
    } 
}

/* To generate house-keeping work at the 
beginning of the function */
void code_gen_func_header(char *functor){
    fprintf(f_asm, ".global %s\n", functor);
    fprintf(f_asm, "%s: \n", functor);
    fprintf(f_asm, "// BEGIN PROLOGUE: codegen is the callee here, so we save callee-saved registers\n");
    fprintf(f_asm, " addi sp, sp, -52\n");
    fprintf(f_asm, " sw sp, 48(sp)\n");
    fprintf(f_asm, " sw s0, 44(sp)\n");
    fprintf(f_asm, " sw s1, 40(sp)\n");
    fprintf(f_asm, " sw s2, 36(sp)\n");
    fprintf(f_asm, " sw s3, 32(sp)\n");
    fprintf(f_asm, " sw s4, 28(sp)\n");
    fprintf(f_asm, " sw s5, 24(sp)\n");
    fprintf(f_asm, " sw s6, 20(sp)\n");
    fprintf(f_asm, " sw s7, 16(sp)\n");
    fprintf(f_asm, " sw s8, 12(sp)\n");
    fprintf(f_asm, " sw s9, 8(sp)\n");
    fprintf(f_asm, " sw s10, 4(sp)\n");
    fprintf(f_asm, " sw s11, 0(sp)\n");
    // fprintf(f_asm, " kadd8  a0, a0, a1\n");
    fprintf(f_asm, " addi s0, sp, 52 // set new frame\n");
    fprintf(f_asm, "// END PROLOGUE\n");
}

/* To generate house-keeping work at 
the end of a function */
void code_gen_at_end_of_function_body(char *functor){
    int i;
    fprintf(f_asm, "\n");
    fprintf(f_asm, " // BEGIN EPILOGUE: restore callee-saved registers\n");
    fprintf(f_asm, " // note that here we assume that the stack is properly maintained, which means\n");
    fprintf(f_asm, " // $sp should point to the same address as when the function prologue exits\n");
    fprintf(f_asm, " lw sp, 48(sp)\n");
    fprintf(f_asm, " lw s0, 44(sp)\n");
    fprintf(f_asm, " lw s1, 40(sp)\n");
    fprintf(f_asm, " lw s2, 36(sp)\n");
    fprintf(f_asm, " lw s3, 32(sp)\n");
    fprintf(f_asm, " lw s4, 28(sp)\n");
    fprintf(f_asm, " lw s5, 24(sp)\n");
    fprintf(f_asm, " lw s6, 20(sp)\n");
    fprintf(f_asm, " lw s7, 16(sp)\n");
    fprintf(f_asm, " lw s8, 12(sp)\n");
    fprintf(f_asm, " lw s9, 8(sp)\n");
    fprintf(f_asm, " lw s10, 4(sp)\n");
    fprintf(f_asm, " lw s11, 0(sp)\n");
    fprintf(f_asm, " addi sp, sp, 52\n");
    fprintf(f_asm, " // END EPILOGUE\n\n");
    fprintf(f_asm, " jalr zero, 0(ra) // return\n");
}

char *copys(char *s){
    char *str = (char *) malloc(sizeof(char) * (strlen(s) + 1));
    strcpy(str, s);
    return str; 
}