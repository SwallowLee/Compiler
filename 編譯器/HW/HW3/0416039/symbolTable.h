#include <stdio.h>
#include <iostream>
#include <stdlib.h>
#include <vector>
#include <string>

extern char *yytext;
extern int linenum;
extern int Opt_D;

using namespace std;
	
struct const_value{
	int integer;
	double float_num;
	char str[100];
};

struct items{
	char name[33], kind[50], type[50], attribute[100];
};

struct symbolTable{
	int level;
	vector<struct items> item;
};

const_value* intToConstValue(int i){
	const_value* a = (const_value*) malloc(sizeof(const_value));
	a->integer = i;
	a->str[0] = '\0';
	a->float_num = 0;
	return a;
}

const_value* strToConstValue(char* i){
	const_value* a = (const_value*) malloc(sizeof(const_value));
	strcpy(a->str, i);
	a->integer = 0;
	a->float_num = 0;
	return a;
}

const_value* subIntToConstValue(const_value* i){
	i->integer = i->integer*-1;
	i->str[0] = '\0';
	i->float_num = 0;
	return i;
}

const_value* floatToConstValue(double i, int j){

	const_value* a = (const_value*) malloc(sizeof(const_value));
	if(j == 0)
	{
		a->float_num = i;
	}
	else
	{
		a->float_num = i*-1;
	}
	a->str[0] = '\0';
	a->integer = 0;
	return a;
}

string giveConstAttri(const_value* i){
	string a;
	if(i->str[0]!='\0')
	{
		string b=i->str;
		a = b;
	}
	else if(i->integer != 0)
	{
		a = to_string(i->integer);
	}
	else if(i->float_num != 0)
	{
		a = to_string(i->float_num);
	}
	else 
	{
		a = to_string(0);
	}

	return a;
}

int getArrayValue(const_value* i, const_value* j){
	int a;
	a = j->integer - i->integer + 1;
	return a;
}

void symbolPrint(symbolTable a){
	if(Opt_D == 1)
	{
		for(int i = 0; i < 110; i++)
		{
			printf("=");
		}
		printf("\n");
		printf("%-33s%-11s%-11s%-17s%-11s\n","Name","Kind","Level","Type","Attribute");
		for(int i = 0; i < 110; i++)
		{
			printf("-");
		}
		printf("\n");
		for(int i = 0; i < a.item.size(); i++)
		{
			if(strcmp(a.item[i].type, "for") == 0) continue;
			printf("%-33s%-11s%d", a.item[i].name, a.item[i].kind, a.level);
			if(a.level == 0)
				printf("%-10s","(global)");
			else
				printf("%-10s","(local)");
			printf("%-17s", a.item[i].type);
			if(strcmp(a.item[i].attribute, "NULL") != 0)
				printf("%-11s\n", a.item[i].attribute);
			else
				printf("\n");
		}
		for(int i = 0; i < 110; i++)
		{
			printf("-");
		}
		printf("\n");
	}
}

bool itemRedeclaration(int level, char* temp, vector<symbolTable> table){
	/*for(int j = 0; j <= level; j++)
		for(int i = 0; i < table[j].item.size(); i++)
		{
			if(strcmp(table[j].item[i].name, temp) == 0)
				return true;
		}*/
	/*for(int i = 0; i < table[0].item.size(); i++)
	{
		if(strcmp(table[0].item[i].name, temp) == 0)
			return true;
	}*/
	for(int i = 0; i < table[level].item.size(); i++)
	{
		if(strcmp(table[level].item[i].name, temp) == 0)
			return true;
	}
	return false;
}

bool checkForForLoop(vector<char*> forLoop, char* temp){
	for(int i = 0; i < forLoop.size(); i++)
	{
		if(strcmp(forLoop[i], temp) == 0)
			return true;
	}
	return false;
}

/*symbolTable* buildTable(){
	
}

bool pushSubTable(){

}

bool pushItem(){

}

bool popSubTable(){

}
*/

