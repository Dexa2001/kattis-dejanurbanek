#include <iostream>
#include <string>

using namespace std;

string octal_binary(string octal){
    string output ="";
    for(int i= octal.length()-1; i > -1; i-- ){
        string temp= "";
        string digits= "";
        temp+=octal[i];

        int num = stoi(temp);
        if(num/4>=1){
            num= num%4;
            digits+="1";
        }else{
            digits+="0";
        }
        if(num/2>=1){
            num = num%2;
            digits+="1";
        }else{
            digits+="0";
        }
        if(num/1>=1){
            num = num%1;
            digits+="1";
        }else{
            digits+="0";
        }
        
        output = digits + output;

    }
    return output;
}

string winner(char board[3][3], char c){
    string temp = "";
    temp += c;
    temp += " wins";

    for(int i =0; i< 3; i++){
        if(board[i][0]==c && board[i][1]==c && board[i][2]==c){
            
            return temp;
        }
        if(board[0][i]==c && board[1][i]==c && board[2][i]==c){
            return temp;
        }
    }
    if((board[0][0]==c && board[1][1]==c && board[2][2]==c) || (board[2][0]==c && board[1][1]==c && board[0][2]==c )){
        return temp;
    }

    return "no win";
}

string inProgress(char board[3][3]){
    for(int i=0;i<3;i++){
        for(int j=0;j<3;j++){
            if(board[i][j] == ' '){
                return "In progress";
            }
        }
    }
    return "done";
}


int main(){
    string octal;
    string binary;
    int cases;

    bool played[3][3];      //3*3 grid
    bool check[3][3];       //checks if it is X or O
    char board[3][3];       // actual game of X/O
    
    cin>> cases;

    for (int i = 0; i < cases; i++)
    {
    cin>> octal;
    binary = octal_binary(octal);

    int row = 0;
    int col = 0;

    bool pinsert = true;
    bool done = false;
    
    for(int i = binary.length()-1; i>-1; i--){
        string temp = "";
        temp += binary[i];
        
        if(pinsert && !done){
            played[col][row] = stoi(temp);
        }

        if(!pinsert && !done){
            check[col][row] = stoi(temp);
            if(row == 2 && col == 2){
                done = true;
            }
        }

        row++;

        if(row==3){
            row=0;
            col++;
        }
        
        if(col==3){
            row=0;
            col=0;
            pinsert = false;
        }
    }

    for(int i = 0;i< 3;i++){
        for(int j = 0;j<3;j++){
            if(!played[i][j]){
                board[i][j]= ' ';
            }
            if(played[i][j]){
                if(check[i][j]){
                    board[i][j]='X';
                }
                else board[i][j]='O';
            }
        }
    }

    // cout << binary << endl;

    // for (int i = 0; i< 3; i++)
    // {
    //     for (int j = 0; j < 3; j++)
    //     {
    //         cout << played[i][j] << " ";

    //     }
    //     cout << endl;
    // }
    // cout << endl;
    // for (int i = 0; i< 3; i++)
    // {
    //     for (int j = 0; j < 3; j++)
    //     {
    //         cout << check[i][j] << " ";

    //     }
    //     cout << endl;
    // }
    //    cout << endl;
    // for (int i = 0; i< 3; i++)
    // {
    //     for (int j = 0; j < 3; j++)
    //     {
    //         cout << board[i][j] << " ";

    //     }
    //     cout << endl;
    // }

    bool finished = false;

    string temp = winner(board,'X');
    if(temp != "no win")
    {
        cout << temp << endl;
        finished = true;
    }

    if(!finished)
    {
    string temp = winner(board,'O');
    if(temp != "no win")
    {
        cout << temp << endl;;
        finished = true;
    } 
    }

    if(!finished)
    {
        temp = inProgress(board);
        if(temp == "done")
        {
            cout << "Cat's" << endl;
        }
        else
        {
            cout << "In progress" << endl;
        }
    }
    
    }

    return 0;
}
