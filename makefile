CXX = g++
CXXFLAGS = -c -g -Wall -std=c++17
PROGRAM = userfunc
CPPFILES = linethemup.cpp
all:
	$(CXX) $(CXXFLAGS) $(CPPFILES)
	$(CXX) -o $(PROGRAM) *.o

clean:
	rm -f $(PROGRAM) *.o

run:
	./$(PROGRAM)

test:
	./$(PROGRAM) tests
