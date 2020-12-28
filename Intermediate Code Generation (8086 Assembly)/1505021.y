%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include<string>
#include<fstream>
#include<vector>
#include "1505021_SymbolTable.h"
//#define YYSTYPE SymbolInfo*
#define SYMBOL_TABLE_BUCKET_SIZE 50

using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;

extern int line_count;
extern int err_count;
int error_semantic = 0;

SymbolTable symbol_table(SYMBOL_TABLE_BUCKET_SIZE);

vector<string> param_ID_yet_to_insert; //SPECIAL CASE : "-1" for func defin/decl like f(int a ,  int) -> ekhane name "-1" diye rakhbo ,  symboltable e insert korbo na - just to make sure idtype_param consistent thake

vector<string> idtype_param_ID_yet_to_insert; //var

vector<string> datatype_param_ID_yet_to_insert; //VAR - "INT" "FLOAT" "VOID" 

vector<string> args_of_func_call; //storing datatypes of arguments of a func call
vector<string> symbols_of_func_call;

string ongoing_data_type; //whenever i find a type specifier i am storing here : will add $$->data_type for type specifier and use it later

vector<string> var_ds; // data segment entry
vector<string> arr_ds;
vector<int> arr_sz_ds;

string code_buffer;

ofstream logtxt ,  errortxt ,  code_gen;

void yyerror(const char *s)
{
	//write your code

	errortxt<<"Error at line "<<line_count<<": "<<string(s)<<endl;
	errortxt<<endl; error_semantic++;
}

//label and temp generation madam's code
int labelCount=0;
int tempCount=0;


char *newLabel()
{
	char *lb= new char[4];
	strcpy(lb , "L");
	char b[3];
	sprintf(b , "%d" ,  labelCount);
	labelCount++;
	strcat(lb , b);
	return lb;
}

char *newTemp()
{
	char *t= new char[4];
	strcpy(t , "t");
	char b[3];
	sprintf(b , "%d" ,  tempCount);
	tempCount++;
	strcat(t , b);
	return t;
}

string to_string(int n){
	char result[16];
	sprintf ( result ,  "%d" ,  n );
	return string(result);
}



%}
%union{
    SymbolInfo * symbol_info;
}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE ASSIGNOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON INCOP DECOP PRINTLN
%token <symbol_info> CONST_INT
%token <symbol_info> CONST_FLOAT
%token <symbol_info> CONST_CHAR
%token <symbol_info> ADDOP
%token <symbol_info> MULOP
%token <symbol_info> RELOP
%token <symbol_info> LOGICOP
%token <symbol_info> BITOP
%token <symbol_info> ID

%type <symbol_info> start program unit func_declaration func_definition parameter_list compound_statement var_declaration type_specifier declaration_list statements statement expression_statement variable expression logic_expression rel_expression simple_expression term unary_expression factor argument_list arguments

//%left 
//%right

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%define parse.error verbose
%define parse.lac full

%%

start : program
	{
		//write your code in this block in all the similar blocks below
        //logtxt<<line_count<<" "<<"program found\n";
		//logtxt<<"At line no: "<<line_count<< " start : program"<<endl;
	
		logtxt<<"    Symbol Table:\n\n";
		symbol_table.printAllScopeTable(logtxt);

		//int errors = error_semantic; 
		int errors = err_count + error_semantic;
		logtxt<<endl<<"Total Lines: "<<line_count<<endl;
		logtxt<<endl<<"Total Errors: "<<errors<<endl;

		errortxt<<endl<<"Total Errors: "<<errors<<endl;

		
		//fout << $1->code;
		
		//adding print function which prints the signed number in AX
		$$ = new SymbolInfo();
		string print_ax_proc= "print_ax proc near\npush ax\npush bx\npush cx\npush dx\nor ax , ax\njge enddif\npush ax\nmov dl , '-'\nmov ah , 2\nint 21h\npop ax\nneg ax\nenddif:\nxor cx , cx\nmov bx , 10d\nrepeat:\nxor dx , dx\ndiv bx\npush dx\ninc cx\nor ax , ax\njne repeat\nmov ah , 2\nprint_loop:\npop dx\nor dl , 30h\nint 21h\nloop print_loop\nmov dl ,  0Dh\nint 21h\nmov dl ,  0Ah\nint 21h\npop dx\npop cx\npop bx\npop ax\nret\nprint_ax endp\n";


		//if error count is zero ,  print the code to asm file

		$$->code += ".model small\n.stack 100h\n.data\n";
		
		//variables

		for(int i = 0; i<var_ds.size(); i++){
			$$->code += (var_ds[i] + " DW ?\n");
		}

		//temporary vars 
		for(int i = 0; i<tempCount; i++) {
			char *t= new char[4];
			strcpy(t , "t");
			char b[3];
			sprintf(b , "%d" ,  i);
			strcat(t , b);
			$$->code += (string(t)+ " DW ?\n");
		}
		//arrays with sizes
		for(int i = 0; i<arr_ds.size(); i++){
			$$->code += (arr_ds[i] + " DW " + to_string(arr_sz_ds[i]) + " dup(0)\n");
		}

		//ADD THEM ALL TO $$ code
		$$->code += ".code\n";
		$$->code += print_ax_proc;
		
		$$->code += $1->code;
		$$->code += "end main\n";
		
		code_gen<<$$->code;
		
	}
	;

program : program unit 
	{
		logtxt<<"At line no: "<<line_count<< " program : program unit"<<endl;
		
		$$ = new SymbolInfo();
		$$->setName( $1->getName() + $2->getName());
		logtxt<<endl<<$$->getName()<<endl<<endl;

		$$->code = $1->code + $2->code;

		delete $1;
		delete $2;
		
	}
	| unit
	{
		logtxt<<"At line no: "<<line_count<< " program : unit"<<endl;
		
		$$ = new SymbolInfo();
		$$->setName( $1->getName() );
		logtxt<<endl<<$$->getName()<<endl<<endl;
		
		$$->code = $1->code;

		delete $1;
	}
	;
	
