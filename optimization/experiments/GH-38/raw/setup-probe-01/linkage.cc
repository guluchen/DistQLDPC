#include <cstdio>
#include <vector>
#include <zlib.h>
#include <unistd.h>
int main(){std::vector<int> v(3,7);printf("%ld %zu %zu %zu %d %s\n",(long)__cplusplus,sizeof(void*),sizeof(int),sizeof(bool),v[1],zlibVersion());fflush(stdout);sleep(5);return 0;}
