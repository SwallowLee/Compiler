/**
 * Introduction to Compiler Design by Prof. Yi Ping You
 * Project 2 Lex Sample
 */

%{

#include <string.h>
#include "y.tab.h"

extern "C" int yylex();

#define LIST strcat( buf, yytext )
#define token(t) { LIST; if (Opt_T) printf("<%s>\n", #t );}
#define tokenChar(t) { LIST; if (Opt_T) printf("<%c>\n", t );}
#define tokenInteger(t, i) { LIST; if (Opt_T) printf("<%s: %d>\n", t, i); }
#define tokenOctInteger(t, i) { LIST; if (Opt_T) printf("<%s: %s>\n", t, i); }
#define tokenFloat(t, i) { LIST; if (Opt_T) printf("<%s: %s>\n", t, i ); }
#define tokenScientific(t, s) { LIST; if ( Opt_T ) printf("<%s: %s>\n", t, s); }
#define tokenString(t, s) { LIST; if (Opt_T) printf("<%s: %s>\n", t, s); }

#define  MAX_LINE_LENG  256

int Opt_S = 1;				/* list source code option */
int Opt_T = 1;				/* list token option */
int linenum = 1;
int oct_num;			/* line number */
char buf[MAX_LINE_LENG];		/* source code line buffer */
char strContent[MAX_LINE_LENG];		/* string buffer */
char str_32[33];

void setPseudoComment( const char * );	/* pseudo comment option switch */
%}

whitespace [ \t]+
letter [A-Za-z]
digit [0-9]
integer 0|[1-9][0-9]*
octal 0[0-7]+
fraction 0|[0-9]*[1-9]
float {integer}"."{fraction}
scientific ({integer}|{float}|{octal})[Ee][+-]?({integer}|{octal})
identifier ({letter})({letter}|{digit})*

 /* exclusive start conditions */
%x COMMENT
%x COMMENT_CPP

%%

","				{ tokenChar(',');yylval.str=strdup(yytext); return MK_COMMA; }
";"				{ tokenChar(';');yylval.str=strdup(yytext); return MK_SEMICOLON; }
":"				{ tokenChar(':');yylval.str=strdup(yytext); return MK_COLON; }
")"				{ tokenChar(')');yylval.str=strdup(yytext); return MK_RPAREN; }
"("				{ tokenChar('(');yylval.str=strdup(yytext); return MK_LPAREN; }
"["				{ tokenChar('[');yylval.str=strdup(yytext); return MK_LB;}
"]"				{ tokenChar(']');yylval.str=strdup(yytext); return MK_RB; }

"+"				{ tokenChar('+');yylval.str=strdup(yytext); return OP_ADD; }
"-"				{ tokenChar('-');yylval.str=strdup(yytext); return OP_SUB; }
"*"				{ tokenChar('*');yylval.str=strdup(yytext); return OP_MUL; }
"/"				{ tokenChar('/');yylval.str=strdup(yytext); return OP_DIV; }
"mod"				{ token(mod);yylval.str=strdup(yytext); return OP_MOD; }
":="				{ token(:=);yylval.str=strdup(yytext); return OP_ASSIGN; }
"<"				{ token(<);yylval.str=strdup(yytext); return OP_LT; }
"<="				{ token(<=);yylval.str=strdup(yytext); return OP_LE; }
"<>"				{ token(<>);yylval.str=strdup(yytext); return OP_NE; }
">="				{ token(>=);yylval.str=strdup(yytext); return OP_GE; }
">"				{ token(>);yylval.str=strdup(yytext); return OP_GT; }
"="				{ token(=);yylval.str=strdup(yytext); return OP_EQ; }
"and"				{ token(and);yylval.str=strdup(yytext); return OP_AND; }
"or"				{ token(or);yylval.str=strdup(yytext); return OP_OR; }
"not"				{ token(not);yylval.str=strdup(yytext); return OP_NOT; }

