#!/usr/bin/env bash
# usage: ./grade.sh gen_B.sv
cd "$(dirname "$0")" || exit 1
gen=$1; name=$(basename "$gen" .sv)
w="work_$name"; rm -rf "$w"; mkdir "$w"
cp "$gen" "$w/ai_assertions.sv"
cp ai_formal.sv "$w/"

run() {   # $1 = mode (bmc|cover), $2 = DUT file, $3 = tag
  cat > "$w/$3.sby" <<EOF
[options]
mode $1
multiclock on
depth 16

[engines]
smtbmc

[script]
read -formal async_fifo.sv
read -formal ai_formal.sv
chparam -set DEPTH 4 -set DATA_W 4 ai_formal
prep -top ai_formal

[files]
async_fifo.sv $2
ai_formal.sv
ai_assertions.sv
EOF
  (cd "$w" && sby -f "$3.sby" > /dev/null 2>&1)
  return $?
}

D=../../async_fifo/rtl/async_fifo.sv
run bmc "$D" ctrl_bmc; rcb=$?
case $rcb in
  0) echo "control, bmc  : PASS (no false alarm)" ;;
  2) echo "control, bmc  : FAIL (an assertion is wrong on the correct design)" ;;
  *) echo "control, bmc  : ERROR (does not compile)"; exit 1 ;;
esac

run cover "$D" ctrl_cover; rcc=$?
case $rcc in
  0) echo "control, cover: PASS (all covers reachable)" ;;
  2) echo "control, cover: some cover unreached (possible vacuity)" ;;
  *) echo "control, cover: ERROR" ;;
esac

if [ $rcb -eq 0 ]; then
  kills=0; total=0
  for m in ../async_fifo/mutants/mut*.sv; do
    b=$(basename "$m" .sv); total=$((total+1))
    run bmc "../../async_fifo/mutants/$b.sv" "$b"; r=$?
    if [ $r -eq 2 ]; then kills=$((kills+1)); echo "  caught $b"; fi
  done
  echo "mutants caught: $kills / $total"
fi