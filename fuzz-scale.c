#define _GNU_SOURCE

#include <math.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

/* Exercise the production parser without loading Steam or mutating the environment. */
#include "steam-cef-scale-override.c"

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size);

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  if (size > 128U) {
    return 0;
  }

  char input[129];
  (void)memcpy(input, data, size);
  input[size] = '\0';

  double scale = -1.0;
  const bool accepted = parse_scale(input, &scale);
  if (accepted) {
    if (!isfinite(scale) || scale < MINIMUM_SCALE || scale > MAXIMUM_SCALE) {
      __builtin_trap();
    }
  } else if (scale != -1.0) {
    __builtin_trap();
  }
  return 0;
}
