#include <iostream>
#include <sstream>
#include <vector>
#include <algorithm>

using namespace std;

class Person{
    string first, last;
    public:
    Person(string newFirst, string newLast){
        first=newFirst;
        last=newLast;
    }
    friend ostream & operator << (ostream &out,const Person &other){
        return out << other.first << "-" << other.last <<endl;

    }
    bool operator <(const Person &other) const{
        if(last<other.last) return true;
        if(first<other.first) return true;
        return false;
    }
};

int main(){
    vector<Person> text;
    text.push_back(Person("Karl", "Castle"));
    text.push_back(Person("Kim", "Castleton"));
    text.push_back(Person("John", "Doe"));
    text.push_back(Person("Jane", "DoeAdeer"));
    

    for(unsigned i=0; i<text.size();i++)
        cout << text[i] << endl;
    sort(text.begin(),text.end());
    cout << "After sorting" << endl;

    for(unsigned i=0; i<text.size();i++)
        cout << text[i] << endl;

    return 0;
}