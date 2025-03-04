#include <iostream>

using namespace std;
void sequence(int n, int count);

int main()
{   
    int m;
    int size;
    sequence(m, size);

    putchar('\n');
    return 0;
}

void sequence(int n, int count){
    n=0;
    count=0;
    scanf("%d", &n);
    int arr[n];
    while(n--)
    {
        int next = 0;
        scanf("%d", &next);

        if (count == 0 || arr[count - 1] < next) arr[count++] = next;
    }
        cout << count<< endl;
    for (int i = 0; i < count; i++){
        cout<< arr[i]<<" ";
    }

}
