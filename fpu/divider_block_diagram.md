# Divider Block Diagram

```mermaid
graph TD
    Start([Start]) --> GetA[Get Input A]
    GetA -->|"input_a_stb & input_a_ack"| GetB[Get Input B]
    GetB -->|"input_b_stb & input_b_ack"| Unpack[Unpack IEEE 754]

    Unpack -->|Extract sign, exponent, mantissa| SpecialCases{"Special Cases?"}

    SpecialCases -->|NaN| PutZ[Put Result Z]
    SpecialCases -->|"Inf/Inf = NaN"| PutZ
    SpecialCases -->|"Inf/Num = Inf"| PutZ
    SpecialCases -->|"Num/Inf = Zero"| PutZ
    SpecialCases -->|"Zero/Zero = NaN"| PutZ
    SpecialCases -->|"Num/Zero = Inf"| PutZ
    SpecialCases -->|Normal| NormaliseA[Normalise A Mantissa]

    NormaliseA -->|a_m bit 23 = 0| NormaliseALoop[Shift Left]
    NormaliseALoop --> NormaliseA
    NormaliseA -->|Normalised| NormaliseB[Normalise B Mantissa]

    NormaliseB -->|b_m bit 23 = 0| NormaliseBLoop[Shift Left]
    NormaliseBLoop --> NormaliseB
    NormaliseB -->|Normalised| Divide0[Initialize Division]

    Divide0 -->|"z_s=a_s XOR b_s; z_e=a_e-b_e; setup dividend/divisor"| Divide1["Shift and Compare"]

    Divide1 -->|"Shift quotient and remainder; load next dividend bit"| Divide2{"remainder >= divisor?"}

    Divide2 -->|Yes| Divide2Yes[Set quotient bit; subtract divisor]
    Divide2 -->|No| Divide2No[Continue]

    Divide2Yes --> DivideCheck{"Count = 49?"}
    Divide2No --> DivideCheck

    DivideCheck -->|No| Divide1
    DivideCheck -->|Yes| Divide3[Extract Result]

    Divide3 -->|Extract z_m, guard, round_bit| Normalise1[Normalise: Shift Left]

    Normalise1 -->|"z_m bit 23 = 0 and z_e > -126"| Normalise1Loop[Shift Left]
    Normalise1Loop --> Normalise1
    Normalise1 -->|Normalised| Normalise2[Check Underflow]

    Normalise2 -->|"z_e < -126"| Normalise2Loop[Shift Right]
    Normalise2Loop --> Normalise2
    Normalise2 -->|Normalised| Round[Round Result]

    Round -->|"guard & round_bit"| RoundInc[Increment Mantissa]
    RoundInc --> Pack[Pack IEEE 754]
    Round -->|No rounding| Pack

    Pack -->|Combine sign, exponent, mantissa| PutZ
    PutZ -->|"output_z_stb & output_z_ack"| GetA

    style Start fill:#90EE90
    style PutZ fill:#90EE90
    style SpecialCases fill:#FFD700
    style Divide2 fill:#FFD700
    style DivideCheck fill:#FFD700
    style Normalise1 fill:#87CEEB
    style Normalise2 fill:#87CEEB
    style Round fill:#FFA500

```

## Divider Implementation Details

### Inputs/Outputs
- **Inputs**: `input_a[31:0]`, `input_b[31:0]` (IEEE 754 single precision)
- **Handshake**: `input_a_stb`, `input_b_stb`, `input_a_ack`, `input_b_ack`
- **Output**: `output_z[31:0]` (IEEE 754 single precision)
- **Handshake**: `output_z_stb`, `output_z_ack`

### Key Processing Stages
1. **Unpack**: Extracts sign, exponent, mantissa from IEEE 754 format
2. **Special Cases**: Handles NaN, Infinity, Zero division cases
3. **Normalise A/B**: Normalizes both mantissas to ensure leading 1
4. **Division Loop**: Performs 50-bit iterative division (shift-and-subtract algorithm)
   - Divides dividend by divisor over 50 iterations
   - Builds quotient bit by bit
5. **Normalise**: Normalizes quotient to IEEE 754 format
6. **Round**: Applies rounding based on guard, round_bit, and sticky bits
7. **Pack**: Combines sign, exponent, and mantissa into final result

## Divider FSM State Diagram

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
    normalise_b --> divide_0: b_m[23] == 1
    
    divide_0 --> divide_1: Initialize division
    
    divide_1 --> divide_2: Shift & load bit
    
    divide_2 --> divide_2: remainder >= divisor (subtract)
    divide_2 --> divide_check: Continue
    
    divide_check --> divide_1: count < 49
    divide_check --> divide_3: count == 49
    
    divide_3 --> normalise_1: Extract result
    
    normalise_1 --> normalise_1: z_m[23] == 0 & z_e > -126
    normalise_1 --> normalise_2: Normalised
    
    normalise_2 --> normalise_2: z_e < -126
    normalise_2 --> round: Normalised
    
    round --> pack
    
    pack --> put_z
    
    put_z --> get_a: output_z_stb & output_z_ack
    
    note right of divide_0
        Setup:
        z_s = a_s XOR b_s
        z_e = a_e - b_e
        dividend = a_m << 27
        divisor = b_m
    end note
    
    note right of divide_1
        Shift quotient left
        Shift remainder left
        Load next dividend bit
    end note
    
    note right of divide_2
        If remainder >= divisor:
        Set quotient bit
        Subtract divisor
    end note
    
    note right of divide_check
        Iterate 50 times
        to get 50-bit quotient
    end note
```
