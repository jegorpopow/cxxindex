struct foo {};
struct bar {};

bar x(foo);

template<int>
struct s {
  bar f(foo);
};

template<int I>
auto x() {
  if constexpr (I == 0) { return int(); }
  else { return float(); }
}

auto z() { return 0; }