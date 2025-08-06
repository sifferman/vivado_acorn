
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
# Timer
##############

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer:2.0 axi_timer_0
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins axi_timer_0/S_AXI]

##############
# Clocks
##############

connect_bd_net [get_bd_pins xdma_0/axi_aresetn] \
               [get_bd_pins axi_interconnect_0/ARESETN] \
               [get_bd_pins axi_interconnect_0/S00_ARESETN] \
               [get_bd_pins axi_interconnect_0/M00_ARESETN] \
               [get_bd_pins axi_timer_0/s_axi_aresetn]

connect_bd_net [get_bd_pins xdma_0/axi_aclk] \
               [get_bd_pins axi_interconnect_0/ACLK] \
               [get_bd_pins axi_interconnect_0/S00_ACLK] \
               [get_bd_pins axi_interconnect_0/M00_ACLK] \
               [get_bd_pins axi_timer_0/s_axi_aclk]

##############
# AXI Addresses
##############

create_bd_addr_seg \
  -range 512M -offset 0x00000000 \
  [get_bd_addr_spaces {/xdma_0/M_AXI}] \
  [get_bd_addr_segs {axi_timer_0/S_AXI/Reg}] \
  SEG_timer
