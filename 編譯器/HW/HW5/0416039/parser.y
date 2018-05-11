%{
/**
 * Introduction to Compiler Design by Prof. Yi Ping You
 * Project 3 YACC sample
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "header.h"
#include "symtab.h"
#include "semcheck.h"

int yydebug;

extern int linenum;     /* declared in lex.l */
extern FILE *yyin;      /* declared by lex */
extern char *yytext;    /* declared by lex */
extern char buf[256];   /* declared in lex.l */
extern int yylex(void);
int yyerror(char*);
int label_count = -1;
int stack[100];
int stack_top = -1;

FILE* outfp;
int scope_var = 1;
int not_load = 0;
int scope = 0;
int Opt_D = 1;               // symbol table dump option
char fileName[256];             // filename of input file
struct SymTable *symbolTable;	// main symbol table
__BOOLEAN paramError;			// indicate is parameter have any error?
struct PType *funcReturn;		// record return type of function, used at 'return statement' production rule

%}

%union {
	int intVal;
	float realVal;
	//__BOOLEAN booleanVal;
	char *lexeme;
	struct idNode_sem *id;
	//SEMTYPE type;
	struct ConstAttr *constVal;
	struct PType *ptype;
	struct param_sem *par;
	struct expr_sem *exprs;
	/*struct var_ref_sem *varRef; */
	struct expr_sem_node *exprNode;
};

/* tokens */
%token ARRAY BEG BOOLEAN DEF DO ELSE END FALSE FOR INTEGER IF OF PRINT READ REAL RETURN STRING THEN TO TRUE VAR WHILE
%token OP_ADD OP_SUB OP_MUL OP_DIV OP_MOD OP_ASSIGN OP_EQ OP_NE OP_GT OP_LT OP_GE OP_LE OP_AND OP_OR OP_NOT
%token MK_COMMA MK_COLON MK_SEMICOLON MK_LPAREN MK_RPAREN MK_LB MK_RB

%token <lexeme>ID
%token <intVal>INT_CONST 
%token <realVal>FLOAT_CONST
%token <realVal>SCIENTIFIC
%token <lexeme>STR_CONST

%type<id> id_list
%type<constVal> literal_const
%type<ptype> type scalar_type array_type opt_type
%type<par> param param_list opt_param_list
%type<exprs> var_ref boolean_expr boolean_term boolean_factor relop_expr expr term factor boolean_expr_list opt_boolean_expr_list
%type<intVal> dim mul_op add_op rel_op array_index loop_param

/* start symbol */
%start program
%%

program			: ID
			{
			  struct PType *pType = createPType (VOID_t);
			  struct SymNode *newNode = createProgramNode ($1, scope, pType);
			  insertTab (symbolTable, newNode);

			  if (strcmp(fileName, $1)) {
				fprintf (stdout, "<Error> found in Line %d: program beginning ID inconsist with file name\n", linenum);
			  }
               
              fprintf(outfp, ";%s.p\n", $1); 
              fprintf(outfp, ".class public %s\n", $1); 
              fprintf(outfp, ".super java/lang/Object\n"); 
              fprintf(outfp, ".field public static _sc Ljava/util/Scanner;\n");
			}
			  MK_SEMICOLON
			  program_body
			  END ID
			{
			  if (strcmp($1, $6)) {
                  fprintf (stdout, "<Error> found in Line %d: program end ID inconsist with the beginning ID\n", linenum);
              }
			  if (strcmp(fileName, $6)) {
				  fprintf (stdout, "<Error> found in Line %d: program end ID inconsist with file name\n", linenum);
			  }
			  // dump symbol table
			  if( Opt_D == 1 )
				printSymTable( symbolTable, scope );
			}
			;

program_body		: opt_decl_list opt_func_decl_list {
                fprintf(outfp, ".method public static main([Ljava/lang/String;)V\n");
                fprintf(outfp, ".limit stack 128\n");
                fprintf(outfp, ".limit locals 128\n");
                fprintf(outfp, "new java/util/Scanner\n");
                fprintf(outfp, "dup\n");
                fprintf(outfp, "getstatic java/lang/System/in Ljava/io/InputStream;\n");
                fprintf(outfp, "invokespecial java/util/Scanner/<init>(Ljava/io/InputStream;)V\n");
                fprintf(outfp, "putstatic %s/_sc Ljava/util/Scanner;\n", fileName);
              }compound_stmt{
                fprintf(outfp, "return\n");
                fprintf(outfp, ".end method\n");
            }
			;

opt_decl_list		: decl_list
			| /* epsilon */
			;

decl_list		: decl_list decl
			| decl
			;

