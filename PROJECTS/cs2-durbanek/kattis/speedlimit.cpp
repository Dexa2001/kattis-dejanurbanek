#include <iostream>

using namespace std;

int main(){
    int n;
    //n is number of entries (times/speed)
    cin >> n;
    while(n != -1){
        int last = 0;
        int sum = 0;
        for(int i = 0; i < n; ++i){
            int s,t;
            cin >> s >> t;
            sum += s*(t-last);
            last = t;
        }
        cout << sum << " miles" << endl;
        cin >>n;
    }
    return 0;
}