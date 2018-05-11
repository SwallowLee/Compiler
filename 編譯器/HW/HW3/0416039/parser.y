%{
/**
 * Introduction to Compiler Design by Prof. Yi Ping You
 * Project 2 YACC sample
 */
#include <stdio.h>
#include <stdlib.h>
#include <vector>
#include <string.h>
#include "symbolTable.h"

extern int linenum;		/* declared in lex.l */
extern "C" FILE *yyin;		/* declared by lex */
extern char *yytext;		/* declared by lex */
extern char buf[256];		/* declared in lex.l */
extern "C" int yylex(void);
int yyerror(char* );

std::vector<symbolTable> table;
std::vector<int> array_num;
std::vector<char*> func, forLoop;
int cur_level = 0, id_num = 0, table_num = 0, cur_num, fun_num = 0;
char cur_type[100], array[100], func_type[100];
bool in_array = false;
string attri;
%}
/*types*/
%union {
	int num;
	double dnum;
	char *str;
 	struct const_value* Const_value;		
}

/* tokens terminal */
%token <str> ARRAY
%token <str> BEG
%token <str> BOOLEAN
%token <str> DEF
%token <str> DO
%token <str> ELSE
%token <str> END
%token <str> FALSE
%token <str> FOR
%token <str> INTEGER
%token <str> IF
%token <str> OF
%token <str> PRINT
%token <str> READ
%token <str> REAL
%token <str> RETURN
%token <str> STRING
%token <str> THEN
%token <str> TO
%token <str> TRUE
%token <str> VAR
%token <str> WHILE

%token <str> ID
%token <num> OCTAL_CONST
%token <num> INT_CONST
%token <dnum> FLOAT_CONST
%token <dnum> SCIENTIFIC
%token <str> STR_CONST

%token <str> OP_ADD
%token <str> OP_SUB
%token <str> OP_MUL
%token <str> OP_DIV
%token <str> OP_MOD
%token <str> OP_ASSIGN
%token <str> OP_EQ
%token <str> OP_NE
%token <str> OP_GT
%token <str> OP_LT
%token <str> OP_GE
%token <str> OP_LE
%token <str> OP_AND
%token <str> OP_OR
%token <str> OP_NOT

%token <str> MK_COMMA
%token <str> MK_COLON
%token <srt> MK_SEMICOLON
%token <str> MK_LPAREN
%token <str> MK_RPAREN
%token <str> MK_LB
%token <str> MK_RB

/*nonterminal*/
%type <str> scalar_type array_type decl type opt_type;
%type <Const_value> literal_const int_const

/* start symbol */
%start program
%%

program			: ID 
	  		 {
	  			symbolTable temp;
				temp.level = cur_level;
				items temp1;
				char * tmp = $1;
				strcpy(temp1.name, tmp);
				strcpy(temp1.kind, "program");
				strcpy(temp1.type, "void");
				strcpy(temp1.attribute, "NULL");
				temp.item.push_back(temp1);
				table.push_back(temp);
				table_num++;
	 		 } 
			  MK_SEMICOLON
			  program_body
			  END ID
			 {	
				symbolPrint(table[0]);
				table.pop_back();
				table_num--;
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
				for(int i = cur_num, j = 0; j < id_num; i++, j++)
				{
					strcpy(table[table_num-1].item[i].kind, "variable");
					strcpy(table[table_num-1].item[i].type, $4);
					strcpy(table[table_num-1].item[i].attribute, "NULL");
				}
				id_num = 0;
			}       
			| VAR id_list MK_COLON array_type MK_SEMICOLON        /* array type declaration */
			{
				for(int i = cur_num, j = 0; j < id_num; i++, j++)
				{
					strcpy(table[table_num-1].item[i].kind, "variable");
					strcpy(table[table_num-1].item[i].type, array);
					strcpy(table[table_num-1].item[i].attribute, "NULL");
				}
				id_num = 0;
			}       
			| VAR id_list MK_COLON literal_const MK_SEMICOLON     /* const declaration */
			{
				for(int i = cur_num, j = 0; j < id_num; i++, j++)
				{
					strcpy(table[table_num-1].item[i].kind, "constant");
					strcpy(table[table_num-1].item[i].type, cur_type);
					strcpy(table[table_num-1].item[i].attribute, attri.c_str());
				}
				id_num = 0;
			}       
			;