decl			: VAR id_list MK_COLON scalar_type MK_SEMICOLON       /* scalar type declaration */
			{
			  // insert into symbol table
			  struct idNode_sem *ptr;
			  struct SymNode *newNode;
			  for (ptr=$2 ; ptr!=0; ptr=(ptr->next)) {
			  	if( verifyRedeclaration(symbolTable, ptr->value, scope) == __TRUE ) {
					newNode = createVarNode (ptr->value, scope, $4);
					if(scope != 0){
                        newNode->var_num = scope_var;
                        scope_var++;
                    }
                    insertTab (symbolTable, newNode);
                    if(scope == 0){
                        if($4->type == INTEGER_t){
                            fprintf(outfp, ".field public static %s I\n", ptr->value);
                        }
                        else if($4->type == BOOLEAN_t){
                            fprintf(outfp, ".field public static %s Z\n", ptr->value);
                        }
                        if($4->type == REAL_t){
                            fprintf(outfp, ".field public static %s F\n", ptr->value);
                        }
                    }
				}
			  }
			  deleteIdList( $2 );
			}
			| VAR id_list MK_COLON array_type MK_SEMICOLON        /* array type declaration */
			{
			  verifyArrayType( $2, $4 );
			  // insert into symbol table
			  struct idNode_sem *ptr;
			  struct SymNode *newNode;
			  for( ptr=$2 ; ptr!=0 ; ptr=(ptr->next) ) {
			  	if( $4->isError == __TRUE ) { }
				else if( verifyRedeclaration( symbolTable, ptr->value, scope ) ==__FALSE ) { }
				else {
					newNode = createVarNode( ptr->value, scope, $4 );
					insertTab( symbolTable, newNode );
				}
			  }
			  
			  deleteIdList( $2 );
			}
			| VAR id_list MK_COLON literal_const MK_SEMICOLON     /* const declaration */
			{
			  struct PType *pType = createPType( $4->category );
			  // insert constants into symbol table
			  struct idNode_sem *ptr;
			  struct SymNode *newNode;
			  for( ptr=$2 ; ptr!=0 ; ptr=(ptr->next) ) {
			  	if( verifyRedeclaration( symbolTable, ptr->value, scope ) ==__FALSE ) { }
				else {
					newNode = createConstNode( ptr->value, scope, pType, $4 );
					insertTab( symbolTable, newNode );
				}
			  }
			  
			  deleteIdList( $2 );
			}
			;

literal_const		: INT_CONST
			{
			  int tmp = $1;
			  $$ = createConstAttr( INTEGER_t, &tmp );
			}
			| OP_SUB INT_CONST
			{
			  int tmp = -$2;
			  $$ = createConstAttr( INTEGER_t, &tmp );
			}
			| FLOAT_CONST
			{
			  float tmp = $1;
			  $$ = createConstAttr( REAL_t, &tmp );
			}
			| OP_SUB FLOAT_CONST
			{
			  float tmp = -$2;
			  $$ = createConstAttr( REAL_t, &tmp );
			}
			| SCIENTIFIC 
			{
			  float tmp = $1;
			  $$ = createConstAttr( REAL_t, &tmp );
			}
			| OP_SUB SCIENTIFIC
			{
			  float tmp = -$2;
			  $$ = createConstAttr( REAL_t, &tmp );
			}
			| STR_CONST
			{
			  $$ = createConstAttr( STRING_t, $1 );
			}
			| TRUE
			{
			  __BOOLEAN tmp = __TRUE;
			  $$ = createConstAttr( BOOLEAN_t, &tmp );
			}
			| FALSE
			{
			  __BOOLEAN tmp = __FALSE;
			  $$ = createConstAttr( BOOLEAN_t, &tmp );
			}
			;

opt_func_decl_list	: func_decl_list
			| /* epsilon */
			;

func_decl_list		: func_decl_list func_decl
			| func_decl
			;

func_decl		: ID MK_LPAREN{
              scope_var = 0;
            } 
            opt_param_list
			{
			  // check and insert parameters into symbol table
			  paramError = insertParamIntoSymTable( symbolTable, $4, scope+1, scope_var);
			  struct idNode_sem *ptr;
              for(struct param_sem *i = $4; i != NULL; i = i->next)
              {
			    for (ptr=i->idlist ; ptr!=0; ptr=(ptr->next)) {
                            scope_var++;
                }
              }
			}
			  MK_RPAREN opt_type 
			{
			  // check and insert function into symbol table
			  if( paramError == __TRUE ) {
			  	printf("<Error> found in Line %d: param(s) with several error\n", linenum);
			  } else if( $7->isArray == __TRUE ) {
					
					printf("<Error> found in Line %d: a function cannot return an array type\n", linenum);
				} else {
					
				insertFuncIntoSymTable( symbolTable, $1, $4, $7, scope );
			  }
			  funcReturn = $7;
              fprintf(outfp, ".method public static %s(", $1);
              struct param_sem *i;
              if($4 != NULL)
              {
                for(i = $4; i != NULL; i = i->next)
                {
                    if(i->pType->type == INTEGER_t)
                    {
                        for(struct idNode_sem *j = i->idlist; j != NULL; j = j->next)
                            fprintf(outfp, "I");
                    }
                    else if(i->pType->type == REAL_t)
                    {
                        for(struct idNode_sem *j = i->idlist; j != NULL; j = j->next)
                            fprintf(outfp, "F");
                    }
                    else if(i->pType->type == BOOLEAN_t)
                    {
                        for(struct idNode_sem *j = i->idlist; j != NULL; j = j->next)
                            fprintf(outfp, "Z");
                    }
                }
              }  
              if($7->type == INTEGER_t)
              {
                 fprintf(outfp, ")I\n");
              }
              else if($7->type == REAL_t)
              {
                 fprintf(outfp, ")F\n");
              }
              else if($7->type == BOOLEAN_t)
              {
                 fprintf(outfp, ")Z\n");
              }
              else
              {
                 fprintf(outfp, ")V\n");
              }

              fprintf(outfp, ".limit stack 128\n");
              fprintf(outfp, ".limit locals 128\n");
            }
			  MK_SEMICOLON
			  compound_stmt
			  END ID
			{
			  if( strcmp($1,$12) ) {
				fprintf( stdout, "<Error> found in Line %d: the end of the functionName mismatch\n", linenum );
			  }
			  funcReturn = 0;
              scope_var = 0;
              if($7->type == INTEGER_t)
              {
                 fprintf(outfp, "ireturn\n");
              }
              else if($7->type == REAL_t)
              {
                 fprintf(outfp, "freturn\n");
              }
              else if($7->type == BOOLEAN_t)
              {
                 fprintf(outfp, "ireturn\n");
              }
              else
              {
                fprintf(outfp, "return\n");
              }
              fprintf(outfp, ".end method\n");
			}
			;