"array"				{ token(KWarray);yylval.str=strdup(yytext); return ARRAY; }
"begin"				{ token(KWbegin);yylval.str=strdup(yytext);  return BEG; }
"boolean"			{ token(KWboolean);yylval.str=strdup(yytext);  return BOOLEAN; }
"def"				{ token(KWdef);yylval.str=strdup(yytext);  return DEF; }
"do"				{ token(KWdo);yylval.str=strdup(yytext);  return DO; }
"else"				{ token(KWelse);yylval.str=strdup(yytext);  return ELSE; }
"end"				{ token(KWend);yylval.str=strdup(yytext);  return END; }
"false"				{ token(KWfalse); yylval.str=strdup(yytext); return FALSE; }
"for"				{ token(KWfor);yylval.str=strdup(yytext);  return FOR; }
"integer"			{ token(KWinteger);yylval.str=strdup(yytext);  return INTEGER; }
"if"				{ token(KWif);yylval.str=strdup(yytext);  return IF; }
"of"				{ token(KWof);yylval.str=strdup(yytext);  return OF; }
"print"				{ token(KWprint);yylval.str=strdup(yytext);  return PRINT; }
"read"				{ token(KWread);yylval.str=strdup(yytext);  return READ; }
"real"				{ token(KWreal);yylval.str=strdup(yytext);  return REAL; }
"return"			{ token(KWreturn);yylval.str=strdup(yytext);  return RETURN; }
"string"			{ token(KWstring);yylval.str=strdup(yytext);  return STRING; }
"then"				{ token(KWthen);yylval.str=strdup(yytext);  return THEN; }
"to"				{ token(KWto);yylval.str=strdup(yytext);  return TO; }
"true"				{ token(KWtrue);yylval.str=strdup(yytext);  return TRUE; }
"var"				{ token(KWvar);yylval.str=strdup(yytext);  return VAR; }
"while"				{ token(KWwhile);yylval.str=strdup(yytext);  return WHILE; }

{octal}				{ tokenOctInteger("oct_integer",yytext);sscanf(yytext, "%o", &oct_num); yylval.val = oct_num;return OCTAL_CONST;}
{identifier}			{ tokenString("id",yytext); strncpy(str_32, yytext, 33); yylval.str=strdup(str_32); return ID; }
{integer}			{ tokenInteger("integer",atoi(yytext)); yylval.num=atoi(yytext); return INT_CONST; }
{float}				{ tokenFloat("float",yytext);yylval.dnum=atof(yytext);  return FLOAT_CONST; }
{scientific}			{ tokenScientific("scientific", yytext);yylval.str=strdup(yytext); return SCIENTIFIC; }

\"((\"\")|[^\"\n])*\"	{
				LIST;
				if (Opt_T){
					size_t wrt_idx = 0;
					size_t rd_idx = 1;
					int quote = 0;
					while( yytext[rd_idx] ){
						if( yytext[rd_idx] == '\"' ){
							if( quote )
								strContent[wrt_idx++] = '\"';
							quote = 1 - quote;
						}
						else
							strContent[wrt_idx++] = yytext[rd_idx];
						rd_idx++;
					}
					strContent[wrt_idx] = '\0';
					printf("<%s: %s>\n", "string", strContent);
				}
				yylval.str=strdup(yytext);
				return STR_CONST;
			}

"//&"[A-Z][+-][^\n]*		{ /* pseudo comment */
				  LIST;
				  setPseudoComment( yytext );
				}
"//"				{ /* C++ stype comment */
				  LIST;
				  BEGIN COMMENT_CPP;
				}

<COMMENT_CPP>[^\n]+		{
				  LIST;
				}

<COMMENT_CPP>"\n"		{
				  LIST;
				  if( Opt_S )
				  	printf("%d: %s",  linenum,  buf);
				  linenum++;
				  buf[0] = '\0';
				  BEGIN INITIAL;
				}

"/*"				{ /* C-style comment */
				  LIST;
				  BEGIN COMMENT;
				}
<COMMENT>"*/"			{
				  LIST;
				  BEGIN INITIAL;
				}
<COMMENT>"\n"			{
				  LIST;
				  if  (Opt_S)
				  	printf("%d: %s",  linenum,  buf);
				  linenum++;
				  buf[0] = '\0';
				}
<COMMENT>.			{
				  LIST;
				}

{whitespace}			{ 
				  LIST; 
				}

\n 				{
				  LIST;
				  if  (Opt_S)
				  	printf("%d: %s",  linenum,  buf);
				  linenum++;
				  buf[0] = '\0';
		   		}

.				{
				  /* error */
				  printf("error at line %d: bad character \"%s\"\n", linenum, yytext );
				  exit(-1);
				}

%%

void setPseudoComment( const char *text )
{
	/* format : //&[A-Z][+-] */
	switch( text[3] ) {
	 case 'S':			/* Source code */
		if( text[4] == '+' )
			Opt_S = 1;
		else if( text[4] == '-' )
			Opt_S = 0;
		break;
	 case 'T':			/* Tokens */
		if( text[4] == '+' )
			Opt_T = 1;
		else if( text[4] == '-' )
			Opt_T = 0;
	 	break;
	 default:
	 	break;
	}

}

