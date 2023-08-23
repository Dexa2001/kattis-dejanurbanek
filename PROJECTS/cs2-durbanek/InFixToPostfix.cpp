#include <iostream>
//#include <ctypes>

using namespace std;

class ParseTree {
	ParseTree *left,*right;
	char value;
	public:
	ParseTree(char newValue,
		ParseTree *newLeft=NULL,ParseTree *newRight=NULL){
		value=newValue;
		left=newLeft;
		right=newRight;
	}
	void postFix(ostream &out=cout) {
		if (left!=NULL) left->postFix(out);
		if (right!=NULL) right->postFix(out);
		out << value;
	}
};

// (3+5)  -> +
//			/ \  -
//         3   5

// 3+5  -> 	 +			3+4+5
//			/ \  -					+
//         3   5				  /   \ -
//								 3     +
//									 /	 \-
//									4	  5

//  3    ->  3

// Expression
//  # -> 3

// # <op> #  -> <op>
//				/ \  -
//  	       3   5

// (<Expression>)

bool isOperator(char c) {
	return c=='+' || c=='-' || c=='/' || c=='*';
}

ParseTree *parse(string s,unsigned &pos) {
	if (isdigit(s[pos])) {
		ParseTree *l=new ParseTree(s[pos]);
		if (pos+1<s.size())
			if (isOperator(s[pos+1])) {
				if (pos+2<s.size()) {
					if (isdigit(s[pos+2])) {
					  ParseTree *r=new ParseTree(s[pos+2]);
					  unsigned opIndex=pos+1;
					  pos+=3;
					  return new ParseTree(s[opIndex],l,r);
				    } else if (s[pos+2]=='(') {
						unsigned pos2=pos+3;
						ParseTree *r=parse(s,pos2);
					    unsigned opIndex=pos+1;
						pos=pos2;
					    return new ParseTree(s[opIndex],l,r);						
					}
				}
			}
		pos++;
		return l;	
	} else if (s[pos]=='(') {
		unsigned pos2=pos+1;
		ParseTree *sub=parse(s,pos2);
		if (s[pos2]==')') {
			pos=pos2+1;
			return sub;
		} else {
			cerr << "Expected ) at "<< pos2 << endl;
		}
	}  
	return NULL;
}
  
// Read a string like (3+5)*(6+7)  and output PostFix 35+67+*
//			 	compared to 3+5*(6+7)
int main() {
	string expression;
	cout << "Enter the expression" << endl;
	cin >> expression;
	unsigned pos=0;
	ParseTree *t=parse(expression,pos);
	t->postFix();
	return 0;
}