opt_param_list		: param_list { $$ = $1; 
            }
			| /* epsilon */ { $$ = 0; }
			;

param_list		: param_list MK_SEMICOLON param
			{
			  param_sem_addParam( $1, $3 );
			  $$ = $1;
			}
			| param { $$ = $1; }
			;

param			: id_list MK_COLON type { $$ = createParam( $1, $3 ); }
			;

id_list			: id_list MK_COMMA ID
			{
			  idlist_addNode( $1, $3 );
			  $$ = $1;
			}
			| ID { $$ = createIdList($1); }
			;

opt_type		: MK_COLON type { $$ = $2; }
			| /* epsilon */ { $$ = createPType( VOID_t ); }
			;

type			: scalar_type { $$ = $1; }
			| array_type { $$ = $1; }
			;

scalar_type		: INTEGER { $$ = createPType (INTEGER_t); }
			| REAL { $$ = createPType (REAL_t); }
			| BOOLEAN { $$ = createPType (BOOLEAN_t); }
			| STRING { $$ = createPType (STRING_t); }
			;

array_type		: ARRAY array_index TO array_index OF type
			{
				verifyArrayDim ($6, $2, $4);
				increaseArrayDim ($6, $2, $4);
				$$ = $6;
			}
			;

array_index		: INT_CONST { $$ = $1; }
			;

stmt			: compound_stmt
			| simple_stmt
			| cond_stmt
			| while_stmt
			| for_stmt
			| return_stmt
			| proc_call_stmt
			;

compound_stmt		: 
			{ 
			  scope++;
			}
			  BEG
			  opt_decl_list
			  opt_stmt_list
			  END 
			{ 
			  // print contents of current scope
			  if( Opt_D == 1 )
			  	printSymTable( symbolTable, scope );
			  deleteScope( symbolTable, scope );	// leave this scope, delete...
			  scope--; 
			}
			;

opt_stmt_list		: stmt_list
			| /* epsilon */
			;

stmt_list		: stmt_list stmt
			| stmt
			;

