/*
Kattis Lineup By Jeremy Koch
Date: 10/31/2022
Program has user input specific number of names chosen by them, returns if they increase or deacrease.
Algorithem:
    1. Read the number of names wanted to input into an array
    2. Read names into array.
    3. Determine if the name order increases, decreases, or is random.
    4. Output increase, decrease or random.
*/
#include <string>
#include <iostream>
#include <algorithm>
#include <cassert>
using namespace std;
void ordertest();
string order(string line[], int index);

int main(int argc, char* argv[])
{
  if (argc == 2 and string(argv[1]) == string("test")) {

    ordertest();

  }

  else {
    int N;
    cin >> N;

  string name[N];
 bool increasing = true, decreasing = true;

  for(int i=0; i < N; i++)
    cin >> name[i];

  string order[N];
  for(int i=0;i<N;i++){
    order[i]=name[i];}
  sort(order, order + N);

  string reverse[N];
  for(int i=0;i<N;i++){
    reverse[i]=name[i];}
  sort(reverse, reverse+N,greater<string>());
 
 for (int i = 0; i < N; i++)
 {
    if (name[i] != order[i])
    {
        increasing = false;
    }
    else if(name[i]!=reverse[i])
    {
        decreasing = false;
    }

 }
 
 if(increasing){
    cout<<"INCREASING"<<endl;
    }
else if(decreasing){
    cout<<"DECREASING"<<endl;
}
else    cout<<"NEITHER"<<endl;

}
  return 0;
}


void ordertest() {
    string ans[3];
}

string order(string line, int index) {
    string ascend = line;  
   
}
