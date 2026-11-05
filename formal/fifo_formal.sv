module fifo_formal #(
    parameter int DATA_W = 8,
    parameter int DEPTH  = 8
) (
    input logic              clk,
    input logic              rst_n,
    input logic              wr_en,
    input logic              rd_en,
    input logic [DATA_W-1:0] wr_data
);
    logic [DATA_W-1:0] rd_data;
    logic              full, empty;

    sync_fifo #(.DATA_W(DATA_W), .DEPTH(DEPTH)) dut (
        .clk(clk), .rst_n(rst_n),
        .wr_en(wr_en), .wr_data(wr_data),
        .rd_en(rd_en), .rd_data(rd_data),
        .full(full), .empty(empty)
    );

    // formal setup: start in reset, skip checks before the first clock edge
    initial assume(!rst_n);
    reg f_past_valid = 0;
    always @(posedge clk) f_past_valid <= 1;

    // reference model: how many words SHOULD be inside, using only the ports
    localparam int CW = $clog2(DEPTH) + 1;
    reg [CW-1:0] count;
    always @(posedge clk) begin
        if (!rst_n) count <= 0;
        else        count <= count + (wr_en && count != DEPTH)
                                   - (rd_en && count != 0);
    end

    always @(posedge clk) if (f_past_valid) begin
        // Property 1: full exactly when the model is at DEPTH
        assert(full == (count == DEPTH));

        // Property 2: empty exactly when the model is at 0
        assert(empty == (count == 0));

        // Property 3: full and empty are never both high
        assert(!(empty && full));
    end

    // remembers whether the FIFO has ever been full since reset
    reg was_full = 0;
    always @(posedge clk) begin
        if (!rst_n)    was_full <= 0;
        else if (full) was_full <= 1;
    end

    // covers: prove the interesting states are reachable
    always @(posedge clk) begin
        cover(f_past_valid && full);
        cover(f_past_valid && was_full && empty);   // filled up, then fully drained
    end
endmodule