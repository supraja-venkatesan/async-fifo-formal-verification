class wr_seq extends uvm_sequence #(wr_item);
    `uvm_object_utils(wr_seq)
    int unsigned n = 20;                     // how many writes
    int unsigned max_gap = 6;                // clamp on the random idle gap

    function new(string name = "wr_seq");
        super.new(name);
    endfunction

    task body();
        repeat (n) begin
            req = wr_item::type_id::create("req");
            start_item(req);
            if (!req.randomize()) `uvm_fatal("RAND", "wr_item randomize failed")
            if (req.gap > max_gap) req.gap = max_gap;
            finish_item(req);
        end
    endtask
endclass

class rd_seq extends uvm_sequence #(rd_item);
    `uvm_object_utils(rd_seq)
    int unsigned n = 20;
    int unsigned max_gap = 6;

    function new(string name = "rd_seq");
        super.new(name);
    endfunction

    task body();
        repeat (n) begin
            req = rd_item::type_id::create("req");
            start_item(req);
            if (!req.randomize()) `uvm_fatal("RAND", "rd_item randomize failed")
            if (req.gap > max_gap) req.gap = max_gap;
            finish_item(req);
        end
    endtask
endclass
