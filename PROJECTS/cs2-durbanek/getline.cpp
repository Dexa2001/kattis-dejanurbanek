/*
    THIS CODE IS FOR SEPARATING STRINGS WITH COMMAS
*/

#include <iostream>
#include <sstream>

using namespace std;

// int main(){
//     string line;
//     // cin>>s;
//     getline(cin,line);
//     cout << "[" << line << "]" <<endl;
//     stringstream lineStream(line);

//     string word;

//     while(!lineStream.eof()){
//     getline(lineStream,word,',');
//     cout << "[" << word << "]" <<endl;
//     }

//     return 0;
// }

int main(){
    while(!cin.eof()){
        string line;
        getline(cin, line);
        stringstream lineStream(line);

        string word;
        while(!lineStream.eof()){
            getline(lineStream,word, ',');
            cout << "[" << word << "]" <<endl;
        
        }
    }
    return 0;
}