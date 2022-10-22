#include <verilated_vcd_c.h>
#include <stdint.h>

extern "C" {
  VerilatedVcdC *alloc_vcd() {
    Verilated::traceEverOn(true);
    auto vcd = new VerilatedVcdC();
    vcd->set_time_resolution("1ps");
    return vcd;
  }

  void open_vcd(VerilatedVcdC *vcd, const char *file) {
    vcd->open(file);
  }

  void free_vcd(VerilatedVcdC *vcd) {
    vcd->close();
    delete vcd;
  }

  void dump_vcd(VerilatedVcdC *vcd, uint64_t time) {
    vcd->dump(time);
  }
}