unit : var_declaration
		{
			logtxt<<"At line no: "<<line_count<< " unit : var_declaration"<<endl;

			$$ = new SymbolInfo();
			$$->setName( $1->getName() );
			logtxt<<endl<<$$->getName()<<endl<<endl;

			$$->code = $1->code;

			delete $1;
		}
     | func_declaration
	 {
		 logtxt<<"At line no: "<<line_count<< " unit : func_declaration"<<endl;

		 $$ = new SymbolInfo();
	 	$$->setName( $1->getName() );
		logtxt<<endl<<$$->getName()<<endl<<endl;

		$$->code = $1->code;

		delete $1;
	 }
     | func_definition
	 {
		 logtxt<<"At line no: "<<line_count<< " unit : func_definition"<<endl;

		$$ = new SymbolInfo();
	 	$$->setName( $1->getName() );
		logtxt<<endl<<$$->getName()<<endl<<endl;

		$$->code = $1->code;

		delete $1;
	 }
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
		{
			//no asm code for func declaration
			
			logtxt<<"At line no: "<<line_count<< " func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON"<<endl;
		
			$$ = new SymbolInfo();
	 		$$->setName( $1->getName() + $2->getName() + "(" + $4->getName() + ")" + ";\n" );
			logtxt<<endl<<$$->getName()<<endl<<endl;
		
			bool flag = symbol_table.Insert( $2->getName()  ,  "ID");

			if(flag){
				//inserted ,  so totally new - setting up other attributes
				SymbolInfo * si = symbol_table.LookUp($2->getName());
				si->IDtype = "FUNC";
				si->return_type = $1->data_type;

				for(int i = 0; i<datatype_param_ID_yet_to_insert.size(); i++){
					si->parameter_list.push_back(datatype_param_ID_yet_to_insert[i]);
				}
			}
			else{
				//two probable cases 
					//0. global variable same name - error
					//1. declaration or definition exists - have to check consistency
				SymbolInfo * si = symbol_table.LookUp($2->getName());
				if(si->IDtype!="FUNC"){
					//case 0
					errortxt<<"Error at line "<<line_count<<": Function name conflicts with global variable."<<endl;
					error_semantic++; errortxt<<endl;
				}
				else{
					//case 1
					bool consistent = true;
					if(si->return_type != $1->data_type){
						//return type doesn't match
						consistent = false;
					}
					else{
						//return type matched but check param list;
						if(si->parameter_list.size() != datatype_param_ID_yet_to_insert.size()){
							consistent = false;
						}
						for(int i = 0; i<datatype_param_ID_yet_to_insert.size(); i++){
							if(si->parameter_list[i] != datatype_param_ID_yet_to_insert[i]){
								consistent = false;
							}
						}
					}
					if(!consistent) {
						errortxt<<"Error at line "<<line_count<<": Conflicting declaration/definition of function "<<$2->getName()<<"(...)."<<endl;
						error_semantic++; errortxt<<endl;
					}
				}
			}

			//clearing param_ID_yet_to_insert as they are no more needed
			param_ID_yet_to_insert.clear();
			idtype_param_ID_yet_to_insert.clear();
			datatype_param_ID_yet_to_insert.clear();

			delete $1;
			delete $2;
			delete $4;
		}
		| type_specifier ID LPAREN RPAREN SEMICOLON
		{
			logtxt<<"At line no: "<<line_count<< " func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON"<<endl;
		
			$$ = new SymbolInfo();
		 	$$->setName( $1->getName() + $2->getName() + "();\n" );
			logtxt<<endl<<$$->getName()<<endl<<endl;
		
			bool flag = symbol_table.Insert( $2->getName()  ,  "ID");

			if(flag){
				//inserted ,  so totally new - setting up other attributes
				SymbolInfo * si = symbol_table.LookUp($2->getName());
				si->IDtype = "FUNC";
				si->return_type = $1->data_type;
				//no parameter
			}
			else{
				//two probable cases 
					//0. global variable same name - error
					//1. declaration or definition exists - have to check consistency
				SymbolInfo * si = symbol_table.LookUp($2->getName());
				if(si->IDtype!="FUNC"){
					//case 0
					errortxt<<"Error at line "<<line_count<<": Function name conflicts with global variable."<<endl;
					error_semantic++; errortxt<<endl;
				}
				else{
					//case 1
					bool consistent = true;
					if(si->return_type != $1->data_type){
						//return type doesn't match
						consistent = false;
					}
					else{
						//return type matched but check param list;
						if(si->parameter_list.size() != 0){
							consistent = false;
						}				
					}
					if(!consistent) {
						errortxt<<"Error at line "<<line_count<<": Conflicting declaration/definition of function "<<$2->getName()<<"(...)."<<endl;
						error_semantic++; errortxt<<endl;
					}
				}
			}
			//clearing param_ID_yet_to_insert as they are no more needed - not needed probably ,  just being over cautious	
			param_ID_yet_to_insert.clear();
			idtype_param_ID_yet_to_insert.clear();
			datatype_param_ID_yet_to_insert.clear();

			delete $1;
			delete $2;
		}
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN 
						{
							bool flag = symbol_table.Insert( $2->getName()  ,  "ID");

							if(flag){
								//inserted ,  so totally new ,  setting up other attributes
								SymbolInfo * si = symbol_table.LookUp($2->getName());
								si->IDtype = "FUNC";
								si->return_type = $1->data_type;

								for(int i = 0; i<datatype_param_ID_yet_to_insert.size(); i++){
									si->parameter_list.push_back(datatype_param_ID_yet_to_insert[i]);
								}

								si->func_defined = true;
							}
							else{
								//three possible cases
									//0. globar variable declared - error
									//1. already exists declaration ,  but not defined - fine but check if consistent
									//2. already defined - error

								SymbolInfo * si = symbol_table.LookUp($2->getName());
								
								if(si->IDtype!="FUNC"){
									//case 0
									errortxt<<"Error at line "<<line_count<<": Function name conflicts with global variable."<<endl;
									error_semantic++; errortxt<<endl;
								}
								else{
									if(si->func_defined){
										//case 2
										errortxt<<"Error at line "<<line_count<<": Redefinition of function "<<$2->getName()<<"(...)."<<endl;
										error_semantic++; errortxt<<endl;
									}
									else{
										//case 1
										//we are defining a func which is already declared - check if the declaration matches or not
										bool consistent = true;
										if(si->return_type != $1->data_type){
											//return type doesn't match
											consistent = false;
										}
										else{
											//return type matched but check param list;
											if(si->parameter_list.size() != datatype_param_ID_yet_to_insert.size()){
												consistent = false;
											}
											for(int i = 0; i<datatype_param_ID_yet_to_insert.size(); i++){
												if(si->parameter_list[i] != datatype_param_ID_yet_to_insert[i]){
													consistent = false;
												}
											}
										}
										if(!consistent) {
											errortxt<<"Error at line "<<line_count<<": Function definition doesn't match declaration."<<endl;
											error_semantic++; errortxt<<endl;
										}
										else si->func_defined = true; //no error - marking defined
									}
								}	
							}
							datatype_param_ID_yet_to_insert.clear();
						}
		compound_statement
		{
			logtxt<<"At line no: "<<line_count<< " func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement"<<endl;
		
			$$ = new SymbolInfo();
		 	$$->setName( $1->getName() + $2->getName() + "(" + $4->getName() + ")" + $7->getName() );
			logtxt<<endl<<$$->getName()<<endl<<endl;
			
			//pop cx saves return address
			string ds_init = "" ,  push="" ,  pop="";
			if($2->getName()=="main"){
				ds_init += "mov dx , @data\nmov ds , dx\n";
			} else{
				pop = "pop cx\n";
				push = "push cx\nret\n";
			}

			$$->code = $2->getName()+" proc\n"+ ds_init + pop + $7->code + push + $2->getName() + " endp\n";

			delete $1;
			delete $2;
			delete $4;
			delete $7;
		}
		| type_specifier ID LPAREN RPAREN 
		
					{
						bool flag = symbol_table.Insert( $2->getName()  ,  "ID");

						if(flag){
							//inserted ,  so totally new ,  setting up other attributes
							SymbolInfo * si = symbol_table.LookUp($2->getName());
							si->IDtype = "FUNC";
							si->return_type = $1->data_type;
							//no param list
							si->func_defined = true;
						}
						else{
							//three possible cases
								//0. globar variable declared - error
								//1. already exists declaration ,  but not defined - fine
								//2. already defined - error

							SymbolInfo * si = symbol_table.LookUp($2->getName());

							if(si->IDtype!="FUNC"){
								//case 0
								errortxt<<"Error at line "<<line_count<<": Function name conflicts with global variable."<<endl;
								error_semantic++; errortxt<<endl;
							}
							else{
								if(si->func_defined){
									//case 2
									errortxt<<"Error at line "<<line_count<<": Redefinition of function "<<$2->getName()<<"(...)."<<endl;
									error_semantic++; errortxt<<endl;
								}
								else{
									//case 1
									//we are defining a func which is already declared - check if the declaration matches or not
									bool consistent = true;
									if(si->return_type != $1->data_type){
										//return type doesn't match
										consistent = false;
									}
									else{
										//return type matched but check param list;
										if(si->parameter_list.size() != 0){
											consistent = false;
										}
									}	
									if(!consistent) {
										errortxt<<"Error at line "<<line_count<<": Function definition doesn't match declaration."<<endl;
										error_semantic++; errortxt<<endl;
									}
									else si->func_defined = true; //no error - marking defined
								}
							}	
						}
						datatype_param_ID_yet_to_insert.clear();
					}

		compound_statement
		{
			logtxt<<"At line no: "<<line_count<< " func_definition : type_specifier ID LPAREN RPAREN compound_statement"<<endl;
		
			$$ = new SymbolInfo();
		 	$$->setName( $1->getName() + $2->getName() + "()" + $6->getName() );
			logtxt<<endl<<$$->getName()<<endl<<endl;

			//pop cx saves return address
			string ds_init = "" ,  push="" ,  pop="";
			if($2->getName()=="main"){
				ds_init += "mov dx , @data\nmov ds , dx\n";
			} else{
				pop = "pop cx\n";
				push = "push cx\nret\n";
			}
			
			$$->code = $2->getName()+" proc\n"+ ds_init + pop + $6->code + push + $2->getName() + " endp\n";

			delete $1;
			delete $2;
			delete $6;
		}
 		;				


