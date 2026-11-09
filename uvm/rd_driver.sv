class rd_driver extends uvm_driver #(rd_item);
    `uvm_component_utils(rd_driver)

    virtual fifo_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "rd_driver: no virtual interface set")
    endfunction

    task run_phase(uvm_phase phase);
        vif.rinc = 0;
        wait (vif.rrst_n === 1'b1);
        forever begin
            seq_item_port.get_next_item(req);
            repeat (req.gap) @(negedge vif.rclk);
            vif.rinc = 1;
            @(negedge vif.rclk);
            vif.rinc = 0;
            seq_item_port.item_done();
        end
    endtask
endclass