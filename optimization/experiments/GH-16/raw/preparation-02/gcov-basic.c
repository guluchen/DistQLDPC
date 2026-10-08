#include <stdio.h>
extern void __gcov_dump(void);
int main(void) { puts("GCOV_BASIC"); __gcov_dump(); return 0; }
