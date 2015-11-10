#include "pmath.h"
#include <stdlib.h>
#include <math.h>

/*
 * power raises base to the power power.
 * This is equivalent to exp(power*ln(base)). Therefore base should be non-negative.
 */
float fpcrtl_power(float base, float exponent)
{
    return exp(exponent * log(base));
}

/* Currently the games only uses sign of an integer */
int fpcrtl_signi(int x)
{
    if(x > 0){
        return 1;
    }
    else if(x < 0){
        return -1;
    }
    else{
        return 0;
    }
}

float fpcrtl_csc(float x)
{
    return 1 / sin(x);
}

float __attribute__((overloadable)) fpcrtl_abs(float x)
{
    return fabs(x);
}
double __attribute__((overloadable)) fpcrtl_abs(double x)
{
    return fabs(x);
}
int __attribute__((overloadable)) fpcrtl_abs(int x)
{
    return abs(x);
}

int64_t __attribute__((overloadable)) fpcrtl_abs(int64_t x)
{
    return x < 0 ? -x : x;
}
