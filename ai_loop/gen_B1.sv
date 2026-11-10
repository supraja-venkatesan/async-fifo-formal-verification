// Write-side: no write accepted while full
always @(posedge wclk) begin
    if (wrst_n && wvalid) begin
        assert (!(winc && wfull) || wfull);
        cover (winc && wfull);
    end
end
