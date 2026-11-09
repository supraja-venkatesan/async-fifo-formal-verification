interface fifo_if #(parameter int DATA_W = 8) (input logic wclk, input logic rclk);
    logic              wrst_n, rrst_n;
    logic              winc, rinc;
    logic [DATA_W-1:0] wdata, rdata;
    logic              wfull, rempty;
endinterface
