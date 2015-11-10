#include <check.h>
#include <stdlib.h>
#include <stdio.h>
#include "check_check.h"
#include "../src/sysutils.h"

static string255 make_string(const char* str)
{
    string255 s;
    s.len = strlen(str);
    memcpy(s.str, str, s.len + 1);
    return s;
}

static int is_string_equal(string255 s1, string255 s2)
{
    return (s1.len == s2.len) && (strcmp(s1.str, s2.str) == 0);
}

START_TEST (test_trim)
{
    string255 t;

    t = fpcrtl_trim(make_string(""));
    fail_if(strcmp(t.str, ""), "trim(\"\")");

    t = fpcrtl_trim(make_string("ab"));
    fail_if(strcmp(t.str, "ab"), "trim(\"ab\")");

    t = fpcrtl_trim(make_string(" "));
    fail_if(strcmp(t.str, ""), "trim(\" \")");

    t = fpcrtl_trim(make_string("   "));
    fail_if(strcmp(t.str, ""), "trim(\"   \")");

    t = fpcrtl_trim(make_string(" ab"));
    fail_if(strcmp(t.str, "ab"), "trim(\" ab\")");

    t = fpcrtl_trim(make_string("ab  "));
    fail_if(strcmp(t.str, "ab"), "trim(\"ab  \")");

    t = fpcrtl_trim(make_string("  ab  "));
    fail_if(strcmp(t.str, "ab"), "trim(\"  ab  \")");

}
END_TEST

START_TEST (test_strToInt)
{
    fail_unless(fpcrtl_strToInt(make_string("123")) == 123, "strToInt(\"123\")");
    fail_unless(fpcrtl_strToInt(make_string("0")) == 0, "strToInt(\"0\")");
    fail_unless(fpcrtl_strToInt(make_string("-123")) == -123, "strToInt(\"-123\")");
}
END_TEST

START_TEST (test_extractFileName)
{
    fail_unless(is_string_equal(fpcrtl_extractFileName(make_string("abc")), make_string("abc")), "extractFileName(\"abc\")");
    fail_unless(is_string_equal(fpcrtl_extractFileName(make_string("a:abc")), make_string("abc")), "extractFileName(\"a:abc\")");
    fail_unless(is_string_equal(fpcrtl_extractFileName(make_string("/abc")), make_string("abc")), "extractFileName(\"/abc\")");
    fail_unless(is_string_equal(fpcrtl_extractFileName(make_string("\\abc")), make_string("abc")), "extractFileName(\"\\abc\")");
    fail_unless(is_string_equal(fpcrtl_extractFileName(make_string("/usr/bin/abc")), make_string("abc")), "extractFileName(\"/usr/bin/abc\")");
    fail_unless(is_string_equal(fpcrtl_extractFileName(make_string("c:\\def\\abc")), make_string("abc")), "extractFileName(\"c:\\def\\abc\")");
}
END_TEST

Suite* sysutils_suite(void)
{
    Suite *s = suite_create("sysutils");

    TCase *tc_core = tcase_create("Core");

    tcase_add_test(tc_core, test_trim);
    tcase_add_test(tc_core, test_strToInt);
    tcase_add_test(tc_core, test_extractFileName);

    suite_add_tcase(s, tc_core);

    return s;
}
