// TEST/PROVENANCE ONLY. Each build uses its own actual ISA option.
#include <cstdio>
#include <vector>
#include <string>
#include <zlib.h>
#include <unistd.h>
int main() {
    const std::string actual_version(zlibVersion());
    const std::vector<int> actual_values(4,int(actual_version.size()));
    std::printf("%ld %zu %zu %zu %zu %zu %d %zu %s\n",long(__cplusplus),
        sizeof(void*),sizeof(int),sizeof(bool),sizeof(std::vector<int>),
        sizeof(std::string),int(_GLIBCXX_USE_CXX11_ABI),sizeof(double),actual_version.c_str());
    std::printf("%zu %d\n",actual_values.size(),actual_values.at(0));
    std::fflush(stdout);
    ::sleep(2); // Allow actual loaded scientific DLL capture, not solver timing.
}
