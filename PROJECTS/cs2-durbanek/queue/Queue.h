#pragma once

#include <iostream>

using namespace std;

class Exception {
  public:
  virtual void describe(ostream &out);
};

class EmptyException:public Exception {
  public:
  void describe(ostream &out);
};

class OverflowException:public Exception {
  public:
  void describe(ostream &out);
};

// Prototype for the class
template <class T>
class Queue {
	const static int MAXQUEUE=1000;
	T values[MAXQUEUE];
	int head,tail;
	int increment(int i){  // modulus arithmetic increment
		i++;
		if (i==MAXQUEUE) i=0;
		return i;
	}
	public:
	Queue(){ 
		head=0;
		tail=0; 
	}
	void push(T x){
	  if (!isFull()) {
	    values[tail]=x;
	    tail=increment(tail);
      } else throw OverflowException();
	}
	T pop(){
	  if (!isEmpty()) {
		T temp=values[head];
		head=increment(head);
	    return temp;
	  }
      throw EmptyException();
	}
	T top(){
	  return values[head];
	}
	bool isEmpty(){
	  return head==tail;
    } 
	bool isFull(){
	  return increment(tail)==head;
	}
};

