#include <stdio.h>
#include <stdlib.h>
#include <libguile.h>

static void run_scm(void *data);

int main(int argc, char **argv) {
  scm_boot_guile(argc, argv, run_scm, NULL);

  return 0;
}

static void run_scm(void *data) {
  load_scm();
  int x = 1;
  printf("inc: %d\tdec: %d\n", inc(x), dec(x));
}

void load_scm() {
  scm_c_primitive_load("util.scm");
}

int inc(int x) {
  SCM func = scm_variable_ref(scm_c_lookup("inc"));
  SCM result = scm_call_1(func, scm_from_int(x));

  return scm_to_int(result);
}

int dec(int x) {
  SCM func = scm_variable_ref(scm_c_lookup("dec"));
  SCM result = scm_call_1(func, scm_from_int(x));

  return scm_to_int(result);
}
