#include <iostream>
#include <string>
#include <cstdio>
#include <fstream>
#include "1505021_SymbolTable.h"
//#include <vector>

using namespace std;

#define dbug cout<<"REACHED"<<endl
#define halt while(1)
#define default_scopeTable_size 100

//unique id to be given to scopetables
int scopetable_id = 0;
//Show input in the output file/console
bool show_inp = false;
//
//class SymbolInfo
//{
//    string name, type;
//public:
//
//    SymbolInfo * next;
////
//    SymbolInfo()
//    {
//        this->name = "xxx";
//        this->type = "";
//        this->next = 0;
//    }
//    SymbolInfo(string nam, string typ)
//    {
//        this->name = nam;
//        this->type = typ;
//        this->next = 0;
//    }
//    void setName(string s)
//    {
//        this->name = s;
//    }
//    void setType(string s)
//    {
//        this->type = s;
//    }
//    string getName()
//    {
//        return this->name;
//    }
//    string getType()
//    {
//        return this->type;
//    }
//};

SymbolInfo::SymbolInfo()
{
    this->name = "";
    this->type = "";
    this->next = 0;
    this->ara_size = 0;
    this->func_defined = false;
}

SymbolInfo::SymbolInfo(string nam, string typ)
{
    this->name = nam;
    this->type = typ;
    this->next = 0;
    this->ara_size = 0;
    this->func_defined = false;
}

void SymbolInfo::setName(string s)
{
    this->name = s;
}
void SymbolInfo::setType(string s)
{
    this->type = s;
}
string SymbolInfo::getName()
{
    return this->name;
}
string SymbolInfo::getType()
{
    return this->type;
}


//class ScopeTable
//{
//    SymbolInfo ** bucket_head;
//    int bucket_sz;
//    int unique_id;
//    int hash_func(string key);
//public:
//    ScopeTable * parentScope;
//    ScopeTable(int n);
//    ~ScopeTable();
//    bool Insert(string name, string type);
//    SymbolInfo * LookUp(string symbol);
//    bool Delete(string symbol);
//    void print(FILE *fp);
//};

ScopeTable::ScopeTable(int n)
{
    bucket_sz = n;
    unique_id = ++scopetable_id;
    bucket_head = new SymbolInfo*[bucket_sz];
    for(int i = 0 ; i<bucket_sz; i++)
    {
        bucket_head[i] = new SymbolInfo;
    }
    //cout<<"New ScopeTable with id "<<this->unique_id<<" created"<<endl;
}

ScopeTable::~ScopeTable()
{
    for(int i = 0 ; i<bucket_sz; i++)
    {
        delete bucket_head[i];
    }
    delete [] bucket_head;
}

int ScopeTable::hash_func(string key)
{
    unsigned long long hash_idx = 5381;
    int len = key.length();
    for(int i = 0; i<len; i++)
    {
        hash_idx = (((hash_idx<<5)+hash_idx)^key[i]); /* hash * 33 ^ c */
    }
    return hash_idx%bucket_sz;
}

bool ScopeTable::Insert(string name, string type)
{
    int hash_idx = this->hash_func(name);
    SymbolInfo * prev = this->bucket_head[hash_idx];
    SymbolInfo * curr = prev->next;
    int pos = 0;
    while(curr!=0)
    {
        string key = curr->getName();
        if(key==name)
        {
            cout<<"<"<<name<<","<<type<<"> already exists in current ScopeTable"<<endl;
            return false;
        }
        prev = curr;
        curr = curr->next;
        pos++;
    }
    SymbolInfo * newSymbol;
    newSymbol = new SymbolInfo;
    newSymbol->setName(name);
    newSymbol->setType(type);
    newSymbol->next = 0;
    prev->next = newSymbol;
    cout<<"Inserted in ScopeTable# "<<this->unique_id<<" at position "<<hash_idx<<", "<<pos<<endl;
    return true;
}

SymbolInfo * ScopeTable::LookUp(string symbol)
{
    int hash_idx = this->hash_func(symbol);
    SymbolInfo * prev = this->bucket_head[hash_idx];
    SymbolInfo * curr = prev->next;
    int pos = 0;
    while(curr!=0)
    {
        string key = curr->getName();
        if(key==symbol)
        {
            cout<<"Found in ScopeTable# "<<this->unique_id<<" at position "<<hash_idx<<", "<<pos<<endl;
            return curr;
        }
        prev = curr;
        curr = curr->next;
        pos++;
    }
    //cout<<"Not found"<<endl;
    return curr;
}

bool ScopeTable::Delete(string symbol)
{
    int hash_idx = this->hash_func(symbol);
    SymbolInfo * prev = this->bucket_head[hash_idx];
    SymbolInfo * curr = prev->next;
    int pos = 0;
    while(curr!=0)
    {
        string key = curr->getName();
        if(key==symbol)
        {
            cout<<"Found in ScopeTable# "<<this->unique_id<<" at position "<<hash_idx<<", "<<pos<<endl<<endl;
            prev->next = curr->next;
            delete curr;
            cout<<"Deleted entry at "<<hash_idx<<", "<<pos<<" from current ScopeTable"<<endl;
            return true;
        }
        prev = curr;
        curr = curr->next;
        pos++;
    }
    cout<<"Not found"<<endl<<endl;
    cout<<symbol<<" not found"<<endl;
    return false;
}

