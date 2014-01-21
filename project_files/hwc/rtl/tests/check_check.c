#include <check.h>
#include <stdlib.h>
#include "check_check.h"

int main(void)
{
    int number_failed;

    Suite *s1 = system_suite();
    Suite *s2 = misc_suite();
    Suite *s3 = sysutils_suite();
    Suite *s4 = fileio_suite();

    SRunner *sr = srunner_create(s1);
    srunner_add_suite(sr, s2);
    srunner_add_suite(sr, s3);
    srunner_add_suite(sr, s4);

    srunner_run_all(sr, CK_NORMAL);
    number_failed = srunner_ntests_failed(sr);
    srunner_free(sr);
    return (number_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}
