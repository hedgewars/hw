#include <check.h>
#include <stdlib.h>
#include <stdio.h>
#include "check_check.h"
#include "../src/system.h"

void check_string(string255 str)
{
    fail_unless(strlen(str.str) == str.len, "String internal inconsistency error");
}

static string255 make_string(const char* str)
{
    string255 s;
    s.len = strlen(str);
    memcpy(s.str, str, s.len + 1);
    return s;
}

START_TEST (test_copy)
    {
        string255 s = STRINIT("1234567");
        string255 t;

        t = fpcrtl_copy(s, 1, 1);
        fail_if(strcmp(t.str, "1"), "Test copy fail 1");

        t = fpcrtl_copy(s, 7, 1);
        fail_if(strcmp(t.str, "7"), "Test copy fail 2");

        t = fpcrtl_copy(s, 8, 1);
        fail_if(t.len != 0, "Test copy fail 3");

        t = fpcrtl_copy(s, 8, 100);
        fail_if(t.len != 0, "Test copy fail 4");
        check_string(t);

        t = fpcrtl_copy(s, 0, 100);
        fail_if(strcmp(t.str, "1234567"), "Test copy fail 5");

        t = fpcrtl_copy(s, 0, 5);
        fail_if(strcmp(t.str, "12345"), "Test copy fail 6");

        t = fpcrtl_copy(s, 4, 100);
        fail_if(strcmp(t.str, "4567"), "Test copy fail 7");

        t = fpcrtl_copy(s, 4, 2);
        fail_if(strcmp(t.str, "45"), "Test copy fail 8");
    }END_TEST

START_TEST (test_delete)
    {
        string255 s = STRINIT("1234567");
        string255 s2 = STRINIT("1234567");
        string255 s3 = STRINIT("1234567");

        fpcrtl_delete(s, 0, 10);
        fail_if(strcmp(s.str, "1234567"), "delete(\"1234567\", 0, 10)");
        check_string(s);

        fpcrtl_delete(s, 1, 1);
        fail_if(strcmp(s.str, "234567"), "delete(\"1234567\", 1, 1)");
        check_string(s);

        fpcrtl_delete(s, 1, 100);
        fail_if(strcmp(s.str, ""), "delete(\"234567\", 1, 100)");
        check_string(s);

        fpcrtl_delete(s2, 3, 2);
        fail_if(strcmp(s2.str, "12567"), "delete(\"1234567\", 3, 2)");
        check_string(s2);

        fpcrtl_delete(s3, 3, 100);
        fail_if(strcmp(s3.str, "12"), "delete(\"1234567\", 3, 100)");
        check_string(s3);

    }
END_TEST

START_TEST (test_FloatToStr)
    {
        double s = 1.2345;
        string255 t = fpcrtl_floatToStr(s);
        printf("-----Entering test floatToStr-----\n");
        printf("FloatToStr(%f) = %s\n", s, t.str);
        printf("-----Leaving test floatToStr-----\n");
    }
END_TEST

START_TEST (test_random)
    {
        fpcrtl_randomize();
        printf("-----Entering test random-----\n");
        printf("random(5000) = %d\n", fpcrtl_random(5000));
        printf("random(1) = %d\n", fpcrtl_random(1));
        printf("random(2) = %d\n", fpcrtl_random(2));
        printf("-----Leaving test random-----\n");

    }
END_TEST

START_TEST (test_posS)
    {
        string255 substr1 = STRINIT("123");
        string255 str1 = STRINIT("12345");

        string255 substr2 = STRINIT("45");
        string255 str2 = STRINIT("12345");

        string255 substr3 = STRINIT("");
        string255 str3 = STRINIT("12345");

        string255 substr4 = STRINIT("123");
        string255 str4 = STRINIT("");

        string255 substr5 = STRINIT("123");
        string255 str5 = STRINIT("456");

        fail_unless(fpcrtl_posS(substr1, str1) == 1, "pos(123, 12345)");
        fail_unless(fpcrtl_posS(substr2, str2) == 4, "pos(45, 12345)");
        fail_unless(fpcrtl_posS(substr3, str3) == 0, "pos(, 12345)");
        fail_unless(fpcrtl_posS(substr4, str4) == 0, "pos(123, )");
        fail_unless(fpcrtl_posS(substr5, str5) == 0, "pos(123, 456)");
    }
END_TEST