simple_stmt		: var_ref OP_ASSIGN boolean_expr MK_SEMICOLON
			{
			  // check if LHS exists
			  __BOOLEAN flagLHS = verifyExistence( symbolTable, $1, scope, __TRUE );
			  // id RHS is not dereferenced, check and deference
			  __BOOLEAN flagRHS = __TRUE;
			  if( $3->isDeref == __FALSE ) {
				flagRHS = verifyExistence( symbolTable, $3, scope, __FALSE );
			  }
			  // if both LHS and RHS are exists, verify their type
			  if( flagLHS==__TRUE && flagRHS==__TRUE ){
				verifyAssignmentTypeMatch( $1, $3 );
                struct SymNode *node = lookupSymbol(symbolTable, $1->varRef->id, scope, __FALSE);
                if(node->category == VARIABLE_t && node->scope != 0){
                    if(node->type->type == INTEGER_t)
                        fprintf(outfp, "istore %d\n", node->var_num);
                    else if(node->type->type == REAL_t){
                        if($3->pType->type == INTEGER_t)
                            fprintf(outfp, "i2f\nfstore %d\n", node->var_num);
                        else if($3->pType->type == REAL_t)
                        {
                            fprintf(outfp, "fstore %d\n", node->var_num);
                        }
                    }
                    else if(node->type->type == BOOLEAN_t){
                        fprintf(outfp, "istore %d\n", node->var_num);
                    }
                }
                else if(node->category == VARIABLE_t && node->scope == 0){
                    if(node->type->type == INTEGER_t)
                        fprintf(outfp, "putstatic %s/%s I\n", fileName, node->name);
                    else if(node->type->type == REAL_t){
                        if($3->pType->type == INTEGER_t)
                            fprintf(outfp, "i2f\nputstatic %s/%s F\n", fileName, node->name);
                        else
                            fprintf(outfp, "putstatic %s/%s F\n", fileName, node->name);
                    }
                    else if(node->category == BOOLEAN_t)
                        fprintf(outfp, "putstatic %s/%s Z\n", fileName, node->name);
                }
              }
			}
			| PRINT{
                fprintf(outfp, "getstatic java/lang/System/out Ljava/io/PrintStream;\n");
            } boolean_expr MK_SEMICOLON { 
                verifyScalarExpr( $3, "print" ); 
                if($3->pType->type == STRING_t){
                    fprintf(outfp, "invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n");
                } 
                else if($3->pType->type == INTEGER_t){
                    fprintf(outfp, "invokevirtual java/io/PrintStream/print(I)V\n");
                } 
                else if($3->pType->type == REAL_t){
                    fprintf(outfp, "invokevirtual java/io/PrintStream/print(F)V\n");
                }
                else if($3->pType->type == BOOLEAN_t){
                    fprintf(outfp, "invokevirtual java/io/PrintStream/print(Z)V\n");
                }
                 
            }
 			| READ{ 
                not_load = 1;
            }boolean_expr MK_SEMICOLON { 
                not_load = 0;
                verifyScalarExpr( $3, "read" );
                fprintf(outfp, "getstatic %s/_sc Ljava/util/Scanner;\n", fileName);
                struct SymNode *node = lookupSymbol(symbolTable, $3->varRef->id, scope, __FALSE);
                if(node != NULL)
                    if(node->category == VARIABLE_t)
                    {
                        if($3->pType->type == INTEGER_t)
                            fprintf(outfp, "invokevirtual java/util/Scanner/nextInt()I\n");
                        else if($3->pType->type == REAL_t)
                            fprintf(outfp, "invokevirtual java/util/Scanner/nextFloat()F\n");
                        else if($3->pType->type == BOOLEAN_t)
                            fprintf(outfp, "invokevirtual java/util/Scanner/nextBoolean()Z\n");
                        if(node->scope != 0)
                        {
                            if($3->pType->type == INTEGER_t || $3->pType->type == BOOLEAN_t)
                                fprintf(outfp, "istore %d\n", node->var_num);
                            else if($3->pType->type == REAL_t)
                                fprintf(outfp, "fstore %d\n", node->var_num);
                        }
                        else{
                            if($3->pType->type == INTEGER_t)
                                fprintf(outfp, "putstatic %s/%s I\n", fileName, node->name);
                            else if($3->pType->type == REAL_t)
                                fprintf(outfp, "putstatic %s/%s F\n", fileName, node->name);
                            else if($3->pType->type == BOOLEAN_t)
                                fprintf(outfp, "putstatic %s/%s Z\n", fileName, node->name);
                        }
                    }
            }
			;

proc_call_stmt		: ID MK_LPAREN opt_boolean_expr_list MK_RPAREN MK_SEMICOLON
			{
			  verifyFuncInvoke( $1, $3, symbolTable, scope );
              struct SymNode *find = lookupSymbol(symbolTable, $1, scope, __FALSE);
              struct PTypeList *k;
              struct expr_sem *m;
              for(k = find->attribute->formalParam->params, m = $3; k != NULL; k = k->next, m = m->next)
              {
                  if(k->value->type == REAL_t){
                    if(m->pType->type == INTEGER_t){
                        int Q = 0;
                        for(struct expr_sem *p = m->next; p != NULL; p = p->next, Q++){
                            if(p->pType->type == INTEGER_t || p->pType->type == BOOLEAN_t)
                                fprintf(outfp, "istore %d\n", scope_var+Q);
                            else if(p->pType->type == REAL_t)
                                fprintf(outfp, "fstore %d\n", scope_var+Q);
                        }
                        fprintf(outfp, "i2f\n");
                        Q--;
                        for(struct expr_sem *p = m->next; p != NULL; p = p->next, Q--){
                            if(p->pType->type == INTEGER_t || p->pType->type == BOOLEAN_t)
                                fprintf(outfp, "iload %d\n", scope_var+Q);
                            else if(p->pType->type == REAL_t)
                                fprintf(outfp, "fload %d\n", scope_var+Q);
                        }
                        
                    }
                  }
              }
              fprintf(outfp, "invokestatic %s/%s(", fileName, $1);
              if(find->attribute->formalParam->params != NULL) 
              { 
                struct PTypeList *i;
                for(i = find->attribute->formalParam->params; i != NULL; i = i->next)
                {
                    if(i->value->type == INTEGER_t)
                        fprintf(outfp, "I");
                    else if(i->value->type == REAL_t)
                        fprintf(outfp, "F");
                    else if(i->value->type == BOOLEAN_t)
                        fprintf(outfp, "Z");
                }
              }
              if(find->type->type == INTEGER_t)
                    fprintf(outfp, ")I\n");
              else if(find->type->type == REAL_t)
                    fprintf(outfp, ")F\n");
              else if(find->type->type == BOOLEAN_t)
                    fprintf(outfp, ")Z\n");
              else
                    fprintf(outfp, ")V\n");
			}
			;

