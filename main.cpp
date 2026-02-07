#include <SFML/Graphics.hpp>
#include <stdio.h>
#include <chrono>
#include <thread>
#include "pluh.cuh"

bool paused = false, lmb = false, rmb = false;

int main()
{
    int width = 100;
    sf::RenderWindow window(sf::VideoMode({1000, 1000}), "ts is PEAK Conway");
    sf::Texture frameBuffer;
    Pluh pluh(width);

    if (pluh.SigmaBoy())
        return 1;
    if (!frameBuffer.resize(sf::Vector2u(width, width)))
    {
        pluh.End();
        return 1;
    }
    frameBuffer.update(pluh.GetBuf(paused));
    sf::Sprite frameSprite(frameBuffer);
    float spriteScale = 1000.0f / width;
    frameSprite.setScale(sf::Vector2f(spriteScale, spriteScale));

    size_t fps = 60;
    size_t nanoWait = (size_t)((1.0 / (double)fps) * 1000000000);

    size_t waitTime = 0;

    while (window.isOpen())
    {
        auto startTime = std::chrono::steady_clock::now();
        while (const std::optional event = window.pollEvent())
        {
            if (event->is<sf::Event::Closed>())
                window.close();
            if (const auto* keyPressed = event->getIf<sf::Event::KeyPressed>())
            {
                if (keyPressed->scancode == sf::Keyboard::Scancode::Space)
                    paused = !paused;
                if (keyPressed->scancode == sf::Keyboard::Scancode::C)
                    pluh.ClearGrid();
            }
            if (const auto* mouseDown = event->getIf<sf::Event::MouseButtonPressed>())
            {
                if (mouseDown->button == sf::Mouse::Button::Left)
                {
                    if (!lmb)
                    {
                        pluh.DrawPixel(mouseDown->position.x * width / window.getSize().x, mouseDown->position.y * width / window.getSize().y, true);
                        lmb = true;
                        rmb = false;
                    }
                }
                if (mouseDown->button == sf::Mouse::Button::Right)
                {
                    if (!rmb)
                    {
                        pluh.DrawPixel(mouseDown->position.x * width / window.getSize().x, mouseDown->position.y * width / window.getSize().y, false);
                        rmb = true;
                        lmb = false;
                    }
                }
            }
            if (const auto* mouseUp = event->getIf<sf::Event::MouseButtonReleased>())
            {
                if (mouseUp->button == sf::Mouse::Button::Left)
                {
                    lmb = false;
                }
                if (mouseUp->button == sf::Mouse::Button::Right)
                {
                    rmb = false;
                }
            }
            if (const auto *mouseMoved = event->getIf<sf::Event::MouseMoved>())
            {
                int x = mouseMoved->position.x * width / window.getSize().x;
                int y = mouseMoved->position.y * width / window.getSize().y;
                if (lmb)
                {
                    pluh.DrawPixel(x, y, true);
                }
                if (rmb)
                {
                    pluh.DrawPixel(x, y, false);
                }
            }
        }

        window.clear();
        if (!paused)
        {
            pluh.Simulate();
        }
        frameBuffer.update(pluh.GetBuf(paused));
        window.draw(frameSprite);
        window.display();
        auto endTime = std::chrono::steady_clock::now();
        auto loopTime = endTime - startTime;
        waitTime += nanoWait - loopTime.count();
        if (waitTime > 0)
        {
            auto sleepStart = std::chrono::steady_clock::now();
            std::this_thread::sleep_for(std::chrono::nanoseconds(waitTime));
            waitTime -= (std::chrono::steady_clock::now() - sleepStart).count();
        }
    }
    pluh.End();
    return 0;
}
