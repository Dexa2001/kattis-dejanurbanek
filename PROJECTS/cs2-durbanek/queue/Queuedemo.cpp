#include <iostream>

using namespace std;

#include "Queue.h"
#include "Stack.h"


class Person{
    string first,last;
    public:
    Person(string newFirst, string newLast){
        first=newFirst;
        last=newLast;
    }
    friend ostream & operator << (ostream &out,const Person &other){
        return out << other.first << ',' << other.last << endl;
    }
};

int main() {
    Queue<Person> line;
    Stack<Person> s;
    line.push(Person("Karl", "Castleton"));
    line.push(Person("Kim","Castleton"));
    line.push(Person("John","Doe"));
    while(!line.isEmpty()){
        Person p=line.pop();
        cout << p;
    }
    while (!s.isEmpty()){
        Person p=s.pop();
        cout<< p;
    }
    
    return 0;
}
