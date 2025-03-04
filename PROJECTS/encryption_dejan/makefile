# Variables
CXX = g++
CXXFLAGS = -Wall -std=c++17
TARGET = encryption_program

# Build target
all: $(TARGET)

$(TARGET): enc.cpp
	$(CXX) $(CXXFLAGS) -o $(TARGET) enc.cpp

# Clean target
clean:
	rm -f $(TARGET)