#include <stdio.h>
#include "openalbridge.h"

int main (int argc, int **argv) {

    openal_init();

    openal_close();

    return 0;
}