parameter_list  : parameter_list COMMA type_specifier ID
		{
			//no asm code needed for parameter list
			logtxt<<"At line no: "<<line_count<< " parameter_list  : parameter_list COMMA type_specifier ID"<<endl;

			$$ = new SymbolInfo();
		 	$$->setName( $1->getName() + " ,  " + $3->getName() + $4->getName() );
			logtxt<<endl<<$$->getName()<<endl<<endl;

			param_ID_yet_to_insert.push_back($4->getName() );
			idtype_param_ID_yet_to_insert.push_back("VAR");
			datatype_param_ID_yet_to_insert.push_back(ongoing_data_type);

			delete $1;
			delete $3;
			delete $4;
		}
		| parameter_list COMMA type_specifier
		{
			logtxt<<"At line no: "<<line_count<< " parameter_list  : parameter_list COMMA type_specifier"<<endl;

			$$ = new SymbolInfo();
		 	$$->setName( $1->getName() + " ,  " + $3->getName() );
			logtxt<<endl<<$$->getName()<<endl<<endl;

			param_ID_yet_to_insert.push_back("-1");
			idtype_param_ID_yet_to_insert.push_back("VAR");
			datatype_param_ID_yet_to_insert.push_back(ongoing_data_type);
			
			delete $1;
			delete $3;
		}	
 		| type_specifier ID
		{
			logtxt<<"At line no: "<<line_count<< " parameter_list  : type_specifier ID"<<endl;

			$$ = new SymbolInfo();
		 	$$->setName( $1->getName() + $2->getName() );
			logtxt<<endl<<$$->getName()<<endl<<endl;

			param_ID_yet_to_insert.push_back($2->getName() );
			idtype_param_ID_yet_to_insert.push_back("VAR");
			datatype_param_ID_yet_to_insert.push_back(ongoing_data_type);

			delete $1;
			delete $2;
		}
		| type_specifier
 		{
			logtxt<<"At line no: "<<line_count<< " parameter_list  : type_specifier"<<endl;

			$$ = new SymbolInfo();
		 	$$->setName( $1->getName() );
			logtxt<<endl<<$$->getName()<<endl<<endl;

			param_ID_yet_to_insert.push_back("-1");
			idtype_param_ID_yet_to_insert.push_back("VAR");
			datatype_param_ID_yet_to_insert.push_back(ongoing_data_type);

			delete $1;
		}
		;

 		
compound_statement : LCURL
						{
							//asm code: get value of temp_syms from stack
							code_buffer = "";
							symbol_table.EnterScope();
							for(int i = 0; i<param_ID_yet_to_insert.size(); i++){
								if(param_ID_yet_to_insert[i] != "-1"){
									//check needed for Multiple declaration of samne variable in this scope 
									//check if insertion successful
									bool flag = symbol_table.Insert(param_ID_yet_to_insert[i] ,  "ID");
									if(flag){
										SymbolInfo * si = symbol_table.LookUp(param_ID_yet_to_insert[i]);
										si->IDtype = idtype_param_ID_yet_to_insert[i];
										si->data_type = datatype_param_ID_yet_to_insert[i];

										int append_int = symbol_table.currScopeTable->unique_id;
										string temp_sym = si->getName()+"_"+to_string(append_int);
										var_ds.push_back(temp_sym);
										si->symbol = temp_sym;

										code_buffer += "pop ax\nmov "+temp_sym+" ,  ax\n";
										
									}
									else{
										errortxt<<"Error at line "<<line_count<<": Found multiple declaration of variable "<<param_ID_yet_to_insert[i]<<" in the scope."<<endl;
										error_semantic++; errortxt<<endl;
									}
								}
							}
							param_ID_yet_to_insert.clear();
							idtype_param_ID_yet_to_insert.clear();
						} 
					 statements
						
					 RCURL
			{

				logtxt<<"At line no: "<<line_count<< " compound_statement : LCURL statements RCURL"<<endl;

				$$ = new SymbolInfo();
			 	$$->setName( "{\n" + $3->getName() + "}\n" );
				logtxt<<endl<<$$->getName()<<endl<<endl;

				$$->code = code_buffer + $3->code;
				code_buffer = "";

				symbol_table.printAllScopeTable(logtxt);
				symbol_table.ExitScope();

				delete $3;
			}
 		    | LCURL
			 	{
					//asm code: get value of temp_syms from stack
					code_buffer = "";
					symbol_table.EnterScope();
					for(int i = 0; i<param_ID_yet_to_insert.size(); i++){
						//symbol_table.Insert(param_ID_yet_to_insert[i] ,  "ID");
						if(param_ID_yet_to_insert[i] != "-1"){
							//check for Multiple declaration of samne variable in this scope 
							//check if insertion successful
							bool flag = symbol_table.Insert(param_ID_yet_to_insert[i] ,  "ID");
							if(flag){
								SymbolInfo * si = symbol_table.LookUp(param_ID_yet_to_insert[i]);
								si->IDtype = idtype_param_ID_yet_to_insert[i];
								si->data_type = datatype_param_ID_yet_to_insert[i];

								int append_int = symbol_table.currScopeTable->unique_id;
								string temp_sym = si->getName()+"_"+to_string(append_int);
								var_ds.push_back(temp_sym);
								si->symbol = temp_sym;
								
								code_buffer += "pop ax\nmov "+temp_sym+" ,  ax\n";

							}
							else{
								errortxt<<"Error at line "<<line_count<<": Found multiple declaration of variable "<<param_ID_yet_to_insert[i]<<" in the scope."<<endl;
								error_semantic++; errortxt<<endl;
							}
						}
					}
					param_ID_yet_to_insert.clear();
					idtype_param_ID_yet_to_insert.clear();
				}

			  RCURL
			{
				logtxt<<"At line no: "<<line_count<< " compound_statement : LCURL RCURL"<<endl;
			
				$$ = new SymbolInfo();
			 	$$->setName( "{}\n" );
				logtxt<<endl<<$$->getName()<<endl<<endl;

				$$->code = code_buffer;
				code_buffer = "";
			
				symbol_table.printAllScopeTable(logtxt);
				symbol_table.ExitScope();
			}
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
		{
			logtxt<<"At line no: "<<line_count<< " var_declaration : type_specifier declaration_list SEMICOLON"<<endl;

			$$ = new SymbolInfo();
			$$->setName(  $1->getName() + $2->getName() + ";\n"  );
			logtxt<<endl<<$$->getName()<<endl<<endl;

			delete $1;
			delete $2;
		}
 		;
 		 
type_specifier	: INT
		{
			logtxt<<"At line no: "<<line_count<< " type_specifier	: INT"<<endl;
			
			ongoing_data_type = "INT";
			
			$$ = new SymbolInfo();
			$$->setName("int ");
			$$->data_type = "INT";
			logtxt<<endl<< $$->getName() <<endl<<endl;
			
		}
 		| FLOAT
		 {
			 logtxt<<"At line no: "<<line_count<< " type_specifier	: FLOAT"<<endl;
			
			ongoing_data_type = "FLOAT";

			$$ = new SymbolInfo();
			$$->setName( "float " );
			$$->data_type = "FLOAT";
			logtxt<<endl<<$$->getName()<<endl<<endl;
			
		 }
 		| VOID
		 {
			 logtxt<<"At line no: "<<line_count<< " type_specifier	: VOID"<<endl;
		 	
			 ongoing_data_type = "VOID";

			 $$ = new SymbolInfo();
			 $$->setName( "void " );
			 $$->data_type = "VOID";
			logtxt<<endl<<$$->getName()<<endl<<endl;
			
		 }
 		;
 		
