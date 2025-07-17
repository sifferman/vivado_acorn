
export C2H_DEVICE=/dev/xdma0_c2h_0
export H2C_DEVICE=/dev/xdma0_h2c_0

xdma_c2h_file() {
  local addr=$1 file=$2 size=$3

  tmp=$(mktemp /tmp/c2h.XXXXXX)
  rm $tmp
  sudo "$(which dma_from_device)" \
    --device "$C2H_DEVICE" \
    --address "$addr" \
    --size "$size" \
    --file "$tmp" > /dev/null
  local rc=$?
  if (( rc != 0 )); then
    sudo rm -f "$tmp"
    return $rc
  fi

  local owner=${SUDO_USER:-$USER}
  sudo chown "$owner":"$owner" "$tmp"
  sudo chmod 644 "$tmp"
  mv "$tmp" "$file"
}

xdma_h2c_file() {
  local addr=$1 file=$2

  local size
  size=$(stat -c%s "$file")

  sudo "$(which dma_to_device)" \
    --device "$H2C_DEVICE" \
    --address "$addr" \
    --size "$size" \
    -f "$file" > /dev/null
}

xdma_c2h_4() {
  local addr=$1 size=4 tmp
  tmp=$(mktemp /tmp/c2h.XXXXXX)
  rm -f "$tmp"
  sudo "$(which dma_from_device)" --device "$C2H_DEVICE" \
       --address "$addr" --size "$size" --file "$tmp" > /dev/null
  local rc=$?
  hexdump -v -e '1/4 "%08x "' "$tmp"
  echo
  sudo rm -f "$tmp"
  return $rc
}