cond_stmt		: IF condition THEN
			  opt_stmt_list{
                fprintf(outfp, "goto Lexit_%d\n", stack[stack_top]);
              }
			  ELSE{
                fprintf(outfp, "Lfalse_%d:\n", stack[stack_top]);
              }
			  opt_stmt_list{
                fprintf(outfp, "Lexit_%d:\n", stack[stack_top]);
                stack_top--;
              }
			  END IF
			| IF condition THEN opt_stmt_list{
                fprintf(outfp, "Lfalse_%d:\n", stack[stack_top]);
                stack_top--;
            }
            END IF
			;

condition		: boolean_expr {
                verifyBooleanExpr( $1, "if" );
                stack_top++;
                label_count++;
                stack[stack_top] = label_count;

                fprintf(outfp, "ifeq Lfalse_%d\n", stack[stack_top]);
            }
			;

while_stmt		: WHILE{
                  stack_top++;
                  label_count++;
                  stack[stack_top] = label_count;
                  fprintf(outfp, "Lbegin_%d:\n", stack[stack_top]);  
              } condition_while{
                  fprintf(outfp, "ifeq Lexit_%d\n", stack[stack_top]);
              } DO
			  opt_stmt_list{
                  fprintf(outfp, "goto Lbegin_%d\n", stack[stack_top]);
                  fprintf(outfp, "Lexit_%d:\n", stack[stack_top]);
			  }END DO{
                  stack_top--;
              }
			;

condition_while		: boolean_expr { verifyBooleanExpr( $1, "while" ); } 
			;

for_stmt		: FOR ID 
			{ 
			  insertLoopVarIntoTable( symbolTable, $2 );
			  struct SymNode *newNode;
			  newNode = lookupLoopVar ( symbolTable, $2);
              newNode->var_num = scope_var;
              scope_var++;
			}
			  OP_ASSIGN loop_param TO loop_param
			{
			  verifyLoopParam( $5, $7 );
              stack_top++;
              label_count++;
              struct SymNode *find = lookupLoopVar( symbolTable, $2);
              if(find != NULL){
                stack[stack_top] = label_count;
                fprintf(outfp, "ldc %d\n", $5);
                fprintf(outfp, "istore %d\n", find->var_num);
                fprintf(outfp, "Lbegin_%d:\n", stack[stack_top]);
                fprintf(outfp, "iload %d\n", find->var_num);
                fprintf(outfp, "ldc %d\n", $7+1);
                fprintf(outfp, "isub\n");
                fprintf(outfp, "iflt Ltrue_%d\n", stack[stack_top]);
                fprintf(outfp, "iconst_0\n");
                fprintf(outfp, "goto Lfalse_%d\n", stack[stack_top]);
                fprintf(outfp, "Ltrue_%d:\n", stack[stack_top]);
                fprintf(outfp, "iconst_1\n");
                fprintf(outfp, "Lfalse_%d:\n", stack[stack_top]);
                fprintf(outfp, "ifeq Lexit_%d\n", stack[stack_top]);
              }
			}
			  DO
			  opt_stmt_list
			  END DO
			{
              struct SymNode *find = lookupLoopVar( symbolTable, $2);
              if(find != NULL){
                fprintf(outfp, "iload %d\n", find->var_num);
                fprintf(outfp, "ldc 1\n");
                fprintf(outfp, "iadd\n");
                fprintf(outfp, "istore %d\n", find->var_num);
                fprintf(outfp, "goto Lbegin_%d\n", stack[stack_top]);
                fprintf(outfp, "Lexit_%d:\n", stack[stack_top]);
              }
              stack_top--; 
			  popLoopVar( symbolTable );
			}
			;

loop_param		: INT_CONST { $$ = $1; }
			| OP_SUB INT_CONST { $$ = -$2; }
			;

return_stmt		: RETURN boolean_expr MK_SEMICOLON
			{
			  verifyReturnStatement( $2, funcReturn );
			}
			;

opt_boolean_expr_list	: boolean_expr_list { $$ = $1; }
			| /* epsilon */ { $$ = 0; }	// null
			;

boolean_expr_list	: boolean_expr_list MK_COMMA boolean_expr
			{
			  struct expr_sem *exprPtr;
			  for( exprPtr=$1 ; (exprPtr->next)!=0 ; exprPtr=(exprPtr->next) );
			  exprPtr->next = $3;
			  $$ = $1;
			}
			| boolean_expr
			{
			  $$ = $1;
			}
			;

boolean_expr		: boolean_expr OP_OR boolean_term
			{
			  verifyAndOrOp( $1, OR_t, $3 );
			  $$ = $1;
              fprintf(outfp, "ior\n");
			}
			| boolean_term { $$ = $1; }
			;

boolean_term		: boolean_term OP_AND boolean_factor
			{
			  verifyAndOrOp( $1, AND_t, $3 );
			  $$ = $1;
              fprintf(outfp, "iand\n");
			}
			| boolean_factor { $$ = $1; }
			;

boolean_factor		: OP_NOT boolean_factor 
			{
			  verifyUnaryNOT( $2 );
			  $$ = $2;
              fprintf(outfp, "iconst_1\n");
              fprintf(outfp, "ixor\n");
			}
			| relop_expr { $$ = $1; }
			;

