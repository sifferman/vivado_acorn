
build/vivado-program.tcl:
	mkdir -p $(dir $@)
	wget -O $@ https://raw.githubusercontent.com/olofk/edalize/refs/tags/v0.6.1/edalize/templates/vivado/vivado-program.tcl.j2
	echo "\nexit" >> $@

build/%/acorn.runs/impl_1/design_1_wrapper.bit: bd/%.tcl vivado.tcl
	rm -rf build/$*
	mkdir -p build
	cd build && \
	 vivado -nolog -nojournal -mode tcl \
	  -source ../vivado.tcl -tclargs $* $<

%_program: build/%/acorn.runs/impl_1/design_1_wrapper.bit build/vivado-program.tcl
	cd build && \
	 vivado -quiet -nolog -nojournal -notrace -mode tcl \
	  -source vivado-program.tcl -tclargs xc7a100tfgg484 ../$<

clean:
	rm -rf build
