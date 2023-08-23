#include <iostream>

using namespace std;

class Dad{
    public:

    virtual void show()=0;

};

class Son: public Dad{
    public:

    virtual void show(){

        cout<< "Hellooo!!"<<endl;
    }

};

int main(){

    Son derived1;

    Dad* base = &derived1;

    base->show();

    return 0;
}