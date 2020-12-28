%option noyywrap


%x MULTIPLE_LINE_COMMENT_STATE

%{
#include<stdio.h>
#include<stdlib.h>
#include<string>
#include "1505021_SymbolTable.h"
#include "y.tab.h"

int line_count=1;
int err_count=0;

//SymbolTable symTab(10);

//FILE *logout;
//FILE *tokenout;

%}

WHITESPACE [ \t\f\r\v]+
LETTER [a-zA-Z]
DIGIT [0-9]
NEWLINE \n
FLOAT_1 -?{DIGIT}*\.{DIGIT}+([eE][+-]?{DIGIT}+)?
FLOAT_2 -?{DIGIT}+(\.{DIGIT}+)?([eE][+-]?{DIGIT}+)

TOO_MANY_DEC -?{DIGIT}*\.{DIGIT}*(\.{DIGIT}*)+([eE][+-]?{DIGIT}+)?
ILL_FORMED_NUM -?(({DIGIT}*\.{DIGIT}+)|({DIGIT}+(\.{DIGIT}+)?))[eE]({FLOAT_1}|{FLOAT_2})

CHAR [ -~]{-}['\\]
CHARACTER ('{CHAR}')
SPECIAL_CHARACTER ('\\[ntafrbv0]')
SP_CH_1 ('\\\"')|('\\\'')
SP_CH_2 ('\\\\')

MULTI_CHAR ({CHAR}|\\[ntafrbv0]|\\\"|\\\\)
MULTI_CHAR_ERR ('{MULTI_CHAR}{MULTI_CHAR}+')

UNTER_CHAR_ERR '({CHAR}|\\[ntafrbv0]|\\\'|\\\"|\\\\)*

ID_ALPHABET [_a-zA-Z]
IDENTIFIER ({ID_ALPHABET}({ID_ALPHABET}|{DIGIT})*)

STRING \"([^\"\n]|(\\\n)|(\\\"))*\"

UNTER_STRING \"([^\"\n]|(\\\n)|(\\\"))*\n
	/*jesob string er sheshe \" paoa jabe segulo incorrect, so*/

SINGLE_LINE_COMMENT "//"(.|\\{NEWLINE})*	
MULTI_LINE_COMMENT "/*"([^*]|"*"[^/])*"*/"
UNTER_COMMENT "/*"([^*]|"*"[^/])*
%%

{NEWLINE} {line_count++;}

{WHITESPACE} {/*ignore*/}

"println" {
			return PRINTLN;
		}
"if"	{
			//fprintf(tokenout,"<IF>");
			//fprintf(logout,"Line no %d: TOKEN <IF> Lexeme %s found\n",line_count,yytext);
			return IF;
		}

"else"	{
			//fprintf(tokenout,"<ELSE>");
			//fprintf(logout,"Line no %d: TOKEN <ELSE> Lexeme %s found\n",line_count,yytext);
			return ELSE;
		}
		
"for"	{
			//fprintf(tokenout,"<FOR>");
			//fprintf(logout,"Line no %d: TOKEN <ELSE> Lexeme %s found\n",line_count,yytext);
			return FOR;
		}

"while"	{
			//fprintf(tokenout,"<WHILE>");
			//fprintf(logout,"Line no %d: TOKEN <WHILE> Lexeme %s found\n",line_count,yytext);
			return WHILE;
		}

"do"	{
			//fprintf(tokenout,"<DO>");
			//fprintf(logout,"Line no %d: TOKEN <DO> Lexeme %s found\n",line_count,yytext);
			return DO;
		}
		
"break"	{
			//fprintf(tokenout,"<BREAK>");
			//fprintf(logout,"Line no %d: TOKEN <BREAK> Lexeme %s found\n",line_count,yytext);
			return BREAK;
		}
		
"int"	{
			//fprintf(tokenout,"<INT>");
			//fprintf(logout,"Line no %d: TOKEN <INT> Lexeme %s found\n",line_count,yytext);
			return INT;
		}
		
"char"	{
			//fprintf(tokenout,"<CHAR>");
			//fprintf(logout,"Line no %d: TOKEN <CHAR> Lexeme %s found\n",line_count,yytext);
			return CHAR;
		}
		
"float"	{
			//fprintf(tokenout,"<FLOAT>");
			//fprintf(logout,"Line no %d: TOKEN <FLOAT> Lexeme %s found\n",line_count,yytext);
			return FLOAT;
		}
		
"double"	{
			//fprintf(tokenout,"<DOUBLE>");
			//fprintf(logout,"Line no %d: TOKEN <DOUBLE> Lexeme %s found\n",line_count,yytext);
			return DOUBLE;
		}
		
"void"	{
			//fprintf(tokenout,"<VOID>");
			//fprintf(logout,"Line no %d: TOKEN <VOID> Lexeme %s found\n",line_count,yytext);
			return VOID;
		}
		
"return"	{
			//fprintf(tokenout,"<RETURN>");
			//fprintf(logout,"Line no %d: TOKEN <RETURN> Lexeme %s found\n",line_count,yytext);
			return RETURN;
		}
		
"switch"	{
			//fprintf(tokenout,"<SWITCH>");
			//fprintf(logout,"Line no %d: TOKEN <SWITCH> Lexeme %s found\n",line_count,yytext);
			return SWITCH;
		}
		
"case"	{
			//fprintf(tokenout,"<CASE>");
			//fprintf(logout,"Line no %d: TOKEN <CASE> Lexeme %s found\n",line_count,yytext);
			return CASE;
		}
		
"default"	{
			//fprintf(tokenout,"<DEFAULT>");
			//fprintf(logout,"Line no %d: TOKEN <DEFAULT> Lexeme %s found\n",line_count,yytext);
			return DEFAULT;
		}
		
"continue"	{
			//fprintf(tokenout,"<CONTINUE>");
			//fprintf(logout,"Line no %d: TOKEN <CONTINUE> Lexeme %s found\n",line_count,yytext);
			return CONTINUE;
		}
		
{DIGIT}+	{
				//fprintf(tokenout,"<CONST_INT,%s>",yytext);
				//fprintf(logout,"Line no %d: TOKEN <CONST_INT> Lexeme %s found\n",line_count,yytext);
				//insert in symbol table and print symbol table content(only non empty buckets)
				//bool f = symTab.Insert(string(yytext), "CONST_INT");
				//if(f) symTab.printAllScopeTable(logout);
				
				SymbolInfo * si = new SymbolInfo(string(yytext), "CONST_INT");
				yylval.symbol_info = si;
				return CONST_INT;
			}
	/*two form .digits thaklei float, digits E digits thakleo float*/
{FLOAT_1} |
{FLOAT_2} {
				//fprintf(tokenout,"<CONST_FLOAT,%s>",yytext);
				//fprintf(logout,"Line no %d: TOKEN <CONST_FLOAT> Lexeme %s found\n",line_count,yytext);
				//insert in symbol table and print symbol table content(only non empty buckets)
				//bool f = symTab.Insert(string(yytext), "CONST_FLOAT");
				//if(f) symTab.printAllScopeTable(logout);

				SymbolInfo * si = new SymbolInfo(string(yytext), "CONST_FLOAT");
				yylval.symbol_info = si;
				return CONST_FLOAT;
			}
			
{TOO_MANY_DEC} {
				//fprintf(logout,"Error at line %d: Too many decimal point %s\n",line_count,yytext);
				err_count++;
			}

{ILL_FORMED_NUM} {
				//fprintf(logout,"Error at line %d: Ill formed number %s\n",line_count,yytext);
				err_count++;
			}

{CHARACTER} {
			/*char * tokenpart = (char *) malloc(2*sizeof(char));
			tokenpart[0] = yytext[1];
			tokenpart[1] = '\0';
			
			*/
			//fprintf(tokenout,"<CONST_CHAR,%c>",yytext[1]);
			//fprintf(logout,"Line no %d: TOKEN <CONST_CHAR> Lexeme %s found\n",line_count,yytext);
			//insert in symbol table and print symbol table content(only non empty buckets)
			//bool f = symTab.Insert(string(yytext), "CONST_CHAR");
			//if(f) symTab.printAllScopeTable(logout);
			
			string name_here = "";
			name_here += yytext[1];
			SymbolInfo * si = new SymbolInfo(name_here, "CONST_CHAR");
			yylval.symbol_info = si;
			return CONST_CHAR;
}

{SPECIAL_CHARACTER} |
{SP_CH_1} |
{SP_CH_2} 	{
			string name_here = "";
			if(strcmp(yytext, "'\\n'")==0){
				//fprintf(tokenout,"<CONST_CHAR,%c>", '\n');
				name_here += '\n';
			}
			if(strcmp(yytext, "'\\t'")==0){
				//fprintf(tokenout,"<CONST_CHAR,%c>", '\t');
				name_here += '\t';
			}
			if(strcmp(yytext, "'\\\"'")==0){
				//fprintf(tokenout,"<CONST_CHAR,%c>", '\"');
				name_here += '\"';
			}
			if(strcmp(yytext, "'\\\''")==0){
				//fprintf(tokenout,"<CONST_CHAR,%c>", '\'');
				name_here += '\'';
			}
			if(strcmp(yytext, "'\\a'")==0){
				//fprintf(tokenout,"<CONST_CHAR,%c>", '\a');
				name_here += '\a';
			}
			if(strcmp(yytext, "'\\f'")==0){
				//fprintf(tokenout,"<CONST_CHAR,%c>", '\f');
				name_here += '\f';
			}
			if(strcmp(yytext, "'\\r'")==0){
				//fprintf(tokenout,"<CONST_CHAR,%c>", '\r');
				name_here += '\r';
			}
			if(strcmp(yytext, "'\\b'")==0){
				//fprintf(tokenout,"<CONST_CHAR,%c>", '\b');
				name_here += '\b';
			}
			if(strcmp(yytext, "'\\v'")==0){
				//fprintf(tokenout,"<CONST_CHAR,%c>", '\v');
				name_here += '\v';
			}
			//null char handling - not sure about what to do
			if(strcmp(yytext, "'\\0'")==0){
				char x[2] = {'\0', '\0'};
				//fprintf(tokenout,"<CONST_CHAR,%s>", x);
				name_here += x[0];
				name_here += x[1];
			}
			if(strcmp(yytext, "'\\\\'")==0){
				//fprintf(tokenout,"<CONST_CHAR,%c>", '\\');
				name_here += '\\';
			}

			
			
			//fprintf(logout,"Line no %d: TOKEN <CONST_CHAR> Lexeme %s found\n",line_count,yytext);
			//insert in symbol table and print symbol table content(only non empty buckets)
			//bool f = symTab.Insert(string(yytext), "CONST_CHAR");
			//if(f) symTab.printAllScopeTable(logout);


			SymbolInfo * si = new SymbolInfo(name_here, "CONST_CHAR");
			yylval.symbol_info = si;
			return CONST_CHAR;
		}

																					
"+"	|

"-"		{
			//fprintf(tokenout,"<ADDOP,%s>",yytext);
			//fprintf(logout,"Line no %d: TOKEN <ADDOP> Lexeme %s found\n",line_count,yytext);
			//insert in symbol table and print symbol table content(only non empty buckets)
			// There is a '|' in "+"'s rule, this means match execute the action for following rule
			//symTab.Insert(string(yytext),"ADDOP");
			//symTab.printAllScopeTable(logout);


			SymbolInfo * si = new SymbolInfo(string(yytext), "ADDOP");
			yylval.symbol_info = si;
			return ADDOP;
		}

"*" |
"/" |
"%" {
		//fprintf(tokenout,"<MULOP,%s>",yytext);
		//fprintf(logout,"Line no %d: TOKEN <MULOP> Lexeme %s found\n",line_count,yytext);
	
		SymbolInfo * si = new SymbolInfo(string(yytext), "MULOP");
		yylval.symbol_info = si;
		return MULOP;
	}
	
"++" {
		//fprintf(tokenout,"<INCOP,%s>",yytext);
		//fprintf(logout,"Line no %d: TOKEN <INCOP> Lexeme %s found\n",line_count,yytext);
	 	
		//SymbolInfo * si = new SymbolInfo(string(yytext), "INCOP");
		//yylval.symbol_info = si;
		return INCOP;
	 }

"--" {
		//fprintf(tokenout,"<INCOP,%s>",yytext);
		//fprintf(logout,"Line no %d: TOKEN <INCOP> Lexeme %s found\n",line_count,yytext);
	 	
		//SymbolInfo * si = new SymbolInfo(string(yytext), "DECOP");
		//yylval.symbol_info = si;
		return DECOP;
	 }

"<" |
"<=" |
">" |
">=" |
"==" |
"!=" {
		//fprintf(tokenout,"<RELOP,%s>",yytext);
		//fprintf(logout,"Line no %d: TOKEN <RELOP> Lexeme %s found\n",line_count,yytext);
	 	
		SymbolInfo * si = new SymbolInfo(string(yytext), "RELOP");
		yylval.symbol_info = si;
		return RELOP;
	 }

"=" {
		//fprintf(tokenout,"<ASSIGNOP,%s>",yytext);
		//fprintf(logout,"Line no %d: TOKEN <ASSIGNOP> Lexeme %s found\n",line_count,yytext);
		return ASSIGNOP;
	}	
	
"&&" |
"||" {
		//fprintf(tokenout,"<LOGICOP,%s>",yytext);
		//fprintf(logout,"Line no %d: TOKEN <LOGICOP> Lexeme %s found\n",line_count,yytext);
	 	
		SymbolInfo * si = new SymbolInfo(string(yytext), "LOGICOP");
		yylval.symbol_info = si;
		return LOGICOP;
	 }
	 
"&" |
"|" |
"^" |
"<<" |
">>" {
		//fprintf(tokenout,"<BITOP,%s>",yytext);
		//fprintf(logout,"Line no %d: TOKEN <BITOP> Lexeme %s found\n",line_count,yytext);
	 	SymbolInfo * si = new SymbolInfo(string(yytext), "BITOP");
		yylval.symbol_info = si;
		return BITOP;
	 }
	 
"!" {
		//fprintf(tokenout,"<NOT,%s>",yytext);
		//fprintf(logout,"Line no %d: TOKEN <NOT> Lexeme %s found\n",line_count,yytext);
		return NOT;
	}
	
"(" {
		//fprintf(tokenout,"<LPAREN,%s>",yytext);
		//fprintf(logout,"Line no %d: TOKEN <LPAREN> Lexeme %s found\n",line_count,yytext);
		return LPAREN;
	}

")" {
		//fprintf(tokenout,"<RPAREN,%s>",yytext);
		//fprintf(logout,"Line no %d: TOKEN <RPAREN> Lexeme %s found\n",line_count,yytext);
		return RPAREN;
	}
"{" {
		//fprintf(tokenout,"<LCURL,%s>",yytext);
		//fprintf(logout,"Line no %d: TOKEN <LCURL> Lexeme %s found\n",line_count,yytext);
		return LCURL;
	}
	
"}" {
		//fprintf(tokenout,"<RCURL,%s>",yytext);
		//fprintf(logout,"Line no %d: TOKEN <RCURL> Lexeme %s found\n",line_count,yytext);
		return RCURL;
	}

"[" {
		//fprintf(tokenout,"<LTHIRD,%s>",yytext);
		//fprintf(logout,"Line no %d: TOKEN <LTHIRD> Lexeme %s found\n",line_count,yytext);
		return LTHIRD;
	}
	
"]" {
		//fprintf(tokenout,"<RTHIRD,%s>",yytext);
		//fprintf(logout,"Line no %d: TOKEN <RTHIRD> Lexeme %s found\n",line_count,yytext);
		return RTHIRD;
	}

"," {
		//fprintf(tokenout,"<COMMA,%s>",yytext);
		//fprintf(logout,"Line no %d: TOKEN <COMMA> Lexeme %s found\n",line_count,yytext);
		return COMMA;
	}
	
";" {
		//fprintf(tokenout,"<SEMICOLON,%s>",yytext);
		//fprintf(logout,"Line no %d: TOKEN <SEMICOLON> Lexeme %s found\n",line_count,yytext);
		return SEMICOLON;
	}
	
{IDENTIFIER} {
		//fprintf(tokenout,"<ID,%s>",yytext);
		//fprintf(logout,"Line no %d: TOKEN <ID> Lexeme %s found\n",line_count,yytext);
		//insert in symbol table and print symbol table content(only non empty buckets)
		//bool f = symTab.Insert(string(yytext), "ID");
		//if(f) symTab.printAllScopeTable(logout);

		SymbolInfo * si = new SymbolInfo(string(yytext), "ID");
		yylval.symbol_info = si;
		return ID;
	}
	

	
{STRING} {
			//printf("\n\n%s\n\n", yytext);
			//printf("string eta\n");
			
			//if(yytext[5]=='\\') printf("\nbugbug\n");
		 	//printf("%c", yytext[5]);
		 	int len = strlen(yytext);
		 	int start_line = line_count;
			char * tokenpart = (char *) malloc(len * sizeof(char));
			int t = 0;
			for(int i = 1; i<=len-2; i++){
				if(i<len-2 && yytext[i]=='\\'){
					//special char check
					if(yytext[i+1]=='n'){
						tokenpart[t] = '\n';
						i++;
						t++;
					}
					else if(yytext[i+1]=='t'){
						tokenpart[t] = '\t';
						i++;
						t++;
					}
					else if(yytext[i+1]=='\"'){
						tokenpart[t] = '\"';
						i++;
						t++;
					}
					else if(yytext[i+1]=='\''){
						tokenpart[t] = '\'';
						i++;
						t++;
					}
					else if(yytext[i+1]=='a'){
						tokenpart[t] = '\a';
						i++;
						t++;
					}
					else if(yytext[i+1]=='f'){
						tokenpart[t] = '\f';
						i++;
						t++;
					}
					else if(yytext[i+1]=='r'){
						tokenpart[t] = '\r';
						i++;
						t++;
					}
					else if(yytext[i+1]=='b'){
						tokenpart[t] = '\b';
						i++;
						t++;
					}
					else if(yytext[i+1]=='v'){
						tokenpart[t] = '\v';
						i++;
						t++;
					}
					else if(yytext[i+1]=='0'){
						tokenpart[t] = '\0';
						i++;
						t++;
					}
					else if(yytext[i+1]=='\\'){
						tokenpart[t] = '\\';
						i++;
						t++;
					}
					else if(yytext[i+1]=='\n'){
						line_count++;
						i++;
					}
					else{
						//do nothing in case of single \ without any special char after it -> like "lo\lo"
					}
				}
				else{
					tokenpart[t] = yytext[i];
					t++;
				}
			}
			tokenpart[t] = '\0';
		 	//printf("String : %s\n\n", tokenpart);
		 	//fprintf(tokenout,"<STRING,\"%s\">",tokenpart);
			//fprintf(logout,"Line no %d: TOKEN <STRING> Lexeme %s found\n",start_line,yytext);
		 }
		 
{UNTER_STRING}	 {
					//CORRUPT AND UNFINISHED STRING ERROR CODES
					//fprintf(logout,"Error at line %d: Unterminated String %s\n",line_count,yytext);
					err_count++;
					int len = strlen(yytext);
		 			for(int i = 0; i<len; i++){
		 				if(yytext[i] == '\n') line_count++;
		 			}
				 }
{SINGLE_LINE_COMMENT} |	
{MULTI_LINE_COMMENT} {
		 	//fprintf(logout,"Line no %d: TOKEN <COMMENT> Lexeme %s found\n",line_count,yytext);
		 	int len = strlen(yytext);
		 	for(int i = 0; i<len; i++){
		 		if(yytext[i] == '\n') line_count++;
		 	}
		 }

{DIGIT}+{IDENTIFIER} {
		//fprintf(logout,"Error at line %d: Invalid prefix on ID or invalid suffix on Number %s\n",line_count,yytext);
		err_count++;
	}
"''" {
		//fprintf(logout,"Error at line %d: Empty character constant error %s\n",line_count,yytext);
		err_count++;
	 }
{MULTI_CHAR_ERR} {
		//fprintf(logout,"Error at line %d: Multi character constant error %s\n",line_count,yytext);
		err_count++;
	}

{UNTER_CHAR_ERR} {
		//fprintf(logout,"Error at line %d: Unterminated character %s\n",line_count,yytext);
		err_count++;
	}

{UNTER_COMMENT} {
		//fprintf(logout,"Error at line %d: Unterminated comment %s\n",line_count,yytext);
		err_count++;
		int len = strlen(yytext);
		for(int i = 0; i<len; i++){
			if(yytext[i] == '\n') line_count++;
		}
	}
	
.	{
		//fprintf(logout,"Error at line %d: Unrecognized character %s\n",line_count,yytext);
		err_count++;
	}
%%

/*
int main(int argc,char *argv[]){

	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}

	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}

	logout= fopen("log.txt","w");
	tokenout= fopen("token.txt","w");
	
	

	yyin= fin;
	yylex();
	
	symTab.printAllScopeTable(logout);
	fprintf(logout,"\nTotal Lines: %d\n",line_count);
	fprintf(logout,"\nTotal Errors: %d\n",err_count);
	
	fclose(yyin);
	fclose(tokenout);
	fclose(logout);
	return 0;
}
*/