#My name of my exe
EXEC=QueuesDemo
#My source file
SRC=Queue.cpp Stack.cpp
INCLUDES=Queue.h Stack.h

${EXEC}:${INCLUDES} ${SRC} ${EXEC}.cpp Makefile
	g++ -g ${EXEC}.cpp ${SRC} -o $@
	
run: ${EXEC}
	./${EXEC}
	
debug: ${EXEC}
	gdb ${EXEC}
	
clean: 
	rm ${EXEC}
