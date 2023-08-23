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
class Stack {
	const static int MAXSTACK=1000;
	double values[MAXSTACK];
	int position;
	public:
	Stack();
	void push(double x);
	double pop();
	double top();
	bool isEmpty();
	bool isFull();
};


