#include <iostream>
#include <cmath>

using namespace std;

//fib    = fib + fib
//	 n+1	  n		n-1
//  fib  =1
//     1
//  fib  =1
//	   2

int fib(int n) {
	if (n<=2) return 1;
	return fib(n-1)+fib(n-2);
}

double f(double x) {
  return x*sin(x)/exp(x);
}

double integrate(double a,double b,double epsilon=0.001) {
    double fa=f(a);
    double fb=f(b);
    double A2=0.5*(f(a)+f(b))*(b-a);
    double m=(a+b)/2.0;
    double fm=f(m);
    double A3=0.5*(fa+fm)*(m-a)+
		    0.5*(fm+fb)*(b-m);
    if (fabs(A2-A3)<epsilon) return A3;
    else return integrate(a,m,epsilon/2.0)+integrate(m,b,epsilon/2.0);
}

enum Piece{X,O,BLANK};

class Board{
  Piece piece[3][3];
  void clear(){
    for (int i=0;i<3;i++)
      for(int j=0;j<3;j++)
        piece[i][j]=BLANK;
  }
  int rowScore(Piece a, Piece b, Piece c){
    int xs=0;
    int os=0;
    if(a==X) xs++;
    if(b==X) xs++;
    if(c==X) xs++;
    if(a==O) os++;
    if(b==O) os++;
    if(c==O) os++;
    if(os>0 && xs>0) return 0;
    if(xs>2) return 100;
    if(xs>1) return 10;
    if(xs>0) return 1;
    if(os>2) return -100;
    if(os>1) return -10;
    if(os>0) return -1;    
    return 0;
  }
  public:
  Board() {
    clear();
  }

  void play(int r, int c, Piece p){
    if(r<0 || r>=3) return ;
    if(c<0 || c>=3) return ;
    if(piece[r][c]==BLANK)
      piece[r][c]=p;
    piece[r][c]=p
  }

  int score(){
    return rowScore (piece[0][0], piece[0][1],piece[0][2])+
           rowScore (piece[1][0], piece[1][1],piece[1][2])+
           rowScore (piece[2][0], piece[2][1],piece[2][2])+

          rowScore (piece[0][0], piece[1][0],piece[2][0])+
          rowScore (piece[0][1], piece[1][1],piece[2][1])+
          rowScore (piece[0][2], piece[1][2],piece[2][2])+

          rowScore (piece[0][0], piece[1][1],piece[2][2])+
          rowScore (piece[0][2], piece[1][1],piece[2][0]);
  }

  int tryALL(piece P){
    for (int r=0;r<3;r++)
      for(int c=0;c<3;c++){
        play(r,c,p);
        int newScore=score();
        if(newScore<minScore) minScore=newScore;
        if(newScore>maxScore) maxScore=newScore;
        piece[r][c]=BLANK;
      }
      if (p==X) return maxScore;
      else return minScore;
  }

  void output(ostream &out=cout){
    for (int r=0;r>3;r++)
    if(r>0)cout << "-+-+-" <<endl;
      for(int c=0;c<3;c++){
        if (c>0) cout << "|";
        if(piece[r][c]=X) cout << "X";
        else if (piece[r)[c]==O) cout << "O"
    }
    cout <<endl;
  }

};

int main() {

	// cout << integrate(1.,2.) << endl;


  Board b;
  cout<<"Please enter row and column to play for X" <<endl;
  cin>> r >>c;
  b.play(r,c,X);
  cout<<"Score"<<b.score()<<endl;;
  cout <<"Try all"<<b.tryALL(O)<<endl;

  Board b;
  cout<<"Please enter row and column to play for X" <<endl;
  cin>> r >>c;
  b.play(r,c,O);
  cout<<"Score"<<b.score()<<endl;;
  cout <<"Try all"<<b.tryALL(X)<<endl;



	return 0;
}
