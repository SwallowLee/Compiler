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

//#include "test.h"

int yydebug;

//extern char filename[256];
extern int linenum;		/* declared in lex.l */
extern FILE *yyin;		/* declared by lex */
extern char *yytext;		/* declared by lex */
extern char buf[256];		/* declared in lex.l */
extern int yylex(void);
int yyerror(char* );
int global;
int return_type;
int scope = 0;

int Opt_D = 1;			/* symbol table dump option */
int is_error = 0;
char fileName[256];


struct SymTable *symbolTable;	// main symbol table

__BOOLEAN paramError;			// indicate is parameter have any error?

struct PType *funcReturn;		// record function's return type, used at 'return statement' production rule

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
			  if(strcmp(fileName, $1) != 0)
			  {
				printf("<Error> found in Line %d: program beginning ID inconsist with the file name\n", linenum);
			  	is_error = 1;
			  }
			  struct PType *pType = createPType( VOID_t );
			  struct SymNode *newNode = createProgramNode( $1, scope, pType );
			  insertTab( symbolTable, newNode );
			  global = 0;
			}
			  MK_SEMICOLON 
			  program_body
			  END ID
			{
			  if(strcmp($1, $6) != 0)
			  {
				printf("<Error> found in Line %d: program end ID inconsist with the beginning ID\n", linenum);
			  	is_error = 1;
			  }
			  if(strcmp(fileName, $6) != 0)
			  {
				printf("<Error> found in Line %d: program end ID inconsist with the file name\n", linenum);
			  	is_error = 1;
			  }
			  // dump symbol table
			  if( Opt_D == 1 )
				printSymTable( symbolTable, scope );
			}
			;

