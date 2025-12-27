#include <cstdint>
#include <cstring>
#include <iostream>

static inline float u2f(uint32_t u) {
  float f;
  std::memcpy(&f, &u, sizeof(f));
  return f;
}

static inline uint32_t f2u(float f) {
  uint32_t u;
  std::memcpy(&u, &f, sizeof(u));
  return u;
}

int main() {
  unsigned long long op64, a64, b64;

  while (true) {
    if (!(std::cin >> op64)) break;
    if (!(std::cin >> a64 >> b64)) break;

    uint32_t a = static_cast<uint32_t>(a64);
    uint32_t b = static_cast<uint32_t>(b64);

    float fa = u2f(a);
    float fb = u2f(b);
    float fz;

    switch (static_cast<uint32_t>(op64)) {
      case 0: fz = fa + fb; break;  // ADD
      case 1: fz = fa * fb; break;  // MUL
      case 2: fz = fa / fb; break;  // DIV
      default: fz = 0.0f; break;
    }

    std::cout << f2u(fz) << "\n";
  }

  return 0;
}
