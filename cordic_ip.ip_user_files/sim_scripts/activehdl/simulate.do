transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

asim +access +r +m+top_cordic  -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.top_cordic xil_defaultlib.glbl

do {top_cordic.udo}

run 1000ns

endsim

quit -force
