/*
    Dejan Urbanek     CSCI 112
    Final Project: 100fly LCM (long course metter pool) swimming analysis program

    *This program is used to analyze 100fly race and the program will 
    compare the performance of the swimmer with the top 8 swimmers
    (finalists) from the latest major swimming competiton (Tokyo 2021)

    Algorithm steps: 

    1. First the program analyses the performance of the top 8 swimmers from Tokyo 2021
     1.1 The program will get data from the input file ( 100fly top8 ) which can be edited
     1.2 swimmers:
       _____________________________________________________________________________________________________________
       |    #SWIMMER          | BY |  15m |  25m  |  50m | 65m  |  85m |  100m |  AV |  SC | SC 2nd | 50ef | 100ef |
       |============================================================================================================
       | 1.  DRESSEl, Caeleb  | 96'|  5.0 |  10.1 | 23.0 | 29.9 | 41.1 | 49.4  |     |  17 |   19   |      |       | 
       |============================================================================================================
       | 2.  MILAK, Kristof   | 00'|  5.1 |  10.5 | 23.6 | 31.0 | 41.6 | 49.6  |     |  16 |   17   |      |       |     
       |============================================================================================================
       | 3.  PONTI, Noe       | 01'|  5.6 |  10.4 | 23.6 | 30.9 | 42.1 | 50.7  |     |  18 |   20   |      |       |
       |============================================================================================================ 
       | 4.  MINAKOV, Andrei  | 02'|  5.3 |  10.3 | 23.6 | 31.2 | 42.3 | 50.8  |     |  18 |   20   |      |       | 
       |============================================================================================================
       | 5.  TEMPLE, Mathew   | 99'|  5.5 |  10.6 | 23.8 | 31.1 | 42.1 | 50.9  |     |  18 |   20   |      |       | 
       |============================================================================================================
       | 6.  MAJERSKI, Jakub  | 00'|  5.5 |  10.7 | 23.9 | 31.5 | 42.5 | 50.9  |     |  17 |   21   |      |       | 
       |============================================================================================================
       | 7.  MARTINEZ, Carlos | 95'|  5.5 |  10.7 | 24.2 | 31.7 | 42.7 | 51.0  |     |  18 |   20   |      |       |
       |============================================================================================================
       | 8.  MILADINOV, Josif | 03'|  5.5 |  10.8 | 24.0 | 31.8 | 42.9 | 51.4  |     |  18 |   21   |      |       |
       =============================================================================================================

       -speed at certain point
       **AV - average speed
       **SC - stroke count 1st 50m
       **SC 2n - stroke count 2nd 50m
       ** ef - efficiency of the stroke 


    2.  Then the user will be prompted to enter the performance of the swimmer
         whose performance is being tested
     2.1 The data will be captured manually by two or three stopwatches
     2.2 The user will enter the average times/data for each prompted input

    3. The program will then:
        a)calculate the speed, stroke rate and other
        b)then the program will compare the data to our top 8 swimmer
        c)the program will output the differences between the swimmer and our top 8
        d)the program will make suggestions on what to change in the race

*/

#include <iostream>
#include <cmath>
#include <vector>
#include <string>
#include <fstream>

using namespace std;

class Swimmer{
    public:

    string lastname;
    string firstname;
    string birthyear;

    double at15m;
    double at25m;
    double at50m;
    double at65m;
    double at85m;
    double at100m;

    double average;

    double sc1;
    double sc2;

    double ef50m;
    double ef100m;

    void calcVals(){
        average = 100/at100m;
        ef50m = at50m/sc1;
        ef100m =at100m/(sc1+sc2);
    }

};

void top8Data(Swimmer data[8]){

    ifstream fin;
    fin.open("input.txt");
    string input_data;
    int num;
    fin >> num;

    for(int i=0; i<num; i++){
        fin >> data[i].lastname >> data[i].firstname >> data[i].birthyear >> data[i].at15m >> data[i].at25m >> data[i].at50m >> 
               data[i].at65m >> data[i].at85m >> data[i].at100m >>data[i].sc1 >> data[i].sc2;
        data[i].calcVals();
    }

}

void outputTable(Swimmer s[8]){

    cout <<"_________________________________________________________________________________________________________________"<<endl;
    cout<<"|    #SWIMMER          | BY  |  15m |  25m  |  50m  |  65m  |  85m  | 100m |   AV   | SC | SC 2 |  50ef | 100ef |"<<endl;
    cout<<"|================================================================================================================"<<endl;

    for (int i = 0; i < 8; i++)
    {
        cout << "| "<< (i+1) <<".  "<< left << setw(17) << (s[i].lastname + ", " +s[i].firstname) << "| "<< setw(3) << s[i].birthyear<<" |  "<< fixed <<
        setprecision(1) << s[i].at15m<<" |  "<< s[i].at25m<<" |  "<< s[i].at50m<<" |  "<<s[i].at65m<<" |  "<<s[i].at85m<<" | "<<s[i].at100m<<" |  "<<
        setprecision(3) << s[i].average<<" | "<< setprecision(0)<< s[i].sc1<< " |  "<<s[i].sc2 << "  | "<< setprecision(3)<< s[i].ef50m << " | " << s[i].ef100m <<" |" <<endl;
        cout << "|================================================================================================================" << endl;
    }
    ofstream averagesfile;
    averagesfile.open("example");
    averagesfile<<"write"<<endl;
    averagesfile.close();
}

