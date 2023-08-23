#include <iostream>

using namespace std;

class DOMNode{
    protected:
    string name;                        //tag name
    vector<DOMNode *> children;         //it is pointer because of polymorphism
    public:

};

class HeadTag:public DOMNode {

};

class BodyTag:public DOMNode{

};


int main(){


    return 0;
}