int_const	:	INT_CONST
	  		{
				$$ = intToConstValue($1);
			}
			|	OCTAL_CONST
			{
				$$ = intToConstValue($1);
			}
			;

literal_const		: int_const
	       		{
				strcpy(cur_type, "integer");
				$$ = $1;	
				attri = giveConstAttri($$);
			}
			| OP_SUB int_const
			{ 
				strcpy(cur_type, "integer");
				$$ = subIntToConstValue($2);
	 			attri = giveConstAttri($$);
			}
			| FLOAT_CONST
			{
				strcpy(cur_type, "real");
				$$ = floatToConstValue($1, 0);
				attri = giveConstAttri($$);
			}
			| OP_SUB FLOAT_CONST
			{
				strcpy(cur_type, "real");
				$$ = floatToConstValue($2, 1);
				attri = giveConstAttri($$);
			}
			| SCIENTIFIC
			{
				strcpy(cur_type, "real");
				$$ = floatToConstValue($1, 0);
				attri = giveConstAttri($$);
			}
			| OP_SUB SCIENTIFIC
			{
				strcpy(cur_type, "real");
				$$ = floatToConstValue($2, 1);
				attri = giveConstAttri($$);
			}
			| STR_CONST
			{
				/*here has some error ""->" */
				strcpy(cur_type, "string");
				$$ = strToConstValue($1);
				attri = giveConstAttri($$);
			}
			| TRUE
			{
				strcpy(cur_type, "boolean");
				$$ = strToConstValue($1);
				attri = giveConstAttri($$);
			}
			| FALSE
			{
				strcpy(cur_type, "boolean");
				$$ = strToConstValue($1);
				attri = giveConstAttri($$);
			}
			;

opt_func_decl_list	: func_decl_list
			| /* epsilon */
			;

func_decl_list		: func_decl_list func_decl
			| func_decl
			;

func_decl		: ID {
	   			cur_level++;
				symbolTable temp;
				temp.level = cur_level;
				table.push_back(temp);
				table_num++;
				/*printf("!!!!HERE IS A TABLE %d\n", cur_level);
				for(int i = 0; i < table[cur_level].item.size(); i++)
					printf("%s  ", table[cur_level].item[i].name);
				printf("\n");*/
	   			fun_num++;
				char *tmp = $1;
				char t[33];
				int i;
				for(i = 0; i < 32; i++)
					t[i] = tmp[i]; 
				t[i] = '\0';
				bool redeclare;
			 	redeclare = itemRedeclaration(cur_level-1, t, table);
				if(redeclare == true)
				{
					printf("<Error> found in Line %d: \"symbol '%s' is redeclared\"\n", linenum, $1);
				}
	   		  }MK_LPAREN opt_param_list MK_RPAREN opt_type MK_SEMICOLON
			  compound_stmt
			  END
			 {	
				items temp1;
				char *tmp = $1;
				char t[33];
				int i;
				for(i = 0; i < 32; i++)
					t[i] = tmp[i]; 
				t[i] = '\0';
				bool redeclare;
			 	redeclare = itemRedeclaration(cur_level, t, table);
				if(redeclare == true)
				{
					//do nothing
				}
				else
				{	
					strcpy(temp1.name, t);
					strcpy(temp1.kind, "function");
					strcpy(temp1.type, $6);
					if(func.size() == 0)
					{
						strcpy(temp1.attribute, "NULL");
					}
					else
					{
						int i;
						char fun_attr[100];
						strcpy(fun_attr, func[0]);
						for(i = 1; i < func.size(); i++)
						{
							//printf("~~~~~~%s\n", func[i]);
							strcat(fun_attr, ", ");
							//printf("@@@@@@@%s\n", func[i]);
							strcat(fun_attr, func[i]);
						}
						strcat(fun_attr, "\0");
						strcpy(temp1.attribute, fun_attr);
						func.clear();
					}
					table[table.size()-1].item.push_back(temp1);
				}
				/*symbolPrint(table[table.size()-1]);
				table.pop_back();
				table_num--;
				cur_level--;*/
			 }
			  ID
			;

