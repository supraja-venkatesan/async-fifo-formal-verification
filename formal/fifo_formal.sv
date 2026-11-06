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


    // ---- data integrity: follow ONE accepted write through the FIFO ----
    (* anyconst *) wire [5:0] f_tag;       // solver picks which accepted write to follow
    reg [5:0]        f_wr_cnt = 0;         // accepted writes so far
    reg [5:0]        f_rd_cnt = 0;         // accepted reads so far
    reg [DATA_W-1:0] f_tag_data;           // data of the tagged write
    reg              f_chk = 0;            // 1 in the cycle when rd_data must be checked

    wire f_wr_acc = rst_n && wr_en && !full;
    wire f_rd_acc = rst_n && rd_en && !empty;

    always @(posedge clk) begin
        f_chk <= 0;
        if (!rst_n) begin
            f_wr_cnt <= 0;
            f_rd_cnt <= 0;
        end else begin
            if (f_wr_acc) begin
                f_wr_cnt <= f_wr_cnt + 1;
                if (f_wr_cnt == f_tag) f_tag_data <= wr_data;
            end
            if (f_rd_acc) begin
                f_rd_cnt <= f_rd_cnt + 1;
                if (f_rd_cnt == f_tag) f_chk <= 1;
            end
        end
    end

    always @(posedge clk) if (f_past_valid && f_chk)
        assert(rd_data == f_tag_data);     // Property 4: tagged item comes out unchanged

    // cover: the data check is actually reachable (guards against a vacuous Property 4)
    always @(posedge clk) cover(f_past_valid && f_chk);

endmodule