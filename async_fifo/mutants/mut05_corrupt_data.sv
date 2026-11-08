module async_fifo #(
    parameter int DATA_W = 8,
    parameter int DEPTH  = 8              // power of 2, at least 4
) (
    input  logic              wclk, wrst_n,
    input  logic              winc,
    input  logic [DATA_W-1:0] wdata,
    output logic              wfull,

    input  logic              rclk, rrst_n,
    input  logic              rinc,
    output logic [DATA_W-1:0] rdata,
    output logic              rempty
);
    localparam int AW = $clog2(DEPTH);

    logic [DATA_W-1:0] mem [0:DEPTH-1];

    // pointers are AW+1 bits: slot bits plus a lap bit
    logic [AW:0] wbin, wgray, wbin_next, wgray_next;
    logic [AW:0] rbin, rgray, rbin_next, rgray_next;
    logic [AW:0] wgray_sync1, wgray_sync2;   // write pointer synchronized into rclk
    logic [AW:0] rgray_sync1, rgray_sync2;   // read pointer synchronized into wclk

    logic wfull_val, rempty_val;

    // ---------------- write side (wclk) ----------------
    assign wbin_next  = wbin + (winc & ~wfull);
    assign wgray_next = (wbin_next >> 1) ^ wbin_next;

    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wbin  <= '0;
            wgray <= '0;
        end else begin
            wbin  <= wbin_next;
            wgray <= wgray_next;
        end
    end

    always_ff @(posedge wclk) begin
        if (winc & ~wfull)
            mem[wbin[AW-1:0]] <= wdata + 1'b1;  // corrupt the data by adding 1
    end

    // ---------------- read side (rclk) ----------------
    assign rbin_next  = rbin + (rinc & ~rempty);
    assign rgray_next = (rbin_next >> 1) ^ rbin_next;

    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rbin  <= '0;
            rgray <= '0;
        end else begin
            rbin  <= rbin_next;
            rgray <= rgray_next;
        end
    end

    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rdata <= '0;
        else if (rinc & ~rempty)
            rdata <= mem[rbin[AW-1:0]];
    end

    // ---------------- 2-flop synchronizers ----------------
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rgray_sync1 <= '0;
            rgray_sync2 <= '0;
        end else begin
            rgray_sync1 <= rgray;
            rgray_sync2 <= rgray_sync1;
        end
    end

    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wgray_sync1 <= '0;
            wgray_sync2 <= '0;
        end else begin
            wgray_sync1 <= wgray;
            wgray_sync2 <= wgray_sync1;
        end
    end

    // ---------------- flags: compare, then register ----------------
    // full: next write gray equals synced read gray with the top two bits inverted
    assign wfull_val  = (wgray_next == {~rgray_sync2[AW:AW-1], rgray_sync2[AW-2:0]});
    // empty: next read gray equals synced write gray
    assign rempty_val = (rgray_next == wgray_sync2);

    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) wfull <= 1'b0;
        else         wfull <= wfull_val;
    end

    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) rempty <= 1'b1;         // empty after reset
        else         rempty <= rempty_val;
    end
endmodule