opt_param_list		: param_list
			| /* epsilon */
			;

param_list		: param_list MK_SEMICOLON param
			| param
			;

param			: id_list MK_COLON type{
				if(in_array == true)
				{
					int i;
					char *temp = (char *)malloc(100);
					strcpy(temp, array);
					for(int i = cur_num, j = 0; j < id_num; i++, j++)
					{
						strcpy(table[table_num-1].item[i].kind, "parameter");
						strcpy(table[table_num-1].item[i].type, array);
		 				strcpy(table[table_num-1].item[i].attribute, "NULL");
						func.push_back(temp);
						//printf("!!!!!!!%s %s\n", temp, func[1]);
					}
					id_num = 0;
					in_array = false;
				}
				else
				{
					for(int i = cur_num, j = 0; j < id_num; i++, j++)
					{
						strcpy(table[table_num-1].item[i].kind, "parameter");
						strcpy(table[table_num-1].item[i].type, cur_type);
						strcpy(table[table_num-1].item[i].attribute, "NULL");
						func.push_back($3);
					}
					id_num = 0;
				}	
			}
			;

id_list			: id_list MK_COMMA ID{
	  			//printf("!!!!I AM PARAMETER%d\n", cur_level);
	  			if(id_num == 0)
					cur_num = table[table_num-1].item.size();
				char *tmp = $3;
				char t[33];
				int i;
				for(i = 0; i < 32; i++)
					t[i] = tmp[i]; 
				t[i] = '\0';
				bool redeclare;
			 	redeclare = itemRedeclaration(cur_level, t, table);
				if(redeclare == true)
				{
					printf("<Error> found in Line %d: \"symbol '%s' is redeclared\"\n", linenum, $3);
				}
				else
				{	
					bool exist;
			 		exist = checkForForLoop(forLoop, $3);
					if(exist == true)
					{
						printf("<Error> found in Line %d: \"symbol '%s' is redeclared\"\n", linenum, $3);
					}
					else
					{	
						items temp;
						strcpy(temp.name, t);
						table[table_num-1].item.push_back(temp);
	  					id_num++;
					}
				}
			}
			| ID{
	  			//printf("!!!!I AM PARAMETER %d\n", cur_level);
	  			if(id_num == 0)
					cur_num = table[table_num-1].item.size();
				char *tmp = $1;
				char t[33];
				int i;
				for(i = 0; i < 32; i++)
					t[i] = tmp[i]; 
				t[i] = '\0';
	 			//printf("!!!!!!!!%s\n", t);
				bool redeclare;
			 	redeclare = itemRedeclaration(cur_level, t, table);
				if(redeclare == true)
				{
					printf("<Error> found in Line %d: \"symbol '%s' is redeclared\"\n", linenum, $1);
				}
				else
				{
					bool exist;
			 		exist = checkForForLoop(forLoop, tmp);
					if(exist == true)
					{
						printf("<Error> found in Line %d: \"symbol '%s' is redeclared\"\n", linenum, $1);
					}
					else
					{	
						items temp;
						strcpy(temp.name, t);
						table[table_num-1].item.push_back(temp);
	  					id_num++;
					}
				}
			}
			;

opt_type		: MK_COLON type
	  		{
				if(in_array == true)
				{
					strcpy($$, array);
					in_array = false;
					
				}
				else
				{
					strcpy($$, $2);	
				}
			}
			| /* epsilon */{
				char temp[5];
				strcpy(temp, "void");
				$$ = temp;
			}
			;

type			: scalar_type{
       				strcpy(cur_type, $1);
				strcpy($$, $1);
				if(array_num.size()!=0)
				{
					strcpy(array, $1);
					strcat(array, " ");
					for(int i = 0; i < array_num.size(); i++)
					{
						strcat(array, "[");
						string temp = to_string(array_num[i]);
						strcat(array, temp.c_str());
						strcat(array, "]");
					}					
					array_num.clear();
					in_array = true;
				}
				else
					in_array = false;
			}
			| array_type
			;