relop_expr		: expr rel_op expr
			{
			  verifyRelOp( $1, $2, $3 );
			  $$ = $1;
              stack_top++;
              label_count++;
              stack[stack_top] = label_count;
              if($3->pType->type == INTEGER_t){
                fprintf(outfp, "isub\n");
              }
              else if($3->pType->type == REAL_t){
                fprintf(outfp, "fcmpl\n");
              }

              if($2 == LT_t){
                fprintf(outfp, "iflt Ltrue_%d\n", stack[stack_top]);
              }
              else if($2 == LE_t){
                fprintf(outfp, "ifle Ltrue_%d\n", stack[stack_top]);
              }
              else if($2 == EQ_t){
                fprintf(outfp, "ifeq Ltrue_%d\n", stack[stack_top]);
              }
              else if($2 == GE_t){
                fprintf(outfp, "ifge Ltrue_%d\n", stack[stack_top]);
              }
              else if($2 == GT_t){
                fprintf(outfp, "ifgt Ltrue_%d\n", stack[stack_top]);
              }
              else if($2 == NE_t){
                fprintf(outfp, "ifne Ltrue_%d\n", stack[stack_top]);
              }
              fprintf(outfp, "iconst_0\n");
              fprintf(outfp, "goto Lfalse_%d\n", stack[stack_top]);
              fprintf(outfp, "Ltrue_%d:\n", stack[stack_top]);
              fprintf(outfp, "iconst_1\n");
              fprintf(outfp, "Lfalse_%d:\n", stack[stack_top]);
              stack_top--;
			}
			| expr { $$ = $1; }
			;

rel_op			: OP_LT { $$ = LT_t; }
			| OP_LE { $$ = LE_t; }
			| OP_EQ { $$ = EQ_t; }
			| OP_GE { $$ = GE_t; }
			| OP_GT { $$ = GT_t; }
			| OP_NE { $$ = NE_t; }
			;

expr			: expr add_op term
			{
              if($1->pType->type == REAL_t || $3->pType->type == REAL_t){
                if($1->pType->type == INTEGER_t)
                {
                    fprintf(outfp, "fstore %d\n", scope_var);
                    fprintf(outfp, "i2f\n");
                    fprintf(outfp, "fload %d\n", scope_var);
                }
                else if($3->pType->type == INTEGER_t)
                {
                        fprintf(outfp, "i2f\n");
                }

                if($2 == ADD_t)
                    fprintf(outfp, "fadd\n");    
                else
                    fprintf(outfp, "fsub\n");    
              }
              else
              {
                if($2 == ADD_t)
                    fprintf(outfp, "iadd\n");    
                else
                    fprintf(outfp, "isub\n");    
              }
			  verifyArithmeticOp( $1, $2, $3 );
			  $$ = $1;
			}
			| term { $$ = $1;
            }
			;

add_op			: OP_ADD { $$ = ADD_t; }
			| OP_SUB { $$ = SUB_t; }
			;

term			: term mul_op factor
			{
			  if( $2 == MOD_t ) {
				verifyModOp( $1, $3 );
                fprintf(outfp, "irem\n");    
			  }
			  else {
                if($1->pType->type == REAL_t || $3->pType->type == REAL_t){
                    if($1->pType->type == INTEGER_t)
                    {
                        fprintf(outfp, "fstore %d\n", scope_var);
                        fprintf(outfp, "i2f\n");
                        fprintf(outfp, "fload %d\n", scope_var);
                    }
                    else if($3->pType->type == INTEGER_t)
                    {
                        fprintf(outfp, "i2f\n");
                    }
                    else
                        printType($3->pType, 1);

                    if($2 == DIV_t)
                        fprintf(outfp, "fdiv\n");    
                    else
                        fprintf(outfp, "fmul\n");    
                }
                else
                {
                    if($2 == DIV_t)
                        fprintf(outfp, "idiv\n");    
                    else
                        fprintf(outfp, "imul\n");    
                }
			  }
			  verifyArithmeticOp( $1, $2, $3 );
			  $$ = $1;
			}
			| factor { $$ = $1; }
			;

mul_op			: OP_MUL { $$ = MUL_t; }
			| OP_DIV { $$ = DIV_t; }
			| OP_MOD { $$ = MOD_t; }
			;

