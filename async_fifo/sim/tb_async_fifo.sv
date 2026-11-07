`timescale 1ns/1ps

`define CHECK(cond, msg) \
    if (cond) $display("PASS: %s", msg); \
    else begin $display("FAIL: %s", msg); errors = errors + 1; end

module tb_async_fifo;
    localparam DATA_W = 8;
    localparam DEPTH  = 8;

    logic              wclk = 0, rclk = 0;
    logic              wrst_n = 0, rrst_n = 0;
    logic              winc = 0, rinc = 0;
    logic [DATA_W-1:0] wdata = 0, rdata;
    logic              wfull, rempty;
    logic [DATA_W-1:0] got;
    int                errors = 0;
    int                accepted;

    async_fifo #(.DATA_W(DATA_W), .DEPTH(DEPTH)) dut (
        .wclk(wclk), .wrst_n(wrst_n), .winc(winc), .wdata(wdata), .wfull(wfull),
        .rclk(rclk), .rrst_n(rrst_n), .rinc(rinc), .rdata(rdata), .rempty(rempty)
    );

    always #5 wclk = ~wclk;     // 10 ns period
    always #7 rclk = ~rclk;     // 14 ns period, unrelated to wclk

    
    task push(input [DATA_W-1:0] d);
        @(negedge wclk);
        winc  = 1;
        wdata = d;
        @(negedge wclk);
        winc  = 0;
    endtask

    
    task pop(output [DATA_W-1:0] d);
        @(negedge rclk);
        rinc = 1;
        @(negedge rclk);
        rinc = 0;
        d    = rdata;
    endtask

    initial begin
        repeat (4) @(negedge wclk);
        wrst_n = 1;
        repeat (4) @(negedge rclk);
        rrst_n = 1;
        repeat (2) @(negedge wclk);

        `CHECK(rempty === 1'b1 && wfull === 1'b0, "empty and not full after reset")

        
        // a) push 1..DEPTH+2 (2 extra, to test push-when-full is ignored)
        for (int i = 1; i <= DEPTH + 2; i++) begin
            push(i[DATA_W-1:0]);
        end

        // b) CHECK wfull === 1
        `CHECK(wfull === 1'b1, "wfull asserted after filling beyond capacity")

        // c) wait about 6 rclk cycles for the write pointer to cross over, then CHECK rempty === 0
        repeat (6) @(posedge rclk);
        `CHECK(rempty === 1'b0, "rempty deasserted after write pointer crosses to read domain")

        // d) pop DEPTH times, CHECK each popped value equals its index
        for (int i = 1; i <= DEPTH; i++) begin
            pop(got);
            `CHECK(got === i[DATA_W-1:0], "popped data matches pushed index")
        end

        // e) wait about 6 wclk cycles, then CHECK wfull === 0
        repeat (6) @(posedge wclk);
        `CHECK(wfull === 1'b0, "wfull deasserted after read pointer crosses to write domain")

        // f) CHECK rempty === 1 after the last pop
        `CHECK(rempty === 1'b1, "rempty asserted after popping all entries")

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d CHECK(S) FAILED", errors);
        $finish;
    end
endmodule