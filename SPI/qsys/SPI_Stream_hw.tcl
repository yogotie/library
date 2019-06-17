# TCL File Generated by Component Editor 17.1
# Sun Feb 04 00:21:03 BRT 2018
# DO NOT MODIFY


#
# SPI_Stream "SPI Stream" v1.0
# SPI Streaming interface
#

#
# request TCL package from ACDS 16.1
#
package require -exact qsys 16.1


#
# module SPI_Stream
#
set_module_property  DESCRIPTION                   "SPI Streaming interface"
set_module_property  NAME                          SPI_Stream
set_module_property  VERSION                       1.0
set_module_property  INTERNAL                      false
set_module_property  OPAQUE_ADDRESS_MAP            true
set_module_property  GROUP                         yogotie
set_module_property  AUTHOR                        "yogotie""
set_module_property  DISPLAY_NAME                  "SPI Stream"
set_module_property  INSTANTIATE_IN_SYSTEM_MODULE  true
set_module_property  EDITABLE                      true
set_module_property  REPORT_TO_TALKBACK            false
set_module_property  ALLOW_GREYBOX_GENERATION      false
set_module_property  REPORT_HIERARCHY              false


#
# file sets
#
# Synthesis Files
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""

set_fileset_property QUARTUS_SYNTH TOP_LEVEL spi
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false

add_fileset_file  spi.vhd     VHDL  PATH  ../vhdl/spi.vhd     TOP_LEVEL_FILE
add_fileset_file  spi_rx.vhd  VHDL  PATH  ../vhdl/spi_rx.vhd
add_fileset_file  spi_tx.vhd  VHDL  PATH  ../vhdl/spi_tx.vhd

# Verilog simulation files
add_fileset SIM_VERILOG SIM_VERILOG "" ""

set_fileset_property SIM_VERILOG TOP_LEVEL spi
set_fileset_property SIM_VERILOG ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property SIM_VERILOG ENABLE_FILE_OVERWRITE_MODE false

add_fileset_file  spi.vhd     VHDL  PATH  ../vhdl/spi.vhd
add_fileset_file  spi_rx.vhd  VHDL  PATH  ../vhdl/spi_rx.vhd
add_fileset_file  spi_tx.vhd  VHDL  PATH  ../vhdl/spi_tx.vhd

# VHDL simulation files
add_fileset SIM_VHDL SIM_VHDL "" ""

set_fileset_property SIM_VHDL TOP_LEVEL spi
set_fileset_property SIM_VHDL ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property SIM_VHDL ENABLE_FILE_OVERWRITE_MODE false

add_fileset_file  spi.vhd     VHDL  PATH  ../vhdl/spi.vhd
add_fileset_file  spi_rx.vhd  VHDL  PATH  ../vhdl/spi_rx.vhd
add_fileset_file  spi_tx.vhd  VHDL  PATH  ../vhdl/spi_tx.vhd


#
# parameters
#
add_parameter           clk_freq   INTEGER        100000000
set_parameter_property  clk_freq   DEFAULT_VALUE  100000000
set_parameter_property  clk_freq   DISPLAY_NAME   clk_freq
set_parameter_property  clk_freq   TYPE           INTEGER
set_parameter_property  clk_freq   UNITS          None
set_parameter_property  clk_freq   HDL_PARAMETER  true

add_parameter           spi_freq   INTEGER        3200000
set_parameter_property  spi_freq   DEFAULT_VALUE  3200000
set_parameter_property  spi_freq   DISPLAY_NAME   spi_freq
set_parameter_property  spi_freq   TYPE           INTEGER
set_parameter_property  spi_freq   UNITS          None
set_parameter_property  spi_freq   HDL_PARAMETER  true

add_parameter           cpol       INTEGER        1
set_parameter_property  cpol       DEFAULT_VALUE  1
set_parameter_property  cpol       DISPLAY_NAME   cpol
set_parameter_property  cpol       TYPE           INTEGER
set_parameter_property  cpol       UNITS          None
set_parameter_property  cpol       HDL_PARAMETER  true

add_parameter           cpha       INTEGER        1
set_parameter_property  cpha       DEFAULT_VALUE  1
set_parameter_property  cpha       DISPLAY_NAME   cpha
set_parameter_property  cpha       TYPE           INTEGER
set_parameter_property  cpha       UNITS          None
set_parameter_property  cpha       HDL_PARAMETER  true

add_parameter           csn_width  INTEGER        1
set_parameter_property  csn_width  DEFAULT_VALUE  1
set_parameter_property  csn_width  DISPLAY_NAME   csn_width
set_parameter_property  csn_width  TYPE           INTEGER
set_parameter_property  csn_width  UNITS          None
set_parameter_property  csn_width  HDL_PARAMETER  true


#
# display items
#


#
# connection point clock
#
add_interface           clock  clock                end

set_interface_property  clock  clockRate            0
set_interface_property  clock  ENABLED              true
set_interface_property  clock  EXPORT_OF            ""
set_interface_property  clock  PORT_NAME_MAP        ""
set_interface_property  clock  CMSIS_SVD_VARIABLES  ""
set_interface_property  clock  SVD_ADDRESS_GROUP    ""

