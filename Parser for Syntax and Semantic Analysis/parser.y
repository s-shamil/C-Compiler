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

vector<string> param_ID_yet_to_insert; //SPECIAL CASE : "-1" for func defin/decl like f(int a, int) -> ekhane name "-1" diye rakhbo, symboltable e insert korbo na - just to make sure idtype_param consistent thake

vector<string> idtype_param_ID_yet_to_insert; //var

vector<string> datatype_param_ID_yet_to_insert; //VAR - "INT" "FLOAT" "VOID" 

vector<string> args_of_func_call; //storing datatypes of arguments of a func call

string ongoing_data_type; //whenever i find a type specifier i am storing here : will add $$->data_type for type specifier and use it later


ofstream logtxt, errortxt;

void yyerror(const char *s)
{
	//write your code

	errortxt<<"Error at line "<<line_count<<": "<<string(s)<<endl;
	errortxt<<endl; error_semantic++;
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

%type <symbol_info> program unit func_declaration func_definition parameter_list compound_statement var_declaration type_specifier declaration_list statements statement expression_statement variable expression logic_expression rel_expression simple_expression term unary_expression factor argument_list arguments

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
	}
	;

program : program unit 
	{
		logtxt<<"At line no: "<<line_count<< " program : program unit"<<endl;
		
		$$ = new SymbolInfo();
		$$->setName( $1->getName() + $2->getName());
		logtxt<<endl<<$$->getName()<<endl<<endl;

		delete $1;
		delete $2;
		
	}
	| unit
	{
		logtxt<<"At line no: "<<line_count<< " program : unit"<<endl;
		
		$$ = new SymbolInfo();
		$$->setName( $1->getName() );
		logtxt<<endl<<$$->getName()<<endl<<endl;
		
		delete $1;
	}
	;
	
