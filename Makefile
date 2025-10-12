
VARIANT ?= cle101

ifeq ($(filter $(VARIANT),cle101 cle215 cle215+),)
    $(error Invalid VARIANT '$(VARIANT)'. Must be one of: cle101, cle215, cle215+)
endif

ifeq ($(VARIANT), cle101)
    PART_NAME = xc7a100tfgg484-2
    DRAM_SIZE = 512M
endif
ifeq ($(VARIANT), cle215)
    PART_NAME = xc7a200tfbg484-2
    DRAM_SIZE = 512M
endif
ifeq ($(VARIANT), cle215+)
    PART_NAME = xc7a200tfbg484-3
    DRAM_SIZE = 1G
endif

build/vivado-program.tcl:
	mkdir -p $(dir $@)
	wget -O $@ https://raw.githubusercontent.com/olofk/edalize/refs/tags/v0.6.1/edalize/templates/vivado/vivado-program.tcl.j2

build/%/acorn_$(VARIANT).runs/impl_1/design_1_wrapper.bit: bd/%.tcl vivado.tcl
	rm -rf build/$*
	mkdir -p build
	cd build && \
	 vivado -nolog -nojournal -mode batch \
	  -source ../vivado.tcl -tclargs $* $(VARIANT) $(PART_NAME) $(DRAM_SIZE) $<

%_program: build/%/acorn_$(VARIANT).runs/impl_1/design_1_wrapper.bit build/vivado-program.tcl
	cd build && \
	 vivado -quiet -nolog -nojournal -notrace -mode batch \
	  -source vivado-program.tcl -tclargs $(PART_NAME) ../$<

clean:
	rm -rf build
