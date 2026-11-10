module ai_formal #(
    parameter int DATA_W = 8,
    parameter int DEPTH  = 8
) (
    input logic              wclk, rclk,
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

    // environment: same constraints as the hand-written wrapper
    initial assume(!wrst_n);
    initial assume(!rrst_n);
    reg wvalid = 0, rvalid = 0;           // 1 after each domain's first clock edge
    always @(posedge wclk) wvalid <= 1;
    always @(posedge rclk) rvalid <= 1;
    always @* if (wvalid) assume(wrst_n);
    always @* if (rvalid) assume(rrst_n);

    `include "ai_assertions.sv"           // LLM-generated code goes here
endmodule