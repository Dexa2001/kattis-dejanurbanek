#include <iostream>
#include <cmath>

using namespace std;


int main(){
    int n, w, h;
    cin>>n>>w>>h;

    int l;
    cin>>l;

    double d = sqrt(w^2+h^2);

    if(l < w || l < h || l <= d ){
        cout << "DA"<<endl;
    }else{
        cout << "NE"<<endl;
    }
    return 0;
}