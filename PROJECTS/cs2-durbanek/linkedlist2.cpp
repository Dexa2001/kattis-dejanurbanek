#include <iostream>

using namespace std;

class DLNode{
    double data;
    DLNode *prev, *next;
    public:
    DLNode(double newData, DLNode *newPrev=NULL, DLNode *newNext=NULL){
        data=newData;
        prev=newPrev;
        next=newNext;
    }

    void forwardWalk(ostream &out){
        DLNode *p=this;
        while(p!=NULL){
        out << p->data << endl;
        p=p->next;
        // if(p!=NULL)
        //     next -> forwardWalk(out);       //recursion
        }
    }

    void backwardWalk(ostream &out){
        DLNode *p;
        p=this;
        while(p!=NULL){
        out << p->data << endl;
        p=p->prev;
        // if(p!=NULL)
        //     next -> forwardWalk(out);       //recursion
        }
    }

    void insert(DLNode *item){

        item ->next=this->next;
        item->prev=this;
        this->next=item;
        if(item->next!=NULL)
        item->next->prev=item;

    }
    DLNode *end(){
        DLNode *p=this;;
        while(p->next!=NULL){
            p=p->next;
            return p;
        }
    }
    bool remove(double d){
        DLNode *p=this;
        while(p!=NULL){
            if(p->data==d){
                DLNode *dead=p;
                if(p->prev!=NULL)p->prev->next=p->next;
                if(p->next!=NULL)p->next->prev=p->prev;
                p=p->next;
                delete dead;
            }else
                p=p->next;
        }
    }
};

int main(){
    // string k("Karl");
    // for(auto it=k.rbegin();it!=k.rend();it++){
    //     cout<<*it << ' ';
    // }                           //will output name in reverse   l a r K
    DLNode head(10.0);
    head.insert(new DLNode(3.14159));
    head.insert(new DLNode(1.414));
    head.forwardWalk(cout);
    head.end()->backwardWalk(cout);

    return 0;
}