#include <iostream>

using namespace std;

class BinaryNode {
	//pair<char,double>  letterFrequency;
	double position;
	char c;
	BinaryNode *left,*right;
	public:
	BinaryNode(char newC=' ',double newPosition=0.0,BinaryNode *newLeft=NULL,BinaryNode *newRight=NULL) {
	  c=newC;
	  position=newPosition;
	  left=newLeft;
	  right=newRight;
	}
	void insert(char newC,double newPosition) {
	  if (position<newPosition) {  // Update the right
			if (right!=NULL) {
				right->insert(newC,newPosition);
			} else {
				right=new BinaryNode(newC,newPosition);
			}
	  } else if (newPosition<position) { // Update the Left
			if (left!=NULL) {  // We actually have a tree to the left
				left->insert(newC,newPosition);
			} else {  // We have no tree to the left
				left=new BinaryNode(newC,newPosition);
			} 
	  } else {  // We are at the point we should update 
		 c=newC;
	  }
	}
	void printPre() {
		cout << c << ' ';
		if (left!=NULL) left->printPre();
		if (right!=NULL) right->printPre();
	}  // # E I S H 5 4 V 3 U F ? 2 A R L ? +
	void printPost() {
		if (left!=NULL) left->printPost();
		if (right!=NULL) right->printPost();
		cout << c << ' ';
	}
	void printInfix() {
		if (left!=NULL) left->printInfix();
		cout << c << ' ';
		if (right!=NULL) right->printInfix();
	}
	//		+
	//        
	//	5		6
	// Pre Order + 5 6
	// Post Order 5 6 +
	// InFix Order 5 + 6
			
};


int main() {
	BinaryNode root('#',0.5);
	root.insert('I',0.125);
	root.insert('E',0.25);
	root.insert('A',0.375);
	root.insert('N',0.625);
	root.insert('T',0.75);
	root.insert('M',0.875);
	cout << "Prefix Order" << endl;
	root.printPre();
	cout << endl<< "Postfix Order" << endl;
	root.printPost();
	cout << endl<<"infix Order" << endl;
	root.printInfix();
	return 0;
}
