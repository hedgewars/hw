#include <check.h>
#include <stdlib.h>
#include <stdio.h>
#include "check_check.h"
#include "../src/misc.h"

static string255 make_string(const char* str)
{
    string255 s;
    s.len = strlen(str);
    memcpy(s.str, str, s.len + 1);
    return s;
}

START_TEST(test_strconcat)
{
    string255 t;
    t = fpcrtl_strconcat(make_string(""), make_string(""));
    fail_if(strcmp(t.str, ""), "strconcat(\"\", \"\")");

    t = fpcrtl_strconcat(make_string(""), make_string("a"));
    fail_if(strcmp(t.str, "a"), "strconcat(\"\", \"a\")");

    t = fpcrtl_strconcat(make_string("a"), make_string(""));
    fail_if(strcmp(t.str, "a"), "strconcat(\"a\", \"\")");

    t = fpcrtl_strconcat(make_string("ab"), make_string(""));
    fail_if(strcmp(t.str, "ab"), "strconcat(\"ab\", \"\")");

    t = fpcrtl_strconcat(make_string("ab"), make_string("cd"));
    fail_if(strcmp(t.str, "abcd"), "strconcat(\"ab\", \"cd\")");
}
END_TEST

START_TEST (test_strappend)
{
    string255 t;

    t = fpcrtl_strappend(make_string(""), 'c');
    fail_if(strcmp(t.str, "c"), "strappend(\"\", 'c')");

    t = fpcrtl_strappend(make_string("ab"), 'c');
    fail_if(strcmp(t.str, "abc"), "strappend(\"ab\", 'c')");
}
END_TEST

START_TEST (test_strprepend)
{
    string255 t;

    t = fpcrtl_strprepend('c', make_string(""));
    fail_if(strcmp(t.str, "c"), "strprepend('c', \"\")");

    t = fpcrtl_strprepend('c', make_string("ab"));
    fail_if(strcmp(t.str, "cab"), "strprepend('c', \"ab\")");
}
END_TEST

START_TEST (test_strcompare)
{
    fail_unless(fpcrtl_strcompare(make_string(""), make_string("")), "strcompare(\"\", \"\")");
    fail_unless(fpcrtl_strcompare(make_string("a"), make_string("a")), "strcompare(\"a\", \"a\"");
    fail_unless(!fpcrtl_strcompare(make_string("a"), make_string("b")), "strcompare(\"a\", \"b\")");
    fail_unless(!fpcrtl_strcompare(make_string("a"), make_string("ab")), "strcompare(\"a\", \"ab\")");

    fail_unless(fpcrtl_strcomparec(make_string(" "), ' '), "strcomparec(\" \", ' ')");
    fail_unless(fpcrtl_strcomparec(make_string("a"), 'a'), "strcomparec(\"a\", 'a')");
    fail_unless(!fpcrtl_strcomparec(make_string("  "), ' '), "strcomparec(\"  \", ' '");
    fail_unless(!fpcrtl_strcomparec(make_string(""), ' '), "strcomparec(\"\", ' ')");

}
END_TEST

Suite* misc_suite(void)
{
    Suite *s = suite_create("misc");

    TCase *tc_core = tcase_create("Core");

    tcase_add_test(tc_core, test_strconcat);
    tcase_add_test(tc_core, test_strappend);
    tcase_add_test(tc_core, test_strprepend);
    tcase_add_test(tc_core, test_strcompare);

    suite_add_tcase(s, tc_core);

    return s;
}