declaration_list : declaration_list COMMA ID
			{
				logtxt<<"At line no: "<<line_count<< " declaration_list : declaration_list COMMA ID"<<endl;

				$$ = new SymbolInfo();
				$$->setName( $1->getName() + " ,  " + $3->getName() );
				logtxt<<endl<<$$->getName()<<endl<<endl;

				bool flag = symbol_table.Insert( $3->getName()  ,  "ID");

				if(flag){
					SymbolInfo * si = symbol_table.LookUp( $3->getName() );
					si->IDtype = "VAR";
					si->data_type = ongoing_data_type;

					int append_int = symbol_table.currScopeTable->unique_id;
					string temp_sym = si->getName()+"_"+to_string(append_int);
					var_ds.push_back(temp_sym);
					si->symbol = temp_sym;
				}
				else{
					errortxt<<"Error at line "<<line_count<<": Multiple declaration of variable "<< $3->getName()<<" in the same scope."<<endl;
					error_semantic++; errortxt<<endl;
				}

				delete $1;
				delete $3;
			}
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
		   {
			   logtxt<<"At line no: "<<line_count<< " declaration_list : declaration_list COMMA ID LTHIRD CONST_INT LTHIRD"<<endl;

				$$ = new SymbolInfo();
			    $$->setName( $1->getName() + " ,  " + $3->getName() + "[" + $5->getName() + "]" );
				logtxt<<endl<<$$->getName()<<endl<<endl;

				bool flag = symbol_table.Insert( $3->getName()  ,  "ID");

				if(flag){
					SymbolInfo * si = symbol_table.LookUp( $3->getName() );
					si->IDtype = "ARA";
					si->data_type = ongoing_data_type;
					si->ara_size = atoi(($5->getName()).c_str());	

					int append_int = symbol_table.currScopeTable->unique_id;
					string temp_sym = si->getName()+"_"+to_string(append_int);
					arr_ds.push_back(temp_sym);
					si->symbol = temp_sym;
					arr_sz_ds.push_back(si->ara_size);

				}
				else{
					errortxt<<"Error at line "<<line_count<<": Multiple declaration of variable "<< $3->getName() <<" in the same scope."<<endl;
					error_semantic++; errortxt<<endl;
				}				

				delete $1;
				delete $3;
				delete $5;
		   }
 		  | ID
		   {
			   logtxt<<"At line no: "<<line_count<< " ID"<<endl;

				$$ = new SymbolInfo();
			   	$$->setName( $1->getName() );
				logtxt<<endl<<$$->getName()<<endl<<endl;

				bool flag = symbol_table.Insert( $1->getName()  ,  "ID");
				if(flag){
					SymbolInfo * si = symbol_table.LookUp( $1->getName() );
					si->IDtype = "VAR";
					si->data_type = ongoing_data_type;		

					int append_int = symbol_table.currScopeTable->unique_id;
					string temp_sym = si->getName()+"_"+to_string(append_int);
					var_ds.push_back(temp_sym);
					si->symbol = temp_sym;
				}
				else{
					errortxt<<"Error at line "<<line_count<<": Multiple declaration of variable "<< $1->getName() <<" in the same scope."<<endl;
					error_semantic++; errortxt<<endl;
				}	
				
				delete $1;
		   }
 		  | ID LTHIRD CONST_INT RTHIRD
		   {
			   logtxt<<"At line no: "<<line_count<< " ID LTHIRD CONST_INT LTHIRD"<<endl;
		   		
				$$ = new SymbolInfo();
		   		$$->setName( $1->getName() + "[" + $3->getName() + "]" );
				logtxt<<endl<<$$->getName()<<endl<<endl;
		   
		   		bool flag = symbol_table.Insert( $1->getName()  ,  "ID");
				if(flag){
					SymbolInfo * si = symbol_table.LookUp( $1->getName() );
					si->IDtype = "ARA";
					si->data_type = ongoing_data_type;
					si->ara_size = atoi(($3->getName()).c_str());

					int append_int = symbol_table.currScopeTable->unique_id;
					string temp_sym = si->getName()+"_"+to_string(append_int);
					arr_ds.push_back(temp_sym);
					si->symbol = temp_sym;
					arr_sz_ds.push_back(si->ara_size);
					
				}
				else {
					errortxt<<"Error at line "<<line_count<<": Multiple declaration of variable "<< $1->getName() <<" in the same scope."<<endl;
					error_semantic++; errortxt<<endl;
				}		

				delete $1;
				delete $3;		
		   }
 		  ;
 		  
statements : statement
		{
			logtxt<<"At line no: "<<line_count<< " statements : statement"<<endl;

			$$ = new SymbolInfo();
		 	$$->setName( $1->getName() );
			logtxt<<endl<<$$->getName()<<endl<<endl;

			$$->code = $1->code;

			delete $1;
		}
	   | statements statement
	   {
		   logtxt<<"At line no: "<<line_count<< " statements : statements statement"<<endl;
	   
	   		$$ = new SymbolInfo();
		 	$$->setName( $1->getName() + $2->getName() );
			logtxt<<endl<<$$->getName()<<endl<<endl;

			$$->code = $1->code + $2->code;

			delete $1;
			delete $2;
	   }
	   ;
	   
