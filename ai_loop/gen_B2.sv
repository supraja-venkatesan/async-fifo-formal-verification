// Read-side: no read accepted while empty
always @(posedge rclk) begin
    if (rrst_n && rvalid) begin
        assert (!(rinc && rempty) || rempty);
        cover (rinc && rempty);
    end
end
