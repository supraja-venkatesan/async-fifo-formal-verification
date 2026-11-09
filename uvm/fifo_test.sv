class fifo_test extends uvm_test;
    `uvm_component_utils(fifo_test)
    fifo_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = fifo_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        wr_seq w;
        rd_seq r;
        phase.raise_objection(this);

        // A: writes only, back-to-back, past capacity (hits write-when-full)
        w = wr_seq::type_id::create("w");  w.n = 20;  w.max_gap = 0;
        w.start(env.wr_sqr);

        // B: random reads and writes at the same time
        w = wr_seq::type_id::create("w");  w.n = 200; w.max_gap = 6;
        r = rd_seq::type_id::create("r");  r.n = 200; r.max_gap = 6;
        fork
            w.start(env.wr_sqr);
            r.start(env.rd_sqr);
        join

        // C: reads only, back-to-back, until empty (hits read-when-empty)
        r = rd_seq::type_id::create("r");  r.n = 40;  r.max_gap = 0;
        r.start(env.rd_sqr);

        #300;                                // let the last read reach the monitor
        phase.drop_objection(this);
    endtask
endclass