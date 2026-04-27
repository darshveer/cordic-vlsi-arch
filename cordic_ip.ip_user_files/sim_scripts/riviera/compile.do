transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib riviera/xil_defaultlib

vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xil_defaultlib  -incr -v2k5 "+incdir+../../../../../../../../../Xilinx/2025.1/Vivado/data/rsb/busdef" -l xil_defaultlib \
"../../../cordic_ip.srcs/sources_1/new/Stage1.v" \
"../../../cordic_ip.srcs/sources_1/new/Stage5.v" \
"../../../cordic_ip.srcs/sources_1/new/cordic_preprocess.v" \
"../../../cordic_ip.srcs/sources_1/new/stage_module.v" \
"../../../cordic_ip.srcs/sources_1/new/top_cordic.v" \


vlog -work xil_defaultlib \
"glbl.v"

