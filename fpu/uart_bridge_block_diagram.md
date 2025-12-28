# UART Bridge Block Diagram

```mermaid
flowchart TD
    Start([Start]) --> WaitSync[Wait Sync Byte]
    
    WaitSync -->|"rx_dv and rx_byte = 0xA5"| GetOp[Get Operation Byte]
    WaitSync -->|"rx_byte != 0xA5"| WaitSync
    
    GetOp -->|rx_dv| OpCheck{"Valid Op?"}
    OpCheck -->|Invalid| TxError[TX Error Status]
    OpCheck -->|Timeout| TxTimeout[TX Timeout Status]
    OpCheck -->|Valid| GetA[Get Input A<br/>4 bytes]
    
    GetA -->|rx_dv| ByteA[Store Byte in a_buf]
    ByteA -->|"byte_idx < 3"| GetA
    ByteA -->|"byte_idx = 3"| GetB[Get Input B<br/>4 bytes]
    
    GetB -->|rx_dv| ByteB[Store Byte in b_buf]
    ByteB -->|"byte_idx < 3"| GetB
    ByteB -->|"byte_idx = 3"| Issue[Issue Operation]
    
    Issue -->|"Set input_a_stb<br/>Set input_b_stb<br/>Set output_z_ack"| WaitAB["Wait A and B Accepted"]
    
    WaitAB -->|input_a_ack| CheckA[A Accepted]
    WaitAB -->|input_b_ack| CheckB[B Accepted]
    
    CheckA -->|Clear input_a_stb| WaitABCheck{"Both Accepted?"}
    CheckB -->|Clear input_b_stb| WaitABCheck
    
    WaitABCheck -->|No| WaitAB
    WaitABCheck -->|Yes| WaitZ[Wait Result Z]
    
    WaitZ -->|output_z_stb| StoreZ[Store z_buf]
    WaitZ -->|Timeout| TxTimeout
    
    StoreZ -->|Clear output_z_ack| Tx0[TX Sync Response<br/>0x5A]
    
    Tx0 -->|tx_done| Tx1[TX Status Byte]
    Tx1 -->|tx_done| Tx2["TX z_buf bits 7:0"]
    Tx2 -->|tx_done| Tx3["TX z_buf bits 15:8"]
    Tx3 -->|tx_done| Tx4["TX z_buf bits 23:16"]
    Tx4 -->|tx_done| Tx5["TX z_buf bits 31:24"]
    
    Tx5 -->|tx_done| WaitSync
    
    TxError --> Tx0
    TxTimeout --> Tx0
    
    style Start fill:#90EE90
    style WaitSync fill:#FFD700
    style OpCheck fill:#FFD700
    style WaitABCheck fill:#FFD700
    style Issue fill:#87CEEB
    style WaitZ fill:#87CEEB
    style Tx0 fill:#FFA500
    style Tx1 fill:#FFA500
    style Tx2 fill:#FFA500
    style Tx3 fill:#FFA500
    style Tx4 fill:#FFA500
    style Tx5 fill:#FFA500
```

## UART Bridge Implementation Details

### Protocol Format
**Request Packet** (9 bytes):
1. Sync byte: `0xA5`
2. Operation byte: `op[1:0]` (bits 1:0), upper bits must be 0
3. Input A: 4 bytes (little-endian)
4. Input B: 4 bytes (little-endian)

**Response Packet** (6 bytes):
1. Sync byte: `0x5A`
2. Status byte: `0x00` (OK), `0x01` (BAD_SYNC), `0x02` (BAD_OP), `0x10` (TIMEOUT)
3. Result Z: 4 bytes (little-endian)

### Inputs/Outputs
- **UART RX**: `rx_dv`, `rx_byte[7:0]`
- **UART TX**: `tx_dv`, `tx_byte[7:0]`, `tx_active`, `tx_done`
- **FPU Interface**:
  - `op[1:0]`, `input_a[31:0]`, `input_b[31:0]`
  - `input_a_stb`, `input_b_stb`, `input_a_ack`, `input_b_ack`
  - `output_z[31:0]`, `output_z_stb`, `output_z_ack`

