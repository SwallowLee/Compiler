%{
#define LIST               strcat(buf, yytext)
#define token(t)           {LIST; if (Opt_T) printf("<%s>\n", #t);}
#define tokenChar(t)       {LIST; if (Opt_T) printf("<%c>\n", (t));}
#define tokenInteger(t, i) {LIST; if (Opt_T) printf("<%s: %d>\n", #t, (i));}
#define tokenString(t, s)  {LIST; if (Opt_T) printf("<%s: %s>\n", #t, (s));}
#define MAX_LINE_LENG      256

int Opt_S = 1;
int Opt_T = 1;
int linenum = 1;
char buf[MAX_LINE_LENG];
%}
%Start COMMENT
%%
\n	{
	  if (Opt_S)
            printf("%d: %s\n", linenum, buf);
          linenum++;
          buf[0] = '\0';
	}

	/*string constants*/
<INITIAL>\"([^\"^\n]|\"{2})*\"	{
	int i, j;
	char ans[yyleng];
	for(i = 1, j = 0; i < yyleng-1; i++)
	{
		if(yytext[i] == '\"' && yytext[i+1] == '\"')
			i++;
		ans[j] = yytext[i];
		j++;
	}
	ans[j] = '\0';
	tokenString(string, ans);
}

	/*white space*/
<INITIAL>" "	{LIST;}
<INITIAL>"	"	{LIST;}

	/*pseudocomment*/
<INITIAL>"//&S+".*	{Opt_S = 1; LIST;}
<INITIAL>"//S-".*	{Opt_S = 0; LIST;}
<INITIAL>"//T+".*	{Opt_T = 1; LIST;}
<INITIAL>"//T-".*	{Opt_T = 0; LIST;}	
<INITIAL>"//".*		{LIST;}

	/*comment*/
<INITIAL>"/*"	{LIST; BEGIN COMMENT;}
<COMMENT>.	{LIST;}
<COMMENT>"*/"	{LIST; BEGIN INITIAL;}

	/*keyword*/
<INITIAL>var     { token(KWvar)}
<INITIAL>array	{ token(KWarray);}
<INITIAL>begin	{ token(KWbegin);}
<INITIAL>boolean	{ token(KWboolean);}
<INITIAL>def	{ token(KWdef);}
<INITIAL>do	{ token(KWdo);}
<INITIAL>else	{ token(KWelse);}
<INITIAL>false	{ token(KWfalse);}
<INITIAL>for	{ token(KWfor);}
<INITIAL>integer	{ token(KWinteger);}
<INITIAL>end	{ token(KWend);}
<INITIAL>if	{ token(KWif);}
<INITIAL>of	{ token(KWof);}
<INITIAL>print	{ token(KWprint);}
<INITIAL>read	{ token(KWread);}
<INITIAL>real	{ token(KWreal);}
<INITIAL>string	{ token(KWstring);}
<INITIAL>then	{ token(KWthen);}
<INITIAL>to	{ token(KWto);}
<INITIAL>true	{ token(KWtrue);}
<INITIAL>return	{ token(KWreturn);}
<INITIAL>while	{ token(KWwhile);}

	/*delimiter*/
<INITIAL>","	{ tokenChar(',');}
<INITIAL>";"	{ tokenChar(';');}
<INITIAL>":"	{ tokenChar(':');}
<INITIAL>"("    { tokenChar('(');}
<INITIAL>")"	{ tokenChar(')');}
<INITIAL>"["	{ tokenChar('[');}
<INITIAL>"]"	{ tokenChar(']');}

	/*arithemic ... operator*/
<INITIAL>"+"	{ token(+);}
<INITIAL>"-"	{ token(-);}
<INITIAL>"*"	{ token(*);}
<INITIAL>"/"	{ token(/);}
<INITIAL>"mod"	{ token(mod);}
<INITIAL>":="	{ token(:=);}
<INITIAL>"<"	{ token(<);}
<INITIAL>"<="	{ token(<=);}
<INITIAL>"<>"	{ token(<>);}
<INITIAL>">"	{ token(>);}
<INITIAL>">="	{ token(>=);}
<INITIAL>"="	{ token(=);}
<INITIAL>"and"	{ token(and);}
<INITIAL>"or"	{ token(or);}
<INITIAL>"not"	{ token(not);}

	/*identifiers*/
<INITIAL>[a-zA-Z]+[0-9a-zA-Z]*	{ tokenString(id, yytext);}

	/*scientific notations*/
<INITIAL>([0-9]+|([0-9]+.[0-9]+))E[+-]?[0-9]+	{ tokenString(scientific, yytext);}
<INITIAL>([0-9]+|([0-9]+.[0-9]+))e[+-]?[0-9]+	{ tokenString(scientific, yytext);}

	/*floating-point constants*/
<INITIAL>[0-9]+\.[0-9]+	{ tokenString(float, yytext);}

	/*integer constants*/
<INITIAL>0[0-7]+	{ tokenString(oct_integer, yytext);}
<INITIAL>(([1-9][0-9]+)|[0-9])	{ tokenInteger(integer, atoi(yytext));}

	/*Error*/	
<INITIAL>.	{
	printf("error at line %d: bad character \"%s\"\n", linenum, yytext);
	return 0;}

%%
int main( int argc, char **argv )
{
  if( argc != 2 ) {
    fprintf( stderr, "Usage: ./scanner [filename]\n" );
    exit(0);
  }
	
  FILE *fp = fopen( argv[1], "r" );
  if( fp == NULL ) {
    fprintf( stderr, "Open file error\n" );
    exit(-1);
  }
	
  yyin = fp;

  yylex();

  exit(0);
}
