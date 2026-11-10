# async-fifo-formal-verification

# Formal Verification of a CDC Async FIFO, with Mutation Scoring

This is a dual-clock (asynchronous) FIFO written in SystemVerilog and checked in two ways: via a directed simulation testbench, a constrained random UVM testbench, and through formal verification using SymbiYosys. The checks are scored by testing **mutants**: where nine deliberate RTL bugs get injected and each method is graded on whether or not it manages to catch them. 

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

| Mutant | Bug | Directed sim | UVM random | Formal |
|---|---|---|---|---|
| mut01 | `wfull` compares only the top pointer bit | CAUGHT | CAUGHT | CAUGHT |
| mut02 | `rempty` resets to 0 | missed | missed | CAUGHT |
| mut03 | write accepted while full | CAUGHT | CAUGHT | CAUGHT |
| mut04 | read accepted while empty | missed | CAUGHT | CAUGHT |
| mut05 | stored data corrupted | CAUGHT | CAUGHT | CAUGHT |
| mut06 | synchronizer reduced to a single stage | missed | missed | missed |
| mut07 | `wfull` compares the stale write pointer | missed | CAUGHT | CAUGHT |
| mut08 | write binary pointer not reset | CAUGHT | missed | CAUGHT |
| mut09 | read address taken from the gray pointer | CAUGHT | CAUGHT | CAUGHT |
| | **Bugs caught** | **5 / 9** | **6 / 9** | **8 / 9** |

The unmodified design passes all three methods (no false alarms).

Notes:
- **Random stimulus found what the directed test missed.** The UVM test forces reads on an empty FIFO and back-to-back writes, which is why it catches mut04 and mut07.
- **mut08 looks like a simulator artifact, not a testbench weakness.** The directed testbench runs on Icarus, where an unreset register starts as `X` and trips the checks. UVM runs on Verilator, which is 2-state, so the same register starts at 0. Formal catches it either way. I have not confirmed this by experiment yet.
- **mut02 is missed by both simulations.** The testbenches only start driving after reset is released, so the first cycle after reset is never stressed. Formal can start from any state.
- **mut06 is missed by all three.** None of these tools models metastability, so removing a synchronizer stage only changes latency. Bugs of this class need a structural CDC check or gate-level simulation.
- The directed testbench has 13 checks and an idle cycle between operations. The UVM run is a single random seed on the default 8-deep, 8-bit instance, with random idle gaps as the only randomization, so a "missed" on a subtle bug could be bad luck. Formal runs on a smaller instance (below), so the comparison is not perfectly like for like.

## Experiment: LLM-written assertions

I gave an LLM a plain-English spec of the FIFO (`ai_loop/spec.md`) and graded what it wrote with the same formal setup. Each assertion is checked on the correct design (no false alarms), its cover points are checked (not vacuous), and then it is run against all nine mutants. Generated code is never hand-fixed.

| Prompt | Result |
|---|---|
| A: naive | Did not parse. It used concurrent SVA (`assert property`, `default clocking`), which Yosys does not support. |
| B: told the tool's limits | 3 assertions, 0 useful. Two are tautologies that can never fail (0 of 9 mutants caught). The third fails on the correct design. |

The third failure came from my spec: I wrote "`wfull` and `rempty` are never both high", which is true for a single-clock FIFO but not for an async one with synchronizer lag. The model turned a wrong spec sentence into a wrong assertion. By comparison, my two hand-written properties catch 8 of 9.

This is one model and one sample per prompt, so it shows what the grading harness can measure, not how good LLMs are in general.

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
uvm/                   constrained-random UVM testbench (Verilator) and its mutant runner
baseline_sync_fifo/    the single-clock warm-up, with its own mutant and scripts


# UVM testbench (needs Verilator and the Accellera UVM 2017 sources; a full run takes about an hour)
export UVM_HOME=/path/to/1800.2-2017-1.0/src
cd ../uvm
./run_uvm_mutants.sh

```