statement : var_declaration
		{
			logtxt<<"At line no: "<<line_count<< " statement : var_declaration"<<endl;
		
			$$ = new SymbolInfo();
		 	$$->setName( $1->getName() );
			logtxt<<endl<<$$->getName()<<endl<<endl;

			$$->code = $1->code;

			delete $1;
		}
	  | expression_statement
		{
			logtxt<<"At line no: "<<line_count<< " statement : expression_statement"<<endl;
		
			$$ = new SymbolInfo();
		 	$$->setName( $1->getName() );
			logtxt<<endl<<$$->getName()<<endl<<endl;

			$$->code = $1->code;

			delete $1;
		}
	  | compound_statement
		{
			logtxt<<"At line no: "<<line_count<< " statement : compound_statement"<<endl;
		
			$$ = new SymbolInfo();
		 	$$->setName( $1->getName() );
			logtxt<<endl<<$$->getName()<<endl<<endl;

			$$->code = $1->code;

			delete $1;
		}
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
		{
			logtxt<<"At line no: "<<line_count<< " statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement"<<endl;
		
			$$ = new SymbolInfo();
		 	$$->setName( "for(" + $3->getName() + $4->getName() + $5->getName() + ")" + $7->getName() );
			logtxt<<endl<<$$->getName()<<endl<<endl;
					/*
						$3's code at first ,  which is already done by assigning $$=$3
						create two labels and append one of them in $$->code
						compare $4's symbol with 0
						if equal jump to 2nd label
						append $7's code
						append $5's code
						append the second label in the code
					*/
			
			char * label1 = newLabel();
			char * label2 = newLabel();

			
			$$->code = $3->code;
			$$->code += ( string(label1) + ":\n");
			$$->code += $4->code;
			$$->code += ("mov ax ,  " + $4->symbol + "\n");
			$$->code += ("cmp ax ,  0\n");
			$$->code += ("je "+ string(label2)+ "\n");
			$$->code += ($7->code);
			$$->code += ($5->code);
			$$->code += ("jmp "+string(label1) + "\n");
			$$->code += (string(label2) + ":\n");




			delete $3;
			delete $4;
			delete $5;
			delete $7;
		}
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
		{
			logtxt<<"At line no: "<<line_count<< " statement : IF LPAREN expression RPAREN statement"<<endl;
			if($3->data_type=="VOID"){
				errortxt<<"Error at line "<<line_count<<": If-else invalid conditioning using void."<<endl;
				error_semantic++; errortxt<<endl;
			}
			$$ = new SymbolInfo();
		 	$$->setName( "if(" + $3->getName() + ")" + $5->getName());
			logtxt<<endl<<$$->getName()<<endl<<endl;

			char * label = newLabel();

			$$->code = $3->code;
			$$->code += ("mov ax ,  " + $3->symbol + "\n");
			$$->code += ("cmp ax ,  0\n");
			$$->code += ("je " + string(label) + "\n");
			$$->code += $5->code;
			$$->code += (string(label) + ":\n");

			delete $3;
			delete $5;
		}
	  | IF LPAREN expression RPAREN statement ELSE statement
		{
			logtxt<<"At line no: "<<line_count<< " statement : IF LPAREN expression RPAREN statement ELSE statement"<<endl;
			if($3->data_type=="VOID"){
				errortxt<<"Error at line "<<line_count<<": If-else invalid conditioning using void."<<endl;
				error_semantic++; errortxt<<endl;
			}
			$$ = new SymbolInfo();
		 	$$->setName( "if(" + $3->getName() + ")" + $5->getName() + "else " + $7->getName() );
			logtxt<<endl<<$$->getName()<<endl<<endl;

			char * label1 = newLabel();
			char * label2 = newLabel();

			/*
				expression
				if(exp) 0 hole label1
					main action
					jmp label2
				label1
					else action
				label2
			*/
			$$->code = $3->code;
			$$->code += ("mov ax ,  " + $3->symbol + "\n");
			$$->code += ("cmp ax ,  0\n");
			$$->code += ("je " + string(label1) + "\n");
			$$->code += ($5->code);
			$$->code += ("jmp " + string(label2) + "\n");
			$$->code += (string(label1) + ":\n");
			$$->code += ($7->code);
			$$->code += (string(label2) + ":\n");

			delete $3;
			delete $5;
			delete $7;
		}
	  | WHILE LPAREN expression RPAREN
	  			{
					//void check
					if($3->data_type=="VOID"){
						errortxt<<"Error at line "<<line_count<<": Void value not ignored as it ought to be."<<endl;
						error_semantic++; errortxt<<endl;
					}
				}
	    statement
		{
			logtxt<<"At line no: "<<line_count<< " statement : WHILE LPAREN expression RPAREN statement"<<endl;
			
			$$ = new SymbolInfo();
		 	$$->setName( "while(" + $3->getName() + ")" + $6->getName() );
			logtxt<<endl<<$$->getName()<<endl<<endl;

			char * label1 = newLabel();
			char * label2 = newLabel();
			
			$$->code = "";
			$$->code += (string(label1)+ ":\n");
			$$->code += ($3->code);
			$$->code += ("mov ax ,  "+$3->symbol+"\n");
			$$->code += ("cmp ax ,  0\n");
			$$->code += ("je "+ string(label2)+ "\n");
			$$->code += ($6->code);
			$$->code += ("jmp "+string(label1)+ "\n");
			$$->code += (string(label2) + ":\n");

			delete $3;
			delete $6;
		}
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
		{
			logtxt<<"At line no: "<<line_count<< " statement : PRINTLN LPAREN ID RPAREN SEMICOLON"<<endl;
		
			$$ = new SymbolInfo();
		 	$$->setName( "println(" + $3->getName() + ");\n" );
			logtxt<<endl<<$$->getName()<<endl<<endl;

			//print procedure should be called with id's symbol
			//$3->symbol wont work BUG BUG BUG

			SymbolInfo * tmp = new SymbolInfo();
			tmp = symbol_table.LookUp($3->getName());

			$$->code = "push ax\nmov ax , "+ tmp->symbol + "\ncall print_ax\npop ax\n";

			delete $3;
		}
	  | RETURN expression SEMICOLON
		{
			logtxt<<"At line no: "<<line_count<< " statement : RETURN expression SEMICOLON"<<endl;
		
			$$ = new SymbolInfo();
		 	$$->setName( "return " + $2->getName() + ";\n" );
			logtxt<<endl<<$$->getName()<<endl<<endl;

			$$->code = $2->code;
			$$->code += ("mov ax ,  "+ $2->symbol + "\n");
			$$->code += ("push ax\n");
			
			delete $2;
		}
	  | error SEMICOLON
	  	{
			$$ = new SymbolInfo();
		}
	  | error RCURL
	    {
			$$ = new SymbolInfo();
		}
	  ;
	  
expression_statement 	: SEMICOLON
			{
				logtxt<<"At line no: "<<line_count<< " expression_statement : SEMICOLON"<<endl;

				$$ = new SymbolInfo();
			 	$$->setName( ";\n" );

				$$->code = "";

				logtxt<<endl<<$$->getName()<<endl<<endl;
			}		
			| expression SEMICOLON 
			{
				logtxt<<"At line no: "<<line_count<< " expression_statement : expression SEMICOLON"<<endl;
			
				$$ = new SymbolInfo();
			 	$$->setName( $1->getName() + ";\n" );
				logtxt<<endl<<$$->getName()<<endl<<endl;
				
				$$->code = $1->code;
				$$->symbol = $1->symbol;

				delete $1;
			}		
			;
	  
variable : ID
		{
			logtxt<<"At line no: "<<line_count<< " variable : ID"<<endl;
		
			$$ = new SymbolInfo();
		 	$$->setName( $1->getName() );

			SymbolInfo * tmp = symbol_table.LookUp($1->getName());
			if(tmp==0){
				//not declared variable : write error message
				errortxt<<"Error at line "<<line_count<<": Variable "<<$1->getName()<<" was not declared."<<endl;
				error_semantic++; errortxt<<endl;
			}
			else{
				//was declared as array but no [] in expression
				if(tmp->IDtype=="ARA"){
					errortxt<<"Error at line "<<line_count<<": Array subscript not found. Invalid conversion."<<endl;
					error_semantic++; errortxt<<endl;
				}
				$$->data_type = tmp->data_type;
			}


			logtxt<<endl<<$$->getName()<<endl<<endl;

			$$->IDtype = tmp->IDtype;
			$$->symbol = tmp->symbol;
			$$->code = "";

			delete $1;
		}
	 | ID LTHIRD expression RTHIRD 
	 {
		 logtxt<<"At line no: "<<line_count<< " variable : ID LTHIRD expression RTHIRD"<<endl;
	 
	 	$$ = new SymbolInfo();
	 	$$->setName( $1->getName() + "[" + $3->getName() + "]" );



		SymbolInfo * tmp = symbol_table.LookUp($1->getName());
		if(tmp==0){
			//not declared variable : write error message
			errortxt<<"Error at line "<<line_count<<": Variable "<<$1->getName()<<" was not declared."<<endl;
			error_semantic++; errortxt<<endl;
		}
		else {
			//was declared as variable but has [] 
			if(tmp->IDtype=="VAR"){
				errortxt<<"Error at line "<<line_count<<": Invalid subscript. Variable was not declared as array."<<endl;
				error_semantic++; errortxt<<endl;
			}
			$$->data_type = tmp->data_type;
		}
		
		string arr_idx_type = $3->data_type;
		if(arr_idx_type!="INT") {
			errortxt<<"Error at line "<<line_count<<": Index of array is not integer."<<endl;
			error_semantic++; errortxt<<endl;
		}

		logtxt<<endl<<$$->getName()<<endl<<endl;

		char * tmp_var = newTemp();

		//ax stores the offset . push ax -> this code -> mov ax , symbol[ax] -> work with ax -> pop ax
		$$->code = $3->code;
		$$->code += ("mov ax ,  " + $3->symbol + "\n");
		$$->code += ("add ax ,  ax\n");

		$$->IDtype = tmp->IDtype;
		$$->symbol = tmp->symbol;

		delete $1;
		delete $3;
	 }
	 ;
	 
 expression : logic_expression	
		{
			logtxt<<"At line no: "<<line_count<< " expression : logic_expression"<<endl;
		
			$$ = new SymbolInfo();
		 	$$->setName( $1->getName() );
			$$->data_type = $1->data_type;

			logtxt<<endl<<$$->getName()<<endl<<endl;

			$$->code = $1->code;
			$$->symbol = $1->symbol;

			delete $1;
		}
	   | variable ASSIGNOP logic_expression 	
	   {
		   logtxt<<"At line no: "<<line_count<< " expression : variable ASSIGNOP logic_expression"<<endl;
	   
	   		$$ = new SymbolInfo();
		 	$$->setName( $1->getName() + " = " + $3->getName() );

			//finally i am writing type mismatch error :|
			string type1 = $1->data_type;
			string type2 = $3->data_type;
			cout<<line_count<<": "<<type1<<" "<<type2<<endl;
			if(type2=="VOID"){
				errortxt<<"Error at line "<<line_count<<": Void function cannot be called as a  part of an expression."<<endl;
				error_semantic++; errortxt<<endl;
			}
			else if(type1!=type2){
				errortxt<<"Error at line "<<line_count<<": Type mismatch error."<<endl;
				error_semantic++; errortxt<<endl;
			}
			$$->data_type = $1->data_type;

			logtxt<<endl<<$$->getName()<<endl<<endl;

			char * tmp_var = newTemp();

			//as this is an expression ,  it will have symbol and that symbol must have a value set
			$$->symbol = string(tmp_var);

			string where = "";
			if($1->IDtype=="VAR"){ where = $1->symbol; }
			else if($1->IDtype=="ARA") { where = $1->symbol + "[si]"; }
			string additional_code_for_si = "";
			if($1->IDtype=="ARA"){ additional_code_for_si += ("mov si ,  ax\n");}

			$$->code = $3->code;
			//if($1->IDtype=="ARA"){ $$->code += ("push ax\n");} //as we are going to use ax as offset for array ,  and bx for value
			$$->code += ("mov bx ,  "+ $3->symbol + "\n");
			$$->code += $1->code;
			$$->code += (additional_code_for_si + "mov "+where + " ,  bx\n"); 
			$$->code += ("mov "+ string(tmp_var) + " ,  bx\n");
			//if($1->IDtype=="ARA"){ $$->code += ("pop ax\n");}
			

			delete $1;
			delete $3;
	   }
	   ;
			
