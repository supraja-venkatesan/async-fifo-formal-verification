#!/usr/bin/env bash
cd "$(dirname "$0")/.." || exit 1

printf "%-34s %-8s %-8s\n" "design" "sim" "formal"
printf "%-34s %-8s %-8s\n" "------" "---" "------"

for f in rtl/async_fifo.sv mutants/mut*.sv; do
    name=$(basename "$f" .sv)

    if iverilog -g2012 -o "sim/tb_$name.vvp" "$f" sim/tb_async_fifo.sv 2>/dev/null; then
        if vvp "sim/tb_$name.vvp" | grep -q "ALL TESTS PASSED"; then sim="missed"; else sim="CAUGHT"; fi
    else
        sim="ERROR"
    fi

    cat > "formal/gen_${name}_bmc.sby" <<EOF
[options]
mode bmc
multiclock on
depth 16

[engines]
smtbmc

[script]
read -formal async_fifo.sv
read -formal async_fifo_formal.sv
chparam -set DEPTH 4 -set DATA_W 4 async_fifo_formal
prep -top async_fifo_formal

[files]
async_fifo.sv ../$f
async_fifo_formal.sv
EOF
    (cd formal && sby -f "gen_${name}_bmc.sby" > /dev/null 2>&1)
    rc=$?
    case $rc in
        0) formal="missed" ;;
        2) formal="CAUGHT" ;;
        *) formal="ERROR" ;;
    esac

    printf "%-34s %-8s %-8s\n" "$name" "$sim" "$formal"
done