class wr_monitor extends uvm_monitor;
    `uvm_component_utils(wr_monitor)

    virtual fifo_if vif;
    uvm_analysis_port #(bit [7:0]) ap;       // broadcasts accepted write data
    int unsigned accepted, dropped;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "wr_monitor: no virtual interface set")
    endfunction

    task run_phase(uvm_phase phase);
        wait (vif.wrst_n === 1'b1);
        forever begin
            @(posedge vif.wclk);
            if (vif.winc && !vif.wfull) begin
                ap.write(vif.wdata[7:0]);    // the DUT took this word
                accepted++;
            end else if (vif.winc && vif.wfull) begin
                dropped++;                   // write attempted while full
            end
        end
    endtask

    function void report_phase(uvm_phase phase);
        `uvm_info("WR_MON", $sformatf("accepted=%0d dropped(full)=%0d", accepted, dropped), UVM_LOW)
    endfunction
endclass