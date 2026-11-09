`timescale 1ns/1ps

module tb_top;
    import uvm_pkg::*;
    import fifo_pkg::*;
    localparam DATA_W = 8;
    localparam DEPTH  = 8;

    logic wclk = 0, rclk = 0;
    always #5 wclk = ~wclk;      // 10 ns period
    always #7 rclk = ~rclk;      // 14 ns period

    fifo_if #(.DATA_W(DATA_W)) vif (.wclk(wclk), .rclk(rclk));

    async_fifo #(.DATA_W(DATA_W), .DEPTH(DEPTH)) dut (
        .wclk(wclk), .wrst_n(vif.wrst_n), .winc(vif.winc), .wdata(vif.wdata), .wfull(vif.wfull),
        .rclk(rclk), .rrst_n(vif.rrst_n), .rinc(vif.rinc), .rdata(vif.rdata), .rempty(vif.rempty)
    );

    initial begin
        vif.wrst_n = 0; vif.rrst_n = 0;
        vif.winc   = 0; vif.rinc   = 0; vif.wdata = 0;
        repeat (4) @(negedge wclk);
        vif.wrst_n = 1;
        repeat (4) @(negedge rclk);
        vif.rrst_n = 1;


    end

    initial begin
        uvm_config_db#(virtual fifo_if)::set(null, "*", "vif", vif);
        run_test();
    end
endmodule