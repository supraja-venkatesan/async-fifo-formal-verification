`timescale 1ns/1ps

// CHECK(condition, "name"): prints PASS or FAIL and counts failures
`define CHECK(cond, msg) \
    if (cond) $display("PASS: %s", msg); \
    else begin $display("FAIL: %s", msg); errors = errors + 1; end

module tb_sync_fifo;
    localparam DATA_W = 8;
    localparam DEPTH  = 8;

    logic              clk = 0, rst_n = 0;
    logic              wr_en = 0, rd_en = 0;
    logic [DATA_W-1:0] wr_data = 0, rd_data;
    logic              full, empty;
    logic [DATA_W-1:0] got;
    int                errors = 0;

    sync_fifo #(.DATA_W(DATA_W), .DEPTH(DEPTH)) dut (
        .clk(clk), .rst_n(rst_n),
        .wr_en(wr_en), .wr_data(wr_data),
        .rd_en(rd_en), .rd_data(rd_data),
        .full(full), .empty(empty)
    );

    always #5 clk = ~clk;                 // 10 ns clock period

    task automatic push(input [DATA_W-1:0] d);
        @(negedge clk); wr_en = 1; wr_data = d;
        @(negedge clk); wr_en = 0;
    endtask

    task automatic pop(output [DATA_W-1:0] d);
        @(negedge clk); rd_en = 1;
        @(negedge clk); rd_en = 0;
        d = rd_data;                      // data is valid after the read edge
    endtask

    initial begin
        $dumpfile("sim/sync_fifo.vcd");
        $dumpvars(0, tb_sync_fifo);

        repeat (3) @(negedge clk);
        rst_n = 1;
        @(negedge clk);

        // Test 1: state after reset
        `CHECK(empty === 1'b1 && full === 1'b0, "empty after reset")

        // Test 2: fill with 1..8, FIFO must report full
        for (int i = 1; i <= DEPTH; i++) push(i);
        `CHECK(full === 1'b1 && empty === 1'b0, "full after 8 pushes")

        // Test 3: a 9th push while full must be ignored
        push(8'hFF);
        `CHECK(full === 1'b1, "still full after push-when-full")

        // Test 4: drain, values must come out 1..8 in order
        for (int i = 1; i <= DEPTH; i++) begin
            pop(got);
            `CHECK(got === i, "popped value matches pushed value")
        end
        `CHECK(empty === 1'b1 && full === 1'b0, "empty after 8 pops")

        // Test 5: a pop while empty must be ignored
        pop(got);
        `CHECK(empty === 1'b1, "still empty after pop-when-empty")
        `CHECK(got === 8, "rd_data holds last value after ignored read")

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d CHECK(S) FAILED", errors);
        $finish;
    end
endmodule