add_interface_port      clock  clk                  clk   Input  1


#
# connection point reset
#
add_interface           reset  reset                end

set_interface_property  reset  associatedClock      clock
set_interface_property  reset  synchronousEdges     DEASSERT
set_interface_property  reset  ENABLED              true
set_interface_property  reset  EXPORT_OF            ""
set_interface_property  reset  PORT_NAME_MAP        ""
set_interface_property  reset  CMSIS_SVD_VARIABLES  ""
set_interface_property  reset  SVD_ADDRESS_GROUP    ""

add_interface_port      reset  reset                reset     Input  1


#
# connection point csn
#
add_interface           csn  conduit              end

set_interface_property  csn  associatedClock      clock
set_interface_property  csn  associatedReset      ""
set_interface_property  csn  ENABLED              true
set_interface_property  csn  EXPORT_OF            ""
set_interface_property  csn  PORT_NAME_MAP        ""
set_interface_property  csn  CMSIS_SVD_VARIABLES  ""
set_interface_property  csn  SVD_ADDRESS_GROUP    ""

add_interface_port      csn  coe_csn_export       export  Output  csn_width


#
# connection point mosi
#
add_interface           mosi  conduit              end

set_interface_property  mosi  associatedClock      clock
set_interface_property  mosi  associatedReset      ""
set_interface_property  mosi  ENABLED              true
set_interface_property  mosi  EXPORT_OF            ""
set_interface_property  mosi  PORT_NAME_MAP        ""
set_interface_property  mosi  CMSIS_SVD_VARIABLES  ""
set_interface_property  mosi  SVD_ADDRESS_GROUP    ""

add_interface_port      mosi  coe_mosi_export      export  Output  1


#
# connection point miso
#
add_interface           miso  conduit              end

set_interface_property  miso  associatedClock      clock
set_interface_property  miso  associatedReset      ""
set_interface_property  miso  ENABLED              true
set_interface_property  miso  EXPORT_OF            ""
set_interface_property  miso  PORT_NAME_MAP        ""
set_interface_property  miso  CMSIS_SVD_VARIABLES  ""
set_interface_property  miso  SVD_ADDRESS_GROUP    ""

add_interface_port      miso  coe_miso_export      export  Input  1


#
# connection point clk
#
add_interface           clk  conduit              end

set_interface_property  clk  associatedClock      clock
set_interface_property  clk  associatedReset      ""
set_interface_property  clk  ENABLED              true
set_interface_property  clk  EXPORT_OF            ""
set_interface_property  clk  PORT_NAME_MAP        ""
set_interface_property  clk  CMSIS_SVD_VARIABLES  ""
set_interface_property  clk  SVD_ADDRESS_GROUP    ""

add_interface_port      clk  coe_clk_export       export  Output  1


#
# connection point rx
#
add_interface           rx  avalon_streaming            start

set_interface_property  rx  associatedClock             clock
set_interface_property  rx  associatedReset             reset
set_interface_property  rx  dataBitsPerSymbol           8
set_interface_property  rx  errorDescriptor             ""
set_interface_property  rx  firstSymbolInHighOrderBits  true
set_interface_property  rx  maxChannel                  0
set_interface_property  rx  readyLatency                0
set_interface_property  rx  ENABLED                     true
set_interface_property  rx  EXPORT_OF                   ""
set_interface_property  rx  PORT_NAME_MAP               ""
set_interface_property  rx  CMSIS_SVD_VARIABLES         ""
set_interface_property  rx  SVD_ADDRESS_GROUP           ""

add_interface_port      rx  aso_rx_channel              channel        Output  8
add_interface_port      rx  aso_rx_data                 data           Output  8
add_interface_port      rx  aso_rx_startofpacket        startofpacket  Output  1
add_interface_port      rx  aso_rx_endofpacket          endofpacket    Output  1
add_interface_port      rx  aso_rx_valid                valid          Output  1
add_interface_port      rx  aso_rx_ready                ready          Input   1


#
# connection point tx
#
add_interface           tx  avalon_streaming            end

set_interface_property  tx  associatedClock             clock
set_interface_property  tx  associatedReset             reset
set_interface_property  tx  dataBitsPerSymbol           8
set_interface_property  tx  errorDescriptor             ""
set_interface_property  tx  firstSymbolInHighOrderBits  true
set_interface_property  tx  maxChannel                  0
set_interface_property  tx  readyLatency                0
set_interface_property  tx  ENABLED                     true
set_interface_property  tx  EXPORT_OF                   ""
set_interface_property  tx  PORT_NAME_MAP               ""
set_interface_property  tx  CMSIS_SVD_VARIABLES         ""
set_interface_property  tx  SVD_ADDRESS_GROUP           ""

add_interface_port      tx  asi_tx_channel              channel        Input   8
add_interface_port      tx  asi_tx_data                 data           Input   8
add_interface_port      tx  asi_tx_startofpacket        startofpacket  Input   1
add_interface_port      tx  asi_tx_endofpacket          endofpacket    Input   1
add_interface_port      tx  asi_tx_valid                valid          Input   1
add_interface_port      tx  asi_tx_ready                ready          Output  1
