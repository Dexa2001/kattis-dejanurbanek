#include <iostream>
#include <fstream>
#include <cmath>

using namespace std;

class Contact {
    string name;
    string phone;
    public:
    Contact(string newName="", string newPhone=""){
        name=newName;
        phone=newPhone;
    }
    void getFromUser() {
        cout<< "Enter name and phone number"<<endl;
        cin >> name >> phone;
    }
    friend ostream & operator << (ostream &out, const Contact &other){
        out << other.name << ", " << other.phone << endl;
        return out;
    }
};

const int MAXCONTACTS=100;
class Contacts {
    int numContacts;
    Contact contacts[MAXCONTACTS];
    public:
    Contacts(){

        numContacts=0;
    }

    // Contact & operator +(const Contact &other) {
    // }

    void add(const Contact &other){
        contacts[numContacts]=other;
        numContacts++;
    }

    void getFromUser(){
        cout << "Enter number of contacts " <<endl;
        cin >> numContacts;
        for (int i=0; i<numContacts;i++)
            contacts[i].getFromUser();
    }

    //return type
    friend ostream & operator << (ostream &out, Contacts &list) {
        for (int i=0; i<list.numContacts;i++)
        out << list.contacts[i] << endl;
        return out;
    }
};

int main(){

    Contact karl("Karl","970-462-7280");
    Contact john("John Doe","970-248-1000");
    Contacts phoneBook;
    phoneBook.add(karl);
    phoneBook.add(john);
    cout << phoneBook << endl;
    ofstream fout;
    fout.open("MaDataDump.txt");
    fout << phoneBook <<endl;
    fout.close();

    return 0;
}