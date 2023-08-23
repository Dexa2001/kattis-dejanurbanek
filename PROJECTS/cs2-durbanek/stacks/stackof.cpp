#include "stackof.h"

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

bool Stack::isEmpty() {
	return position==MAXSTACK-1;
}

bool Stack::isFull() {
	return position==-1;
}

// Implementation
Stack::Stack() {
	position=MAXSTACK-1;
}
void Stack::push(double x) {
	if (!isFull()) {
	  values[position]=x;
	  position--;
    } else throw StackOverflowException();
}
double Stack::pop(){
	if (!isEmpty()) {
	  position++;
	  return values[position];
	}
	throw EmptyStackException();
}
double Stack::top() {
	return values[position+1];
}