START_TEST (test_trunc)
    {
          fail_unless(fpcrtl_trunc(123.456) == 123, "trunc(123.456)");
          fail_unless(fpcrtl_trunc(-123.456) == -123, "trunc(-123.456)");
          fail_unless(fpcrtl_trunc(12.3456) == 12, "trunc(12.3456)");
          fail_unless(fpcrtl_trunc(-12.3456) == -12, "trunc(-12.3456)");
          fail_unless(fpcrtl_trunc(0.3) == 0, "trunc(0.3)");
          fail_unless(fpcrtl_trunc(0.5) == 0, "trunc(0.5)");
          fail_unless(fpcrtl_trunc(99.9999999) == 99, "trunc(99.9999999)");
          fail_unless(fpcrtl_trunc(0x01000000.0) == 0x01000000, "trunc(0x01000000.0)");
          fail_unless(fpcrtl_trunc(0x01000001.0) == 0x01000001, "trunc(0x01000001.0)");
          fail_unless(fpcrtl_trunc(0x02000000.0) == 0x02000000, "trunc(0x02000000.0)");
          fail_unless(fpcrtl_trunc(0x04000000.0) == 0x04000000, "trunc(0x04000000.0)");
          fail_unless(fpcrtl_trunc(0x08000000.0) == 0x08000000, "trunc(0x08000000.0)");
          fail_unless(fpcrtl_trunc(0x10000000.0) == 0x10000000, "trunc(0x10000000.0)");
          fail_unless(fpcrtl_trunc(0x10000001.0) == 0x10000001, "trunc(0x10000001.0)");
          fail_unless(fpcrtl_trunc(0x20000000.0) == 0x20000000, "trunc(0x20000000.0)");
          fail_unless(fpcrtl_trunc(0x40000000.0) == 0x40000000, "trunc(0x40000000.0)");
          fail_unless(fpcrtl_trunc(0x80000000.0) == 0x80000000, "trunc(0x80000000.0)");
          fail_unless(fpcrtl_trunc(0xF0000000.0) == 0xF0000000, "trunc(0xF0000000.0)");
          fail_unless(fpcrtl_trunc(0xF0000001.0) == 0xF0000001, "trunc(0xF0000001.0)");
          fail_unless(fpcrtl_trunc(0x01010101.0) == 0x01010101, "trunc(0x01010101.0)");
          fail_unless(fpcrtl_trunc(0xFFFFFFFF.0) == 0xFFFFFFFF, "trunc(0xFFFFFFFF.0)");
          fail_unless(fpcrtl_trunc(0x8943FE39.0) == 0x8943FE39, "trunc(0x01000000.0)");
    }
END_TEST

START_TEST (test_odd)
{
    fail_unless(fpcrtl_odd(123) != 0, "odd(123)");
    fail_unless(fpcrtl_odd(124) == 0, "odd(124)");
    fail_unless(fpcrtl_odd(0) == 0, "odd(0)");
    fail_unless(fpcrtl_odd(-1) != 0, "odd(-1)");
    fail_unless(fpcrtl_odd(-2) == 0, "odd(-2)");
}
END_TEST

START_TEST (test_sqr)
{
    fail_unless(fpcrtl_sqr(0) == 0, "sqr(0)");
    fail_unless(fpcrtl_sqr(5) == 25, "sqr(5)");
    fail_unless(fpcrtl_sqr(-5) == 25, "sqr(-5)");
}
END_TEST

START_TEST (test_lowercase)
{
    string255 s1 = STRINIT("");
    string255 s2 = STRINIT("a");
    string255 s3 = STRINIT("abc");
    string255 t;

    t = fpcrtl_lowerCase(make_string(""));
    fail_if(strcmp(t.str, s1.str), "lowerCase(\"\")");

    t = fpcrtl_lowerCase(make_string("a"));
    fail_if(strcmp(t.str, s2.str), "lowerCase(\"a\")");

    t = fpcrtl_lowerCase(make_string("A"));
    fail_if(strcmp(t.str, s2.str), "lowerCase(\"A\")");

    t = fpcrtl_lowerCase(make_string("AbC"));
    fail_if(strcmp(t.str, s3.str), "lowerCase(\"AbC\")");

    t = fpcrtl_lowerCase(make_string("abc"));
    fail_if(strcmp(t.str, s3.str), "lowerCase(\"abc\")");
}
END_TEST

START_TEST (test_str)
{
    int8_t a1 = -8;
    uint8_t a2 = 8;
    int16_t a3 = -13;
    uint16_t a4 = 13;
    int32_t a5 = -19;
    uint32_t a6 = 22;
    int64_t a7 = -199999999999999;
    uint64_t a8 = 200000000000000;

    float a9 = 12345.6789;
    double a10 = -9876.54321;

    string255 s;

    printf("-----Entering test str-----\n");

    fpcrtl_str(a1, s);
    printf("%d == %s\n", a1, s.str);

    fpcrtl_str(a2, s);
    printf("%u == %s\n", a2, s.str);

    fpcrtl_str(a3, s);
    printf("%d == %s\n", a3, s.str);

    fpcrtl_str(a4, s);
    printf("%u == %s\n", a4, s.str);

    fpcrtl_str(a5, s);
    printf("%d == %s\n", a5, s.str);

    fpcrtl_str(a6, s);
    printf("%u == %s\n", a6, s.str);

    fpcrtl_str(a7, s);
    printf("%lld == %s\n", a7, s.str);

    fpcrtl_str(a8, s);
    printf("%llu == %s\n", a8, s.str);

    fpcrtl_str(a9, s);
    printf("%f == %s\n", a9, s.str);

    fpcrtl_str(a10, s);
    printf("%f == %s\n", a10, s.str);

    printf("-----Leaving test str------\n");
}
END_TEST

Suite* system_suite(void)
{
    Suite *s = suite_create("system");

    TCase *tc_core = tcase_create("Core");

    tcase_add_test(tc_core, test_copy);
    tcase_add_test(tc_core, test_FloatToStr);
    tcase_add_test(tc_core, test_random);
    tcase_add_test(tc_core, test_posS);
    tcase_add_test(tc_core, test_trunc);
    tcase_add_test(tc_core, test_delete);
    tcase_add_test(tc_core, test_odd);
    tcase_add_test(tc_core, test_sqr);
    tcase_add_test(tc_core, test_lowercase);
    tcase_add_test(tc_core, test_str);

    suite_add_tcase(s, tc_core);

    return s;
}

