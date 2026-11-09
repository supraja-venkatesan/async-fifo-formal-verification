class fifo_env extends uvm_env;
    `uvm_component_utils(fifo_env)

    uvm_sequencer #(wr_item) wr_sqr;
    uvm_sequencer #(rd_item) rd_sqr;
    wr_driver  wr_drv;
    wr_monitor wr_mon;
    rd_driver  rd_drv;
    rd_monitor rd_mon;
    scoreboard sb;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        wr_sqr = uvm_sequencer #(wr_item)::type_id::create("wr_sqr", this);
        rd_sqr = uvm_sequencer #(rd_item)::type_id::create("rd_sqr", this);
        wr_drv = wr_driver ::type_id::create("wr_drv", this);
        wr_mon = wr_monitor::type_id::create("wr_mon", this);
        rd_drv = rd_driver ::type_id::create("rd_drv", this);
        rd_mon = rd_monitor::type_id::create("rd_mon", this);
        sb     = scoreboard::type_id::create("sb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        wr_drv.seq_item_port.connect(wr_sqr.seq_item_export);
        rd_drv.seq_item_port.connect(rd_sqr.seq_item_export);
        wr_mon.ap.connect(sb.wr_imp);
        rd_mon.ap.connect(sb.rd_imp);
    endfunction
endclass