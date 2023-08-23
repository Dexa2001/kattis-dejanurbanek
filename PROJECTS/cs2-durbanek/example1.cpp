#include <iostream>
#include <fstream>
#include <cmath>

using namespace std;

class Complex {
    double r, i;
    public:
    Complex(double newR=0.0, double newI=0.0){
        r=newR;
        i=newI;
    }
    void add(const Complex &other) {
        // r+=other.r;
        // i+=other.i;
        (*this) = (*this)=other;
    }
    Complex operator +(const Complex &other) const{
        return Complex(r+other.r, i+other.i);
    }
    void multiply(Complex &other){
        // double tr=r*other.r-i*other.i;
        // i=r*other.i+other.r*i;
        // r=tr;
        (*this)=(*this)*other;
    }
    Complex operator *(const Complex &other) const{
        return Complex(r*other.r-i*other.i, 
                        r*other.i*r+other.r*i);
    }

    Complex operator *(double scalar) const{
        return Complex(r*scalar, i*scalar);
    }
    
    Complex operator /(double scalar) const{
        return Complex(r/scalar, i/scalar);
    }
    
    friend Complex operator *(double scalar, const Complex &other){
        return other*scalar;
    }
    
    friend Complex operator *(const Complex &a, const Complex &b){

    }

    Complex operator -(const Complex &other) const{
        return Complex(r-other.r, i-other.i);
    }
    double getReal(){
        return r;
    }

    double getImaginery(){
        return i;
    }

    double magnitude(){
        return sqrt(r*r+i*i);
    }

    void print(ostream &theStream=cout){
        theStream << " r: "<< r << " i: " << i << endl;
    }
};

// int main(){
//     Complex c;
//     Complex b(M_PI);
//     Complex d;

//     d=c+Complex(1.0,1.0);
//     c.multiply(b);
//     c.print();
//     b.print();

//     return 0;
// }

int main(){
    const int MAXPOINTS = 100;
    const int MAXTRIES = 100;
    Complex ul(-2.0, -2.0);
    Complex lr(2.0, 2.0);
    Complex dp = (ul-lr)/ MAXPOINTS;
    // dp.print();
    for (int x=0; x<MAXPOINTS; x++){
        for(int y=0; y<MAXPOINTS; y++){
            Complex C = ul-Complex(dp.getReal()*y, dp.getImaginery()*x);
            // C.print();
            Complex Z;
            int n;
            for (n=0; n<MAXTRIES;n++){
            Z=Z*Z*Z+C;
            if(Z.magnitude()>2.0) break;
        }
        // cout << n << endl;
        if(n==MAXTRIES) cout <<'#';
        else if(n>=50) cout <<'0';
        else if(n>=25) cout << '=';
        else if(n>=12) cout << '.';
        else cout << ' ';
        }
        cout <<endl;
    }

    return 0;
}