### Key States
1. **S_WAIT_SYNC**: Waits for sync byte `0xA5`
2. **S_GET_OP**: Receives operation byte (validates op code)
3. **S_GET_A**: Receives 4 bytes for input A
4. **S_GET_B**: Receives 4 bytes for input B
5. **S_ISSUE**: Issues operation to FPU (asserts strobes)
6. **S_WAIT_AB**: Waits for FPU to accept inputs A and B
7. **S_WAIT_Z**: Waits for FPU result (with timeout)
8. **S_TX_0 to S_TX_5**: Transmits response packet (6 bytes)

### Timeout Handling
- **RX Timeout**: `RX_TIMEOUT_CYCLES` (~40ms @50MHz) - timeout between bytes
- **Z Timeout**: `Z_TIMEOUT_CYCLES` (~1s @50MHz) - timeout waiting for result

### Error Handling
- **BAD_SYNC**: Invalid sync byte received
- **BAD_OP**: Invalid operation code (not 00, 01, or 10)
- **TIMEOUT**: Timeout during byte reception or result waiting

## UART Bridge FSM State Diagram

```mermaid
stateDiagram-v2
    [*] --> S_WAIT_SYNC: Reset
    
    S_WAIT_SYNC --> S_WAIT_SYNC: rx_byte != 0xA5
    S_WAIT_SYNC --> S_GET_OP: rx_byte == 0xA5
    
    S_GET_OP --> S_TX_0: Timeout
    S_GET_OP --> S_TX_0: Invalid op
    S_GET_OP --> S_GET_A: Valid op
    
    S_GET_A --> S_TX_0: Timeout
    S_GET_A --> S_GET_A: byte_idx < 3
    S_GET_A --> S_GET_B: byte_idx == 3
    
    S_GET_B --> S_TX_0: Timeout
    S_GET_B --> S_GET_B: byte_idx < 3
    S_GET_B --> S_ISSUE: byte_idx == 3
    
    S_ISSUE --> S_WAIT_AB: Assert strobes
    
    S_WAIT_AB --> S_WAIT_AB: Waiting for ACKs
    S_WAIT_AB --> S_WAIT_Z: Both ACKed
    
    S_WAIT_Z --> S_TX_0: Timeout
    S_WAIT_Z --> S_TX_0: output_z_stb
    
    S_TX_0 --> S_TX_1: tx_done (SYNC 0x5A)
    S_TX_1 --> S_TX_2: tx_done (Status)
    S_TX_2 --> S_TX_3: tx_done (z[7:0])
    S_TX_3 --> S_TX_4: tx_done (z[15:8])
    S_TX_4 --> S_TX_5: tx_done (z[23:16])
    S_TX_5 --> S_WAIT_SYNC: tx_done (z[31:24])
    
    note right of S_WAIT_SYNC
        Wait for sync byte 0xA5
        Reset byte_idx
    end note
    
    note right of S_GET_OP
        Receive operation byte
        Validate op code (00/01/10)
        Set status on error
    end note
    
    note right of S_GET_A
        Receive 4 bytes for input A
        Store in a_buf
        Increment byte_idx
        Timeout if gap too long
    end note
    
    note right of S_GET_B
        Receive 4 bytes for input B
        Store in b_buf
        Increment byte_idx
        Timeout if gap too long
    end note
    
    note right of S_ISSUE
        Assert input_a_stb
        Assert input_b_stb
        Assert output_z_ack
    end note
    
    note right of S_WAIT_AB
        Wait for both inputs
        to be accepted by FPU
        Clear strobes on ACK
    end note
    
    note right of S_WAIT_Z
        Wait for FPU result
        Store in z_buf on output_z_stb
        Timeout after 1 second
    end note
    
    note right of S_TX_0
        Transmit response:
        1. Sync (0x5A)
        2. Status byte
        3-6. Result bytes (little-endian)
    end note
```
