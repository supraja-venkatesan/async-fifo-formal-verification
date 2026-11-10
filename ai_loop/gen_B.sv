// Write-side: no write accepted while full
always @(posedge wclk) begin
    if (wrst_n && wvalid) begin
        assert (!(winc && wfull) || wfull);
        cover (winc && wfull);
    end
end

// Read-side: no read accepted while empty
always @(posedge rclk) begin
    if (rrst_n && rvalid) begin
        assert (!(rinc && rempty) || rempty);
        cover (rinc && rempty);
    end
end

// Empty and full must never be asserted simultaneously
always @* begin
    if (wvalid && rvalid && wrst_n && rrst_n) begin
        assert (!(wfull && rempty));
        cover (wfull && rempty);
    end
end

// Write-side: full flag must be known to the environment
always @(posedge wclk) begin
    if (wrst_n && wvalid) begin
        cover (wfull);
        cover (!wfull);
    end
end

// Read-side: empty flag must be known to the environment
always @(posedge rclk) begin
    if (rrst_n && rvalid) begin
        cover (rempty);
        cover (!rempty);
    end
end

// Write and read activity can occur
always @(posedge wclk) begin
    if (wrst_n && wvalid)
        cover (winc && !wfull);
end

always @(posedge rclk) begin
    if (rrst_n && rvalid)
        cover (rinc && !rempty);
end