void userTable(Swimmer u){
    cout <<"_________________________________________________________________________________________________________________"<<endl;
    cout<<"|    #SWIMMER          | BY  |  15m |  25m  |  50m  |  65m  |  85m  | 100m |   AV   | SC | SC 2 |  50ef | 100ef |"<<endl;
    cout<<"|================================================================================================================"<<endl;
    cout << "| "<< "?" <<".  "<< left << setw(17) << (u.lastname + ", " + u.firstname) << "| "<< setw(3) << u.birthyear<<" |  "<< fixed <<
    setprecision(1) << u.at15m<<" |  "<< u.at25m<<" |  "<< u.at50m<<" |  "<<u.at65m<<" |  "<<u.at85m<<" | "<<u.at100m<<" |  "<<
    setprecision(3) << u.average<<" | "<< setprecision(0)<< u.sc1<< " |  "<<u.sc2 << "  | "<< setprecision(3)<< u.ef50m << " | " << u.ef100m <<" |" <<endl;
    cout << "|================================================================================================================" << endl;

}

void averageTop8(Swimmer data[8], double average[11]){

    for(int i = 0;i < 8 ;i++){
        average[0] += data[i].at15m;
        average[1] += data[i].at25m;
        average[2] += data[i].at50m;
        average[3] += data[i].at65m;
        average[4] += data[i].at85m;
        average[5] += data[i].at100m;
        average[6] += data[i].average;
        average[7] += data[i].sc1;
        average[8] += data[i].sc2;
        average[9] += data[i].ef50m;
        average[10] += data[i].ef100m;
            
    }

    for(int j=0;j<11;j++){
        average[j]=average[j]/8;
    }

}

void userPerformance(Swimmer u, Swimmer data[8]){
    double average[11] = {0};
    averageTop8(data, average);
    double swimmerVals[11] = { u.at15m, u.at25m, u.at50m, u.at65m, u.at85m, u.at100m, u.average, u.sc1, u.sc2, u.ef50m, u.ef100m} ;
    string suffix[6] = {"15m.", "25m.", "50m.", "65m.", "85m.", "100m."};
   
    for(int i = 0;i < 6 ;i++){
        cout<<"Your swimmer is ";
        if(average[i]<swimmerVals[i]){
            cout<<"slower by "<< abs(average[i]-swimmerVals[i])<<" seconds or " <<(swimmerVals[i]*100 / average[i])-100<<"%"<<" at "<< suffix[i] << endl;
        }
        else if(average[i]>swimmerVals[i]){
            cout<<"faster by " << abs(swimmerVals[i]-average[i])<<" seconds or " <<(average[i]*100 / swimmerVals[i])-100<<"%"<<" at "<< suffix[i] << endl;
        }
        else{
            cout<<"tied with other top 8 swimmers"<<endl;
        }
        
    }
    
    if(swimmerVals[6]<average[6])
        cout<<"Your swimmer is " << abs(swimmerVals[6]-average[6])<<" m/s slower than our top 8 swimmers."<<endl;
        
    if(swimmerVals[6]>average[6])
        cout<<"Your swimmer is " << abs(average[6]-swimmerVals[6])<<" m/s faster than our top 8 swimmers."<<endl;

    if(swimmerVals[6]==average[6])
        cout<<"Your swimmers average speed is tied with the avergae speed of top 8 swimmers"<<endl;

    for(int i=7;i<9;i++){
        if(swimmerVals[i]==average[i] || (swimmerVals[i]-average[i]>0 && swimmerVals[i]-average[i]<1)|| (average[i]-swimmerVals[i]>0 && average[i]-swimmerVals[i]<1))
        cout<<"Your swimmer has same number of strokes as our top 8 swimmers in the ";
        else if(swimmerVals[i]>average[i])
            cout<<"Your swimmer has "<<setprecision(0)<< swimmerVals[i]-average[i]<< " more strokes in the";
        else if(swimmerVals[i]<average[i])
            cout<<"Your swimmer has "<<average[i]-swimmerVals[i]<< " strokes less in the";


        if(i == 7){
            cout << " first 50m" << endl;
        }
        if(i == 8){
            cout << " last 50m" << endl;
        }
    }

}


int main()
{
    cout<<endl;
    cout<<"Current top 8 swimmers from last major competiton."<<endl;
    Swimmer data[8];
    top8Data(data);
    outputTable(data);
    cout<<endl;

    double averages[11];

    averageTop8(data, averages);

    Swimmer user;

    cout<<"Enter your swimmers first name, last name and birth year (00') "<<endl;
    cin>> user.firstname >> user.lastname >> user.birthyear;
    cout<<endl;

    cout<<"Enter " << user.firstname <<" splits at 15, 25, 50, 65, 85, 100 meters"<<endl;
    cin>> user.at15m >> user.at25m >> user.at50m >> user.at65m >> user.at85m >> user.at100m;
    cout<<endl;

    cout<< "How many strokes did " << user.firstname << " had in his first and second 50m?"<<endl;
    cin>> user.sc1 >> user.sc2;

    user.calcVals();

    userTable(user);
    userPerformance(user, data);

    freopen("output.txt","w",stdout);
    userTable(user);
    userPerformance(user, data);

    fclose (stdout);

    return 0;
}
