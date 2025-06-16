#
# This file is derived from LiteX-Boards.
#
# Copyright (c) 2020 Florent Kermarrec <florent@enjoy-digital.fr>
# SPDX-License-Identifier: BSD-2-Clause

# The Acorn (CLE-101, CLE-215(+)) are cryptocurrency mining accelerator cards from SQRL that can be
# repurposed as generic FPGA PCIe development boards:
# - http://www.squirrelsresearch.com/acorn-cle-101
# - http://www.squirrelsresearch.com/acorn-cle-215-plus
# The 101 variant is eguivalent to the LiteFury and 215 variant equivalent to the NiteFury from
# RHSResearchLLC that are documented at: https://github.com/RHSResearchLLC/NiteFury-and-LiteFury.

# https://github.com/litex-hub/litex-boards/blob/master/litex_boards/platforms/sqrl_acorn.py

################
# Pins
################

# The following pins constraints are set by the MIG:
# clk200_p/n
# ddr3_dq[15:0]
# ddr3_dq[15:0]
# ddr3_dqs_p/n[1:0]
# ddr3_addr[15:0]
# ddr3_ba[2:0]
# ddr3_ras_n
# ddr3_cas_n
# ddr3_we_n
# ddr3_reset_n
# ddr3_clk_p/n
# ddr3_clk_en
# ddr3_dm[1:0]
# ddr3_odt

# PCIe lane 0
set_property PACKAGE_PIN A10 [get_ports {pcie_x4_rx_n[0]}]
set_property PACKAGE_PIN B10 [get_ports {pcie_x4_rx_p[0]}]
set_property PACKAGE_PIN A6 [get_ports {pcie_x4_tx_n[0]}]
set_property PACKAGE_PIN B6 [get_ports {pcie_x4_tx_p[0]}]

# PCIe lane 1
set_property PACKAGE_PIN A8 [get_ports {pcie_x4_rx_n[1]}]
set_property PACKAGE_PIN B8 [get_ports {pcie_x4_rx_p[1]}]
set_property PACKAGE_PIN A4 [get_ports {pcie_x4_tx_n[1]}]
set_property PACKAGE_PIN B4 [get_ports {pcie_x4_tx_p[1]}]

# PCIe lane 2
set_property PACKAGE_PIN C11 [get_ports {pcie_x4_rx_n[2]}]
set_property PACKAGE_PIN D11 [get_ports {pcie_x4_rx_p[2]}]
set_property PACKAGE_PIN C5 [get_ports {pcie_x4_tx_n[2]}]
set_property PACKAGE_PIN D5 [get_ports {pcie_x4_tx_p[2]}]

# PCIe lane 3
set_property PACKAGE_PIN C9 [get_ports {pcie_x4_rx_n[3]}]
set_property PACKAGE_PIN D9 [get_ports {pcie_x4_rx_p[3]}]
set_property PACKAGE_PIN C7 [get_ports {pcie_x4_tx_n[3]}]
set_property PACKAGE_PIN D7 [get_ports {pcie_x4_tx_p[3]}]

# Other PCIe signals
set_property LOC J1 [get_ports {pcie_x4_rst_n}]
set_property IOSTANDARD LVCMOS33 [get_ports {pcie_x4_rst_n}]
set_property PULLUP TRUE [get_ports {pcie_x4_rst_n}]

# set_property PACKAGE_PIN G1 [get_ports {pcie_clkreq_n}]
# set_property IOSTANDARD LVCMOS33 [get_ports {pcie_clkreq_n}]

set_property LOC F6 [get_ports {pcie_x4_clk_p}]
set_property LOC E6 [get_ports {pcie_x4_clk_n}]
create_clock -name pcie_x4_clk_p -period 10.0 [get_nets pcie_x4_clk_p]

################
# Miscellaneous
################

set_property INTERNAL_VREF 0.750 [get_iobanks 34]

set_property BITSTREAM.CONFIG.OVERTEMPPOWERDOWN ENABLE [current_design]

set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN Div-1 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