program_body		: opt_decl_list opt_func_decl_list compound_stmt
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
			  for( ptr=$2 ; ptr!=0 ; ptr=(ptr->next) ) {
			  	if( verifyRedeclaration( symbolTable, ptr->value, scope ) ==__FALSE ) { }
				else {
					newNode = createVarNode( ptr->value, scope, $4 );
					insertTab( symbolTable, newNode );
				}
			  }

			  deleteIdList( $2 );
			}
			| VAR id_list MK_COLON array_type MK_SEMICOLON        /* array type declaration */
			{
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

func_decl		: ID MK_LPAREN opt_param_list
			{
			  // check and insert parameters into symbol table
			  paramError = insertParamIntoSymTable( symbolTable, $3, scope+1 );
			  return_type = 0;
			}
			  MK_RPAREN opt_type 
			{
			  if(return_type == 0)
			  {
			  	// check and insert function into symbol table
			  	insertFuncIntoSymTable( symbolTable, $1, $3, $6, scope );
			  }
			  funcReturn = $6;
			  global++;
			}
			  MK_SEMICOLON
			{
			  if(return_type == 1)
			  {
				funcReturn->isArray = __TRUE;
				printf("<Error> found in Line %d: function return type can not be array type.\n", linenum);
			  	is_error = 1;
			  }
			}
			  compound_stmt
			  END ID
			{
			  if(strcmp($1, $12) != 0)
			  {
				printf("<Error> found in Line %d: function end ID inconsist with the beginning ID\n", linenum);
			  	is_error = 1;
			  }
			  global--;
			  funcReturn = 0;
			}
			;

opt_param_list		: param_list { $$ = $1; }
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
			| array_type { $$ = $1; return_type = 1;}
			;

scalar_type		: INTEGER { $$ = createPType( INTEGER_t ); }
			| REAL { $$ = createPType( REAL_t ); }
			| BOOLEAN { $$ = createPType( BOOLEAN_t ); }
			| STRING { $$ = createPType( STRING_t ); }
			;

array_type		: ARRAY array_index TO array_index OF type
			{
				if($2 >= $4)
			  	{
					printf("<Error> found in Line %d: the index of the lower bound must be smaller than that of the upper bound.\n", linenum);
					is_error = 1;
			  	}

				if($2 < 0)
				{
					printf("<Error> found in Line %d: the index of the lower bound must be greater than zero.\n", linenum);
					is_error = 1;
				}

				if($4 < 0)
				{
					printf("<Error> found in Line %d: the index of the upper bound must be greater than zero.\n", linenum);
					is_error = 1;
				}
				
				increaseArrayDim( $6, $2, $4 );
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
			  if($1 == 0)
			  {
			  }
			  else if($1->isFor == __TRUE)
			  {
				printf("<Error> found in Line %d: for loop variable cannot be assign.\n", linenum);
			  	is_error = 1;
			  }
				//Constant determined
			  if($1->pType == 0)
			  {
			  }
			  else if($1->pType->isConst == __TRUE)
			  {
				printf("<Error> found in Line %d: constant variable cannot be assign.\n", linenum);
			  	is_error = 1;
			  }
				//type mismatch determined
			  if($1->pType == 0 || $3->pType ==0)
			  {
				if($1->pType == 0)
                    printf("<Error> found in Line %d: type of LHS can not detect.\n", linenum);
                if($3->pType == 0)
                    printf("<Error> found in Line %d: type of RHS can not detect.\n", linenum);
			  	if(($1->pType == 0 && $3->pType != 0) || ($1->pType != 0 && $3->pType == 0))
					printf("<Error> found in Line %d: assign type mismatch: the types of RHS and LHS must be same.\n", linenum);
                is_error = 1;
			  }
			  else if($1->pType->type != $3->pType->type)
			  {
				if($1->pType->type == REAL_t && $3->pType->type == INTEGER_t)
				{///array demension must be same
					int is_print = 0;
					if($1->varRef == 0 || $3->varRef == 0);
					else if($1->pType->isArray == __TRUE)
					{
						if($3->pType->isArray == __TRUE)
						{
							struct ArrayDimNode *one, *two;
							int i;
							for(one = $1->pType->dim, i = $1->varRef->dimNum; i != 0 && one->next != 0; i--, one = one->next);
							for(two = $3->pType->dim, i = $3->varRef->dimNum; i != 0 && two->next != 0; i--, two = two->next);
							for(; (one)!=0 && (two)!=0; one = one->next, two = two->next)
							{
								if(one->size != two->size)
								{
									printf("<Error> found in Line %d: assign type mismatch: the size of array must be same.\n", linenum);
									is_print = 1;
									is_error = 1;
									break;
								}
								if(one->next == 0 ||  two->next == 0)
									break;
							}
							if((one->next != 0 || two->next != 0) && is_print == 0)
							{
                                printf("<Error> found in Line %d: assign type mismatch: the dimension of array must be same.\n", linenum);
                                is_error = 1;
							}
						}
						else
						{
                            if($1->pType->dimNum != ($1->varRef->dimNum))
			                {
					            printf("<Error> found in Line %d: assign type mismatch: the types of RHS and LHS must be same.\n", linenum);
			  	                is_error = 1;
			                }
						}
					}
					else if($3->pType->isArray == __TRUE)
					{
                            if($3->pType->dimNum != ($3->varRef->dimNum))
			                {
					            printf("<Error> found in Line %d: assign type mismatch: the types of RHS and LHS must be same.\n", linenum);
			  	                is_error = 1;
			                }
					}
				}
				else
				{	
					printf("<Error> found in Line %d: assign type mismatch: the types of RHS and LHS must be same.\n", linenum);
			  		is_error = 1;
			  	}
			  } 
			  else	//type same -> array demension must be same
			  {
				if($1->varRef == 0 || $3->varRef == 0)
				{
				}
				else if($1->pType->isArray == __TRUE)
				{
					if($3->pType->isArray == __TRUE)
					{
						struct ArrayDimNode *one, *two;
						int i;
						int is_print = 0;
						for(one = $1->pType->dim, i = $1->varRef->dimNum; i != 0 && one->next != 0; i--, one = one->next);
						for(two = $3->pType->dim, i = $3->varRef->dimNum; i != 0 && two->next != 0; i--, two = two->next);
						for(; (one)!=0 && (two)!=0; one = one->next, two = two->next)
						{
							if(one->size != two->size)
							{
								printf("<Error> found in Line %d: assign type mismatch: the size of array must be same.\n", linenum);
								is_print = 1;
								is_error = 1;
								break;
							}
							if(one->next == 0 ||  two->next == 0)
								break;
						}
						if((one->next != 0 || two->next != 0) && is_print == 0)
						{
                            printf("<Error> found in Line %d: assign type mismatch: the dimension of array must be same.\n", linenum);
							is_error = 1;
						}
					}
					else
					{
                            if($1->pType->isArray == __TRUE && $1->pType->dimNum != ($1->varRef->dimNum))
			                {
					            printf("<Error> found in Line %d: assign type mismatch: the types of RHS and LHS must be same.\n", linenum);
			  	                is_error = 1;
			                }
					}
				}
				else if($3->pType->isArray == __TRUE)
				{
                    if($3->pType->isArray == __TRUE && $3->pType->dimNum != ($3->varRef->dimNum))
			        {
					    printf("<Error> found in Line %d: assign type mismatch: the types of RHS and LHS must be same.\n", linenum);
			  	        is_error = 1;
			        }
				}
			  }

				// array cannot assigned
			  if($1->pType == 0);
              else if($1->pType->isArray == __TRUE && $1->pType->dimNum != ($1->varRef->dimNum))
			  {
				printf("<Error> found in Line %d: array assignment is not allowed(LHS).\n", linenum);
			  	is_error = 1;
			  }
			  if($3->pType == 0);
			  else if($3->pType->isArray == __TRUE && $3->pType->dimNum != ($3->varRef->dimNum))
			  {
				printf("<Error> found in Line %d: array assignment is not allowed(RHS).\n", linenum);
			  	is_error = 1;
			  }
			}
			| PRINT boolean_expr MK_SEMICOLON
			{
			  if($2->pType->isArray == __TRUE)
			  {
				printf("<Error> found in Line %d: variable reference of print statement must be scalar type.\n", linenum);
			  	is_error = 1;
			  }	
			}
 			| READ boolean_expr MK_SEMICOLON
			{
			  if($2->pType->isArray == __TRUE)
			  {
				printf("<Error> found in Line %d: variable reference of read statement must be scalar type.\n", linenum);
			  	is_error = 1;
			  }	
			}
			;

proc_call_stmt		: ID MK_LPAREN opt_boolean_expr_list MK_RPAREN MK_SEMICOLON
			{
			  //verifyFuncInvoke( $1, $3, symbolTable, scope );     //has something to write here!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			}
			;

cond_stmt		: IF condition THEN
			  opt_stmt_list
			  ELSE
			  opt_stmt_list
			  END IF
			| IF condition THEN opt_stmt_list END IF
			;

condition		: boolean_expr
	   		{
			  if($1->pType == 0)
			  {
			    printf("<Error> found in Line %d: the condition expression of if statement can not detect.\n", linenum);
			  	is_error = 1;
			  }
			  else if($1->pType->type != BOOLEAN_t)
			  {
				printf("<Error> found in Line %d: the condition expression of if statement must be boolean type.\n", linenum);
			  	is_error = 1;
			  }
              else
              {
                if($1->pType->isArray == __TRUE && $1->pType->dimNum != $1->varRef->dimNum)
				{
                    printf("<Error> found in Line %d: the condition expression of if statement can not be array.\n", linenum);
			  	    is_error = 1;
                }  
              }
			}
			;

while_stmt		: WHILE condition_while DO
			  opt_stmt_list
			  END DO
			;

condition_while		: boolean_expr
		 	{
			  if($1->pType == 0)
			  {
			    printf("<Error> found in Line %d: the condition expression of while statement can not detect.\n", linenum);
				is_error = 1;
			  }
			  else if($1->pType->type != BOOLEAN_t)
			  {
			    printf("<Error> found in Line %d: the condition expression of while statement must be boolean type.\n", linenum);
			    is_error = 1;
			  }
              else
              {
                if($1->pType->isArray == __TRUE && $1->pType->dimNum != $1->varRef->dimNum)
				{
                    printf("<Error> found in Line %d: the condition expression of while statement can not be array.\n", linenum);
			  	    is_error = 1;
                }  
              }
			}
			;

for_stmt		: FOR ID
			{
			  insertLoopVarIntoTable( symbolTable, $2 );
			}
			  OP_ASSIGN loop_param TO loop_param
			{
			  if($5 > $7)
			  {
				printf("<Error> found in Line %d: for statement must be increment order.\n", linenum);
			  	is_error = 1;
			  }
			  if($5 < 0 || $7 < 0)
			  {
				printf("<Error> found in Line %d: the loop parameter of the for statement must be greater than or equal to zero.\n", linenum);
			  	is_error = 1;
			  }

			}
			  DO
			  opt_stmt_list
			  END DO
			{
			  popLoopVar( symbolTable );
			}
			;

loop_param		: INT_CONST { $$ = $1; }
			| OP_SUB INT_CONST { $$ = -$2; }
			;

return_stmt		: RETURN boolean_expr MK_SEMICOLON
			{
			  if(global == 0)
			  {
				printf("<Error> found in Line %d: return statement can not appear in the main block.\n", linenum);
			  	is_error = 1;
			  }
			  else
			  {
			  	if($2->pType == 0 || funcReturn == 0)
			  	{
                    if($2->pType == 0 && funcReturn == 0);
                    else
					{    
					    printf("<Error> found in Line %d: type mismatch between return statement and function return type.\n", linenum);
			  			is_error = 1;
			  		}
			  	}
				else if(funcReturn->type != $2->pType->type)
				{
				    printf("<Error> found in Line %d: type mismatch between return statement and function return type.\n", linenum);
					is_error = 1;
				}
				else if(funcReturn->isArray == __TRUE && $2->pType->isArray == __FALSE)
				{
				    printf("<Error> found in Line %d: type mismatch between return statement and function return type.\n", linenum);
					is_error = 1;
				}
				else if(funcReturn->isArray == __FALSE && $2->pType->isArray == __TRUE)
				{
					if($2->pType->dimNum != ($2->varRef->dimNum))
					{	
				    	printf("<Error> found in Line %d: type mismatch between return statement and function return type.\n", linenum);
						is_error = 1;
					}
				}
				else if(funcReturn->isArray == __TRUE && $2->pType->isArray == __TRUE)
				{
					if($2->pType->dimNum == ($2->varRef->dimNum))
					{
						printf("<Error> found in Line %d: type mismatch between return statement an	function return type.\n", linenum);
						is_error = 1;
					}
					else
					{
						printf("<Error> found in Line %d: return type can not be array type.\n", linenum);
						is_error = 1;
					}
				}	
			  }
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
			  $$ = $1;
			  if($1->pType == 0 || $3->pType ==0)
			  {
                if($1->pType == 0)
				    printf("<Error> found in Line %d: the left operand of boolean expression can not detect.\n", linenum);
                if($3->pType == 0)
				    printf("<Error> found in Line %d: the right operand of boolean expression can not detect.\n", linenum);

			  	is_error = 1;
			  }
			  else if($1->pType->type != BOOLEAN_t || $3->pType->type != BOOLEAN_t)
			  {
				printf("<Error> found in Line %d: the operand of the boolean expression must be boolean type.\n", linenum, $1, $3);
			  	is_error = 1;
			  }
			  if($1->pType == 0);
			  else if($1->pType->isArray == __TRUE && $1->pType->dimNum != ($1->varRef->dimNum))
			  {
				printf("<Error> found in Line %d: array arithmetic is not allowed(left operand).\n", linenum);
			  	is_error = 1;
			  }
			  if($3->pType == 0);
			  else if($3->pType->isArray == __TRUE && $3->pType->dimNum != ($3->varRef->dimNum))
			  {
				printf("<Error> found in Line %d: array arithmetic is not allowed(right operand).\n", linenum);
			  	is_error = 1;
			  }
			}
			| boolean_term { $$ = $1;
			}
			;

boolean_term		: boolean_term OP_AND boolean_factor
			{
			  $$ = $1;
			  if($1->pType == 0 || $3->pType ==0)
			  {
                if($1->pType == 0)
				    printf("<Error> found in Line %d: the left operand of boolean expression can not detect.\n", linenum);
                if($3->pType == 0)     
				    printf("<Error> found in Line %d: the right operand of boolean expression can not detect.\n", linenum);
			  	is_error = 1;
			  }
			  else if($1->pType->type != BOOLEAN_t || $3->pType->type != BOOLEAN_t)
			  {
				printf("<Error> found in Line %d: the operand of the boolean expression must be boolean type.\n", linenum, $1, $3);
				is_error = 1;			 
			  }
			  if($1->pType == 0);
			  else if($1->pType->isArray == __TRUE && $1->pType->dimNum != ($1->varRef->dimNum))
			  {
				printf("<Error> found in Line %d: array arithmetic is not allowed(left operand).\n", linenum);
			  	is_error = 1;
			  }
			  if($3->pType == 0);
			  else if($3->pType->isArray == __TRUE && $3->pType->dimNum != ($3->varRef->dimNum))
			  {
				printf("<Error> found in Line %d: array arithmetic is not allowed(right operand).\n", linenum);
			  	is_error = 1;
			  }
			}
			| boolean_factor { $$ = $1; }
			;

boolean_factor		: OP_NOT boolean_factor 
			{
			  $$ = $2;
			  if($2->pType == 0)
			  {
				printf("<Error> found in Line %d: the operand of boolean expression(not) can not detect.\n", linenum);
			  	is_error = 1;
			  }
			  else if($2->pType->type != BOOLEAN_t)
			  {
				printf("<Error> found in Line %d: the operand of the boolean operator must be boolean type.\n", linenum);
			  	is_error = 1;
			  }
			  else if($2->pType->isArray == __TRUE && $2->pType->dimNum != ($2->varRef->dimNum))
			  {
				printf("<Error> found in Line %d: array arithmetic is not allowed.\n", linenum);
			  	is_error = 1;
			  }
			}
			| relop_expr { $$ = $1; }
			;

relop_expr		: expr rel_op expr
			{
			  if($1->pType == 0 || $3->pType ==0)
			  {
			  	if($1->pType == 0 && $3->pType ==0)
				{
					$$ = $1;
				}
				else if($1->pType == 0)
				{
					$$ = $1;
				}
				else if($3->pType == 0)
				{
					$$ = $3;
				}
				if($1->pType == 0)
				    printf("<Error> found in Line %d: the left operand of relation exprssion can not detect.\n", linenum);
				if($3->pType == 0)
				    printf("<Error> found in Line %d: the right operand of relation expression can not detect.\n", linenum);
				is_error = 1;
			  }
			  else
			  {
			  	$$ = (struct expr_sem *)malloc(sizeof(struct expr_sem));
			  	$$->beginningOp = $1->beginningOp;
			  	$$->isDeref = $1->isDeref;
			  	$$->varRef = $1->varRef;
			  	$$->pType = createPType(BOOLEAN_t);
			  	$$->next = $1->next;
			  	if($1->pType->type != INTEGER_t || $3->pType->type != INTEGER_t)
                {
                    if ($1->pType->type != REAL_t || $3->pType->type != REAL_t)
			  	    {
					    printf("<Error> found in Line %d: the operand of the relational expression is not both integer or real.\n", linenum);
			  		    //$$->pType = 0;
                        is_error = 1;
			  	    }
                }
			  }
			  if($1->pType == 0)
			  {
			  }
			  else if($1->pType->isArray == __TRUE && $1->pType->dimNum != ($1->varRef->dimNum))
			  {
				printf("<Error> found in Line %d: array arithmetic is not allowed(left operand).\n", linenum);
			  	is_error = 1;
			  }
			  if($3->pType == 0)
			  {
			  }
			  else if($3->pType->isArray == __TRUE && $3->pType->dimNum != ($3->varRef->dimNum))
			  {
				printf("<Error> found in Line %d: array arithmetic is not allowed(right operand).\n", linenum);
			  	is_error = 1;
			  }
			  //array determined
			}
			| expr { 
			  $$ = $1; 
			}
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
			  if($2 == ADD_t)
			  {
			  	if($1->pType == 0 || $3->pType ==0)
			  	{
				    if($1->pType == 0)
				        printf("<Error> found in Line %d: the left operand of arithmetic expression can not detect.\n", linenum);
				    if($3->pType == 0)
				        printf("<Error> found in Line %d: the right operand of arithmetic expression can not detect.\n", linenum);
			  		is_error = 1;
			  	}
				else if($1->pType->type == STRING_t && $3->pType->type == STRING_t);
			  	else if(($1->pType->type != INTEGER_t && $1->pType->type != REAL_t) || ($3->pType->type != INTEGER_t && $3->pType->type != REAL_t) )		//the operand of add/sub must be real or integer
			  	{
					printf("<Error> found in Line %d: the operand of arithmetic expression (add/sub) must be integer or real type.\n", linenum);
			  		is_error = 1;
			  	}
				
			  }
			  else if($1->pType == 0 || $3->pType ==0)
			  {
				if($1->pType == 0)
				    printf("<Error> found in Line %d: the left operand of arithmetic expression can not detect.\n", linenum);
				if($3->pType == 0)
				    printf("<Error> found in Line %d: the right operand of arithmetic expression can not detect.\n", linenum);
			 	is_error = 1;
			  }
			  else if(($1->pType->type != INTEGER_t && $1->pType->type != REAL_t) || 
			     ($3->pType->type != INTEGER_t && $3->pType->type != REAL_t) )		//the operand of add/sub must be real or integer
			  {
				printf("<Error> found in Line %d: the operand of arithmetic expression (add/sub) must be integer or real type.\n", linenum, $1, $3);
			  	is_error = 1;
			  }
			  if($1->pType == 0 || $3->pType ==0)
			  {
				$$ = $1;
			  }
			  else if($1->pType->type == INTEGER_t && $3->pType->type == REAL_t)
			  {
			  	$$ = (struct expr_sem *)malloc(sizeof(struct expr_sem));
			  	$$->beginningOp = $1->beginningOp;
			  	$$->isDeref = $1->isDeref;
			  	$$->varRef = $1->varRef;
			  	$$->pType = createPType(REAL_t);
			  	$$->next = $1->next;	
			  }
			  else
			  {
				$$ = $1;
			  }
			  if($1->pType == 0)
			  {
			  }
			  else if($1->pType->isArray == __TRUE && $1->pType->dimNum != ($1->varRef->dimNum))
			  {
				printf("<Error> found in Line %d: array arithmetic is not allowed(left operand).\n", linenum);
			  	is_error = 1;
			  }
			  if($3->pType == 0)
			  {
			  }
			  else if($3->pType->isArray == __TRUE && $3->pType->dimNum != ($3->varRef->dimNum))
			  {
				printf("<Error> found in Line %d: array arithmetic is not allowed(right operand).\n", linenum);
			  	is_error = 1;
			  }
			  
			  //array determined
			}
			| term { $$ = $1; 
			}
			;

add_op			: OP_ADD { $$ = ADD_t; }
			| OP_SUB { $$ = SUB_t; }
			;

term			: term mul_op factor
			{
			  if($2 == MOD_t)
			  {
			  	if($1->pType == 0 || $3->pType ==0)
			  	{
				    if($1->pType == 0)
				        printf("<Error> found in Line %d: the left operand of arithmetic expression can not detect.\n", linenum);
				    if($3->pType == 0)
				        printf("<Error> found in Line %d: the right operand of arithmetic expression can not detect.\n", linenum);
			  		is_error = 1;
			  	}
				else if($1->pType->type != INTEGER_t || $3->pType->type != INTEGER_t)		//the operand of mod must be integer 
				{
					printf("<Error> found in Line %d: the operand of mod must be integer type.\n", linenum, $1, $3);
			  		is_error = 1;
			  	}
			  	$$ = $1;
			  }
			  else
			  {
			  	if($1->pType == 0 || $3->pType ==0)
			  	{
				    if($1->pType == 0)
				        printf("<Error> found in Line %d: the left operand of arithmetic expression can not detect.\n", linenum);
				    if($3->pType == 0)
				        printf("<Error> found in Line %d: the right operand of arithmetic expression can not detect.\n", linenum);
					is_error = 1;
					$$ = $1;
			  	}
				else if(($1->pType->type != INTEGER_t && $1->pType->type != REAL_t) || 
				   ($3->pType->type != INTEGER_t && $3->pType->type != REAL_t) )		//the operand of mul/div must be real or integer
				{
					printf("<Error> found in Line %d: the operand of arithmetic expression (mul/div) must be integer or real type.\n", linenum, $1, $3);
			  		is_error = 1;
			  	}

			  	if($1->pType == 0 || $3->pType ==0)
			  	{
					$$ = $1;
			  	}
				else if($1->pType->type == INTEGER_t && $3->pType->type == REAL_t)
				{
			  		$$ = (struct expr_sem *)malloc(sizeof(struct expr_sem));
			  		$$->beginningOp = $1->beginningOp;
			  		$$->isDeref = $1->isDeref;
			  		$$->varRef = $1->varRef;
			  		$$->pType = createPType(REAL_t);
			  		$$->next = $1->next;	
				}
				else
			  	{
					$$ = $1;
				}
			  }			
			  if($1->pType == 0);
			  else if($1->pType->isArray == __TRUE && $1->pType->dimNum != ($1->varRef->dimNum))
			  {
				printf("<Error> found in Line %d: array arithmetic is not allowed(left operand).\n", linenum);
			  	is_error = 1;
			  }
			  if($3->pType == 0);
			  else if($3->pType->isArray == __TRUE && $3->pType->dimNum != ($3->varRef->dimNum))
			  {
				printf("<Error> found in Line %d: array arithmetic is not allowed(right operand).\n", linenum);
			  	is_error = 1;
			  }

			}
			| factor { $$ = $1; 
            }
			;

mul_op			: OP_MUL { $$ = MUL_t; }
			| OP_DIV { $$ = DIV_t; }
			| OP_MOD { $$ = MOD_t; }
			;

factor			: var_ref
			{
			  $$ = $1;
			  $$->beginningOp = NONE_t;
			  if($$->pType == 0);
			  else if($$->pType->isArray == __FALSE && $$->varRef->dimNum != 0 )
			  {
				printf("<Error> found in Line %d: %s is not array type.\n", linenum, $1->varRef->id);
			  	is_error = 1;
			  }
              else if($$->pType->isArray == __TRUE && $$->pType->dimNum < $$->varRef->dimNum)
              {
				printf("<Error> found in Line %d: array '%s' is over dimension.\n", linenum, $1->varRef->id);
			  	is_error = 1;
              }
			}
			| OP_SUB var_ref
			{
			  $$ = $2;
			  $$->beginningOp = SUB_t;
			  if($$->pType == 0);
			  else if($$->pType->isArray == __FALSE && $$->varRef->dimNum != 0 )
			  {
				printf("<Error> found in Line %d: %s is not array type.\n", linenum, $2->varRef->id);
			  	is_error = 1;
			  }
              else if($$->pType->isArray == __TRUE && $$->pType->dimNum < $$->varRef->dimNum)
              {
				printf("<Error> found in Line %d: array '%s' is over dimension.\n", linenum, $2->varRef->id);
			  	is_error = 1;
              }
			}
			| MK_LPAREN boolean_expr MK_RPAREN 
			{
			  $2->beginningOp = NONE_t;
			  $$ = $2; 
			}
			| OP_SUB MK_LPAREN boolean_expr MK_RPAREN
			{
			  $$ = $3;
			  $$->beginningOp = SUB_t;
			}
			| ID MK_LPAREN opt_boolean_expr_list MK_RPAREN
			{
			  //$$ = verifyFuncInvoke( $1, $3, symbolTable, scope );
			  $$ = (struct expr_sem *)malloc(sizeof(struct expr_sem));
			  $$->isDeref = __TRUE;
			  $$->varRef = (struct var_ref_sem*) malloc(sizeof(struct var_ref_sem));
			  $$->varRef->id = (char *) malloc(sizeof(char)*(strlen($1)+1));
			  strcpy($$->varRef->id, $1);
			  $$->varRef->dimNum = 0;
			  $$->varRef->dim = 0;
              		  $$->next = 0;

              		  struct SymNode *node = 0;
              	 	  node = lookupSymbol( symbolTable, $1, 0, __FALSE );
			  if(node == 0)
			  {
				printf("<Error> found in Line %d: %s can not be found in the statement.\n", linenum, $1);
			  	is_error = 1;
			  }
			  else
			  {
              	$$->pType = node->type;
			  	$$->beginningOp = NONE_t;
			  	if(node->category != FUNCTION_t)
			  	{
					printf("<Error> found in Line %d: %s is not a function.\n", linenum, $1);
			  		is_error = 1;
			  	}

			  	struct expr_sem *exprPtr;
			  	struct PTypeList *paraPtr;
			  	int is_print = 0;
			  	paraPtr = node->attribute->formalParam->params;
			  	if(paraPtr != 0)
			  	{
					if($3 != 0)
					{
			  			for( exprPtr=$3, paraPtr = node->attribute->formalParam->params ; (exprPtr)!=0 && (paraPtr) != 0 ; exprPtr=(exprPtr->next), paraPtr = (paraPtr->next) )
			  			{
							if(exprPtr->pType->type != paraPtr->value->type)
							{
								if(exprPtr->pType->type != INTEGER_t || paraPtr->value->type != REAL_t)
								{
									printf("<Error> found in Line %d: the parameter of function mismatch: the type of parameter must be same.\n", linenum);
									is_print = 1;
									is_error = 1;
								}
								else if(exprPtr->varRef == 0);
								else if(exprPtr->pType->isArray == __TRUE)
								{
									if(paraPtr->value->isArray == __TRUE)
									{
										struct ArrayDimNode *one, *two;
										int i;
										for(one = exprPtr->pType->dim, i = exprPtr->varRef->dimNum; i != 0 && one->next != 0; i--, one = one->next);
										for(two = paraPtr->value->dim; (one)!=0 && (two)!=0; one = one->next, two = two->next)
										{
											if(one->size != two->size)
											{
												printf("<Error> found in Line %d: the parameter of function mismatch: the array size must be same.\n", linenum);
												is_print = 1;
												is_error = 1;
												break;
											}
											if(one->next == 0 ||  two->next == 0)
												break;
										}
										if((one->next != 0 || two->next != 0) && is_print == 0)
										{
											printf("<Error> found in Line %d: the parameter of function mismatch: the array dimension must be same.\n", linenum);
											is_print = 1;
											is_error = 1;
										}
									}
									else
									{
										if(exprPtr->varRef->dimNum != exprPtr->pType->dimNum)
										{
											printf("<Error> found in Line %d: the parameter of function mismatch: the parameter of function is not array.\n", linenum);
											is_print = 1;
											is_error = 1;
										}
									}
								}
								else if(paraPtr->value->isArray == __TRUE)
								{
									printf("<Error> found in Line %d: the parameter of function mismatch: the parameter of function is array.\n", linenum);
									is_print = 1;
									is_error = 1;
								}
							}
							else if(exprPtr->varRef == 0);
							else if(exprPtr->pType->isArray == __TRUE)
							{
								if(paraPtr->value->isArray == __TRUE)
								{
									struct ArrayDimNode *one, *two;
									int i;
									for(one = exprPtr->pType->dim, i = exprPtr->varRef->dimNum; i != 0 && one->next != 0; i--, one = one->next);
									for(two = paraPtr->value->dim; (one)!=0 && (two)!=0; one = one->next, two = two->next)
									{
										if(one->size != two->size)
										{
											printf("<Error> found in Line %d: the parameter of function mismatch: the size of array must be same.\n", linenum);
											is_print = 1;
											is_error = 1;
											break;
										}
										if(one->next == 0 ||  two->next == 0)
											break;
									}
									if((one->next != 0 || two->next != 0) && is_print == 0)
									{
										printf("<Error> found in Line %d: the parameter of function mismatch: th dimension of array must be same.\n", linenum);
										is_print = 1;
										is_error = 1;
									}
								}
								else
								{
									if(exprPtr->varRef->dimNum != exprPtr->pType->dimNum)
									{
                                        printf("<Error> found in Line %d: the parameter of function mismatch: the parameter of function is not array.\n", linenum);
									    is_print = 1;
									    is_error = 1;
								    }
                                }
							}
							else if(paraPtr->value->isArray == __TRUE)
							{
								printf("<Error> found in Line %d: the parameter of function mismatch: the parameter of function is array.\n", linenum);
								is_print = 1;
								is_error = 1;
							}
							if(is_print == 1)
								break;
			 	 			if(exprPtr->next == 0 || paraPtr->next == 0)
								break;
						}
			  			if(is_print == 0 && ((exprPtr->next)!=0 || (paraPtr->next)!=0))
			  			{
							printf("<Error> found in Line %d: the parameter of function mismatch: the number of parameter is not match.\n", linenum);
			 				is_error = 1;
			 			}
					}
			  	}
			  	else if($3 != 0)
			  	{
					printf("<Error> found in Line %d: the parameter of function mismatch: the number of parameter is not match.\n", linenum);
			  		is_error = 1;
			  	}
			  }
			  
			}
			| OP_SUB ID MK_LPAREN opt_boolean_expr_list MK_RPAREN
			{
			  //$$ = verifyFuncInvoke( $2, $4, symbolTable, scope );
			  $$ = (struct expr_sem *)malloc(sizeof(struct expr_sem));
			  $$->isDeref = __TRUE;
			  $$->varRef = (struct var_ref_sem*) malloc(sizeof(struct var_ref_sem));
			  $$->varRef->id = (char *) malloc(sizeof(char)*(strlen($2)+1));
			  strcpy($$->varRef->id, $2);
			  $$->varRef->dimNum = 0;
			  $$->varRef->dim = 0;
              		  $$->next = 0;

              		  struct SymNode *node = 0;
              		  node = lookupSymbol( symbolTable, $2, 0, __FALSE );
			  if(node == 0)
			  {
				printf("<Error> found in Line %d: %s can not be found in the statement.\n", linenum, $2);
			  	is_error = 1;
			  }
			  else
			  {
              		  	$$->pType = node->type;
			  	$$->beginningOp = SUB_t;
			  	if(node->category != FUNCTION_t)
			  	{
					printf("<Error> found in Line %d: %s is not a function.\n", linenum, $2);
			  		is_error = 1;
			  	}
			  	struct expr_sem *exprPtr;
			  	struct PTypeList *paraPtr;
			  	int is_print = 0;
			  	paraPtr = node->attribute->formalParam->params;
			  	if(paraPtr != 0)
			  	{
					if($4 != 0)
					{
			  			for( exprPtr=$4, paraPtr = node->attribute->formalParam->params ; (exprPtr)!=0 && (paraPtr) != 0 ; exprPtr=(exprPtr->next), paraPtr = (paraPtr->next) )
			  			{
							if(exprPtr->pType->type != paraPtr->value->type)
							{
								if(exprPtr->pType->type != INTEGER_t || paraPtr->value->type != REAL_t)
								{
									printf("<Error> found in Line %d: the parameter of function mismatch: the type of parameter must be same.\n", linenum);
									is_print = 1;
									is_error = 1;
								}
								else if(exprPtr->varRef == 0);
								else if(exprPtr->pType->isArray == __TRUE)
								{
									if(paraPtr->value->isArray == __TRUE)
									{
										struct ArrayDimNode *one, *two;
										int i;
										for(one = exprPtr->pType->dim, i = exprPtr->varRef->dimNum; i != 0 && one->next != 0; i--, one = one->next);
										for(two = paraPtr->value->dim; (one)!=0 && (two)!=0; one = one->next, two = two->next)
										{
											if(one->size != two->size)
											{
												printf("<Error> found in Line %d: the parameter of function mismatch: the size of array must be same.\n", linenum);
												is_print = 1;
												is_error = 1;
												break;
											}
											if(one->next == 0 ||  two->next == 0)
												break;
										}
										if((one->next != 0 || two->next != 0) && is_print == 0)
										{
											printf("<Error> found in Line %d: the parameter of function mismatch: the dimension of array must be same.\n", linenum);
											is_print = 1;
											is_error = 1;
										}
									}
									else
									{
										if(exprPtr->varRef->dimNum != exprPtr->pType->dimNum)
										{
											printf("<Error> found in Line %d: the parameter of function mismatch: the parameter of function is not array.\n", linenum);
											is_print = 1;
											is_error = 1;
										}
									}
								}
								else if(paraPtr->value->isArray == __TRUE)
								{
									printf("<Error> found in Line %d: the parameter of function mismatch: the parameter of function is array.\n", linenum);
									is_print = 1;
									is_error = 1;
								}
							}
							else if(exprPtr->varRef == 0);
							else if(exprPtr->pType->isArray == __TRUE)
							{
								if(paraPtr->value->isArray == __TRUE)
								{
									struct ArrayDimNode *one, *two;
									int i;
									for(one = exprPtr->pType->dim, i = exprPtr->varRef->dimNum; i != 0 && one->next != 0; i--, one = one->next);
									for(two = paraPtr->value->dim; (one)!=0 && (two)!=0; one = one->next, two = two->next)
									{
										if(one->size != two->size)
										{
											printf("<Error> found in Line %d: the parameter of function mismatch: the size of array must be same.\n", linenum);
											is_print = 1;
											is_error = 1;
											break;
										}
										if(one->next == 0 ||  two->next == 0)
											break;
									}
									if((one->next != 0 || two->next != 0) && is_print == 0)
									{
										printf("<Error> found in Line %d: the parameter of function mismatch: the dimension of array must be same.\n", linenum);
										is_print = 1;
										is_error = 1;
									}
								}
								else
								{
									printf("<Error> found in Line %d: the parameter of function mismatch: the parameter of function is not array.\n", linenum);
									is_print = 1;
									is_error = 1;
								}
							}
							else if(paraPtr->value->isArray == __TRUE)
							{
								printf("<Error> found in Line %d: the parameter of function mismatch: the parameter of function is array.\n", linenum);
								is_print = 1;
								is_error = 1;
							}
							if(is_print == 1)
								break;
			 	 			if(exprPtr->next == 0 || paraPtr->next == 0)
								break;
						}
			  			if(is_print == 0 && ((exprPtr->next)!=0 || (paraPtr->next)!=0))
			  			{
							printf("<Error> found in Line %d: the parameter of function mismatch: the number of parameter is not match.\n", linenum);
			 				is_error = 1;
			 			}
					}
			  	}
			  	else if($4 != 0)
			  	{
					printf("<Error> found in Line %d: the parameter of function mismatch: the number of parameter is not match.\n", linenum);
			  		is_error = 1;
			  	}
			  }
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
			}
			;

var_ref			: ID					/* final: ID[int][int][int]...... or ID */
			{
			  $$ = createExprSem($1);
              		  struct SymNode *node = 0;
              		  node = lookupSymbol( symbolTable, $1, scope, __FALSE );
			  if(node == 0)
			  {
                struct SymNode *forVar = 0;
                forVar = lookupLoopVar(symbolTable, $1);
                if(forVar == 0)
                {
				    printf("<Error> found in Line %d: %s can not be found in the statement.\n", linenum, $1);
                	is_error = 1;
				}
			  	else
                {
                    $$->pType = createPType(INTEGER_t);
                    $$->isFor = __TRUE;
                }
                			  }
		  	  else
              {
                $$->pType = node->type;
              }
			}
			| var_ref dim
			{
			  increaseDim( $1, $2 );			
			  $$ = $1;
			}
			;

dim			: MK_LB boolean_expr MK_RB
            		  {
			  	if($2->pType->type != INTEGER_t )		//the index of array must be integer
			  	{
					printf("<Error> found in Line %d: the index of the array must be integer type.\n", linenum, $2);
			  		is_error = 1;
			  	}
              			$$ = INTEGER_t;
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

