# Adder Block Diagram

```mermaid
flowchart TD
    Start([Start]) --> GetA[Get Input A]
    GetA -->|"input_a_stb and input_a_ack"| GetB[Get Input B]
    GetB -->|"input_b_stb and input_b_ack"| Unpack[Unpack IEEE 754]
    
    Unpack -->|Extract sign, exponent, mantissa| SpecialCases{"Special Cases?"}
    
    SpecialCases -->|NaN| PutZ[Put Result Z]
    SpecialCases -->|Infinity| PutZ
    SpecialCases -->|Zero| PutZ
    SpecialCases -->|Normal| Align[Align Exponents]
    
    Align -->|Shift smaller mantissa| AlignCheck{"Aligned?"}
    AlignCheck -->|No| Align
    AlignCheck -->|Yes| Add0[Add/Subtract Mantissas]
    
    Add0 -->|"Same sign: add<br/>Different sign: subtract"| Add1[Check Sum Overflow]
    
    Add1 -->|sum bit 27 = 1| Normalise1[Normalise: Shift Right]
    Add1 -->|sum bit 27 = 0| Normalise1
    
    Normalise1 -->|"z_m bit 23 = 0 and z_e > -126"| Normalise1Loop[Shift Left]
    Normalise1Loop --> Normalise1
    Normalise1 -->|Normalised| Normalise2[Check Underflow]
    
    Normalise2 -->|"z_e < -126"| Normalise2Loop[Shift Right]
    Normalise2Loop --> Normalise2
    Normalise2 -->|Normalised| Round[Round Result]
    
    Round -->|"guard and round_bit"| RoundInc[Increment Mantissa]
    RoundInc --> Pack[Pack IEEE 754]
    Round -->|No rounding| Pack
    
    Pack -->|Combine sign, exponent, mantissa| PutZ
    PutZ -->|"output_z_stb and output_z_ack"| GetA
    
    style Start fill:#90EE90
    style PutZ fill:#90EE90
    style SpecialCases fill:#FFD700
    style AlignCheck fill:#FFD700
    style Normalise1 fill:#87CEEB
    style Normalise2 fill:#87CEEB
    style Round fill:#FFA500
```

## Adder Implementation Details

### Inputs/Outputs
- **Inputs**: `input_a[31:0]`, `input_b[31:0]` (IEEE 754 single precision)
- **Handshake**: `input_a_stb`, `input_b_stb`, `input_a_ack`, `input_b_ack`
- **Output**: `output_z[31:0]` (IEEE 754 single precision)
- **Handshake**: `output_z_stb`, `output_z_ack`

### Key Processing Stages
1. **Unpack**: Extracts sign (bit 31), exponent (bits 30:23), mantissa (bits 22:0)
2. **Special Cases**: Handles NaN, Infinity, Zero cases
3. **Align**: Aligns mantissas by shifting the smaller exponent
4. **Add/Subtract**: Performs mantissa addition or subtraction based on signs
5. **Normalise**: Normalizes result to IEEE 754 format
6. **Round**: Applies rounding based on guard, round_bit, and sticky bits
7. **Pack**: Combines sign, exponent, and mantissa into final result

## Adder FSM State Diagram

```mermaid
stateDiagram-v2
    [*] --> get_a: Reset
    
    get_a --> get_b: input_a_stb & input_a_ack
    get_b --> unpack: input_b_stb & input_b_ack
    
    unpack --> special_cases
    
    special_cases --> put_z: NaN/Inf/Zero detected
    special_cases --> align: Normal numbers
    
    align --> align: a_e != b_e (shift mantissa)
    align --> add_0: a_e == b_e
    
    add_0 --> add_1
    
    add_1 --> normalise_1
    
    normalise_1 --> normalise_1: z_m[23] == 0 & z_e > -126
    normalise_1 --> normalise_2: Normalised
    
    normalise_2 --> normalise_2: z_e < -126
    normalise_2 --> round: Normalised
    
    round --> pack
    
    pack --> put_z
    
    put_z --> get_a: output_z_stb & output_z_ack
    
    note right of get_a
        Wait for input_a
        Assert input_a_ack
    end note
    
    note right of special_cases
        Check for:
        - NaN
        - Infinity
        - Zero
    end note
    
    note right of align
        Shift smaller mantissa
        until exponents match
    end note
    
    note right of normalise_1
        Left shift if needed
        to normalize mantissa
    end note
    
    note right of normalise_2
        Right shift if underflow
        (z_e < -126)
    end note
```