xdma_h2c_4() {
  local addr=$1 data=$2 size=4 tmp
  local datalen=${#data}
  local maxlen=$(( size * 2 ))

  if [[ ! $data =~ ^[0-9A-Fa-f]*$ ]]; then
    echo "xdma_h2c_4 ERROR: data contains non-hex characters" >&2
    return 1
  elif (( datalen > maxlen )); then
    echo "xdma_h2c_4 ERROR: data length ${datalen} exceeds maximum ${maxlen}" >&2
    return 1
  fi

  data=$(printf "%0${maxlen}s" "$data" | tr ' ' '0')

  # convert to little endian
  local swapped="" chunk
  for (( i=0; i<maxlen; i+=8 )); do
    chunk=${data:i:8}
    swapped+="${chunk:6:2}${chunk:4:2}${chunk:2:2}${chunk:0:2}"
  done
  data=$swapped

  # write to tmp and send
  tmp=$(mktemp /tmp/h2c.XXXXXX)
  echo -n "$data" | xxd -r -p > "$tmp"
  # xxd "$tmp"
  sudo "$(which dma_to_device)" --device "$H2C_DEVICE" \
       --address "$addr" --size "$size" -f "$tmp"  > /dev/null
  local rc=$?
  rm -f "$tmp"
  return $rc
}

test_pcie_bram() {
  dd if=/dev/urandom of=TEST8K bs=$((8*1024)) count=1
  xdma_h2c_file 0x0 TEST8K
  xdma_c2h_file 0x0 RECV8K $((8*1024))
  cmp -b TEST8K RECV8K
  rm -rf TEST8K RECV8K
}

test_pcie_ddr3() {
  dd if=/dev/urandom of=TEST512M bs=$((512*1024*1024)) count=1
  xdma_h2c_file 0x0 TEST512M
  xdma_c2h_file 0x0 RECV512M $((512*1024*1024))
  cmp -b TEST512M RECV512M
  rm -rf TEST512M RECV512M
}

test_pcie_ddr3_rtl() {
  dd if=/dev/urandom of=TEST512M bs=$((512*1024*1024)) count=1
  xdma_h2c_file 0x0 TEST512M
  xdma_c2h_file 0x0 RECV512M $((512*1024*1024))
  cmp -b TEST512M RECV512M
  rm -rf TEST512M RECV512M

  expected="beefcafe"
  received=$(xdma_c2h_4 0x80000000 | tr -d ' \n')
  if [[ "$received" == "$expected" ]]; then
    echo "PASS: received $received"
  else
    echo "FAIL: expected $expected, received $received"
  fi
}

# Xilinx AXI MM2S FIFO IP
# https://docs.amd.com/r/en-US/pg080-axi-fifo-mm-s/Programing-Sequence

# Register offsets from C_BASEADDR
ISR_OFFSET=0x0   # Interrupt Status (Read/Clear W1)
IER_OFFSET=0x4   # Interrupt Enable
TDFR_OFFSET=0x8  # Transmit Data FIFO Reset
TDFV_OFFSET=0xC  # TX FIFO Vacancy (Read)
TDFD_OFFSET=0x10 # TX FIFO Data Write
TLR_OFFSET=0x14  # Transmit Length
SRR_OFFSET=0x28  # AXI4-Stream Reset
TDR_OFFSET=0x2C  # Transmit Destination
RDR_OFFSET=0x30  # Receive Destination

xdma_mm2s_setup() {
  local base=$1

  echo Reset \(missing from documentation\)
  xdma_h2c_4 $((base + TDFR_OFFSET)) a5
  xdma_h2c_4 $((base + SRR_OFFSET)) a5

  echo Read interrupt status register \(indicates transmit reset complete and receive reset complete\) \(01D00000\)
  xdma_c2h_4 $((base + ISR_OFFSET))
  echo Write to clear reset done interrupt bits
  xdma_h2c_4 $((base + ISR_OFFSET)) FFFFFFFF
  echo Read interrupt status register \(00000000\)
  xdma_c2h_4 $((base + ISR_OFFSET))
  echo Read interrupt enable register \(00000000\)
  xdma_c2h_4 $((base + IER_OFFSET))
  echo Read the transmit FIFO vacancy \(for TX FIFO Depth of 512\) \(000001FC\)
  xdma_c2h_4 $((base + TDFV_OFFSET))
  echo Read the receive FIFO occupancy \(00000000\)
  xdma_c2h_4 $((base + RDFO_OFFSET))
}


xdma_mm2s_transmit_4() {
  local base=$1
  local word=$2
  echo Enable transmit complete and receive complete interrupts
  xdma_h2c_4 $((base + IER_OFFSET)) 0C000000

  echo Transmit Destination address \(0x2 = destination device address is 2\)
  xdma_h2c_4 $((base + TDR_OFFSET)) 00000002

  echo 4 bytes of data
  xdma_h2c_4 $((base + TDFD_OFFSET)) $word

  echo Read the transmit FIFO vacancy \(000001F4\)
  xdma_c2h_4 $((base + TDFV_OFFSET))
  echo Transmit length \(4 bytes\), this starts transmission
  xdma_h2c_4 $((base + TLR_OFFSET)) 4
  echo A typical value after TX Complete is indicated by interrupt \(08000000\)
  xdma_c2h_4 $((base + ISR_OFFSET))
  echo Write to clear transmit complete interrupt bits
  xdma_h2c_4 $((base + ISR_OFFSET)) FFFFFFFF
  echo Read interrupt status register \(00000000\)
  xdma_c2h_4 $((base + ISR_OFFSET))
  echo Read the transmit FIFO vacancy \(000001FC\)
  xdma_c2h_4 $((base + TDFV_OFFSET))
}

test_pcie_mm2s_rtl() {
  local word="${1:-deadbeef}"
  xdma_mm2s_setup 0x0
  xdma_mm2s_transmit_4 0x0 $word
  echo Data from Internal register:
  expected=$word
  received=$(xdma_c2h_4 0x80000000 | tr -d ' \n')
  if [[ "$received" == "$expected" ]]; then
    echo "PASS: received $received"
  else
    echo "FAIL: expected $expected, received $received"
  fi
}
