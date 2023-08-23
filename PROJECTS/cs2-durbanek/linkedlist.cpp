#include <iostream>

using namespace std;

class Node{
    string data;
    Node *next;
    public:
    Node(string newData, Node *newNext=NULL){
        next=newNext;
        data=newData;
    }

    void add(Node *item){
        string t=data;
        data=item->data;
        item->data=t;
        item ->next = next;
        next=item;

    }

    void erase(){
        if(next!=NUll)
            data=next->data;
        Node *p =next;
        if(next!=NULL){
        next=next ->next;
        delete p;

    }

    void print(ostream &out){
        Node *p=this;
        while(p!=NULL){
            out << p-> data <<endl;
            p = p->next;
        }
    }

    bool operator == (const Node &other) const {
        return !((data<other.data)||(other.data<data));
    }

    bool operator < (const Node &other){
        return data<other.data;
    }

    bool operator >(const Node &other){
        return other.data<data;
    }

    bool operator !=(const Node &other){
        return (other.data<data || data<other.data);
    }


};


int main(){
    Node *head;
    head=new Node ("Karl");
    Node *kim;
    kim=new Node ("Kim");
    head ->add(kim);
    Node *emilee;
    emilee=new Node("Emilee");
    head ->add(emilee);
    Node *kaleb;
    kaleb = new Node("Kaleb");
    head ->add(kaleb);

    head -> print(cout);

    cout<<"after erase"<<endl;

    head->erase();
    head ->print(cout);

    return 0;
}