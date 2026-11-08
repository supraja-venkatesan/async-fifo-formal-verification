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
    always @(posedge wclk) wvalid <= 1;
    always @(posedge rclk) rvalid <= 1;
    always @* if (wvalid) assume(wrst_n);   // applies at every step, not only at clock edges
    always @* if (rvalid) assume(rrst_n);

    // covers only, to prove the setup works
    always @(posedge wclk) cover(wvalid && wfull);
    always @(posedge rclk) cover(rvalid && !rempty);


    // ---- data integrity (symbolic tag) across the clock crossing ----
    (* anyconst *) wire [5:0] f_tag;       // solver picks which accepted write to follow
    reg [5:0]        f_wr_cnt = 0;         // accepted writes so far (wclk domain)
    reg [5:0]        f_rd_cnt = 0;         // accepted reads so far (rclk domain)
    reg [DATA_W-1:0] f_tag_data;           // data of the tagged write (captured in wclk)
    reg              f_chk = 0;            // 1 in the rclk cycle when rdata must be checked

    always @(posedge wclk) begin
        if (!wrst_n) f_wr_cnt <= 0;
        else if (winc && !wfull) begin
            f_wr_cnt <= f_wr_cnt + 1;
            if (f_wr_cnt == f_tag) f_tag_data <= wdata;
        end
    end

    always @(posedge rclk) begin
        f_chk <= 0;
        if (!rrst_n) f_rd_cnt <= 0;
        else if (rinc && !rempty) begin
            f_rd_cnt <= f_rd_cnt + 1;
            if (f_rd_cnt == f_tag) f_chk <= 1;
        end
    end

    always @(posedge rclk) if (rvalid && f_chk)
        assert(rdata == f_tag_data);       // the tagged word comes out unchanged

    always @(posedge rclk) cover(rvalid && f_chk);   
endmodule