#pragma once
#include <SFML/Graphics.hpp>

class Pluh 
{
private:
    int width;
    size_t imageSize;
    uint8_t* buf;
    uint8_t* cubuf;
    bool* prevFrame;
    bool* currFrame;
public:
    int SigmaBoy();
    void Simulate();
    void DrawPixel(int x, int y, bool value);
    void ClearGrid();
    uint8_t* GetBuf(bool paused);
    size_t GetBufSize();
    void End();
    Pluh(int width);
};