#include <iostream>
#include <string>

using namespace std;

int main(){
    string s1, s2;

    cout << "Enter first string:";
    getline(cin, s1);

    cout << "Enter second string:";
    getline(cin, s2);

    if(CheckSubstring(s1, s2))
        cout << "Second string is a substring of the frist string.\n";
    else
        cout << "Second string is not a substring of the first string.\n";

    return 0;
}

bool CheckSubstring(string s1, string s2){
    if(s2.size() > s1.size())
        return false;

    for (int i = 0; i < s1.size(); i++){
        int j = 0;

        if(s1[i] == s2[j]){
            int k = i;
            while (s1[i] == s2[j] && j <s2.size()){
                j++;
                i++;
            }
            if (j == s2.size())
                return true;
            else
                i = k;
        }
    }
    return false;
}

