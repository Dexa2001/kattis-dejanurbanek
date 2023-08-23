#include <iostream>

using namespace std;

#include "stackof.h"


int main() {
  Stack s;
  while (true) {
	  string input;
	  cin >> input;
	  try {
		  if (input=="+") {
				double a=s.pop();
				double b=s.pop();
				s.push(a+b);
		  } else if (input=="-") {
				double b=s.pop();
				double a=s.pop();
				s.push(a-b);
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
      } catch(StackException &e) {
		  e.describe(cerr);
	  }

	  
  }
  return 0;
}
