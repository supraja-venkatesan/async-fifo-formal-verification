# async-fifo-formal-verification

# Formal Verification of a CDC Async FIFO, with Mutation Scoring

This is a dual-clock (asynchronous) FIFO written in SystemVerilog and checked in two ways: via a directed simulation testbench, and through formal veriification using SymbiYosys. The checks are scored by testing **mutants**: where nine deliberate RTL bugs get injected and each method is graded on whether or not it manages to catch them. 

## Design

`async_fifo/rtl/async_fifo.sv`
- Separate write and read clocks, with asynchronous active-low resets
- Gray-coded pointers (AW+1 bits), each crossing the clock boundary through a 2-flop synchronizer
- `wfull` is computed in the write domain and `rempty` in the read domain, both registered
- `rdata` is registered, valid the cycle after an accepted read

## Formal properties

`async_fifo/formal/async_fifo_formal.sv` (multi-clock, with both clocks free for the solver to drive)
- **Data integrity (symbolic tag):** the solver picks an arbitrary write and the wrapper follows it through the crossing. The word read out must equal the word written.
- **Occupancy:** accepted writes minus accepted reads always stays within 0..DEPTH, which covers overflow and underflow.
- **Cover points:** full, data-check reached, and full occupancy reached. These show the assertions are not passing vacuously.
- **Environment constraint:** asynchronous resets are assumed to stay released at every solver step after a domain's first clock edge. Without this, the solver can pulse a reset between clock edges, which caused a false failure early in development.

## Results: mutation kill table

| Mutant | Bug | Simulation | Formal |
|---|---|---|---|
| mut01 | `wfull` compares only the top pointer bit | CAUGHT | CAUGHT |
| mut02 | `rempty` resets to 0 | missed | CAUGHT |
| mut03 | write accepted while full | CAUGHT | CAUGHT |
| mut04 | read accepted while empty | missed | CAUGHT |
| mut05 | stored data corrupted | CAUGHT | CAUGHT |
| mut06 | synchronizer reduced to a single stage | missed | missed |
| mut07 | `wfull` compares the stale write pointer | missed | CAUGHT |
| mut08 | write binary pointer not reset | CAUGHT | CAUGHT |
| mut09 | read address taken from the gray pointer | CAUGHT | CAUGHT |

The unmodified design passes both methods (no false alarms). **Formal killed 8 of 9; the directed testbench killed 5 of 9.**

Notes:
- The simulation side is a directed testbench with 13 checks and an idle cycle between operations. It is not a constrained-random or UVM comparison.
- mut08 is caught in simulation partly because an unreset register is `X` in simulation.
- **mut06 is missed by both methods.** Both tools sample signals atomically and do not model metastability, so removing a synchronizer stage only changes latency. Bugs of this class need a structural CDC check or gate-level simulation.

## Bounds and limitations

- Formal runs on a 4-deep, 4-bit instance (`DEPTH=4`, `DATA_W=4` via `chparam`), to depth 16. In multi-clock mode a step is a solver time step, not a clock cycle of either domain.
- These are bounded results ("no violation within 16 steps"). An unbounded proof by k-induction is **not** established: the base case passes, but the induction step needs invariants on internal state that have not been written.
- Nine mutants is a small set, and most are straightforward.

## Baseline: sync FIFO

`baseline_sync_fifo/` is a single-clock FIFO used to bring up the toolchain before the async design. Its formal checks first missed a data-corruption mutant because the properties only covered the `full` and `empty` flags. Adding the same symbolic-tag property fixed that. Result: control missed/missed, data-corruption mutant CAUGHT by both (formal to 12 steps on a 4x4 instance).

## Reproduce

Tools: OSS CAD Suite (Yosys, SymbiYosys, Yices, Icarus Verilog)

```bash
cd async_fifo

# full kill table: simulation and formal on the design and every mutant
./scripts/run_mutants.sh

# or one piece at a time
iverilog -g2012 -o sim/tb.vvp rtl/async_fifo.sv sim/tb_async_fifo.sv && vvp sim/tb.vvp
cd formal
sby -f async_fifo.sby bmc
sby -f async_fifo.sby cover
```

## Layout

```
async_fifo/            RTL, testbench, formal wrapper, mutants, scripts
baseline_sync_fifo/    the single-clock warm-up, with its own mutant and scripts
```