#pragma once

#include <utility>


template <typename T>
class Exmpl {
public:
    Exmpl() = default;
    Exmpl(T&& value) : value_{std::forward<T>(value)} {}

    const T& Get() const { return value_; }

private:
    T value_{};
};


template<>
class Exmpl<void> {
public:
    Exmpl() = default;

    template <typename U>
    Exmpl(U&&) {}

    void Get() const {}
};