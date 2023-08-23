#pragma once

#include <iostream>

using namespace std;

class StackException {
  public:
  virtual void describe(ostream &out);
};

class EmptyStackException:public StackException {
  public:
  void describe(ostream &out);
};

class StackOverflowException:public StackException {
  public:
  void describe(ostream &out);
};

// Prototype for the class
template <class T>
class Stack {
	const static int MAXSTACK=1000;
	T values[MAXSTACK];
	int position;
	public:
	Stack(){ position=MAXSTACK-1; }
	void push(T x){
	  if (!isFull()) {
	    values[position]=x;
	    position--;
      } else throw StackOverflowException();
	}
	T pop(){
	  if (!isEmpty()) {
	    position++;
	    return values[position];
	  }
      throw EmptyStackException();
	}
	T top(){
	  return values[position+1];
	}
	bool isEmpty(){
	  return position==MAXSTACK-1;
    } 
	bool isFull(){
	  return position==-1;
	}
};

