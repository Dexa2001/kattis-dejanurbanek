#include <iostream>

using namespace std;

class Complex{
    private:
    double real, imaginary;
    public:
    Complex(){

    }
};

class Animal {
    protected:
    string commonName, scientificName, attribute;
    public:
    Animal(string nemCommonName="",string newScientificName=""){
        friend ostream &operator <<(ostream &out,const Animal &animal){
            void
        }
        attribute="Can Move";
    }
    friend ostream & operator <<(ostream &out, const Animal &animal){
        return out << animal.commonName << ':' << animal.scientificName
        << endl << animal.attribute <<endl;
        animal.output(out);
        return out;
    }
    void output(ostream &out) const{
        out << commonName<< ':' << scientificName <<endl <<attribute<<endl;

    }
};

class Mammal: public Animal {
    public:
    Mammal(string newCommonName="mammal", string newScientificName="mammalia") {
        // commonName="mammal";
        // scientificName="mammalia";
        Animal(newCommonName, newScientificName){
        attribute="Has hair, live birth, warm blooded";
    }
    // void output(ostream &out){
    //     Animal::output(out);
    //     out << "mamal : mammalia" << endl <<
    //     attribute << endl;
    // }
//    friend ostream & operator <<(ostream &out, const Mammal &mammal){
//         out<< Animal::operator << (out,const (Animal &)(*this));
//         return out << mammal.commonName << ':' << mammal.scientificName
//         << endl << mammal.attribute <<endl;
//   }   
};

class Dog: public Mammal{
    public:
    Dog() : Mammal("dog", "canis lupus familiaris"){
        // commonName="dog";
        // scientificName=" canis lupus familiaris";
        attribute="domesticated four legged animal";
    }
    // void output(ostream &out){
    //     Animal::output(out);
    //     Mammal::output(out);
    //     out << "dog : canis lupus familiaris"<< endl
    //     <<attribute <<endl;
    // }
};

int main(){
    Dog d;
    Mammal m;
    Animal a("karl", "Human Comp");
    // d.output(cout);
    cout << d << endl;
    cout << m << endl;
    cout << a << endl;
    return 0;
}