/*
Dejan Urbanek   CSCI 112    02/27/2022

Square foot gardening

Each box is 4x4 feet
+-+-+-+-+
| | | | |
+-+-+-+-+
| | | | |
+-+-+-+-+
| | | | |
+-+-+-+-+
| | | | |
+-+-+-+-+

I will use :
  plant        size
|Tomatoes      | 1x1 feet
|Dwarf_Peaches | 2x2 feet
|Raspeberry    | 3x3 feet
|Marigold      | 4x4 feet

*/

#include <iostream>
#include <cmath>
#include <vector>
#include <string>

using namespace std;

class Plants{
    public:
        string getName(){

            return name;
        }

        int getSize(){
            return size;
        }

    protected: 
        string name;
        int size;
};

class Box{
    public:
        void is_planted();

        int planting(Plants sprout){
            bool success;

            if(sprout.getName()=="Tomatoes"){
                success = false;
                for(int x=0; x<4;x++){
                for(int y=0; y<4;y++){
                    if(!success && space[x][y]==false){
                        success = true;
                        space[x][y] = true ;
                        }
                    }
                }            
            }

            if(sprout.getName()=="Dwarf_Peaches"){
                success = false;
                for(int x=0; x<3;x++){
                for(int y=0; y<3;y++){
                    if(!success && !space[x][y] && !space[x+1][y] && !space[x][y+1] && !space[x+1][y+1] ){
                        success = true;
                        space[x][y] = true;
                        space[x+1][y] = true;
                        space[x][y+1] = true;
                        space[x+1][y+1] = true;
                        }
                    }
                }
            }

            if(sprout.getName()=="Raspberry"){
                success=false;
                for(int x=0; x<2; x++){
                for(int y=0; y<2; y++){
                    if(!success && !space[x][y] && !space[x+1][y] && !space[x][y+1] && !space[x+1][y+1] &&
                        !space[x+2][y] && !space[x][y+2] && !space[x+2][y+2] && !space[x+2][y+1] && !space[x+1][y+2]) {
                            success = true;
                            space[x][y] = true;
                            space[x+1][y] = true;
                            space[x+2][y] = true;
                            space[x+1][y+1] = true;
                            space[x+2][y+1] = true;
                            space[x][y+1] = true;
                            space[x][y+2] = true;
                            space[x+1][y+2] = true;
                            space[x+2][y+2] = true;
                        }
                    }   
                }
            }

            if(sprout.getName()=="Marigold"){
                success = true;
                for(int x=0; x<4 ; x++){
                    for(int y =0; y<4 ; y++){
                        if(space[x][y]){
                            success = false;
                        }
                    }
                }

                if (success)
                {
                for(int x=0; x<4 ; x++){
                    for(int y =0; y<4 ; y++){
                        space[x][y] = true;
                        }
                    }
                }
            }

            if (success){
                bool found = false;
                for (int i =0; i < planted.size(); i++){
                    if(planted[i]== sprout.getName())
                    {
                        found = true;
                        plantedAmount[i]++;
                    }
                }
                if (!found){
                planted.push_back(sprout.getName());
                plantedAmount.push_back(1);
                }
                
                return 0;
            }else
                return -1;    
        }

        int spaceleft(){

            int z = 0;

            for(int x=0; x<4;x++)
                for(int y=0; y<4;y++)
                    if(space[x][y]==false)
                        z++;
            return z;
        }

        void display()
        {
            for(int x=0; x<4;x++){
                for(int y=0; y<4;y++){
                    cout << space[x][y] << " ";
                }
                cout << endl;
            }
        }

        void clearBox()
        {
            for(int x=0; x<4;x++){
                for(int y=0; y<4;y++){
                    space[x][y] = false;
                }
            }
        }

        void listPlants()
        {
            for(int i = 0; i< planted.size(); i++)
            {
                cout << plantedAmount[i] << " " << planted[i] << endl;
            }
        }

    private:
        bool space[4][4];
        vector<string> planted;
        vector<int> plantedAmount;
    
};


class Small: public Plants{
    public:
    Small(){
        name = "Tomatoes";
        size = 1;
    }
};

class Medium1: public Plants{
    public:
    Medium1(){
        name = "Dwarf_Peaches";
        size = 2;
    }
};

class Medium2: public Plants{
    public:
    Medium2(){
        name = "Raspberry";
        size = 3;
    }
};

class Large: public Plants{
    public:
    Large(){
        name = "Marigold";
        size = 4;
    }
};

int main(){
    int x;
    int p;
    string plantname;
    vector<Plants> plantList;

    cout<<"How many plants you plan to plant"<<endl;
    cin>>p;

    for(int y=0; y<p; y++){
        cout<<"Enter how much to plants and what to plant: "<<endl;
        cin>>x>>plantname;

        if(plantname=="Tomatoes"){
            Small temp;
            for(int t=0; t<x; t++){

            plantList.push_back(temp);
            }
        }else if(plantname=="Dwarf_Peaches"){
            Medium1 temp;
            for(int t=0; t<x; t++){

            plantList.push_back(temp);
            }
        }else if(plantname=="Raspberry"){
            Medium2 temp;
            for(int t=0; t<x; t++){

            plantList.push_back(temp);
            }
        }else if(plantname=="Marigold"){
            Large temp;
            for(int t=0; t<x; t++){

            plantList.push_back(temp);
            }
        }else{
            cout<<"Plant is not on plantlist"<<endl;

        }
        
    }

    Box temp;
    vector<Box> garden;
    temp.clearBox();
    garden.push_back(temp);
    
    for (int i = 0; i < plantList.size(); i++){

    bool success = false;
        for(int t =0; t< garden.size(); t++){
            if (!success){
            if(garden[t].planting(plantList[i])==0){
                success = true;
            }
            }
        }

        if (!success){
            Box temp1;
            temp1.clearBox();
            temp1.planting(plantList[i]);
            garden.push_back(temp1);
        }
    }
    cout<<endl;
    for(int i=0; i<garden.size(); i++){
        cout <<endl;
        cout<<"Box"<< i+1 <<endl;
        cout<<endl;
        garden[i].display();
        garden[i].listPlants();
        cout<<endl;
    }
    return 0;
}