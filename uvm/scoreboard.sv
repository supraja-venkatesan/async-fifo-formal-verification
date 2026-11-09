`uvm_analysis_imp_decl(_wr)
`uvm_analysis_imp_decl(_rd)

class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)

    uvm_analysis_imp_wr #(bit [7:0], scoreboard) wr_imp;
    uvm_analysis_imp_rd #(bit [7:0], scoreboard) rd_imp;

    bit [7:0] exp_q[$];                      // words written, not yet read
    int unsigned checks, errors;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        wr_imp = new("wr_imp", this);
        rd_imp = new("rd_imp", this);
    endfunction

    function void write_wr(bit [7:0] d);     // called by the write monitor
        exp_q.push_back(d);
    endfunction

    function void write_rd(bit [7:0] d);     // called by the read monitor
        bit [7:0] exp;
        checks++;
        if (exp_q.size() == 0) begin
            errors++;
            `uvm_error("SB", $sformatf("read data %0h but nothing was written", d))
        end else begin
            exp = exp_q.pop_front();
            if (d !== exp) begin
                errors++;
                `uvm_error("SB", $sformatf("mismatch: got %0h expected %0h", d, exp))
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SB", $sformatf("checks=%0d errors=%0d left_in_fifo=%0d",
                                   checks, errors, exp_q.size()), UVM_LOW)
    endfunction
endclass