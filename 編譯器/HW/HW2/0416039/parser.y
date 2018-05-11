%{
#include <stdio.h>
#include <stdlib.h>

extern int linenum;             /* declared in lex.l */
extern FILE *yyin;              /* declared by lex */
extern char *yytext;            /* declared by lex */
extern char buf[256];           /* declared in lex.l */
%}

%token END ID KWBEGIN MOD 
%token ASSIGN LE NE BE AND OR NOT 
%token ARRAY TYPE DEF DO ELSE STRING
%token FALSE FOR IF OF PRINT READ 
%token THEN TO TRUE RETURN VAR WHILE 
%token OCT_INT INT FLOAT SCIENTIFIC
%left OR
%left AND
%left NOT
%left '<' LE '=' BE '>' NE
%left '+' '-'
%left '*' '/' MOD
%left '(' ')'

%%

program		: programname ';' programbody END ID
		;

programname	: identifier
		;

identifier	: ID
		;

programbody	: variable function compound
		;

nonEmptyfunction: ID '(' argument ')' return_type ';' compound END ID
		| nonEmptyfunction ID '(' argument ')' return_type ';' compound END ID
		;

function	: /*epilson*/
		| nonEmptyfunction
	    	;

return_type	: /*expilson*/
		| ':' assignType
		;

assignType	: TYPE
	   	| array_declare
		;

argument	: /*epilson*/
	 	| nonEmptyArgument
		;

nonEmptyArgument: id_list ':' assignType
		| twoArgument
		;

twoArgument	: id_list ':' assignType ';'
	    	| twoArgument id_list ':' assignType ';'
		;

id_list		: ID
	 	| nonId_list ID
	 	;

nonId_list	: ID ','
	   	| nonId_list ID ','
		;

variable	: /*expilson*/
	 	| VarOrConst
		;

VarOrConst	: VAR id_list ':' TYPE ';'
	  	| VAR id_list ':' array_declare ';'
	   	| VAR id_list ':' literalConst ';'
		| VarOrConst VAR id_list ':' assignType ';'
		| VarOrConst VAR id_list ':' literalConst ';'
		;

array_declare	: ARRAY intConst TO intConst OF assignType
	      	;

intConst		: INT
				| OCT_INT
				;

literalConst	: INT
	     	| OCT_INT
		| FLOAT
		| SCIENTIFIC
		| STRING
		| TRUE
		| FALSE
		;

compound	: KWBEGIN variable statement END 
	 	;

statement	: /*expilson*/
	 	| nonEmptyState	
	  	;

nonEmptyState	: nonEmptyState simple
		| nonEmptyState	conditional
		| nonEmptyState	whileLoop
		| nonEmptyState	forLoop
		| nonEmptyState	returnExpress
		| nonEmptyState invocation
		| nonEmptyState compound
		| simple			
		| conditional
		| whileLoop
		| forLoop
		| returnExpress
		| invocation
		| compound
	      	;

simple		: varRef ASSIGN expression ';'
		| PRINT varRef ';'	
		| PRINT expression ';'
		| READ varRef ';'
		;

varRef		: ID arrayList
		;

arrayList	: /*expilson*/
	  	| arrayList '[' expression ']'
	  	;

expression	: arithmetic
	   	| boolExpress
	   	;

arithmetic	: arithmetic '+' arithmetic
	   	| arithmetic '-' arithmetic
		| arithmetic '*' arithmetic
		| arithmetic '/' arithmetic
		| arithmetic MOD arithmetic
		| '(' arithmetic ')'
		| '-' arithmetic %prec '*'
		| expre_invocation
		| varRef
		| literalConst
	   	;

boolExpress	: expression AND expression
	    	| expression OR expression
		| expression NOT expression
		| arithmetic '<' arithmetic
		| arithmetic LE arithmetic
		| arithmetic '=' arithmetic
		| arithmetic BE arithmetic
		| arithmetic '>' arithmetic
		| arithmetic NE arithmetic
	    	;

conditional	: IF boolExpress THEN statement ELSE statement END IF
	    	| IF boolExpress THEN statement	END IF
	    	;

whileLoop	: WHILE boolExpress DO statement END DO
       		;

forLoop		: FOR ID ASSIGN INT TO INT DO statement	END DO
	 	;

returnExpress	: RETURN expression ';'
	      	;

expre_invocation: ID '(' expressList ')'
	   	;

invocation	: ID '(' expressList ')' ';'
	   	;

nonEmptyExpress	: expression
		| nonEmptyExpress ',' expression
		;

expressList	: /*explison*/
	    	| nonEmptyExpress
	    	;

%%

int yyerror( char *msg )
{
        fprintf( stderr, "\n|--------------------------------------------------------------------------\n" );
	fprintf( stderr, "| Error found in Line #%d: %s\n", linenum, buf );
	fprintf( stderr, "|\n" );
	fprintf( stderr, "| Unmatched token: %s\n", yytext );
        fprintf( stderr, "|--------------------------------------------------------------------------\n" );
        exit(-1);
}

int  main( int argc, char **argv )
{
	if( argc != 2 ) {
		fprintf(  stdout,  "Usage:  ./parser  [filename]\n"  );
		exit(0);
	}

	FILE *fp = fopen( argv[1], "r" );
	
	if( fp == NULL )  {
		fprintf( stdout, "Open  file  error\n" );
		exit(-1);
	}
	
	yyin = fp;
	yyparse();

	fprintf( stdout, "\n" );
	fprintf( stdout, "|--------------------------------|\n" );
	fprintf( stdout, "|  There is no syntactic error!  |\n" );
	fprintf( stdout, "|--------------------------------|\n" );
	exit(0);
}
