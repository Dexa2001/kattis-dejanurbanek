/* 
Dejan Urbanek
11/14/2021
Falling apart -  Kattis Problem
Program alghorithm:
1. define function solve to solve a problem
    1.1 function should include for loops
2. define test casses a and assert function
3. upload input and output files from Kattis online
4. check if code compiles online

*/

#include <iostream>
#include <string>
#include <cassert>

using namespace std; 

string solve(int pieces, int array[]);

void test();

int main(int argc, char *argv[]){
    if (argc == 2 and string(argv[1]) == "test")
        test();
    else{
        int number_of_pieces;
        int numbers[15];

        for(int i =0; i < 15;i++){
            numbers[i]=0;
        }

        cin>>number_of_pieces;
        for(int i = 0; i<number_of_pieces; i++){
            cin>>numbers[i];
        }
        // solve(number_of_pieces, numbers);

        printf("%s",solve(number_of_pieces, numbers).c_str());
    }
}

string solve(int pieces, int array[]){
    int alice, bob;
    alice = 0;
    bob = 0;

    // int numbers[15];


    for(int z = 0; z < pieces; z++){
        int largest = 0;
        int index = 0;

        for(int j = 0; j < pieces; j++ ){
            if(largest < array[j]){
                largest = array[j];
                index = j;
            }
        } 
        array[index] = 0;

        if(z%2==0){
            alice +=largest;
        }else{
            bob +=largest;
        }

    }
    string answer = to_string(alice)+" "+to_string(bob);
    return answer;
}

void test(){
    string answer;
    int test1[] = {3, 1, 2};

    assert(solve(3, test1)=="4 2");

    int test2[]={4, 5, 6, 8};

    assert(solve(4, test2)=="13 10");

    cout<<"all test cases passed!"<<endl;

}