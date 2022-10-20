#include <stdint.h>

#include <Valu.h>
#include "driver.h"

uint32_t test() {
  auto value = 999999;
  auto alu = new Valu();
  alu->lhs = 1;
  alu->rhs = 2;
  alu->eval();
  value = alu->res;
  delete alu;

  return value;
}
