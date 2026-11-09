class wr_item extends uvm_sequence_item;
    rand bit [7:0]   data;
    rand int unsigned gap;                   // idle wclk cycles before this write
    constraint c_gap { gap inside {[0:6]}; }

    `uvm_object_utils(wr_item)

    function new(string name = "wr_item");
        super.new(name);
    endfunction
endclass