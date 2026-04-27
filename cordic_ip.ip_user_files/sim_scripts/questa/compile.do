vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xil_defaultlib

vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -work xil_defaultlib  -incr -mfcu  "+incdir+../../../../../../../../../Xilinx/2025.1/Vivado/data/rsb/busdef" \
"../../../cordic_ip.srcs/sources_1/new/Stage1.v" \
"../../../cordic_ip.srcs/sources_1/new/Stage5.v" \
"../../../cordic_ip.srcs/sources_1/new/cordic_preprocess.v" \
"../../../cordic_ip.srcs/sources_1/new/stage_module.v" \
"../../../cordic_ip.srcs/sources_1/new/top_cordic.v" \


vlog -work xil_defaultlib \
"glbl.v"

