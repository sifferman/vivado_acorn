
# PCIe
# https://www.amd.com/content/dam/xilinx/support/documents/ip_documentation/xdma/v4_1/pg195-pcie-dma.pdf
# https://docs.amd.com/r/en-US/pg054-7series-pcie/Artix-7-Devices
# https://github.com/Xilinx/dma_ip_drivers
create_bd_cell -type ip -vlnv xilinx.com:ip:xdma:4.1 xdma_0
set_property -dict [list \
  CONFIG.pl_link_cap_max_link_width {X4} \
  CONFIG.ref_clk_freq {100_MHz} \
  CONFIG.axisten_freq {125} \
  CONFIG.xdma_axi_intf_mm {AXI_Memory_Mapped} \
] [get_bd_cells xdma_0]

# BRAM Controller
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0
set_property -dict [list \
  CONFIG.DATA_WIDTH {64} \
  CONFIG.SINGLE_PORT_BRAM {1} \
] [get_bd_cells axi_bram_ctrl_0]
connect_bd_net [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins xdma_0/axi_aclk]
connect_bd_net [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins xdma_0/axi_aresetn]
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_0/S_AXI] [get_bd_intf_pins xdma_0/M_AXI]

# BRAM
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0
set_property CONFIG.use_bram_block {BRAM_Controller} [get_bd_cells blk_mem_gen_0]
connect_bd_intf_net [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]

# Reset
create_bd_port -dir I -type rst pcie_x4_rst_n
connect_bd_net [get_bd_ports pcie_x4_rst_n] [get_bd_pins xdma_0/sys_rst_n]

# Clock
create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 util_ds_buf_0
create_bd_port -dir I -type clk -freq_hz 100000000 pcie_x4_clk_p
create_bd_port -dir I -type clk -freq_hz 100000000 pcie_x4_clk_n
set_property CONFIG.C_BUF_TYPE {IBUFDSGTE} [get_bd_cells util_ds_buf_0]
connect_bd_net [get_bd_ports pcie_x4_clk_p] [get_bd_pins util_ds_buf_0/IBUF_DS_P]
connect_bd_net [get_bd_ports pcie_x4_clk_n] [get_bd_pins util_ds_buf_0/IBUF_DS_N]
connect_bd_net [get_bd_pins util_ds_buf_0/IBUF_OUT] [get_bd_pins xdma_0/sys_clk]

# PCIe Data
create_bd_port -dir I -from 3 -to 0 -type data pcie_x4_rx_p
create_bd_port -dir I -from 3 -to 0 -type data pcie_x4_rx_n
create_bd_port -dir O -from 3 -to 0 -type data pcie_x4_tx_p
create_bd_port -dir O -from 3 -to 0 -type data pcie_x4_tx_n
connect_bd_net [get_bd_ports pcie_x4_rx_p] [get_bd_pins xdma_0/pci_exp_rxp]
connect_bd_net [get_bd_ports pcie_x4_rx_n] [get_bd_pins xdma_0/pci_exp_rxn]
connect_bd_net [get_bd_ports pcie_x4_tx_p] [get_bd_pins xdma_0/pci_exp_txp]
connect_bd_net [get_bd_ports pcie_x4_tx_n] [get_bd_pins xdma_0/pci_exp_txn]

# AXI Addresses
assign_bd_address
set_property -dict [list \
  offset 0x00000000 \
  range 8K \
] [get_bd_addr_segs {xdma_0/M_AXI/SEG_axi_bram_ctrl_0_Mem0}]
