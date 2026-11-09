class rd_monitor extends uvm_monitor;
    `uvm_component_utils(rd_monitor)

    virtual fifo_if vif;
    uvm_analysis_port #(bit [7:0]) ap;       // broadcasts data that came out
    int unsigned accepted, dropped;
    bit pending;                             // a read was accepted last edge

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "rd_monitor: no virtual interface set")
    endfunction

    task run_phase(uvm_phase phase);
        wait (vif.rrst_n === 1'b1);
        forever begin
            @(posedge vif.rclk);
            if (pending) ap.write(vif.rdata[7:0]);   // rdata is valid one edge after the accept
            pending = 0;
            if (vif.rinc && !vif.rempty) begin
                pending = 1;
                accepted++;
            end else if (vif.rinc && vif.rempty) begin
                dropped++;                           // read attempted while empty
            end
        end
    endtask

    function void report_phase(uvm_phase phase);
        `uvm_info("RD_MON", $sformatf("accepted=%0d dropped(empty)=%0d", accepted, dropped), UVM_LOW)
    endfunction
endclass