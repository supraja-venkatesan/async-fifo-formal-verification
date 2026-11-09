class rd_item extends uvm_sequence_item;
    rand int unsigned gap;                   // idle rclk cycles before this read
    constraint c_gap { gap inside {[0:6]}; }

    `uvm_object_utils(rd_item)

    function new(string name = "rd_item");
        super.new(name);
    endfunction
endclass