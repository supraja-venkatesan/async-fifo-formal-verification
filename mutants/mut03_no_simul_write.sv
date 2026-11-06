// MUTANT 03: No simultaneous write and read (accepts simultaneous write and read) 

module sync_fifo #(
    parameter int DATA_W = 8,
    parameter int DEPTH  = 8          // must be a power of 2
) (
    input  logic              clk,
    input  logic              rst_n,   // active-low, synchronous
    input  logic              wr_en,
    input  logic [DATA_W-1:0] wr_data,
    input  logic              rd_en,
    output logic [DATA_W-1:0] rd_data,
    output logic              full,
    output logic              empty
);
    localparam int AW = $clog2(DEPTH);       // address bits

    logic [DATA_W-1:0] mem [0:DEPTH-1];      // the storage
    logic [AW:0]       wr_ptr, rd_ptr;       // AW+1 bits: slot + lap bit

    // status flags, computed from the pointers
    assign empty = (wr_ptr == rd_ptr);
    assign full  = (wr_ptr[AW-1:0] == rd_ptr[AW-1:0]) &&
                   (wr_ptr[AW]     != rd_ptr[AW]);

    // write side
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr <= '0;
        end else if (wr_en && !full && !rd_en) begin
            mem[wr_ptr[AW-1:0]] <= wr_data;
            wr_ptr              <= wr_ptr + 1'b1;
        end
    end

    // read side (registered output)
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rd_ptr  <= '0;
            rd_data <= '0;
        end else if (rd_en && !empty) begin
            rd_data <= mem[rd_ptr[AW-1:0]];
            rd_ptr  <= rd_ptr + 1'b1;
        end
    end
endmodule