void ScopeTable::print(ofstream& fp)
{
    fp<<" ScopeTable # "<<this->unique_id<<endl;
    //fprintf(fp," ScopeTable # %d\n",this->unique_id);
    
    for(int i = 0; i<this->bucket_sz; i++)
    {
        SymbolInfo * curr = this->bucket_head[i]->next;

        if(curr!=0)
        {
            fp<<" "<<i<<" --> ";
            //fprintf(fp," %d --> ",i);
            while(curr!=0)
            {
                fp<<" < "<<curr->getName()<<" : "<<curr->getType()<<" > ";
                
                //following code segment PRINTS DETAIL SYMBOL TABLE for debugging
                
                /*
                fp<<" < "<<curr->getName()<<" : "<<curr->getType()<<" > "<<" ("<<curr->IDtype<<"["<<curr->ara_size<<"]"<<" : "<<curr->data_type<<")->ret("<<curr->return_type<<") (";
                for(int ii = 0; ii< curr->parameter_list.size(); ii++){
                    fp<<curr->parameter_list[ii]<<" | ";
                }
                fp<<") ";
                */
                
                //fprintf(fp," < %s : %s > ",curr->getName().c_str(), curr->getType().c_str());
                curr = curr->next;
            }
            //fprintf(fp, "\n");
            fp<<endl;
        }
    }
    fp<<endl;
    //fprintf(fp, "\n");
}

//class SymbolTable
//{
//    //vector<ScopeTable> symTable;
//    int bucket_size;
//public:
//    ScopeTable * currScopeTable;
//    SymbolTable(int n);
//    void EnterScope();
//    void ExitScope();
//    bool Insert(string name, string type);
//    bool Remove(string symbol);
//    SymbolInfo * LookUp(string symbol);
//    void printCurrScopeTable(FILE *fp);
//    void printAllScopeTable(FILE *fp);
//};

SymbolTable::SymbolTable(int n)
{
    bucket_size = n;
    currScopeTable = 0;
    ScopeTable * newScopeTable = new ScopeTable(bucket_size);
    newScopeTable->parentScope = currScopeTable;
    currScopeTable = newScopeTable;
}

void SymbolTable::EnterScope()
{
    ScopeTable * newScopeTable = new ScopeTable(bucket_size);
    newScopeTable->parentScope = currScopeTable;
    currScopeTable = newScopeTable;
    cout<<"New ScopeTable with id "<<scopetable_id<<" created"<<endl;
}

void SymbolTable::ExitScope()
{
    ScopeTable * temp = currScopeTable;
    cout<<"ScopeTable with id "<<currScopeTable->unique_id<<" removed"<<endl;
    currScopeTable = currScopeTable->parentScope;
    delete temp;
    //scopetable_id--;
}

bool SymbolTable::Insert(string name, string type)
{
    bool ret = currScopeTable->Insert(name, type);
    return ret;
}

bool SymbolTable::Remove(string symbol)
{
    bool ret = currScopeTable->Delete(symbol);
    return ret;
}

SymbolInfo * SymbolTable::LookUp(string symbol)
{
    ScopeTable * temp = currScopeTable;
    SymbolInfo * symbolInfoObj;
    while(temp!=0)
    {
        symbolInfoObj = temp->LookUp(symbol);
        if(symbolInfoObj!=0)
        {
            return symbolInfoObj;
        }
        temp = temp->parentScope;
    }
    cout<<"Not found"<<endl;
    return symbolInfoObj;
}

SymbolInfo * SymbolTable::LookUpCurrScopeTable(string symbol){
    ScopeTable * temp = currScopeTable;
    SymbolInfo * symbolInfoObj = 0;

    symbolInfoObj = temp->LookUp(symbol);

    return symbolInfoObj;
}

void SymbolTable::printCurrScopeTable(ofstream& fp)
{
    currScopeTable->print(fp);
}

void SymbolTable::printAllScopeTable(ofstream& fp)
{
    ScopeTable * temp = currScopeTable;
    while(temp!=0)
    {
        temp->print(fp);
        temp = temp->parentScope;
    }
}


//int main()
//{
//    freopen("myInput.txt", "r", stdin);
//    freopen("myOutput.txt", "w", stdout);
//    int n;
//    cin>>n;
//    //if(show_inp) cout<<n<<endl;
//    SymbolTable symTab(n);
//    //enter Q or q to Quit
//    string cmd;
//    while(cin>>cmd){
//        if(cmd=="Q" || cmd=="q"){
//            break;
//        }
//        if(cmd=="I"){
//            string name, type;
//            cin>>name>>type;
//            if(show_inp) cout<<cmd<<" "<<name<<" "<<type<<endl;
//            //output
//            cout<<endl<<" ";
//            symTab.Insert(name, type);
//            cout<<endl;
//        }
//        else if(cmd=="L"){
//            string symbol;
//            cin>>symbol;
//            if(show_inp) cout<<cmd<<" "<<symbol<<endl;
//            //output
//            cout<<endl<<" ";
//            symTab.LookUp(symbol);
//            cout<<endl;
//        }
//        else if(cmd=="D"){
//            string symbol;
//            cin>>symbol;
//            if(show_inp) cout<<cmd<<" "<<symbol<<endl;
//            //output
//            cout<<endl<<" ";
//            symTab.Remove(symbol);
//            cout<<endl;
//        }
//        else if(cmd=="P"){
//            string ac;
//            cin>>ac;
//            if(show_inp) cout<<cmd<<" "<<ac<<endl;
//            //output
//            cout<<endl;
//            if(ac=="A"){
//                symTab.printAllScopeTable();
//            }
//            else if(ac=="C"){
//                symTab.printCurrScopeTable();
//            }
//            //cout<<endl;
//        }
//        else if(cmd=="S"){
//            if(show_inp) cout<<cmd<<endl;
//            //output
//            cout<<endl<<" ";
//            symTab.EnterScope();
//            cout<<endl;
//        }
//        else if(cmd=="E"){
//            if(show_inp) cout<<cmd<<endl;
//            //output
//            cout<<endl<<" ";
//            symTab.ExitScope();
//            cout<<endl;
//        }
//    }
//    return 0;
//}
