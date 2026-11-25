filename = top
top = top
pcf_file = common/iceBlinkPico.pcf

build:
	yosys -p "synth_ice40 -top $(top) -json $(filename).json" $(filename).sv
	nextpnr-ice40 --up5k --package sg48 --json $(filename).json --pcf $(pcf_file) --asc $(filename).asc
	icepack $(filename).asc $(filename).bin

prog: #for sram
	dfu-util --device 1d50:6146 --alt 0 -D $(filename).bin -R

test:
	iverilog -g2012 -o cpu_tb.vvp cpu_tb.sv
	vvp cpu_tb.vvp

clean:
	rm -rf $(filename).blif $(filename).asc $(filename).json $(filename).bin $(filename)_tb.vvp cpu_tb.vvp cpu_tb.vcd
