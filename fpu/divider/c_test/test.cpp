#include <cstdint>
#include <cstring>
#include <iostream>

static inline float u32_to_f32(std::uint32_t u) {
    float f;
    std::memcpy(&f, &u, sizeof(f));
    return f;
}

static inline std::uint32_t f32_to_u32(float f) {
    std::uint32_t u;
    std::memcpy(&u, &f, sizeof(u));
    return u;
}

int main() {
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);

    std::uint64_t a_in = 0, b_in = 0;

    // Read pairs; exit cleanly on EOF.
    while (std::cin >> a_in >> b_in) {
        std::uint32_t a = static_cast<std::uint32_t>(a_in);
        std::uint32_t b = static_cast<std::uint32_t>(b_in);

        float fa = u32_to_f32(a);
        float fb = u32_to_f32(b);

        float fz = fa / fb;               // divider reference
        std::uint32_t z = f32_to_u32(fz);

        std::cout << static_cast<unsigned long long>(z) << "\n";
    }
    return 0;
}
