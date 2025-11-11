#pragma once

namespace util {

    int add(int a, int b);
    double add(double a, double b);

    struct Point 
    {
        int x;
        int y;
    };

    int add(int a, int b) { return a + b; }
    double add(double a, double b) { return a + b; }
    
} // namespace util