logic_expression : rel_expression 	
		 {
			 logtxt<<"At line no: "<<line_count<< " logic_expression : rel_expression"<<endl;
		 
		 	$$ = new SymbolInfo();
		 	$$->setName( $1->getName() );
			$$->data_type = $1->data_type;
			 
			logtxt<<endl<<$$->getName()<<endl<<endl;

			$$->code = $1->code;
			$$->symbol = $1->symbol;

			delete $1;
		 }
		 | rel_expression LOGICOP rel_expression 	
		 {
			 logtxt<<"At line no: "<<line_count<< " logic_expression : rel_expression LOGICOP rel_expression"<<endl;
		 
		 	$$ = new SymbolInfo();
		 	$$->setName( $1->getName() + $2->getName() + $3->getName() );

			string type1 = $1->data_type;
			string type2 = $3->data_type;
			//cout<<type1<<endl<<type2<<endl<<endl;

			if(type1=="VOID" || type2=="VOID") {
				errortxt<<"Error at line "<<line_count<<": Void function cannot be called as a  part of an expression."<<endl;
				error_semantic++; errortxt<<endl;
			}

			//result of logicop is int
			$$->data_type = "INT";

			logtxt<<endl<<$$->getName()<<endl<<endl;

			char * tmp_var = newTemp();
			$$->symbol = string(tmp_var);

			char * make_zero = newLabel();
			char * make_one = newLabel();
			char * exit = newLabel();

			$$->code = $1->code + $3->code;

			if($2->getName()=="&&"){
				$$->code += ("mov ax ,  "+ $1->symbol + "\nmov bx ,  " + $3->symbol + "\n");

				$$->code += ("cmp ax ,  0\nje "+string(make_zero)+"\n");
				$$->code += ("cmp bx ,  0\nje "+string(make_zero)+"\n");
				
				$$->code += (string(make_one) + ":\n");
				$$->code += ("mov " + string(tmp_var) + " ,  1\n");
				$$->code += ("jmp " + string(exit)+ "\n");
				
				$$->code += (string(make_zero) + ":\n");
				$$->code += ("mov " + string(tmp_var) + " ,  0\n");
				
				$$->code += (string(exit)+ ":\n");
			}
			else if($2->getName()=="||"){
				$$->code += ("mov ax ,  "+ $1->symbol + "\nmov bx ,  " + $3->symbol + "\n");

				$$->code += ("cmp ax ,  0\njne "+string(make_one)+"\n");
				$$->code += ("cmp bx ,  0\njne "+string(make_one)+"\n");
				
				$$->code += (string(make_zero) + ":\n");
				$$->code += ("mov " + string(tmp_var) + " ,  0\n");
				$$->code += ("jmp " + string(exit)+ "\n");
				
				$$->code += (string(make_one) + ":\n");
				$$->code += ("mov " + string(tmp_var) + " ,  1\n");
				
				$$->code += (string(exit)+ ":\n");
			}

			delete $1;
			delete $2;
			delete $3;
		 }
		 ;
			
rel_expression	: simple_expression 
		{
			logtxt<<"At line no: "<<line_count<< " rel_expression : simple_expression"<<endl;
		
			$$ = new SymbolInfo();
		 	$$->setName( $1->getName() );

			$$->data_type = $1->data_type;

			logtxt<<endl<<$$->getName()<<endl<<endl;

/*
			char * tmp_var = newTemp();

			char * make_zero = newLabel();
			char * made_one = newLabel();

			$$->symbol = string(tmp_var);

			$$->code = $1->code;
			$$->code += ("mov ax ,  "+ $1->symbol + "\n");
			$$->code += ("cmp ax ,  0\n");
			$$->code += ("je " + string(make_zero) + "\n");
			$$->code += ("mov "+string(tmp_var)+" ,  1\n");
			$$->code += ("jmp "+ string(made_one) + "\n");
			$$->code += (string(make_zero) + ":\n");
			$$->code += ("mov "+string(tmp_var) + " ,  0\n");
			$$->code += (string(made_one) + ":\n");
*/
			$$->code = $1->code;
			$$->symbol = $1->symbol;

			delete $1;
		}
		| simple_expression RELOP simple_expression	
		{
			logtxt<<"At line no: "<<line_count<< " rel_expression : simple_expression RELOP simple_expression"<<endl;
		
			$$ = new SymbolInfo();
		 	$$->setName( $1->getName() + $2->getName() + $3->getName());

			string type1 = $1->data_type;
			string type2 = $3->data_type;
			//cout<<type1<<endl<<type2<<endl<<endl;

			if(type1=="VOID" || type2=="VOID") {
				errortxt<<"Error at line "<<line_count<<": Void function cannot be called as a  part of an expression."<<endl;
				error_semantic++; errortxt<<endl;
			}

			//result of relop is int
			$$->data_type = "INT";

			logtxt<<endl<<$$->getName()<<endl<<endl;


			char * tmp_var = newTemp();

			$$->symbol = string(tmp_var);

			char * make_zero = newLabel();
			char * made_one = newLabel();

			$$->code = $1->code + $3->code;
			$$->code += ("mov ax ,  " + $1->symbol + "\nmov bx ,  " + $3->symbol + "\n");
			$$->code += ("cmp ax ,  bx\n");
			
			string jump_decide; //will jump to zero_making_label
			if($2->getName() == "<"){
				jump_decide = "jge ";
			}
			else if($2->getName() == "<="){
				jump_decide = "jg ";
			}
			else if($2->getName() == ">"){
				jump_decide = "jle ";
			}
			else if($2->getName() == ">="){
				jump_decide = "jl ";
			}
			else if($2->getName() == "=="){
				jump_decide = "jne ";
			}
			else if($2->getName() == "!="){
				jump_decide = "je ";
			}

			$$->code += (jump_decide + string(make_zero)+ "\n");
			$$->code += ("mov "+string(tmp_var) + " ,  1\n");
			$$->code += ("jmp "+string(made_one)+"\n");
			$$->code += (string(make_zero) + ":\n");
			$$->code += ("mov "+string(tmp_var) + " ,  0\n");
			$$->code += (string(made_one)+":\n");

			delete $1;
			delete $2;
			delete $3;
		}
		;
				
