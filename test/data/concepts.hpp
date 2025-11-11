#pragma once

template <typename T>
concept Adable = requires(T a, T b) {
    a + b;
};

template <Adable T>
T sum(T a, T b)
{
    return a + b;
}