// Compile against the production translation unit, not a copied implementation.
#define main distqldpc_application_main
#include "../../src/core/distqldpc.cc"
#undef main
#include <chrono>
int main(int argc, char** argv) {
    if (argc != 2) return 2;
    Matrix before = load_matrix(argv[1]);
    const auto start = std::chrono::steady_clock::now();
    Matrix after = shorten_logical_basis(before);
    const auto end = std::chrono::steady_clock::now();
    fprintf(stderr, "preprocess_ns=%lld\n", (long long)
        std::chrono::duration_cast<std::chrono::nanoseconds>(end-start).count());
    for (int r=0; r<after.rows; ++r) {
        for (int c=0; c<after.cols; ++c) printf("%d ", getm(after,r,c));
        printf("\n");
    }
    return 0;
}