simple_expression : term 
			{
				logtxt<<"At line no: "<<line_count<< " simple_expression : term"<<endl;
			
				$$ = new SymbolInfo();
			 	$$->setName( $1->getName() );

				$$->data_type = $1->data_type;

				logtxt<<endl<<$$->getName()<<endl<<endl;

				$$->code = $1->code;
				$$->symbol = $1->symbol;

				delete $1;
			}
		  | simple_expression ADDOP term 
		  {
			  logtxt<<"At line no: "<<line_count<< " simple_expression : simple_expression ADDOP term"<<endl;
		  
		  	$$ = new SymbolInfo();
		 	$$->setName( $1->getName() + $2->getName() + $3->getName() );

			string type1 = $1->data_type;
			string type2 = $3->data_type;

			//propagating void data type
			if(type1=="VOID" || type2=="VOID") $$->data_type = "VOID";
			//keu void na ,  so float thakle float
			else if(type1=="FLOAT" || type2=="FLOAT") $$->data_type = "FLOAT";
			//void or float nai ,  int
			else $$->data_type = type1;

			logtxt<<endl<<$$->getName()<<endl<<endl;

			char * tmp_var = newTemp();
			$$->symbol = string(tmp_var);

			$$->code = $1->code + $3->code;
			$$->code += ("mov ax ,  "+$1->symbol + "\n" + "mov bx ,  "+$3->symbol+"\n");
			if($2->getName()=="+") {
				$$->code += ("add ax ,  bx\n");
			}
			else {
				$$->code += ("sub ax ,  bx\n");
			}
			$$->code += ("mov "+string(tmp_var) + " ,  ax\n");
			
			delete $1;
			delete $2;
			delete $3;
		  }
		  ;
					
term :	unary_expression
		{
			logtxt<<"At line no: "<<line_count<< " term : unary_expression"<<endl;

			$$ = new SymbolInfo();
		 	$$->setName( $1->getName() );

			$$->data_type = $1->data_type;

			logtxt<<endl<<$$->getName()<<endl<<endl;

			$$->code = $1->code;
			$$->symbol = $1->symbol;

			delete $1;
		}
     |  term MULOP unary_expression
	 {
		 logtxt<<"At line no: "<<line_count<< " term : term MULOP unary_expression"<<endl;

		$$ = new SymbolInfo();
	 	$$->setName( $1->getName() + $2->getName() + $3->getName() );

		string type1 = $1->data_type;
		string type2 = $3->data_type;

		if($2->getName()=="%" && (type1!="INT" || type2!="INT")){
			//a%b ,  both a b must be int
			errortxt<<"Error at line "<<line_count<<": Non-integer operand of modulus operator."<<endl;
			error_semantic++; errortxt<<endl;
		}


		//propagating void data type
		if(type1=="VOID" || type2=="VOID") $$->data_type = "VOID";
		//keu void na ,  so float thakle float
		else if(type1=="FLOAT" || type2=="FLOAT") $$->data_type = "FLOAT";
		//void or float nai ,  int
		else $$->data_type = type1;

		logtxt<<endl<<$$->getName()<<endl<<endl;

		char * tmp_var = newTemp();
		$$->symbol = string(tmp_var);

		$$->code = $1->code + $3->code;

		$$->code += ("mov ax ,  "+ $1->symbol + "\n");
		$$->code += ("mov bx ,  "+ $3->symbol + "\n");
		
		if($2->getName()=="*"){
			$$->code += ("mul bx\nmov " +string(tmp_var) + " ,  ax\n");
		}
		else if($2->getName()=="/"){
			$$->code += ("xor dx , dx\ndiv bx\nmov " + string(tmp_var) + " ,  ax\n");
		}
		else if($2->getName()=="%"){
			$$->code += ("xor dx , dx\ndiv bx\nmov " + string(tmp_var) + " ,  dx\n");
		}
		

		delete $1;
		delete $2;
		delete $3;
	 }
     ;

unary_expression : ADDOP unary_expression  
			{
				logtxt<<"At line no: "<<line_count<< " unary_expression : ADDOP unary_expression"<<endl;

				$$ = new SymbolInfo();
			 	$$->setName( $1->getName() + $2->getName() );

				$$->data_type = $2->data_type;

				logtxt<<endl<<$$->getName()<<endl<<endl;

				char * tmp_var = newTemp();

				$$->symbol = string(tmp_var);

				$$->code = $2->code;
				$$->code += ("mov ax ,  "+ $2->symbol + "\n");
				$$->code += ("mov "+ string(tmp_var) + " ,  ax\n");
				if($1->getName()=="-") $$->code += ("neg "+string(tmp_var) + "\n");

				delete $1;
				delete $2;
			}
		 | NOT unary_expression 
		 {
			 logtxt<<"At line no: "<<line_count<< " unary_expression : NOT unary_expression"<<endl;
		 
		 	$$ = new SymbolInfo();
		 	$$->setName( "!" + $2->getName() );

			//BUG error handling needed : operand should be int : if void keep it ,  if float convert it to int
			$$->data_type = $2->data_type;

			logtxt<<endl<<$$->getName()<<endl<<endl;

			char * make_one = newLabel();
			char * made_zero = newLabel();

			char * tmp_var = newTemp();

			$$->symbol = string(tmp_var);

			$$->code = $2->code;
			$$->code += ("mov ax ,  " + $2->symbol + "\n");
			$$->code += ("cmp ax ,  0\n");
			$$->code += ("je "+string(make_one)+"\n");
			$$->code += ("mov "+string(tmp_var) + " ,  0\n");
			$$->code += ("jmp "+ string(made_zero)+"\n");
			$$->code += (string(make_one) + ":\n");
			$$->code += ("mov "+string(tmp_var)+ " ,  1\n");
			$$->code += (string(made_zero) + ":\n");

			delete $2;
		 }
		 | factor 
		 {
			 logtxt<<"At line no: "<<line_count<< " unary_expression : factor"<<endl;
		 
		 	$$ = new SymbolInfo();
		 	$$->setName( $1->getName() );

			$$->data_type = $1->data_type;

			logtxt<<endl<<$$->getName()<<endl<<endl;

			$$->code = $1->code;
			$$->symbol = $1->symbol;

			delete $1;
		 }
		 ;
	
