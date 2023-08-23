#include <iostream>
#include <fstream>
#include <cmath>

using namespace std;

class Contact {
	string name;
	string phone;
	public:
	Contact(string newName="",string newPhone="") {
		name=newName;
		phone=newPhone;
	}
	void getFromUser(/* Contact *this */) {
		cout << "Enter name and phone " << endl;
		cin >> name >> phone;
	}
	friend ostream &  operator << (ostream &out,const Contact &c) {
	  out << c.name << ", " << c.phone << endl;
	  return out;
	}
	friend istream & operator >> (istream &input, Contact &c) {
	  input >> c.name >> c.phone;
	  return input;
	}	
};

const int MAXCONTACTS=100;
class Contacts {
	int numContacts;
	Contact contacts[MAXCONTACTS];
	public:
	Contacts() {
		numContacts=0;
	}
	void add(const Contact &other) {
		contacts[numContacts]=other;
		numContacts++;
	}
	void getFromUser() {
		cout << "Enter number of contacts" << endl;
		cin >> numContacts;
		for (int i=0;i<numContacts;i++) 
		  contacts[i].getFromUser();
	}
	friend ostream &operator << (ostream &out,const Contacts &list) {
		for (int i=0;i<list.numContacts;i++) 
		  out << list.contacts[i] << endl;
		return out;
	}
	friend istream &operator >> (istream &input, Contacts &list) {
		input >> list.numContacts;
		for (int i=0;i<list.numContacts;i++)
		  input >> list.contacts[i] ;
		return input;
	}	
};

int main() {

	Contact karl("Karl","970-462-7280");
	Contact john("John Doe","970-248-1000");
	Contacts phoneBook;
	phoneBook.add(john);
	phoneBook.add(karl);
	cout << phoneBook <<endl;
	cin >> phoneBook;
	ofstream fout;
	fout.open("MyDataDump.txt");
	fout << phoneBook << endl;
	fout.close();
	return 0;
}