factor			: var_ref
			{
              _Bool exist;
			  exist = verifyExistence( symbolTable, $1, scope, __FALSE );
			  if(exist == __TRUE && not_load == 0)
              {
                struct SymNode *node = lookupLoopVar(symbolTable, $1->varRef->id);
                if(node == NULL)
                    node = lookupSymbol(symbolTable, $1->varRef->id, scope, __FALSE);
                if((node->category == VARIABLE_t || node->category == PARAMETER_t || node->category == LOOPVAR_t) && node->scope != 0)   //local
                {
                    if(node->type->type == INTEGER_t || node->type->type == BOOLEAN_t)
                        fprintf(outfp, "iload %d\n", node->var_num);
                    else
                        fprintf(outfp, "fload %d\n", node->var_num);
                }
                else if(node->category == VARIABLE_t && node->scope == 0){
                        if(node->type->type == INTEGER_t){
                            fprintf(outfp, "getstatic %s/%s I\n", fileName, node->name);
                        }
                        else if(node->type->type == BOOLEAN_t){
                            fprintf(outfp, "getstatic %s/%s Z\n", fileName, node->name);
                        }
                        if(node->type->type == REAL_t){
                            fprintf(outfp, "getstatic %s/%s F\n", fileName, node->name);
                        }
                }
                else if(node->category == CONSTANT_t){
                    if(node->type->type == INTEGER_t){
                            fprintf(outfp, "ldc %d\n", node->attribute->constVal->value.integerVal);
                    }
                    else if(node->type->type == REAL_t){
                            fprintf(outfp, "ldc %lf\n", node->attribute->constVal->value.realVal);
                    }
                    else if(node->type->type == BOOLEAN_t){
                            fprintf(outfp, "iconst_%d\n", node->attribute->constVal->value.booleanVal);
                    }
                    else if(node->type->type == STRING_t){
                            fprintf(outfp, "ldc \"%s\"\n", node->attribute->constVal->value.stringVal);
                    }
                }    
              }
              $$ = $1;
			  $$->beginningOp = NONE_t;
			}
			| OP_SUB var_ref
			{
			  if( verifyExistence( symbolTable, $2, scope, __FALSE ) == __TRUE && not_load == 0){
				verifyUnaryMinus( $2 );
                struct SymNode *node = lookupLoopVar(symbolTable, $2->varRef->id);
                if(node == NULL)
                    node = lookupSymbol(symbolTable, $2->varRef->id, scope, __FALSE);
                if((node->category == VARIABLE_t || node->category == PARAMETER_t) && node->scope != 0)   //local
                {
                    if(node->type->type == INTEGER_t || node->type->type == BOOLEAN_t)
                        fprintf(outfp, "iload %d\n", node->var_num);
                    else
                        fprintf(outfp, "fload %d\n", node->var_num);
                }
                else if(node->category == VARIABLE_t && node->scope == 0){
                        if(node->type->type == INTEGER_t){
                            fprintf(outfp, "getstatic %s/%s I\n", fileName, node->name);
                        }
                        else if(node->type->type == BOOLEAN_t){
                            fprintf(outfp, "getstatic %s/%s Z\n", fileName, node->name);
                        }
                        if(node->type->type == REAL_t){
                            fprintf(outfp, "getstatic %s/%s F\n", fileName, node->name);
                        }
                }
                else{
                    if(node->type->type == INTEGER_t){
                            fprintf(outfp, "ldc %d\n", node->attribute->constVal->value.integerVal);
                    }
                    else if(node->type->type == REAL_t){
                            fprintf(outfp, "ldc %lf\n", node->attribute->constVal->value.realVal);
                    }
                    else if(node->type->type == BOOLEAN_t){
                            fprintf(outfp, "iconst_%d\n", node->attribute->constVal->value.booleanVal);
                    }
                    else if(node->type->type == STRING_t){
                            fprintf(outfp, "ldc \"%s\"\n", node->attribute->constVal->value.stringVal);
                    }
                }
                if($2->pType->type == INTEGER_t)
                    fprintf(outfp, "ineg\n");
                else if($2->pType->type == REAL_t)
                    fprintf(outfp, "fneg\n");
                }
			    $$ = $2;
			    $$->beginningOp = SUB_t;
			}
			| MK_LPAREN boolean_expr MK_RPAREN 
			{
			  $2->beginningOp = NONE_t;
			  $$ = $2; 
			}
			| OP_SUB MK_LPAREN boolean_expr MK_RPAREN
			{
			  verifyUnaryMinus( $3 );
			  $$ = $3;
			  $$->beginningOp = SUB_t;
                if($3->pType->type == INTEGER_t)
                    fprintf(outfp, "ineg\n");
                else if($3->pType->type == REAL_t)
                    fprintf(outfp, "fneg\n");
			}
			| ID MK_LPAREN opt_boolean_expr_list MK_RPAREN
			{
			  $$ = verifyFuncInvoke( $1, $3, symbolTable, scope );
			  $$->beginningOp = NONE_t;
              struct SymNode *find = lookupSymbol(symbolTable, $1, scope, __FALSE);
              struct PTypeList *k;
              struct expr_sem *m;
              for(k = find->attribute->formalParam->params, m = $3; k != NULL; k = k->next, m = m->next)
              {
                  if(k->value->type == REAL_t){
                    if(m->pType->type == INTEGER_t){
                        int Q = 0;
                        for(struct expr_sem *p = m->next; p != NULL; p = p->next, Q++){
                            if(p->pType->type == INTEGER_t || p->pType->type == BOOLEAN_t)
                                fprintf(outfp, "istore %d\n", scope_var+Q);
                            else if(p->pType->type == REAL_t)
                                fprintf(outfp, "fstore %d\n", scope_var+Q);
                        }
                        fprintf(outfp, "i2f\n");
                        Q--;
                        for(struct expr_sem *p = m->next; p != NULL; p = p->next, Q--){
                            if(p->pType->type == INTEGER_t || p->pType->type == BOOLEAN_t)
                                fprintf(outfp, "iload %d\n", scope_var+Q);
                            else if(p->pType->type == REAL_t)
                                fprintf(outfp, "fload %d\n", scope_var+Q);
                        }
                        
                    }
                  }
              }
              fprintf(outfp, "invokestatic %s/%s(", fileName, $1);
              if(find->attribute->formalParam->params != NULL) 
              { 
                for(struct PTypeList *i = find->attribute->formalParam->params; i != NULL; i = i->next)
                {
                    if(i->value->type == INTEGER_t)
                        fprintf(outfp, "I");
                    else if(i->value->type == REAL_t)
                        fprintf(outfp, "F");
                    else if(i->value->type == BOOLEAN_t)
                        fprintf(outfp, "Z");
                }
              }
              if(find->type->type == INTEGER_t)
                    fprintf(outfp, ")I\n");
              else if(find->type->type == REAL_t)
                    fprintf(outfp, ")F\n");
              else if(find->type->type == BOOLEAN_t)
                    fprintf(outfp, ")Z\n");
              else
                    fprintf(outfp, ")V\n");
			}
			| OP_SUB ID MK_LPAREN opt_boolean_expr_list MK_RPAREN
			{
			  $$ = verifyFuncInvoke( $2, $4, symbolTable, scope );
			  $$->beginningOp = SUB_t;
              struct SymNode *find = lookupSymbol(symbolTable, $2, scope, __FALSE);
              struct PTypeList *k;
              struct expr_sem *m;
              for(k = find->attribute->formalParam->params, m = $4; k != NULL; k = k->next, m = m->next)
              {
                  if(k->value->type == REAL_t){
                    if(m->pType->type == INTEGER_t){
                        int Q = 0;
                        for(struct expr_sem *p = m->next; p != NULL; p = p->next, Q++){
                            if(p->pType->type == INTEGER_t || p->pType->type == BOOLEAN_t)
                                fprintf(outfp, "istore %d\n", scope_var+Q);
                            else if(p->pType->type == REAL_t)
                                fprintf(outfp, "fstore %d\n", scope_var+Q);
                        }
                        fprintf(outfp, "i2f\n");
                        Q--;
                        for(struct expr_sem *p = m->next; p != NULL; p = p->next, Q--){
                            if(p->pType->type == INTEGER_t || p->pType->type == BOOLEAN_t)
                                fprintf(outfp, "iload %d\n", scope_var+Q);
                            else if(p->pType->type == REAL_t)
                                fprintf(outfp, "fload %d\n", scope_var+Q);
                        }
                        
                    }
                  }
              }
              fprintf(outfp, "invokestatic %s/%s(", fileName, $2);
              if(find->attribute->formalParam->params != NULL) 
              { 
                for(struct PTypeList *i = find->attribute->formalParam->params; i != NULL; i = i->next)
                {
                    if(i->value->type == INTEGER_t)
                        fprintf(outfp, "I");
                    else if(i->value->type == REAL_t)
                        fprintf(outfp, "F");
                    else if(i->value->type == BOOLEAN_t)
                        fprintf(outfp, "Z");
                }
              }
              if(find->type->type == INTEGER_t)
                    fprintf(outfp, ")I\n");
              else if(find->type->type == REAL_t)
                    fprintf(outfp, ")F\n");
              else if(find->type->type == BOOLEAN_t)
                    fprintf(outfp, ")Z\n");
              else
                    fprintf(outfp, ")V\n");
                if(find->type->type == INTEGER_t)
                    fprintf(outfp, "ineg\n");
                else if(find->type->type == REAL_t)
                    fprintf(outfp, "fneg\n");
			}
			| literal_const
			{
			  $$ = (struct expr_sem *)malloc(sizeof(struct expr_sem));
			  $$->isDeref = __TRUE;
			  $$->varRef = 0;
			  $$->pType = createPType( $1->category );
			  $$->next = 0;
			  if( $1->hasMinus == __TRUE ) {
			  	$$->beginningOp = SUB_t;
			  }
			  else {
				$$->beginningOp = NONE_t;
			  }
              if($1->category == STRING_t){
                fprintf(outfp, "ldc \"%s\"\n", $1->value.stringVal);
              }
              else if($1->category == INTEGER_t){
                fprintf(outfp, "ldc %d\n", $1->value.integerVal); 
              }
              else if($1->category == REAL_t){
                fprintf(outfp, "ldc %lf\n", $1->value.realVal);
              }
              else if($1->category == BOOLEAN_t){
                fprintf(outfp, "iconst_%d\n", $1->value.booleanVal);
              }
			}
			;

var_ref			: ID
			{
			  $$ = createExprSem( $1 );
			}
			| var_ref dim
			{
			  increaseDim( $1, $2 );
			  $$ = $1;
			}
			;

dim			: MK_LB boolean_expr MK_RB
			{
			  $$ = verifyArrayIndex( $2 );
			}
			;

%%

int yyerror( char *msg )
{
	(void) msg;
	fprintf( stderr, "\n|--------------------------------------------------------------------------\n" );
	fprintf( stderr, "| Error found in Line #%d: %s\n", linenum, buf );
	fprintf( stderr, "|\n" );
	fprintf( stderr, "| Unmatched token: %s\n", yytext );
	fprintf( stderr, "|--------------------------------------------------------------------------\n" );
	exit(-1);
}