scalar_type		: INTEGER{$$ = $1;}
			| REAL{$$ = $1;}
			| BOOLEAN{$$ = $1;}
			| STRING{$$ = $1;}
			;

array_type		: ARRAY int_const TO int_const
	    		{
				int temp = getArrayValue($2, $4);
				array_num.push_back(temp);	
			}
			  OF type
			;

stmt			: compound_stmt
			| simple_stmt
			| cond_stmt
			| while_stmt
			| for_stmt
			| return_stmt
			| proc_call_stmt
			;

compound_stmt		: BEG
	       		{
				if(fun_num > 0)	//already have table
				{
					fun_num--;
				}
				else
				{	
	   				cur_level++;
					symbolTable temp;
					temp.level = cur_level;
					table.push_back(temp);
					table_num++;
	   				//end_num++;
				}
			}
			  opt_decl_list
			  opt_stmt_list
			  END{
				/*if(end_num > 0)	//need to print
				{*/
					symbolPrint(table[table.size()-1]);
					table.pop_back();
					table_num--;
					cur_level--;
					//end_num--;
				//}
			}
			;

opt_stmt_list		: stmt_list
			| /* epsilon */
			;

stmt_list		: stmt_list stmt
			| stmt
			;

simple_stmt		: var_ref OP_ASSIGN boolean_expr MK_SEMICOLON
			| PRINT boolean_expr MK_SEMICOLON
			| READ boolean_expr MK_SEMICOLON
			;

proc_call_stmt		: ID MK_LPAREN opt_boolean_expr_list MK_RPAREN MK_SEMICOLON
			;

cond_stmt		: IF boolean_expr THEN
			  opt_stmt_list
			  ELSE
			  opt_stmt_list
			  END IF
			| IF boolean_expr THEN opt_stmt_list END IF
			;

while_stmt		: WHILE boolean_expr DO
			  opt_stmt_list
			  END DO
			;

for_stmt		: FOR ID {	
				bool redeclare;
				char *tmp = $1;
				char t[33];
				int i;
				for(i = 0; i < 32; i++)
					t[i] = tmp[i]; 
				t[i] = '\0';
			 	redeclare = checkForForLoop(forLoop, t);
				if(redeclare == true)
				{
					printf("<Error> found in Line %d: \"symbol '%s' is redeclared\"\n", linenum, $2);
				}
				else
				{	
	  				forLoop.push_back($2);
				}
	  			
	  		  }OP_ASSIGN int_const TO int_const DO
			  opt_stmt_list
			  END DO{
				forLoop.pop_back();
			}
			;

return_stmt		: RETURN boolean_expr MK_SEMICOLON
			;

opt_boolean_expr_list	: boolean_expr_list
			| /* epsilon */
			;

boolean_expr_list	: boolean_expr_list MK_COMMA boolean_expr
			| boolean_expr
			;

boolean_expr		: boolean_expr OP_OR boolean_term
			| boolean_term
			;

boolean_term		: boolean_term OP_AND boolean_factor
			| boolean_factor
			;

boolean_factor		: OP_NOT boolean_factor 
			| relop_expr
			;

relop_expr		: expr rel_op expr
			| expr
			;

rel_op			: OP_LT
			| OP_LE
			| OP_EQ
			| OP_GE
			| OP_GT
			| OP_NE
			;

expr			: expr add_op term
			| term
			;

add_op			: OP_ADD
			| OP_SUB
			;

term			: term mul_op factor
			| factor
			;

mul_op			: OP_MUL
			| OP_DIV
			| OP_MOD
			;

factor			: var_ref
			| OP_SUB var_ref
			| MK_LPAREN boolean_expr MK_RPAREN
			| OP_SUB MK_LPAREN boolean_expr MK_RPAREN
			| ID MK_LPAREN opt_boolean_expr_list MK_RPAREN
			| OP_SUB ID MK_LPAREN opt_boolean_expr_list MK_RPAREN
			| literal_const
			;

var_ref			: ID
			| var_ref dim
			;

dim			: MK_LB boolean_expr MK_RB
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

