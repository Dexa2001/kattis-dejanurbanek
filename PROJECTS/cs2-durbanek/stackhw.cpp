#include <iostream>

using namespace std;

// Prototype for the class
class Stack {
	const static int MAXSTACK=1000;
	double values[MAXSTACK];
	int position;
	public:
	Stack();
	void push(double x);
	double pop();
	double top();
};

// Implementation
Stack::Stack() {
	position=MAXSTACK-1;
}
void Stack::push(double x) {
	values[position]=x;
	position--;
}
double Stack::pop(){
	position++;
	return values[position];
}
double Stack::top() {
	return values[position+1];
}

int main() {
  Stack s;
  while (true) {
	  string input;
	  cin >> input;
	  if (input=="+") {
			double a=s.pop();
			double b=s.pop();
			s.push(a+b);
	  } else if (input=="-") {
			double b=s.pop();
			double a=s.pop();
			s.push(a-b);
	  } else if (input=="*") {
			double b=s.pop();
			double a=s.pop();
			s.push(a*b);
	  } else if (input=="/") {
			double b=s.pop();
			double a=s.pop();
			s.push(a/b);
	  }else if (input=="sqrt") {
			double a=s.pop();
			s.push(sqrt(a));
	  } else if (input=="#") {
		  cout << s.top() << endl;
	  }
	  else {
	    try{
	      double x=stod(input);
	      s.push(x);
        } catch(exception &e) {
	    }
      }
  }
  return 0;
}
