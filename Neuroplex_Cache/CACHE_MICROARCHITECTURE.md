# NeuroplexCache Microarchitecture Documentation

This document provides detailed Mermaid diagrams of the NeuroplexCache microarchitecture.

## Diagram Files

1. **`cache_overview.mmd`** - High-level overview showing major components
2. **`cache_microarchitecture.mmd`** - Detailed block diagram with all modules and connections
3. **`cache_state_machine.mmd`** - FSM state transitions and operations
4. **`cache_data_flow.mmd`** - Data flow paths for hit and miss scenarios

## Cache Specifications

- **Size**: 64KB (512 sets × 4 ways × 32 bytes/line)
- **Associativity**: 4-way set-associative
- **Line Size**: 32 bytes (256 bits)
- **Address Space**: 20 bits (1MB)
- **Tag Bits**: 6 bits
- **Index Bits**: 9 bits
- **Offset Bits**: 5 bits
- **Write Policy**: Write-back, write-allocate
- **Replacement**: Random (invalid-first)

## Component Descriptions

### 1. Address Decoder (AddrDecode)
- Splits 20-bit address into:
  - **Tag** [19:14]: 6 bits
  - **Index** [13:5]: 9 bits (selects set)
  - **Offset** [4:0]: 5 bits (byte offset within line)

### 2. Tag Array (TagArray)
- **Storage**: 512 sets × 4 ways
- **Per way**: tag[5:0], valid bit, dirty bit
- **Read**: Combinational read of all 4 ways for a set
- **Write**: Tag/valid write on refill, dirty write on store hits

### 3. Data Array (DataArray)
- **Storage**: 512 sets × 4 ways × 256 bits
- **Read**: Combinational read of one line (selected way)
- **Write**: 
  - Line write (refill): Write entire 256-bit line
  - Word write (store hit): Write 32-bit word with byte mask

### 4. Hit Comparator (HitCompare)
- Compares request tag with all 4 way tags
- Outputs:
  - `hit`: Boolean hit/miss
  - `hitWay`: Way number if hit (priority encoded)
  - `hasInvalid`: True if any way is invalid
  - `firstInvalidWay`: Lowest-index invalid way

### 5. Replacement Policy (ReplRandom)
- **Algorithm**: 16-bit Fibonacci LFSR
- **Taps**: 16, 14, 13, 11
- **Output**: `victimWay[1:0]` = LFSR[1:0]
- **Policy**: Invalid-first, then random

### 6. Control FSM
- **States**: 
  - `sIdle`: Wait for CPU request
  - `sLookup`: Tag comparison phase
  - `sWbReq`: Write-back dirty victim
  - `sMemReq`: Request memory refill
  - `sWaitResp`: Wait for memory response
  - `sResp`: Send response to CPU

## Data Paths

### Hit Path
1. CPU request → Address decode
2. Tag array read (all ways)
3. Hit comparison
4. Data array read (hit way)
5. Word extraction
6. CPU response (hit=true)

### Miss Path
1. CPU request → Address decode
2. Tag array read (all ways)
3. Hit comparison (miss detected)
4. Replacement way selection
5. Data array read (victim way)
6. If dirty: Write-back to memory
7. Memory refill request
8. Memory response
9. If write: Merge word into refill line
10. Install tag/data
11. CPU response (hit=false)

## Control Signals

### Request Handling
- `req.ready`: True only in `sIdle`
- `req.fire`: Latches request, transitions to `sLookup`

### Response Handling
- `resp.valid`: True in `sResp`
- `resp.fire`: Consumes response, returns to `sIdle`

### Memory Interface
- `memReq.valid`: True in `sWbReq` or `sMemReq`
- `memReq.wen`: True for write-back, false for refill
- `memResp.ready`: True in `sWaitResp`

## Statistics & Latency

The cache tracks:
- **accessCnt**: Total CPU requests
- **hitCnt**: Cache hits
- **missCnt**: Cache misses
- **evictCnt**: Evictions (conflict misses)
- **hitCyclesTotal**: Sum of hit latencies
- **missCyclesTotal**: Sum of miss latencies
- **lastLatency**: Latency of most recent request

## Viewing the Diagrams

### Using Mermaid Live Editor
1. Go to https://mermaid.live
2. Copy contents of any `.mmd` file
3. Paste into the editor
4. View rendered diagram

### Using VS Code
1. Install "Markdown Preview Mermaid Support" extension
2. Open `.mmd` files or embed in markdown

### Using Command Line
```bash
# Install mermaid-cli
npm install -g @mermaid-js/mermaid-cli

# Generate PNG
mmdc -i cache_microarchitecture.mmd -o cache_microarchitecture.png

# Generate SVG
mmdc -i cache_microarchitecture.mmd -o cache_microarchitecture.svg
```

## Key Features

1. **Masked Writes**: Supports byte, halfword, and word writes
2. **Write-Allocate**: Writes allocate cache lines on miss
3. **Write-Back**: Dirty victims written back before eviction
4. **Latency Tracking**: Measures and reports access latencies
5. **Statistics**: Comprehensive performance counters


