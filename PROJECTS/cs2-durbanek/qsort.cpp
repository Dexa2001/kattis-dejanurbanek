#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

int compare(const void *pa,const void *pb) {
	double *fpa;
	double *fpb;
	fpa=(double *)pa;
	fpb=(double *)pb;
	if (*fpa<*fpb) return -1;
	else if (*fpa>*fpb) return 1;
	else return 0;
}

int main() {

	double values[]={6.0,8.0,1.0,3.0,5.0};
	vector<double> values2;
	values2.push_back(6.0);
	values2.push_back(8.0);
	values2.push_back(1.0);
	values2.push_back(3.0);
	values2.push_back(5.0);
	for (auto d:values2) {
		cout << d << " ";
	}
	cout << endl;

	sort(values2.begin(),values2.end());

	for (auto d:values2) {
		cout << d << " ";
	}
	cout << endl;
	
	int numValues=5; // O(n^2)
/*	for (int i=0;i<numValues;i++) {
	  for (int j=0;j<i;j++) {
	    if (values[i]<values[j]) {
			double t=values[i];
			values[i]=values[j];
			values[j]=t;
	    }
	  }
	} */
	qsort(values,numValues,sizeof(double),compare);
	for (int i=0;i<numValues;i++) 
	  cout << values[i] << ' ';
	cout << endl;
	bool found=false;
	int radix=numValues/2+1;
	int index=radix;
	double x=8.0;
	while(!found && radix>0) {
		if (values[index]==x) {
			cout << index  << endl;
			found=true;
		} else if (x<values[index]) {
			radix/=2;
			index-=radix;
		} else {
			radix/=2;
			index+=radix;
		}
	}
	cout << index << " " << radix <<endl;
	return 0;
}
