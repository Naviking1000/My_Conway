rm app main.o pluh.o
nvcc --compiler-bindir /usr/bin/gcc-14 -c main.cpp pluh.cu
nvcc main.o pluh.o -o app -lsfml-graphics -lsfml-window -lsfml-system
./app
