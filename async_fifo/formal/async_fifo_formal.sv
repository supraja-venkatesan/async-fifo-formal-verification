module async_fifo_formal #(
    parameter int DATA_W = 8,
    parameter int DEPTH  = 8
) (
    input logic              wclk, rclk,        // free: the solver drives both clocks
    input logic              wrst_n, rrst_n,
    input logic              winc, rinc,
    input logic [DATA_W-1:0] wdata
);
    logic [DATA_W-1:0] rdata;
    logic              wfull, rempty;

    async_fifo #(.DATA_W(DATA_W), .DEPTH(DEPTH)) dut (
        .wclk(wclk), .wrst_n(wrst_n), .winc(winc), .wdata(wdata), .wfull(wfull),
        .rclk(rclk), .rrst_n(rrst_n), .rinc(rinc), .rdata(rdata), .rempty(rempty)
    );

    // both resets start asserted, then stay released after each domain's first clock edge
    initial assume(!wrst_n);
    initial assume(!rrst_n);
    reg wvalid = 0, rvalid = 0;
    always @(posedge wclk) begin wvalid <= 1; if (wvalid) assume(wrst_n); end
    always @(posedge rclk) begin rvalid <= 1; if (rvalid) assume(rrst_n); end

    // covers only, to prove the setup works
    always @(posedge wclk) cover(wvalid && wfull);
    always @(posedge rclk) cover(rvalid && !rempty);
endmodule