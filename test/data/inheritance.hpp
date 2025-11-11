#pragma once

struct Base {
    virtual ~Base() = default;
    virtual int id() const { return 0; }
};

struct Derived : public Base {
    virtual int id() const override { return 1; }
};