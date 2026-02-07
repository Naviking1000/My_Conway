rm app main.o pluh.o
nvcc -c main.cpp pluh.cu
nvcc main.o pluh.o -o app -lsfml-graphics -lsfml-window -lsfml-system
./app
