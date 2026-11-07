#!/usr/bin/env bash
cd "$(dirname "$0")/.." || exit 1

printf "%-30s %-8s %-8s\n" "design" "sim" "formal"
printf "%-30s %-8s %-8s\n" "------" "---" "------"

for f in rtl/sync_fifo.sv mutants/mut*.sv; do
    name=$(basename "$f" .sv)

    if iverilog -g2012 -o "sim/tb_$name.vvp" "$f" sim/tb_sync_fifo.sv 2>/dev/null; then
        if vvp "sim/tb_$name.vvp" | grep -q "ALL TESTS PASSED"; then sim="missed"; else sim="CAUGHT"; fi
    else
        sim="ERROR"
    fi

    cat > "formal/gen_${name}_bmc.sby" <<EOF
[options]
mode bmc
depth 12

[engines]
smtbmc

[script]
read -formal sync_fifo.sv
read -formal fifo_formal.sv
chparam -set DEPTH 4 -set DATA_W 4 fifo_formal
prep -top fifo_formal

[files]
sync_fifo.sv ../$f
fifo_formal.sv
EOF
    (cd formal && sby -f "gen_${name}_bmc.sby" > /dev/null 2>&1)
    rc=$?
    case $rc in
        0) formal="missed" ;;
        2) formal="CAUGHT" ;;
        *) formal="ERROR" ;;
    esac

    printf "%-30s %-8s %-8s\n" "$name" "$sim" "$formal"
done