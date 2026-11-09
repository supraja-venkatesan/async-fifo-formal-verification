class wr_driver extends uvm_driver #(wr_item);
    `uvm_component_utils(wr_driver)

    virtual fifo_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "wr_driver: no virtual interface set")
    endfunction

    task run_phase(uvm_phase phase);
        vif.winc = 0;
        wait (vif.wrst_n === 1'b1);          // wait for reset release
        forever begin
            seq_item_port.get_next_item(req);
            repeat (req.gap) @(negedge vif.wclk);   // idle gap
            vif.winc  = 1;
            vif.wdata = req.data;
            @(negedge vif.wclk);
            vif.winc  = 0;
            seq_item_port.item_done();
        end
    endtask
endclass