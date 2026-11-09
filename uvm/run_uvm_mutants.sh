#!/usr/bin/env bash
cd "$(dirname "$0")" || exit 1
export UVM_HOME="${UVM_HOME:-$HOME/uvm-scratch/1800.2-2017-1.0/src}"

printf "%-34s %-8s\n" "design" "uvm"
printf "%-34s %-8s\n" "------" "---"

if [ $# -gt 0 ]; then files=("$@"); else files=(../async_fifo/rtl/async_fifo.sv ../async_fifo/mutants/mut*.sv); fi
for f in "${files[@]}"; do
    name=$(basename "$f" .sv)
    if ! verilator -Wno-fatal --binary -j "$(nproc)" --top-module tb_top \
         --Mdir "obj_$name" +incdir+"$UVM_HOME" +define+UVM_NO_DPI +incdir+"$(pwd)" \
         "$UVM_HOME/uvm_pkg.sv" "$f" fifo_if.sv fifo_pkg.sv tb_top.sv > /dev/null 2>&1; then
        res="ERROR"
    else
        out=$(timeout 300 "./obj_$name/Vtb_top" +UVM_TESTNAME=fifo_test 2>&1)
        e=$(echo "$out"  | awk '/^UVM_ERROR :/{print $3}')
        fa=$(echo "$out" | awk '/^UVM_FATAL :/{print $3}')
        if [ -z "$e" ]; then res="ERROR"
        elif [ "$e" -gt 0 ] || [ "$fa" -gt 0 ]; then res="CAUGHT"
        else res="missed"; fi
    fi
    printf "%-34s %-8s\n" "$name" "$res"
done
