# Multiplier Block Diagram

```mermaid
flowchart TD
    Start([Start]) --> GetA[Get Input A]
    GetA -->|"input_a_stb and input_a_ack"| GetB[Get Input B]
    GetB -->|"input_b_stb and input_b_ack"| Unpack[Unpack IEEE 754]
    
    Unpack -->|Extract sign, exponent, mantissa| SpecialCases{"Special Cases?"}
    
    SpecialCases -->|NaN| PutZ[Put Result Z]
    SpecialCases -->|"Inf * Zero = NaN"| PutZ
    SpecialCases -->|"Inf * Num = Inf"| PutZ
    SpecialCases -->|"Zero * Num = Zero"| PutZ
    SpecialCases -->|Normal| NormaliseA[Normalise A Mantissa]
    
    NormaliseA -->|a_m bit 23 = 0| NormaliseALoop[Shift Left]
    NormaliseALoop --> NormaliseA
    NormaliseA -->|Normalised| NormaliseB[Normalise B Mantissa]
    
    NormaliseB -->|b_m bit 23 = 0| NormaliseBLoop[Shift Left]
    NormaliseBLoop --> NormaliseB
    NormaliseB -->|Normalised| Multiply0[Multiply Mantissas]
    
    Multiply0 -->|"z_s = a_s XOR b_s<br/>z_e = a_e + b_e + 1<br/>product = a_m * b_m"| Multiply1[Extract Product]
    
    Multiply1 -->|Extract z_m bits 47:24<br/>guard, round_bit, sticky| Normalise1[Normalise: Shift Left]
    
    Normalise1 -->|z_m bit 23 = 0| Normalise1Loop[Shift Left]
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
    style Normalise1 fill:#87CEEB
    style Normalise2 fill:#87CEEB
    style Round fill:#FFA500
```

## Multiplier Implementation Details

### Inputs/Outputs
- **Inputs**: `input_a[31:0]`, `input_b[31:0]` (IEEE 754 single precision)
- **Handshake**: `input_a_stb`, `input_b_stb`, `input_a_ack`, `input_b_ack`
- **Output**: `output_z[31:0]` (IEEE 754 single precision)
- **Handshake**: `output_z_stb`, `output_z_ack`

### Key Processing Stages
1. **Unpack**: Extracts sign, exponent, mantissa from IEEE 754 format
2. **Special Cases**: Handles NaN, Infinity, Zero multiplication cases
3. **Normalise A/B**: Normalizes both mantissas to ensure leading 1
4. **Multiply**: Performs 24-bit × 24-bit multiplication (produces 48-bit product)
   - Sign: XOR of input signs
   - Exponent: Sum of exponents + 1
   - Mantissa: Product of mantissas
5. **Normalise**: Normalizes product to IEEE 754 format
6. **Round**: Applies rounding based on guard, round_bit, and sticky bits
7. **Pack**: Combines sign, exponent, and mantissa into final result

## Multiplier FSM State Diagram

```mermaid
stateDiagram-v2
    [*] --> get_a: Reset
    
    get_a --> get_b: input_a_stb & input_a_ack
    get_b --> unpack: input_b_stb & input_b_ack
    
    unpack --> special_cases
    
    special_cases --> put_z: NaN/Inf/Zero detected
    special_cases --> normalise_a: Normal numbers
    
    normalise_a --> normalise_a: a_m[23] == 0 (shift left)
    normalise_a --> normalise_b: a_m[23] == 1
    
    normalise_b --> normalise_b: b_m[23] == 0 (shift left)
    normalise_b --> multiply_0: b_m[23] == 1
    
    multiply_0 --> multiply_1: Compute product
    
    multiply_1 --> normalise_1: Extract product bits
    
    normalise_1 --> normalise_1: z_m[23] == 0 (shift left)
    normalise_1 --> normalise_2: Normalised
    
    normalise_2 --> normalise_2: z_e < -126
    normalise_2 --> round: Normalised
    
    round --> pack
    
    pack --> put_z
    
    put_z --> get_a: output_z_stb & output_z_ack
    
    note right of multiply_0
        Compute:
        z_s = a_s XOR b_s
        z_e = a_e + b_e + 1
        product = a_m * b_m (48 bits)
    end note
    
    note right of multiply_1
        Extract:
        z_m = product[47:24]
        guard = product[23]
        round_bit = product[22]
        sticky = product[21:0] != 0
    end note
    
    note right of normalise_1
        Left shift mantissa
        if leading bit is 0
    end note
    
    note right of normalise_2
        Right shift if underflow
        (z_e < -126)
    end note
```