unit : var_declaration
		{
			logtxt<<"At line no: "<<line_count<< " unit : var_declaration"<<endl;

			$$ = new SymbolInfo();
			$$->setName( $1->getName() );
			logtxt<<endl<<$$->getName()<<endl<<endl;

			delete $1;
		}
     | func_declaration
	 {
		 logtxt<<"At line no: "<<line_count<< " unit : func_declaration"<<endl;

		 $$ = new SymbolInfo();
	 	$$->setName( $1->getName() );
		logtxt<<endl<<$$->getName()<<endl<<endl;

		delete $1;
	 }
     | func_definition
	 {
		 logtxt<<"At line no: "<<line_count<< " unit : func_definition"<<endl;

		$$ = new SymbolInfo();
	 	$$->setName( $1->getName() );
		logtxt<<endl<<$$->getName()<<endl<<endl;

		delete $1;
	 }
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
		{
			
			logtxt<<"At line no: "<<line_count<< " func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON"<<endl;
		
			$$ = new SymbolInfo();
	 		$$->setName( $1->getName() + $2->getName() + "(" + $4->getName() + ")" + ";\n" );
			logtxt<<endl<<$$->getName()<<endl<<endl;
		
			bool flag = symbol_table.Insert( $2->getName() , "ID");

			if(flag){
				//inserted, so totally new - setting up other attributes
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
		
			bool flag = symbol_table.Insert( $2->getName() , "ID");

			if(flag){
				//inserted, so totally new - setting up other attributes
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
			//clearing param_ID_yet_to_insert as they are no more needed - not needed probably, just being over cautious	
			param_ID_yet_to_insert.clear();
			idtype_param_ID_yet_to_insert.clear();
			datatype_param_ID_yet_to_insert.clear();

			delete $1;
			delete $2;
		}
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN 
						{
							bool flag = symbol_table.Insert( $2->getName() , "ID");

							if(flag){
								//inserted, so totally new, setting up other attributes
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
									//1. already exists declaration, but not defined - fine but check if consistent
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
			
			delete $1;
			delete $2;
			delete $4;
			delete $7;
		}
		| type_specifier ID LPAREN RPAREN 
		
					{
						bool flag = symbol_table.Insert( $2->getName() , "ID");

						if(flag){
							//inserted, so totally new, setting up other attributes
							SymbolInfo * si = symbol_table.LookUp($2->getName());
							si->IDtype = "FUNC";
							si->return_type = $1->data_type;
							//no param list
							si->func_defined = true;
						}
						else{
							//three possible cases
								//0. globar variable declared - error
								//1. already exists declaration, but not defined - fine
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

			delete $1;
			delete $2;
			delete $6;
		}
 		;				


parameter_list  : parameter_list COMMA type_specifier ID
		{
			logtxt<<"At line no: "<<line_count<< " parameter_list  : parameter_list COMMA type_specifier ID"<<endl;

			$$ = new SymbolInfo();
		 	$$->setName( $1->getName() + ", " + $3->getName() + $4->getName() );
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
		 	$$->setName( $1->getName() + ", " + $3->getName() );
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
							symbol_table.EnterScope();
							for(int i = 0; i<param_ID_yet_to_insert.size(); i++){
								if(param_ID_yet_to_insert[i] != "-1"){
									//check needed for Multiple declaration of samne variable in this scope 
									//check if insertion successful
									bool flag = symbol_table.Insert(param_ID_yet_to_insert[i], "ID");
									if(flag){
										SymbolInfo * si = symbol_table.LookUp(param_ID_yet_to_insert[i]);
										si->IDtype = idtype_param_ID_yet_to_insert[i];
										si->data_type = datatype_param_ID_yet_to_insert[i];
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

				symbol_table.printAllScopeTable(logtxt);
				symbol_table.ExitScope();

				delete $3;
			}
 		    | LCURL
			 	{
					symbol_table.EnterScope();
					for(int i = 0; i<param_ID_yet_to_insert.size(); i++){
						//symbol_table.Insert(param_ID_yet_to_insert[i], "ID");
						if(param_ID_yet_to_insert[i] != "-1"){
							//check for Multiple declaration of samne variable in this scope 
							//check if insertion successful
							bool flag = symbol_table.Insert(param_ID_yet_to_insert[i], "ID");
							if(flag){
								SymbolInfo * si = symbol_table.LookUp(param_ID_yet_to_insert[i]);
								si->IDtype = idtype_param_ID_yet_to_insert[i];
								si->data_type = datatype_param_ID_yet_to_insert[i];
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
				$$->setName( $1->getName() + ", " + $3->getName() );
				logtxt<<endl<<$$->getName()<<endl<<endl;

				bool flag = symbol_table.Insert( $3->getName() , "ID");

				if(flag){
					SymbolInfo * si = symbol_table.LookUp( $3->getName() );
					si->IDtype = "VAR";
					si->data_type = ongoing_data_type;
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
			    $$->setName( $1->getName() + ", " + $3->getName() + "[" + $5->getName() + "]" );
				logtxt<<endl<<$$->getName()<<endl<<endl;

				bool flag = symbol_table.Insert( $3->getName() , "ID");

				if(flag){
					SymbolInfo * si = symbol_table.LookUp( $3->getName() );
					si->IDtype = "ARA";
					si->data_type = ongoing_data_type;
					si->ara_size = atoi(($5->getName()).c_str());		
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

				bool flag = symbol_table.Insert( $1->getName() , "ID");
				if(flag){
					SymbolInfo * si = symbol_table.LookUp( $1->getName() );
					si->IDtype = "VAR";
					si->data_type = ongoing_data_type;		
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
		   
		   		bool flag = symbol_table.Insert( $1->getName() , "ID");
				if(flag){
					SymbolInfo * si = symbol_table.LookUp( $1->getName() );
					si->IDtype = "ARA";
					si->data_type = ongoing_data_type;
					si->ara_size = atoi(($3->getName()).c_str());
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

			delete $1;
		}
	   | statements statement
	   {
		   logtxt<<"At line no: "<<line_count<< " statements : statements statement"<<endl;
	   
	   		$$ = new SymbolInfo();
		 	$$->setName( $1->getName() + $2->getName() );
			logtxt<<endl<<$$->getName()<<endl<<endl;

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

			delete $1;
		}
	  | expression_statement
		{
			logtxt<<"At line no: "<<line_count<< " statement : expression_statement"<<endl;
		
			$$ = new SymbolInfo();
		 	$$->setName( $1->getName() );
			logtxt<<endl<<$$->getName()<<endl<<endl;

			delete $1;
		}
	  | compound_statement
		{
			logtxt<<"At line no: "<<line_count<< " statement : compound_statement"<<endl;
		
			$$ = new SymbolInfo();
		 	$$->setName( $1->getName() );
			logtxt<<endl<<$$->getName()<<endl<<endl;

			delete $1;
		}
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
		{
			logtxt<<"At line no: "<<line_count<< " statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement"<<endl;
		
			$$ = new SymbolInfo();
		 	$$->setName( "for(" + $3->getName() + $4->getName() + $5->getName() + ")" + $7->getName() );
			logtxt<<endl<<$$->getName()<<endl<<endl;

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

			delete $3;
			delete $6;
		}
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
		{
			logtxt<<"At line no: "<<line_count<< " statement : PRINTLN LPAREN ID RPAREN SEMICOLON"<<endl;
		
			$$ = new SymbolInfo();
		 	$$->setName( "println(" + $3->getName() + ");\n" );
			logtxt<<endl<<$$->getName()<<endl<<endl;

			delete $3;
		}
	  | RETURN expression SEMICOLON
		{
			logtxt<<"At line no: "<<line_count<< " statement : RETURN expression SEMICOLON"<<endl;
		
			$$ = new SymbolInfo();
		 	$$->setName( "return " + $2->getName() + ";\n" );
			logtxt<<endl<<$$->getName()<<endl<<endl;

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
				logtxt<<endl<<$$->getName()<<endl<<endl;
			}		
			| expression SEMICOLON 
			{
				logtxt<<"At line no: "<<line_count<< " expression_statement : expression SEMICOLON"<<endl;
			
				$$ = new SymbolInfo();
			 	$$->setName( $1->getName() + ";\n" );
				logtxt<<endl<<$$->getName()<<endl<<endl;
				
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
			//keu void na, so float thakle float
			else if(type1=="FLOAT" || type2=="FLOAT") $$->data_type = "FLOAT";
			//void or float nai, int
			else $$->data_type = type1;

			logtxt<<endl<<$$->getName()<<endl<<endl;

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
			//a%b, both a b must be int
			errortxt<<"Error at line "<<line_count<<": Non-integer operand of modulus operator."<<endl;
			error_semantic++; errortxt<<endl;
		}


		//propagating void data type
		if(type1=="VOID" || type2=="VOID") $$->data_type = "VOID";
		//keu void na, so float thakle float
		else if(type1=="FLOAT" || type2=="FLOAT") $$->data_type = "FLOAT";
		//void or float nai, int
		else $$->data_type = type1;

		logtxt<<endl<<$$->getName()<<endl<<endl;

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

				delete $1;
				delete $2;
			}
		 | NOT unary_expression 
		 {
			 logtxt<<"At line no: "<<line_count<< " unary_expression : NOT unary_expression"<<endl;
		 
		 	$$ = new SymbolInfo();
		 	$$->setName( "!" + $2->getName() );

			//BUG error handling needed : operand should be int : if void keep it, if float convert it to int
			$$->data_type = $2->data_type;

			logtxt<<endl<<$$->getName()<<endl<<endl;

			delete $2;
		 }
		 | factor 
		 {
			 logtxt<<"At line no: "<<line_count<< " unary_expression : factor"<<endl;
		 
		 	$$ = new SymbolInfo();
		 	$$->setName( $1->getName() );

			$$->data_type = $1->data_type;

			logtxt<<endl<<$$->getName()<<endl<<endl;

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

			delete $1;
		}
	| ID LPAREN { args_of_func_call.clear(); } argument_list RPAREN
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

		delete $2;
	}
	| CONST_INT 
	{
		logtxt<<"At line no: "<<line_count<< " factor : CONST_INT"<<endl;
	
		$$ = new SymbolInfo();
	 	$$->setName( $1->getName() );

		$$->data_type = "INT";

		logtxt<<endl<<$$->getName()<<endl<<endl;

		delete $1;
	}
	| CONST_FLOAT
	{
		logtxt<<"At line no: "<<line_count<< " factor : CONST_FLOAT"<<endl;
	
		$$ = new SymbolInfo();
		$$->setName( $1->getName() );

		$$->data_type = "FLOAT";

		logtxt<<endl<<$$->getName()<<endl<<endl;

		delete $1;
	}
	| variable INCOP 
	{
		logtxt<<"At line no: "<<line_count<< " factor : variable INCOP"<<endl;
	
		$$ = new SymbolInfo();
	 	$$->setName( $1->getName() + "++" );

		$$->data_type = $1->data_type;

		logtxt<<endl<<$$->getName()<<endl<<endl;

		delete $1;
	}
	| variable DECOP
	{
		logtxt<<"At line no: "<<line_count<< " factor : variable DECOP"<<endl;
	
		$$ = new SymbolInfo();
		$$->setName( $1->getName() + "--");

		$$->data_type = $1->data_type;

		logtxt<<endl<<$$->getName()<<endl<<endl;

		delete $1;
	}
	;
	
argument_list : arguments
				{
					logtxt<<"At line no: "<<line_count<< " argument_list : arguments"<<endl;
				
					$$ = new SymbolInfo();
					$$->setName( $1->getName() );
					logtxt<<endl<<$$->getName()<<endl<<endl;

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
				$$->setName( $1->getName() + ", " + $3->getName() );

				args_of_func_call.push_back($3->data_type);
				
				logtxt<<endl<<$$->getName()<<endl<<endl;

				delete $1;
				delete $3;
			}
	      | logic_expression
		  {
			  logtxt<<"At line no: "<<line_count<< " arguments : logic_expression"<<endl;
		  
		  		$$ = new SymbolInfo();
				$$->setName( $1->getName() );

				args_of_func_call.push_back($1->data_type);

				logtxt<<endl<<$$->getName()<<endl<<endl;

				delete $1;
		  }
	      ;
 

%%
int main(int argc,char *argv[])
{
	FILE * fp;

	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	//fp2= fopen(argv[2],"w");
	//fclose(fp2);
	//fp3= fopen(argv[3],"w");
	//fclose(fp3);
	
	//fp2= fopen(argv[2],"a");
	//fp3= fopen(argv[3],"a");

	logtxt.open("1505021Log.txt");
	errortxt.open("1505021Error.txt");

	yyin=fp;
	yyparse();
	
	logtxt.close();
	errortxt.close();

	//fclose(fp2);
	//fclose(fp3);
	
	return 0;
}