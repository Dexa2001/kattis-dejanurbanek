#include <map>
#include <iostream>

using namespace std;

//efficient about finding values associated with a key/name

class Cell{
    public:
    string value;
    virtual void eval()=0;
    friend ostream& operator <<(ostream &out,const Cell &other){
        return out;
    }

};

class Formula: public Cell{

};

class Label: public Cell{

};

class Value:public Cell{

};

class Kstring{
    public:
    string value;
    bool operator <(const Kstring &other){
        return value>other.value;
    }
};

map<string,double>symbolTable;        //string->cell name
map<string, Cell*>ss;

int main(){
symbolTable["A5"]=20;
symbolTable["A1"]=1;
symbolTable["B255"]=symbolTable["A5"]+symbolTable["A1"];

for(auto it=ss.begin();it!=ss.end();it++){
    cout<<*(it->second)<<endl;
}

for(auto it=ss.begin();it!=ss.end();it++){
    it->second->eval();
}

for(auto it=symbolTable.begin();it!=symbolTable.end();it++){
    cout<<it->first<<" contains "<<it->second<<endl;
}

return 0;
}