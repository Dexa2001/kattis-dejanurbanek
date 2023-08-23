#include <iostream>
#include <fstream>
#include <string>
#include <cmath>
#include <vector>


// add read in form txt file and save command
// make class cell with 3 sub classes that 
// will each handle different type of data


using namespace std;

class Cell{
    public:
    string name;

    virtual void display() = 0;
    virtual string returnVal() = 0;
    virtual bool isString() = 0;

};

class numCell: public Cell {
    public:
    double number;

    void display(){
        cout << name << " " << number << endl;
    }
    string returnVal()
    {
        return to_string(number);
    }
    bool isString()
    {
        return false;
    }

};

class stringCell: public Cell {
    public:
    string words;

    void display(){
        cout << name << " " << words << endl;
    }
    string returnVal()
    {
        return words;
    }
    bool isString()
    {
        return true;
    }

};

class formulaCell: public Cell{
    public:
    string formula;

    void display(){
        cout << name << " " << formula << endl;
    }
    string returnVal()
    {
        return formula;
    }
    bool isString()
    {
        return false;
    }
};


double calculate(string formula, vector<Cell*> spreadsheet){
    int previous = 0;
    formula+=" ";
    vector<string>split;

    for(int i = 0; i<formula.length() ; i++){
        if(formula[i] == ' ' ){
            split.push_back(formula.substr(previous, i-previous));
            previous = i+1;
        }
    }

    vector<double> stack;

    for (int i = 0; i< split.size(); i++){

        bool isNumber = true;
        
        try{
            stack.push_back(stod(split[i]));
        }
        catch(exception e)
        {
            isNumber = false;
        }
    
        if(!isNumber){

            if(split[i]=="+"){
                double one, two;
                one = stack.back();
                stack.pop_back();
                two = stack.back();
			    stack.pop_back();
			    stack.push_back(one+two);
            }
            else if(split[i]=="-"){
                double one, two;
                one = stack.back();
                stack.pop_back();
                two = stack.back();
			    stack.pop_back();
			    stack.push_back(one-two);

            }
            else if(split[i]=="*"){
                double one, two;
                one = stack.back();
                stack.pop_back();
                two = stack.back();
			    stack.pop_back();
			    stack.push_back(one*two);

            }
            else if(split[i]=="/"){
                double one, two;
                one = stack.back();
                stack.pop_back();
                two = stack.back();
			    stack.pop_back();
			    stack.push_back(one/two);
            }
            else {
                string name = split[i];
            for(int i = 0;i< spreadsheet.size();i++){
                if(name==(*spreadsheet[i]).name){
                    stack.push_back(calculate((*spreadsheet[i]).returnVal(), spreadsheet));
                    }  
                }
            }
        }
    }
    return stack[0];
}

int main(){
    string cell;
    vector <Cell*> spreadsheet;
    bool running = true;

    while(running){
        string input;
        cout<<"Do you want to add, remove, calculate, read, save or quit?"<<endl;
        cin>>input;

        if(input=="add"){
            cout<<"Enter the name and number of cell"<<endl;
            cin>>cell;

            string input2;
            cout<<"What type of data are you entering:"<<endl;
            cout<<"1)number"<<endl;
            cout<<"2)string"<<endl;
            cout<<"3)formula"<<endl;
            cin>>input2;

            if(input2== "number"){
                double number;
                cout<<"What number you want to enter in your cell?"<<endl;
                cin>>number;

                numCell* temp = new numCell;
                (*temp).name = cell;
                (*temp).number = number;
                spreadsheet.push_back(temp);

            }else if(input2=="string"){
                string words;
                cout<<"What words do you want to enter in your cell?"<<endl;
                cin.ignore();
                getline(cin, words);

                stringCell* temp = new stringCell;
                (*temp).name = cell;
                (*temp).words = words;
                spreadsheet.push_back(temp);

            }else if(input2=="formula"){
                string formula;
                cout<<"What fomrula you want to enter in your cell"<<endl;
                cin.ignore();
                getline(cin, formula);

                formulaCell* temp = new formulaCell;
                (*temp).formula = formula;
                (*temp).name = cell;
                spreadsheet.push_back(temp);

            }else cout<<"wrong input"<<endl;

        }
        else if(input=="remove"){
            string name;
            cout<< "what cell do you want to remove?"<<endl;
            cin>>name;
            
            for(int i = 0;i< spreadsheet.size();i++){
                if(name==(*spreadsheet[i]).name){
                    spreadsheet.erase(spreadsheet.begin() + i);
                }
            }

        }
        else if(input=="calculate"){

            for (int i = 0; i< spreadsheet.size(); i++){
                if ((*spreadsheet[i]).isString() == false){
                    cout << (*spreadsheet[i]).name << ": " << calculate((*spreadsheet[i]).returnVal(), spreadsheet) << endl;
                }
            }


        }
        else if(input=="read"){
            ifstream readFile;
            string name;
            double num;
            string contents;
            
            readFile.open("read.txt");
            if(readFile.is_open()){
                cout << "opened file" << endl;
            }
            
            while(!readFile.eof())
            {
            bool isFormula = false;
            readFile >> name;
            getline(readFile,contents);
            contents = contents.substr(1);
            
            try{
                num = stod(contents);

                numCell* temp = new numCell;
                (*temp).name = name;
                (*temp).number = num;
                spreadsheet.push_back(temp);

            }catch(exception e) {
                for(int i = 0; i < contents.length(); i++) {
                    if (contents[i] == '+' || contents[i] == '*' || contents[i] == '/' || contents[i] == '-' ){
                        isFormula = true;
                        }
                    }

                if(isFormula){
                    formulaCell* temp = new formulaCell;
                    (*temp).name = name;
                    (*temp).formula = contents;
                    spreadsheet.push_back(temp);
                    }

                else{
                    stringCell* temp = new stringCell;
                    (*temp).name = name;
                    (*temp).words = contents;
                    spreadsheet.push_back(temp);
                    }

                }     
            }
            readFile.close();
            
        }
        else if(input=="save"){
            ofstream outputFile;
            outputFile.open("output.txt");
             for (int i = 0; i< spreadsheet.size()-1; i++){
                outputFile << (*spreadsheet[i]).name << " " << (*spreadsheet[i]).returnVal() << endl;
            }
            outputFile << (*spreadsheet[spreadsheet.size()-1]).name << " " << (*spreadsheet[spreadsheet.size()-1]).returnVal();
            outputFile.close();

        }

        else if(input=="quit"){
            running = false;
        }
            cout<<endl;
            for (int i = 0; i< spreadsheet.size(); i++){
                (*spreadsheet[i]).display();
            }   
    }
    return 0;
}