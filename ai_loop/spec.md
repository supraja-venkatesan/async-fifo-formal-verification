# Async FIFO specification

A FIFO with separate write and read clocks. Parameters: DATA_W (data width), DEPTH (power of 2, at least 4).

Write side (clock `wclk`, active-low async reset `wrst_n`): `winc` requests a write of `wdata`. `wfull` is high when the FIFO cannot accept another word.
Read side (clock `rclk`, active-low async reset `rrst_n`): `rinc` requests a read. `rdata` holds the word read, valid one `rclk` cycle after an accepted read. `rempty` is high when there is nothing to read.

Behavior:
- After reset the FIFO is empty (`rempty` = 1) and not full (`wfull` = 0).
- A write is accepted only when `winc` is high and `wfull` is low. A read is accepted only when `rinc` is high and `rempty` is low.
- Words come out in the order they went in, unchanged.
- The FIFO never holds more than DEPTH words and never delivers more words than were written.
- `wfull` and `rempty` are never both high.
- Reads and writes may happen at the same time on unrelated clocks.