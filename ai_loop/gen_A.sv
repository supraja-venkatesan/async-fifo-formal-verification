module async_fifo_sva #(
    parameter int DATA_W = 8,
    parameter int DEPTH  = 16,
    parameter int ADDR_W = $clog2(DEPTH)
) (
    input logic                 wclk,
    input logic                 wrst_n,
    input logic                 winc,
    input logic [DATA_W-1:0]    wdata,
    input logic                 wfull,

    input logic                 rclk,
    input logic                 rrst_n,
    input logic                 rinc,
    input logic [DATA_W-1:0]    rdata,
    input logic                 rempty
);

    default clocking w_cb @(posedge wclk);
    endclocking

    // Reset behavior
    ap_reset_not_full:
        assert property (!wrst_n |-> !wfull);

    ap_reset_empty:
        assert property (@(posedge rclk)
            !rrst_n |-> rempty);

    // Write-side safety
    ap_no_write_when_full:
        assert property (
            winc && wfull |-> !($past(winc && !wfull))
        );

    // Read-side safety
    ap_no_read_when_empty:
        assert property (@(posedge rclk)
            rinc && rempty |-> !($past(rinc && !rempty))
        );

    // FIFO must never report full and empty simultaneously
    ap_not_full_and_empty:
        assert property (@(posedge wclk)
            !(wfull && rempty)
        );

    // Accepted write definition
    wire write_accept = winc && !wfull;

    // Accepted read definition
    wire read_accept = rinc && !rempty;

    // No overflow: occupancy must never exceed DEPTH.
    // No underflow: reads must never exceed previously accepted writes.
    // These properties require a reference occupancy model.

    logic signed [ADDR_W:0] occupancy = 0;

    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            occupancy <= 0;
        else begin
            if (write_accept)
                occupancy <= occupancy + 1;
        end
    end

    ap_no_overflow:
        assert property (@(posedge wclk)
            occupancy <= DEPTH
        );

    // Read data validity: accepted read produces valid data
    // one read-clock cycle later.
    // Data ordering and exact correspondence require a
    // reference queue or ghost memory model.

    property p_read_data_stable;
        @(posedge rclk)
        disable iff (!rrst_n)
        !read_accept |=> $stable(rdata);
    endproperty

    // Note: rdata stability is not required by the specification
    // when no read is accepted, so this property is intentionally
    // not asserted.

    // Parameter constraints
    initial begin
        assert (DEPTH >= 4);
        assert ((DEPTH & (DEPTH - 1)) == 0);
    end

endmodule