#include <cstdio>
#include <vector>
#include <string>
#include <zlib.h>
#include <unistd.h>
int main(int argc,char**){std::vector<int> v(argc+4,argc+7);std::string s(v.size(),char(v[1]));printf("%ld %zu %zu %zu %zu %zu %d %d %s\n",(long)__cplusplus,sizeof(void*),sizeof(int),sizeof(bool),sizeof(v),sizeof(s),_GLIBCXX_USE_CXX11_ABI,(int)s[1],zlibVersion());fflush(stdout);sleep(5);return 0;}
