
# Sqrl Acorn FPGA Example

The [LiteFury and NiteFury PCIe FPGA](https://github.com/RHSResearchLLC/NiteFury-and-LiteFury) boards are some of the most affordable PCIe FPGA development platforms available. The cryptocurrency company SQRL licensed and re-released the designs as the Acorn CLE-101, CLE-215, and CLE-215+. Although all five boards are now discontinued, they are still readily available on eBay.

![LiteFury](https://raw.githubusercontent.com/RHSResearchLLC/NiteFury-and-LiteFury/701716e3ccf9a7613e425db4bb4faeb7615c30c5/images/lf-hero-cropped.PNG)

This repository demonstrates how to get these boards working with Vivado.

The easiest way to get started is to purchase the [LiteX Acorn Baseboard Mini](https://enjoy-digital-shop.myshopify.com/products/litex-acorn-baseboard-mini-sqrl-acorn-cle215), a PCIe x4 riser with an onboard FT2232H JTAG programmer.

## Scripts

This project includes multiple Vivado Block Design-based projects of varying complexity:

```bash
# Use bd/pcie_bram.tcl
make pcie_bram_program
vivado build/pcie_bram/acorn.xpr

# Use bd/pcie_ddr3.tcl
dmake pcie_ddr3_program
vivado build/pcie_ddr3/acorn.xpr

# Use bd/pcie_ddr3_rtl.tcl
make pcie_ddr3_rtl_program
vivado build/pcie_ddr3_rtl/acorn.xpr

# etc...
```

## Connecting and Powering the Board

### With PCIe Access

* The easiest way to install the board is to plug it into an open M.2 slot.
* The next best option is to install it via a PCIe x4 riser.
* For laptop users, you may connect the board via an external Thunderbolt 3/4 enclosure.

### Without PCIe Access

Because Thunderbolt 3/4 enclosures are quite expensive, laptop users may choose to use a cheap USB3.2 SSD Enclosure like this one: [SSK SHE-C325](https://www.amazon.com/SSK-Aluminum-Enclosure-External-Based/dp/B07MKCG5ZG). You won't be able to connect via PCIe, but you can still access the LEDs and the Molex PicoEzMate 6-pins connector.

## Programming

### General Notes

Note that every time you program the FPGA, you must reboot your computer. The FPGA's volatile memory will be preserved if the FPGA doesn't loose power during the reboot. Otherwise, consider flashing the on-board non-volatile memory.

### Programming Over JTAG

Note that to program the board, you first need to power it with an aformentioned method. JTAG does not provide power.

The easiest method of programming the board is with the [LiteX Acorn Baseboard Mini](https://enjoy-digital-shop.myshopify.com/products/litex-acorn-baseboard-mini).

Otherwise, the Acorn board exposes a JTAG interface which can be programmed via a JTAG programmer, such as the [Digilent HS2](https://www.digikey.fr/fr/product-highlight/d/digilent/jtag-hs2-programming-cable). Unfortunetly, the connector is not a standard 7-pin 2mm port, but is instead a Molex PicoEzMate 6. An explanation of how to make an adapter is explained here: [Use LiteX on the Acorn CLE 215](https://github.com/enjoy-digital/litex/wiki/Use-LiteX-on-the-Acorn-CLE-215).

Once the board is connected, ensure that you have installed the cable drivers. Then the FPGA should appear in Vivado's Hardware Manager.

```bash
cd ${VIVADO_INSTALLATION}/data/xicom/cable_drivers/lin64/install_script/install_drivers
sudo ./install_drivers
```

If you want to program using OpenOCD instead of Vivado's Hardware Manager, check out this guide: <https://github.com/SMB784/SQRL_quickstart>.

### Programming Over PCIe + SPI

If your design includes PCIe access to the SPI flash, you can program it through PCIe. See the following tutorial: <https://github.com/RHSResearchLLC/NiteFury-and-LiteFury/tree/master/spi-loader>.

## XDMA Help

The PCIe IP used by this example repo is the [XDMA](https://www.amd.com/content/dam/xilinx/support/documents/ip_documentation/xdma/v4_1/pg195-pcie-dma.pdf). The Linux driver for it is here: <https://github.com/Xilinx/dma_ip_drivers/tree/master/XDMA/linux-kernel>.

To install the driver just run the following:

```bash
git clone git@github.com:Xilinx/dma_ip_drivers.git
cd dma_ip_drivers/XDMA/linux-kernel/xdma
make
sudo make install
```

If `make` fails due to a missing Makefile, you may have to install your Linux kernel's build files and headers with the following:

```bash
sudo apt install linux-headers-$(uname -r)
```

Now, you should be all set to load the driver module and connect to the FPGA via the XDMA IP.

```bash
su -

# unload driver (if needed)
rmmod xdma
# load driver
modprobe xdma

# Ensure that the driver and FPGA are working
dmesg | grep -i xdma
lspci | grep -i Xilinx
ls /dev/xdma*

```

### Example Transfers

```bash
cd dma_ip_drivers/XDMA/linux-kernel/tools

# Transfer 8KB to 0x0
dd if=/dev/urandom of=TEST8K bs=8192 count=1
./dma_to_device --verbose --device /dev/xdma0_h2c_0 --address 0x00000000 --size $((8*1024)) -f TEST8K
./dma_from_device --verbose --device /dev/xdma0_c2h_0 --address 0x00000000 --size $((8*1024)) --file RECV8K
cmp -b TEST8K RECV8K

# Transfer 512M to 0x0
dd if=/dev/urandom of=TEST512M bs=1M count=512
./dma_to_device --verbose --device /dev/xdma0_h2c_0 --address 0x00000000 --size $((512*1024*1024)) -f TEST512M
./dma_from_device --verbose --device /dev/xdma0_c2h_0 --address 0x00000000 --size $((512*1024*1024)) --file RECV512M
cmp -b TEST512M RECV512M
```
