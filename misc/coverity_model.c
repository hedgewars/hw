void fpcrtl_halt(int num) {
    __coverity_panic__();
}

int fpcrtl_abs(int num) {
    return num >= 0 ? num : -num;
}
