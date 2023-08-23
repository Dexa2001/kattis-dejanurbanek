#include <iostream>

using namespace std;

class DLNode {
	double data;
	DLNode *prev,*next;
	public:
	DLNode *getNext() const {
		return next;
	}
	double getData() const {
		return data;
	}
	DLNode(double newData,DLNode *newPrev=NULL,DLNode *newNext=NULL) {
		data=newData;
		prev=newPrev;
		next=newNext;
	}
	void forwardWalk(ostream &out) {
		DLNode *p;
		p=this;
		while (p!=NULL) {
		  out << p->data << endl;
		  p=p->next;
		}
	}
	void backwardWalk(ostream &out) {
		DLNode *p;
		p=this;
		while (p!=NULL) {
		  out << p->data << endl;
		  p=p->prev;
		}
	}
	void insert(DLNode *item) {
		item->next=this->next;
		item->prev=this;
		cout << "this, next and then item " 
		  << hex << this << ' ' 
		  <<hex << this->next <<' '
		  << hex << item << endl;
		this->next=item;
		if (item->next!=NULL) 
		  item->next->prev=item;
	}
	DLNode *begin() {
		return this;
	}
	DLNode *end() {
		DLNode *p=this;
		while (p->next!=NULL) p=p->next;
		return p;
	}
/*	void cleanUp() {
		DLNode *p=this;
		while (p->next!=NULL) {
			p=p->next;
			delete p->prev;
		}
		delete p;
	}*/
	bool remove(double d) {
		DLNode *p=this;
		while (p!=NULL) {
			if (p->data==d) {
				DLNode *dead=p;
				if (p->prev!=NULL) p->prev->next=p->next;
				if (p->next!=NULL) p->next->prev=p->prev;
				p=p->next;
				delete dead;
			} else 
			  p=p->next;
		}
		return p;
	}
};

class Queue {
	DLNode *head,*tail;
	public:
    class Iterator{
    DLNode *current;
    public:
        Iterator increment(){
            current= current->getNext();
            return *this;
        }
        Iterator operator ++(){
            return increment();
        }

        Iterator(DLNode *newCurrent){
            current=newCurrent;
        }
        // Iterator end(){
        //     return tail;
        //     // return NULL;
        // }
    };
	Queue() {
		head=NULL;
		tail=NULL;
	}
    Iterator* begin(){
        return new Iterator(head);
    }

    Iterator* end(){
        return NULL;
    }

    // DLNode* increment(){
    //     return current=current->next;
    // }

	Queue(const Queue &other) { // I want to make a copy
		//head=other.head;  // Shallow Copy
		//tail=other.tail;
		head=NULL;
		tail=NULL;
		cout << "Deep Copy Other head tail " << hex << other.head << ' ' << hex << other.tail << endl;
		DLNode *p=other.head;
		while (p!=NULL) {
			cout << "Deep Copy constructor head tail " << hex << head << ' ' << hex << tail << endl;
			cout << "Deep Copy data to copy " << p->getData() << endl;
			push(p->getData());
			p=p->getNext();
		}
	}
	void pop() {
		DLNode *temp=head;
		head=head->getNext();
		if (head==NULL) tail=NULL;
		cout << "Deleting " << hex << temp << endl;
		delete temp;
	}
	double front() {
		cout << "front head tail " << hex << head << ' ' << hex << tail << endl;
		if (!empty()) {
		  return head->getData();
		}else
			return 0.0;
	}
	void push(double data) {
		if (empty()) {
		  head=new DLNode(data);
		  cout << "push first " << hex << head << endl;
		  tail=head;
	    } else {
			DLNode *nTail=new DLNode(data);
  		    cout << "push rest " << hex << nTail << endl;
			tail->insert(nTail);
			tail=nTail;
		}
	}
	void emplace(double data) {
		push(data);
	}
	bool empty() {
		return head==NULL || tail==NULL;
	}
	~Queue() {
	//	if (!empty()) head->cleanup();
		while (!empty()) 
		  pop();
	}
};

int main() {
   Queue *q=new Queue();
   vector<int> numbers;

   numbers.push_back(10);
   numbers.push_back(20);
   for(auto it=numbers.begin();it!=numbers.end();it++){
       for(auto it2=numbers.begin();it2!=numbers.end();it2++){
           if(it==it2)
                cout<< *it <<' '<< *it2 <<endl;
       }
   }
   //Queue p;
   // (*q).  => q->
//    q->push(10.0);
//    q->push(12.0);
//    Queue p=Queue(*q);
//    cout << "Before q->pop " << endl;
//    q->pop();
//    cout << "Q's front " << q->front() << endl;
//  //  q.pop();
//  //  delete p;
//    q->pop();  // Seg Fault
//    delete q;
//    cout << "P's front "<<p.front() << endl;  // should be 10
//    p.pop();
//    cout << "P's front after one pop" << p.front() << endl;  // should be 12 
//    cout << "End of Program " << endl;
//   return 0;


}