factor	: variable 
		{
			logtxt<<"At line no: "<<line_count<< " factor : variable"<<endl;
		
			$$ = new SymbolInfo();
		 	$$->setName( $1->getName() );

			//$$->IDtype = $1->IDtype;
			$$->data_type = $1->data_type;

			logtxt<<endl<<$$->getName()<<endl<<endl;


			char * tmp_var = newTemp();
			$$->symbol = string(tmp_var);


			string where = "";
			if($1->IDtype=="VAR"){ where = $1->symbol; }
			else if($1->IDtype=="ARA") { where = $1->symbol + "[si]"; }
			string additional_code_for_si = "";
			if($1->IDtype== "ARA") {additional_code_for_si += ("mov si ,  ax\n");}

			//if($1->IDtype=="ARA"){ $$->code += ("push ax\n");} //as we are going to use ax as offset for array ,  and bx for value
			$$->code += $1->code;
			$$->code += (additional_code_for_si + "mov bx ,  "+where+"\n"); 
			$$->code += ("mov "+ string(tmp_var) + " ,  bx\n");
			//if($1->IDtype=="ARA"){ $$->code += ("pop ax\n");}

			
			delete $1;
		}
	| ID LPAREN { args_of_func_call.clear(); symbols_of_func_call.clear(); } argument_list RPAREN
	{
		logtxt<<"At line no: "<<line_count<< " factor : ID LPAREN argument_list RPAREN"<<endl;



		$$ = new SymbolInfo();

	 	$$->setName( $1->getName() + "(" + $4->getName() + ")" );

		SymbolInfo * tmp = symbol_table.LookUp($1->getName());

		//cout<<tmp->getName()<<" "<<tmp->return_type<<endl<<endl;;
		
		if(tmp==0){
			//write code here : not declared id 
			errortxt<<"Error at line "<<line_count<<": Function "<<$1->getName()<<"(...) was not declared."<<endl;
			error_semantic++; errortxt<<endl;
		}
		else {

			$$->data_type = tmp->return_type;
		
			//function call : check if 
					//ID is a function
					//arglist matches with parameter_list

			//checking IDtype of tmp
			if(tmp->IDtype!="FUNC"){
				errortxt<<"Error at line "<<line_count<<": Function call cannot be made with non-function type identifier."<<endl;
				error_semantic++; errortxt<<endl;
				//just to avoid type mismatch error as we already reported one here ^^^
				$$->data_type = tmp->data_type;
			}
			//argument mismatch
			else{
				int len_tmp = tmp->parameter_list.size();
				int len_arg = args_of_func_call.size();
				if(len_tmp!=len_arg){
					errortxt<<"Error at line "<<line_count<<": Number of arguments of function call is not consistent with the definition."<<endl;
					error_semantic++; errortxt<<endl;
				}
				else{
					for(int i = 0; i<len_arg; i++){
						if(args_of_func_call[i]!=tmp->parameter_list[i]){
							errortxt<<"Error at line "<<line_count<<": Types of arguments of function call is not consistent with the definition."<<endl;
							error_semantic++; errortxt<<endl;
							break;
						}
					}
				}
			}
		}

		

		//cout<<$$->data_type<<endl<<endl;

		logtxt<<endl<<$$->getName()<<endl<<endl;

		char * tmp_var = newTemp();

		$$->symbol = string(tmp_var);

		$$->code = "";
		$$->code += "push ax\npush bx\npush cx\npush dx\n";
		$$->code += $4->code;

		for(int i = symbols_of_func_call.size() - 1; i>=0; i--){
			$$->code += ("push "+symbols_of_func_call[i]+"\n");
		}
		$$->code += ("call " + $1->getName() + "\n");

		if(tmp->return_type != "VOID"){
			$$->code += ("pop "+ string(tmp_var) + "\n");
		}

		$$->code += "pop dx\npop cx\npop bx\npop ax\n";

		delete $1;
		delete $4;
	}
	| LPAREN expression RPAREN
	{
		logtxt<<"At line no: "<<line_count<< " factor : LPAREN expression RPAREN"<<endl;
	
		$$ = new SymbolInfo();
	 	$$->setName( "(" + $2->getName() + ")" );
		
		$$->data_type = $2->data_type;

		logtxt<<endl<<$$->getName()<<endl<<endl;

		$$->code = $2->code;
		$$->symbol = $2->symbol;

		delete $2;
	}
	| CONST_INT 
	{
		logtxt<<"At line no: "<<line_count<< " factor : CONST_INT"<<endl;
	
		$$ = new SymbolInfo();
	 	$$->setName( $1->getName() );

		$$->data_type = "INT";

		logtxt<<endl<<$$->getName()<<endl<<endl;

		char * tmp_var = newTemp();
		$$->symbol = string(tmp_var);
		$$->code = "mov "+ string(tmp_var)+ " ,  "+ $1->getName() + "\n";

		delete $1;
	}
	| CONST_FLOAT
	{
		logtxt<<"At line no: "<<line_count<< " factor : CONST_FLOAT"<<endl;
	
		$$ = new SymbolInfo();
		$$->setName( $1->getName() );

		$$->data_type = "FLOAT";

		logtxt<<endl<<$$->getName()<<endl<<endl;

		char * tmp_var = newTemp();
		$$->symbol = string(tmp_var);
		$$->code = "mov "+ string(tmp_var)+ " ,  "+ $1->getName() + "\n";

		delete $1;
	}
	| variable INCOP 
	{
		logtxt<<"At line no: "<<line_count<< " factor : variable INCOP"<<endl;
	
		$$ = new SymbolInfo();
	 	$$->setName( $1->getName() + "++" );

		$$->data_type = $1->data_type;

		logtxt<<endl<<$$->getName()<<endl<<endl;

		char * tmp_var = newTemp();

		$$->symbol = string(tmp_var);

		string where = "";
		if($1->IDtype=="VAR"){ where = $1->symbol; }
		else if($1->IDtype=="ARA") { where = $1->symbol + "[si]"; }
		string additional_code_for_si = "";
		if($1->IDtype=="ARA"){ additional_code_for_si += ("mov si ,  ax\n");}
		
		$$->code += $1->code;
		$$->code += (additional_code_for_si + "mov bx ,  "+ where + "\n" );
		$$->code += ("mov " + string(tmp_var) + " ,  bx\n");
		$$->code += ("inc " + where + "\n") ;

		delete $1;
	}
	| variable DECOP
	{
		logtxt<<"At line no: "<<line_count<< " factor : variable DECOP"<<endl;
	
		$$ = new SymbolInfo();
		$$->setName( $1->getName() + "--");

		$$->data_type = $1->data_type;

		logtxt<<endl<<$$->getName()<<endl<<endl;

		char * tmp_var = newTemp();

		$$->symbol = string(tmp_var);

		string where = "";
		if($1->IDtype=="VAR"){ where = $1->symbol; }
		else if($1->IDtype=="ARA") { where = $1->symbol + "[si]"; }
		string additional_code_for_si = "";
		if($1->IDtype=="ARA"){ additional_code_for_si += ("mov si ,  ax\n");}
			
		$$->code += $1->code;
		$$->code += (additional_code_for_si + "mov bx ,  "+ where + "\n" );
		$$->code += ("mov " + string(tmp_var) + " ,  bx\n");
		$$->code += ("dec " + where + "\n") ;


		delete $1;
	}
	;
	
argument_list : arguments
				{
					logtxt<<"At line no: "<<line_count<< " argument_list : arguments"<<endl;
				
					$$ = new SymbolInfo();
					$$->setName( $1->getName() );
					logtxt<<endl<<$$->getName()<<endl<<endl;

					$$->code = $1->code;

					delete $1;
				}
			  |
			  {
				  logtxt<<"At line no: "<<line_count<< " argument_list : arguments"<<endl;

				  $$ = new SymbolInfo();
				  $$->setName("");
				  logtxt<<endl<<$$->getName()<<endl<<endl; 
			  }
			  ;
	
arguments : arguments COMMA logic_expression
			{
				logtxt<<"At line no: "<<line_count<< " arguments : arguments COMMA logic_expression"<<endl;
			
				$$ = new SymbolInfo();
				$$->setName( $1->getName() + " ,  " + $3->getName() );

				args_of_func_call.push_back($3->data_type);
				symbols_of_func_call.push_back($3->symbol);


				
				logtxt<<endl<<$$->getName()<<endl<<endl;

				$$->code = $1->code + $3->code;

				delete $1;
				delete $3;
			}
	      | logic_expression
		  {
			  logtxt<<"At line no: "<<line_count<< " arguments : logic_expression"<<endl;
		  
		  		$$ = new SymbolInfo();
				$$->setName( $1->getName() );

				args_of_func_call.push_back($1->data_type);
				symbols_of_func_call.push_back($1->symbol);

				logtxt<<endl<<$$->getName()<<endl<<endl;

				$$->code = $1->code;

				delete $1;
		  }
	      ;
 

%%
int main(int argc , char *argv[])
{
	FILE * fp;

	if((fp=fopen(argv[1] , "r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	//fp2= fopen(argv[2] , "w");
	//fclose(fp2);
	//fp3= fopen(argv[3] , "w");
	//fclose(fp3);
	
	//fp2= fopen(argv[2] , "a");
	//fp3= fopen(argv[3] , "a");

	logtxt.open("1505021Log.txt");
	errortxt.open("1505021Error.txt");
	code_gen.open("code.asm");

	yyin=fp;
	yyparse();
	
	logtxt.close();
	errortxt.close();
	code_gen.close();

	//fclose(fp2);
	//fclose(fp3);
	
	return 0;
}