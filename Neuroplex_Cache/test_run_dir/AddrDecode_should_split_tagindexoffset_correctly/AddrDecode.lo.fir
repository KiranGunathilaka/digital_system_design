FIRRTL version 1.1.0
circuit AddrDecode :
  module AddrDecode :
    input clock : Clock
    input reset : UInt<1>
    input io_addr : UInt<20>
    output io_tag : UInt<6>
    output io_index : UInt<9>
    output io_offset : UInt<5>

    node _io_offset_T = bits(io_addr, 4, 0) @[AddrDecode.scala 15:23]
    node _io_index_T = bits(io_addr, 13, 5) @[AddrDecode.scala 16:23]
    node _io_tag_T = bits(io_addr, 19, 14) @[AddrDecode.scala 17:23]
    io_tag <= _io_tag_T @[AddrDecode.scala 17:13]
    io_index <= _io_index_T @[AddrDecode.scala 16:13]
    io_offset <= _io_offset_T @[AddrDecode.scala 15:13]
