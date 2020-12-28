#include <iostream>
#include <string>
#include <cstdio>
#include <vector>

using namespace std;

#define dbug cout<<"REACHED"<<endl
#define halt while(1)
#define default_scopeTable_size 100

//unique id to be given to scopetables
////int scopetable_id = 0;
//Show input in the output file/console
////bool show_inp = false;

class SymbolInfo
{
    string name, type;
public:
    string IDtype; //done --- Variable, Array or Function "VAR", "ARA", "FUNC"
    
    //for variable and array
    string data_type; //done --- for VAR and ARA : "INT" "CHAR" "FLOAT"

    //for array
    int ara_size; //done

    //for functions 
    bool func_defined;
    string return_type; //done "CHAR", "INT", "FLOAT", "VOID"
    vector<string> parameter_list; //done --- list of "CHAR", "INT", "FLOAT" 
    //^BUG------declare korar por define korle param list abar input ney, so insert successful kina check kore tarpor param list insert hobe
    
    SymbolInfo * next;
//
    SymbolInfo();
    SymbolInfo(string nam, string typ);
    void setName(string s);
    void setType(string s);
    string getName();
    string getType();
};

class ScopeTable
{
    SymbolInfo ** bucket_head;
    int bucket_sz;
    int hash_func(string key);
public:
    int unique_id;
    ScopeTable * parentScope;
    ScopeTable(int n);
    ~ScopeTable();
    bool Insert(string name, string type);
    SymbolInfo * LookUp(string symbol);
    bool Delete(string symbol);
    void print(ofstream& fp);
};


class SymbolTable
{
    //vector<ScopeTable> symTable;
    int bucket_size;
public:
    ScopeTable * currScopeTable;
    SymbolTable(int n);
    void EnterScope();
    void ExitScope();
    bool Insert(string name, string type);
    bool Remove(string symbol);
    SymbolInfo * LookUp(string symbol);
    SymbolInfo * LookUpCurrScopeTable(string symbol);
    void printCurrScopeTable(ofstream& fp);
    void printAllScopeTable(ofstream& fp);
};
