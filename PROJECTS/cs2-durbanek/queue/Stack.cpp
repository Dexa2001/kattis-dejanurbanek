#include "Stack.h"

#include <iostream>

using namespace std;

void StackException::describe(ostream &out) {
	  out << "Stack Exception" << endl;
  }


  void EmptyStackException::describe(ostream &out) {
	  out << "Empty Stack Exception" << endl;
  }


  void StackOverflowException::describe(ostream &out) {
	  out << "Stack Overflow Exception" << endl;
  }

// Karl's To-Do
//template <class T>
//	bool Stack<class T>::isFull(){
//	  return position==-1;
//	}
