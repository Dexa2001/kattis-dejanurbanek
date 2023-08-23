#include <queue>
#include <cmath>
#include <iostream>

// abstract
// pure virtual
	// function
	// class
// concrete

using namespace std;

class Functor {
	public:
	virtual double f(double x)=0;
};

class IntegrationRequest {
	double a,b,epsilon;
	public:
	void setParams(double newA,double newB,double newEpsilon) {
		a=newA;
		b=newB;
		epsilon=newEpsilon;
	}
	void copyFrom(IntegrationRequest other) {
		a=other.a;
		b=other.b;
		epsilon=other.epsilon;
	}
    double integrate(Functor *integrand) {
	  queue<IntegrationRequest> sections;
	  sections.push(*this);
	  double sum=0.0;
	  while (sections.size()>0) {
		  copyFrom(sections.front());
		  sections.pop();
          double fa=integrand->f(a);
		  double fb=integrand->f(b);
		  double A2=0.5*(fa+fb)*(b-a);
		  double m=(a+b)/2.0;
		  double fm=integrand->f(m);
		  double A3=0.5*(fa+fm)*(m-a)+
				0.5*(fm+fb)*(b-m);
		  if (fabs(A2-A3)<epsilon) sum+=A3;
		  else //return integrate(a,m,epsilon/2.0)+integrate(m,b,epsilon/2.0);
		  {
			  IntegrationRequest first;
			  first.setParams(a,m,epsilon/2.0);
			  sections.push(first);
			  IntegrationRequest second;
			  second.setParams(m,b,epsilon/2.0);
			  sections.push(second);
		  }
      }
      return sum;
    }
};

class Easy:public Functor {
	double f(double x) {return x*x; }
};

class Hard:public Functor {
  double f(double x) { return x*sin(x)/exp(x);  }
};

int main() {
    Hard e;
    IntegrationRequest result;
    result.setParams(0,1,0.001);
    cout << result.integrate(&e) << endl;	
	return 0;
}
