#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

__attribute__((optimize("O0"))) int add(int a, int b) { return a + b; }

int main(void) {
    int a = 1, b = 2;
    int s = add(a, b);
    puts("puts: target");
    printf("printf: %d + %d = %d\n", a, b, s);
    write(STDOUT_FILENO, "write: finish\n", 14);
    // _exit(EXIT_SUCCESS);  // skip destructor
    return 0;
}
