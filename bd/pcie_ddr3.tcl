
##############
# PCIe
##############

# https://www.amd.com/content/dam/xilinx/support/documents/ip_documentation/xdma/v4_1/pg195-pcie-dma.pdf
# https://docs.amd.com/r/en-US/pg054-7series-pcie/Artix-7-Devices
# https://github.com/Xilinx/dma_ip_drivers
create_bd_cell -type ip -vlnv xilinx.com:ip:xdma:4.1 xdma_0
set_property -dict [list \
  CONFIG.pl_link_cap_max_link_width {X4} \
  CONFIG.pl_link_cap_max_link_speed {5.0_GT/s} \
  CONFIG.ref_clk_freq {100_MHz} \
  CONFIG.axisten_freq {125} \
  CONFIG.xdma_axi_intf_mm {AXI_Memory_Mapped} \
] [get_bd_cells xdma_0]

# PCIe Reset
create_bd_port -dir I -type rst pcie_x4_rst_n
connect_bd_net [get_bd_ports pcie_x4_rst_n] [get_bd_pins xdma_0/sys_rst_n]

# PCIe Clock
create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 util_ds_buf_pcie
create_bd_port -dir I -type clk -freq_hz 100000000 pcie_x4_clk_p
create_bd_port -dir I -type clk -freq_hz 100000000 pcie_x4_clk_n
set_property CONFIG.C_BUF_TYPE {IBUFDSGTE} [get_bd_cells util_ds_buf_pcie]
connect_bd_net [get_bd_ports pcie_x4_clk_p] [get_bd_pins util_ds_buf_pcie/IBUF_DS_P]
connect_bd_net [get_bd_ports pcie_x4_clk_n] [get_bd_pins util_ds_buf_pcie/IBUF_DS_N]
connect_bd_net [get_bd_pins util_ds_buf_pcie/IBUF_OUT] [get_bd_pins xdma_0/sys_clk]

# PCIe Data
create_bd_port -dir I -from 3 -to 0 -type data pcie_x4_rx_p
create_bd_port -dir I -from 3 -to 0 -type data pcie_x4_rx_n
create_bd_port -dir O -from 3 -to 0 -type data pcie_x4_tx_p
create_bd_port -dir O -from 3 -to 0 -type data pcie_x4_tx_n
connect_bd_net [get_bd_ports pcie_x4_rx_p] [get_bd_pins xdma_0/pci_exp_rxp]
connect_bd_net [get_bd_ports pcie_x4_rx_n] [get_bd_pins xdma_0/pci_exp_rxn]
connect_bd_net [get_bd_ports pcie_x4_tx_p] [get_bd_pins xdma_0/pci_exp_txp]
connect_bd_net [get_bd_ports pcie_x4_tx_n] [get_bd_pins xdma_0/pci_exp_txn]

# Buffer the XDMA port
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
set_property -dict [list \
  CONFIG.NUM_MI {1} \
  CONFIG.NUM_SI {1} \
] [get_bd_cells axi_interconnect_0]
connect_bd_intf_net [get_bd_intf_pins xdma_0/M_AXI] [get_bd_intf_pins axi_interconnect_0/S00_AXI]

##############
# DDR3
##############

# MIG
create_bd_cell -type ip -vlnv xilinx.com:ip:mig_7series:4.2 mig_7series_0
set_property CONFIG.XML_INPUT_FILE [pwd]/../mig_a.prj [get_bd_cells mig_7series_0]
make_bd_intf_pins_external [get_bd_intf_pins mig_7series_0/DDR3]

# Disable MIG Reset
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_1
set_property CONFIG.CONST_VAL {1} [get_bd_cells xlconstant_1]

# MIG CLK
make_bd_intf_pins_external [get_bd_intf_pins mig_7series_0/SYS_CLK]
set_property NAME DDR_CLK [get_bd_intf_ports /SYS_CLK_0]

# PCIe -> MIG
connect_bd_intf_net [get_bd_intf_pins mig_7series_0/S_AXI] [get_bd_intf_pins axi_interconnect_0/M00_AXI]

# Reset
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0
set_property -dict [list \
  CONFIG.C_OPERATION {not} \
  CONFIG.C_SIZE {1} \
] [get_bd_cells util_vector_logic_0]

##############
# Clocks
##############

connect_bd_net [get_bd_pins mig_7series_0/ui_clk] \
               [get_bd_pins axi_interconnect_0/M00_ACLK]

connect_bd_net [get_bd_pins util_vector_logic_0/Op1] \
               [get_bd_pins mig_7series_0/ui_clk_sync_rst]

connect_bd_net [get_bd_pins util_vector_logic_0/Res] \
               [get_bd_pins axi_interconnect_0/M00_ARESETN]

connect_bd_net [get_bd_pins xlconstant_1/dout] \
               [get_bd_pins mig_7series_0/aresetn] \
               [get_bd_pins mig_7series_0/sys_rst]

connect_bd_net [get_bd_pins xdma_0/axi_aclk] \
               [get_bd_pins axi_interconnect_0/ACLK] \
               [get_bd_pins axi_interconnect_0/S00_ACLK]

connect_bd_net [get_bd_pins xdma_0/axi_aresetn] \
               [get_bd_pins axi_interconnect_0/ARESETN] \
               [get_bd_pins axi_interconnect_0/S00_ARESETN]

##############
# AXI Addresses
##############

set_property -dict [list \
  offset 0x00000000 \
  range 512M \
] [get_bd_addr_segs {xdma_0/M_AXI/SEG_mig_7series_0_memaddr}]
