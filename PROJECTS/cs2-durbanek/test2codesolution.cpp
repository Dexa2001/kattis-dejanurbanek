#include <iostream>

using namespace std;

class Person {
    string name;
    int FICO;
    public:
    bool isNamed(const Person &other){
        return (name=other.name);
    }
    double getRate(){
        return 24.99*(800-FICO)/800;
    }

    virtual void out()=0;
};

class RiskyPerson: public Person {
    public:
    void out(){
        cout <<getRate()<<endl;
    }
};

class Tester{
    int y;
    public:
    Tester (int iY){
        y=iY;
    }
    bool check(int &x){

    }
};