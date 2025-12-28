# FPU Top Unit Block Diagram

```mermaid
flowchart TD
    InputA["input_a(31:0)"] --> MuxA[Input Multiplexer]
    InputB["input_b(31:0)"] --> MuxB[Input Multiplexer]
    Op["op(1:0)"] --> OpLatch[Operation Latch]
    
    OpLatch -->|00 = ADD<br/>01 = MUL<br/>10 = DIV| OpSel[Operation Selector]
    
    OpSel -->|OP_ADD| GateA1[Gate A STB]
    OpSel -->|OP_ADD| GateB1[Gate B STB]
    OpSel -->|OP_MUL| GateA2[Gate A STB]
    OpSel -->|OP_MUL| GateB2[Gate B STB]
    OpSel -->|OP_DIV| GateA3[Gate A STB]
    OpSel -->|OP_DIV| GateB3[Gate B STB]
    
    MuxA --> AdderUnit[Adder Unit]
    MuxA --> MultiplierUnit[Multiplier Unit]
    MuxA --> DividerUnit[Divider Unit]
    
    MuxB --> AdderUnit
    MuxB --> MultiplierUnit
    MuxB --> DividerUnit
    
    GateA1 --> AdderUnit
    GateB1 --> AdderUnit
    GateA2 --> MultiplierUnit
    GateB2 --> MultiplierUnit
    GateA3 --> DividerUnit
    GateB3 --> DividerUnit
    
    AdderUnit -->|add_z bits 31:0<br/>add_z_stb| OutputMux[Output Multiplexer]
    MultiplierUnit -->|mul_z bits 31:0<br/>mul_z_stb| OutputMux
    DividerUnit -->|div_z bits 31:0<br/>div_z_stb| OutputMux
    
    OpSel --> OutputMux
    
    AdderUnit -->|add_a_ack<br/>add_b_ack| AckMux[Acknowledge Multiplexer]
    MultiplierUnit -->|mul_a_ack<br/>mul_b_ack| AckMux
    DividerUnit -->|div_a_ack<br/>div_b_ack| AckMux
    
    OpSel --> AckMux
    
    OutputMux --> OutputZ["output_z(31:0)"]
    OutputMux --> OutputZStb[output_z_stb]
    
    AckMux --> InputAAck[input_a_ack]
    AckMux --> InputBAck[input_b_ack]
    
    OutputZAck[output_z_ack] -->|Gated by op_sel| AdderUnit
    OutputZAck -->|Gated by op_sel| MultiplierUnit
    OutputZAck -->|Gated by op_sel| DividerUnit
    
    BusyLogic[Busy Logic] --> OpLatch
    BusyLogic -->|Transaction tracking| OpSel
    
    style OpLatch fill:#FFD700
    style OpSel fill:#FFD700
    style AdderUnit fill:#87CEEB
    style MultiplierUnit fill:#87CEEB
    style DividerUnit fill:#87CEEB
    style OutputMux fill:#90EE90
    style AckMux fill:#90EE90
```

## FPU Top Unit Implementation Details

### Inputs/Outputs
- **Operation Select**: `op[1:0]`
  - `2'b00` = ADD
  - `2'b01` = MUL
  - `2'b10` = DIV
- **Inputs**: `input_a[31:0]`, `input_b[31:0]` (IEEE 754 single precision)
- **Handshake**: `input_a_stb`, `input_b_stb`, `input_a_ack`, `input_b_ack`
- **Output**: `output_z[31:0]` (IEEE 754 single precision)
- **Handshake**: `output_z_stb`, `output_z_ack`

### Key Components
1. **Operation Latch**: Latches the operation code when transaction starts
2. **Operation Selector**: Selects which FPU unit to activate based on `op`
3. **Input Gating**: Gates input strobes (`input_a_stb`, `input_b_stb`) to selected unit only
4. **Output Multiplexer**: Routes output from selected unit to `output_z`
5. **Acknowledge Multiplexer**: Routes acknowledgements from selected unit
6. **Busy Logic**: Tracks transaction state (from A accepted to Z accepted)
   - Prevents operation change during active transaction
   - Ensures proper handshaking

### Transaction Flow
1. `op` must be stable when `input_a_stb` is asserted
2. Operation is latched when `input_a` is accepted
3. Selected unit processes the operation
4. Result is routed through output multiplexer
5. Busy flag clears when result is accepted

## FPU Top Unit State Tracking

```mermaid
stateDiagram-v2
    [*] --> idle: Reset
    
    idle --> busy: input_a_stb & input_a_ack
    note right of idle
        op_lat = op
        busy = 0
        Ready for new transaction
    end note
    
    busy --> busy: Processing
    note right of busy
        op_lat latched
        busy = 1
        Selected unit processing
        - Adder (op=00)
        - Multiplier (op=01)
        - Divider (op=10)
    end note
    
    busy --> idle: output_z_stb & output_z_ack
    note right of idle
        Result accepted
        busy = 0
        Ready for next transaction
    end note
    
    note right of busy
        During busy state:
        - Inputs gated to selected unit
        - Outputs muxed from selected unit
        - ACKs routed from selected unit
        - op changes ignored
    end note
```
