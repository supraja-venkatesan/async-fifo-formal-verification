`timescale 1ns/1ps

package fifo_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    `include "wr_item.sv"
    `include "wr_driver.sv"
    `include "wr_monitor.sv"
    `include "rd_item.sv"
    `include "rd_driver.sv"
    `include "rd_monitor.sv"
    `include "scoreboard.sv"
    `include "seqs.sv"
    `include "fifo_env.sv"
    `include "fifo_test.sv"
endpackage