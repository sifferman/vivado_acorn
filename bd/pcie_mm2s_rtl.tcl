
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

# Split the XDMA Manager into 2 Ports
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
set_property -dict [list \
  CONFIG.NUM_MI {2} \
  CONFIG.NUM_SI {1} \
] [get_bd_cells axi_interconnect_0]
connect_bd_intf_net [get_bd_intf_pins xdma_0/M_AXI] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S00_AXI]

##############
# RTL
##############

create_bd_cell -type module -reference axi_mm2s_test axi_mm2s_test
set_property -dict [list \
  CONFIG.DATA_WIDTH {32} \
  CONFIG.ADDR_WIDTH {64} \
  CONFIG.ID_WIDTH {4} \
] [get_bd_cells axi_mm2s_test]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins axi_mm2s_test/s_axi]

##############
# MM2S
##############

# https://docs.amd.com/r/en-US/pg080-axi-fifo-mm-s
# https://docs.amd.com/r/en-US/pg080-axi-fifo-mm-s/Programing-Sequence
# https://github.com/search?q=%2Fcreate_bd_cell%20-type%20ip%20-vlnv%20xilinx.com%3Aip%3Aaxi_fifo_mm_s%2F%20language%3ATcl&type=code
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_fifo_mm_s:4.3 axi_fifo_mm_s_0
set_property -dict [list \
  CONFIG.C_DATA_INTERFACE_TYPE {0} \
  CONFIG.C_USE_TX_CTRL {0} \
  CONFIG.C_USE_RX_DATA {0} \
] [get_bd_cells axi_fifo_mm_s_0]
# interface type set to AXI Lite, with 32-bit data width

connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins axi_fifo_mm_s_0/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_fifo_mm_s_0/AXI_STR_TXD] [get_bd_intf_pins axi_mm2s_test/s_axis]

##############
# Clocks
##############

connect_bd_net [get_bd_pins axi_mm2s_test/axi_clk] \
               [get_bd_pins axi_mm2s_test/s_axis_aclk] \
               [get_bd_pins axi_fifo_mm_s_0/s_axi_aclk] \
               [get_bd_pins xdma_0/axi_aclk] \
               [get_bd_pins axi_interconnect_0/ACLK] \
               [get_bd_pins axi_interconnect_0/S00_ACLK] \
               [get_bd_pins axi_interconnect_0/M00_ACLK] \
               [get_bd_pins axi_interconnect_0/M01_ACLK]

connect_bd_net [get_bd_pins axi_mm2s_test/axi_resetn] \
               [get_bd_pins axi_mm2s_test/s_axis_aresetn] \
               [get_bd_pins axi_fifo_mm_s_0/s_axi_aresetn] \
               [get_bd_pins xdma_0/axi_aresetn] \
               [get_bd_pins axi_interconnect_0/ARESETN] \
               [get_bd_pins axi_interconnect_0/S00_ARESETN] \
               [get_bd_pins axi_interconnect_0/M00_ARESETN] \
               [get_bd_pins axi_interconnect_0/M01_ARESETN]

##############
# AXI Addresses
##############

create_bd_addr_seg \
  -range 512M -offset 0x00000000 \
  [get_bd_addr_spaces {/xdma_0/M_AXI}] \
  [get_bd_addr_segs {/axi_fifo_mm_s_0/S_AXI/Mem0}] \
  SEG_mm2s_write

create_bd_addr_seg \
  -range 2G -offset 0x80000000 \
  [get_bd_addr_spaces {/xdma_0/M_AXI}] \
  [get_bd_addr_segs {/axi_mm2s_test/s_axi/reg0}] \
  SEG_axi_read
