// Empty and full must never be asserted simultaneously
always @* begin
    if (wvalid && rvalid && wrst_n && rrst_n) begin
        assert (!(wfull && rempty));
        cover (wfull && rempty);
    end
end
