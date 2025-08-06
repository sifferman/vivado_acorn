#!/bin/bash
#
# One‑Shot 50 ms Timer0 (down‑count, hold at 0 when done,
# GenerateOut pulses one clock at rollover)
#

# 1) Your AXI‑Timer base
BASE=0x40000000

# 2) Register offsets
TCSR0=0x00   # Control/Status
TLR0=0x04    # Load
TCR0=0x08    # Counter

# 3) Load value for 50 ms @100 MHz:
#    (50e-3 * 1e8) - 2 = 4_999_998 = 0x004C4B3E
TLR0_VAL=004C4B3E

# 4) Disable Timer0
echo "Disabling Timer0"
xdma_h2c_int32 $((BASE+TCSR0)) 00000000

# 5) Write the load register (32‑bit padded)
echo "Programming TLR0 = 0x$TLR0_VAL"
xdma_h2c_int32 $((BASE+TLR0)) $TLR0_VAL

# 6) Pulse LOAD0 to copy TLR0→TCR0
#    LOAD0 (bit5)=0x20, UDT0 (bit1)=0x02 → CSR=0x00000022
echo "Pulsing LOAD0 (0x22) to copy TLR0→TCR0"
xdma_h2c_int32 $((BASE+TCSR0)) 00000022

# 7) Read back TCR0 now—should equal TLR0_VAL
echo -n " TCR0 after LOAD: "
xdma_c2h_int32 $((BASE+TCR0))

# 8) Small delay
sleep 0.001

# 9) Start the timer: clear LOAD0 and set ENT0+GENT0+UDT0
#    ENT0(bit7)=0x80, GENT0(bit2)=0x04, UDT0(bit1)=0x02 → CSR=0x00000086
echo "Starting Timer0 (CSR=0x00000086)"
xdma_h2c_int32 $((BASE+TCSR0)) 00000086

# 10) Poll TCR0 every 10 ms to show it counting down
echo; echo "... polling TCR0 every 10 ms:"
for i in 1 2 3 4 5; do
  sleep 0.01
  printf " TCR0 @ +%d0 ms: " $i
  xdma_c2h_int32 $((BASE+TCR0))
done

# 11) Final check: should be 00000000 and held
echo; echo "Final TCR0 (should be 00000000):"
xdma_c2h_int32 $((BASE+TCR0))

# Re‑arm by repeating steps 6 and 9:
#   xdma_h2c_int32 $((BASE+TCSR0)) 00000022
#   sleep 0.001
#   xdma_h2c_int32 $((BASE+TCSR0)) 00000086
