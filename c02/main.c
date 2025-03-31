#include <stdio.h>
#include <stdlib.h>

typedef struct Array {
  int *p;
  int len;
  int cap;
} Array;

Array *new_array(int *xs, int len) {
  Array* arr = malloc(sizeof(Array));
  arr->p = xs;
  arr->len = len;
  arr->cap = len;

  return arr;
}

int at(Array *arr, int idx) {
  return arr->p[idx];
}

void foreach(Array *arr, void (*func)(int)) {
  int i;
  for (i = 0; i < arr->len; i++) {
    func(at(arr, i));
  }
}

int is_appendable(Array *arr) {
  return arr->len < arr->cap;
}

void copy(Array *from, Array *to) {
  int i;
  for (i = 0; i < from->len; i++) {
    to->p[i] = from->p[i];
  }
}

Array *append(Array *arr, int new_value) {
  if (is_appendable(arr)) {
    arr->p[arr->len] = new_value;
    arr->len++;

    return arr;
  }

  Array *new_arr = malloc(sizeof(Array));


  new_arr->len = arr->len + 1;
  new_arr->cap = arr->cap * 2;
  int new_p[new_arr->cap];
  new_arr->p = new_p;
  copy(arr, new_arr);
  new_arr->p[new_arr->len-1] = new_value;

  return new_arr;
}

void display_num(int x) {
  printf("%d\n", x);
}

int main() {
  int xs[] = {1, 2, 3, 4, 5};
  Array *arr = new_array(xs, 5);
  arr = append(arr, 10);
  foreach(arr, display_num);

  return 0;
}
