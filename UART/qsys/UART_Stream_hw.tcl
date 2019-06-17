# TCL File Generated by Component Editor 17.1
# Sat Feb 03 20:35:35 BRT 2018
# DO NOT MODIFY


#
# UART_Stream "UART Stream" v1.0
# UART streaming interface
#

#
# request TCL package from ACDS 16.1
#
package require -exact qsys 16.1


#
# module UART_Stream
#
set_module_property  DESCRIPTION                   "UART streaming interface"
set_module_property  NAME                          UART_Stream
set_module_property  VERSION                       1.0
set_module_property  INTERNAL                      false
set_module_property  OPAQUE_ADDRESS_MAP            true
set_module_property  GROUP                         yogotie
set_module_property  AUTHOR                        "yogotie""
set_module_property  DISPLAY_NAME                  "UART Stream"
set_module_property  INSTANTIATE_IN_SYSTEM_MODULE  true
set_module_property  EDITABLE                      true
set_module_property  REPORT_TO_TALKBACK            false
set_module_property  ALLOW_GREYBOX_GENERATION      false
set_module_property  REPORT_HIERARCHY              false


#
# file sets
#
# Synthesis Files
add_fileset           QUARTUS_SYNTH  QUARTUS_SYNTH                  ""     ""

set_fileset_property  QUARTUS_SYNTH  TOP_LEVEL                      uart
set_fileset_property  QUARTUS_SYNTH  ENABLE_RELATIVE_INCLUDE_PATHS  false
set_fileset_property  QUARTUS_SYNTH  ENABLE_FILE_OVERWRITE_MODE     false

add_fileset_file      uart.vhd       VHDL                           PATH   ../vhdl/uart.vhd     TOP_LEVEL_FILE
add_fileset_file      uart_rx.vhd    VHDL                           PATH   ../vhdl/uart_rx.vhd
add_fileset_file      uart_tx.vhd    VHDL                           PATH   ../vhdl/uart_tx.vhd

# Verilog simulation files
add_fileset           SIM_VERILOG  SIM_VERILOG                    ""     ""

set_fileset_property  SIM_VERILOG  TOP_LEVEL                      uart
set_fileset_property  SIM_VERILOG  ENABLE_RELATIVE_INCLUDE_PATHS  false
set_fileset_property  SIM_VERILOG  ENABLE_FILE_OVERWRITE_MODE     false

add_fileset_file      uart.vhd     VHDL                           PATH   ../vhdl/uart.vhd
add_fileset_file      uart_rx.vhd  VHDL                           PATH   ../vhdl/uart_rx.vhd
add_fileset_file      uart_tx.vhd  VHDL                           PATH   ../vhdl/uart_tx.vhd

# VHDL simulation files
add_fileset           SIM_VHDL     SIM_VHDL                       ""     ""

set_fileset_property  SIM_VHDL     TOP_LEVEL                      uart
set_fileset_property  SIM_VHDL     ENABLE_RELATIVE_INCLUDE_PATHS  false
set_fileset_property  SIM_VHDL     ENABLE_FILE_OVERWRITE_MODE     false

add_fileset_file      uart.vhd     VHDL                           PATH   ../vhdl/uart.vhd
add_fileset_file      uart_rx.vhd  VHDL                           PATH   ../vhdl/uart_rx.vhd
add_fileset_file      uart_tx.vhd  VHDL                           PATH   ../vhdl/uart_tx.vhd


#
# parameters
#
add_parameter           clk_freq   INTEGER         100000000
set_parameter_property  clk_freq   DEFAULT_VALUE   100000000
set_parameter_property  clk_freq   DISPLAY_NAME    clk_freq
set_parameter_property  clk_freq   TYPE            INTEGER
set_parameter_property  clk_freq   UNITS           None
set_parameter_property  clk_freq   ALLOWED_RANGES  -2147483648:2147483647
set_parameter_property  clk_freq   HDL_PARAMETER   true

add_parameter           baud_rate  INTEGER         115200
set_parameter_property  baud_rate  DEFAULT_VALUE   115200
set_parameter_property  baud_rate  DISPLAY_NAME    baud_rate
set_parameter_property  baud_rate  TYPE            INTEGER
set_parameter_property  baud_rate  UNITS           None
set_parameter_property  baud_rate  ALLOWED_RANGES  -2147483648:2147483647
set_parameter_property  baud_rate  HDL_PARAMETER   true


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
# connection point rx
#
add_interface           rx  conduit              end

set_interface_property  rx  associatedClock      clock
set_interface_property  rx  associatedReset      ""
set_interface_property  rx  ENABLED              true
set_interface_property  rx  EXPORT_OF            ""
set_interface_property  rx  PORT_NAME_MAP        ""
set_interface_property  rx  CMSIS_SVD_VARIABLES  ""
set_interface_property  rx  SVD_ADDRESS_GROUP    ""

add_interface_port      rx  coe_rx_export        export  Input  1


#
# connection point tx
#
add_interface           tx  conduit              end

set_interface_property  tx  associatedClock      clock
set_interface_property  tx  associatedReset      ""
set_interface_property  tx  ENABLED              true
set_interface_property  tx  EXPORT_OF            ""
set_interface_property  tx  PORT_NAME_MAP        ""
set_interface_property  tx  CMSIS_SVD_VARIABLES  ""
set_interface_property  tx  SVD_ADDRESS_GROUP    ""

add_interface_port      tx  coe_tx_export        export  Output  1


#
# connection point rxdata
#
add_interface           rxdata  avalon_streaming            start

set_interface_property  rxdata  associatedClock             clock
set_interface_property  rxdata  associatedReset             reset
set_interface_property  rxdata  dataBitsPerSymbol           8
set_interface_property  rxdata  errorDescriptor             ""
set_interface_property  rxdata  firstSymbolInHighOrderBits  true
set_interface_property  rxdata  maxChannel                  0
set_interface_property  rxdata  readyLatency                0
set_interface_property  rxdata  ENABLED                     true
set_interface_property  rxdata  EXPORT_OF                   ""
set_interface_property  rxdata  PORT_NAME_MAP               ""
set_interface_property  rxdata  CMSIS_SVD_VARIABLES         ""
set_interface_property  rxdata  SVD_ADDRESS_GROUP           ""

add_interface_port      rxdata  aso_rxData_data             data           Output  8
add_interface_port      rxdata  aso_rxData_valid            valid          Output  1
add_interface_port      rxdata  aso_rxData_ready            ready          Input   1
add_interface_port      rxdata  aso_rxData_startofpacket    startofpacket  Output  1
add_interface_port      rxdata  aso_rxData_endofpacket      endofpacket    Output  1


#
# connection point txdata
#
add_interface           txdata  avalon_streaming            end

set_interface_property  txdata  associatedClock             clock
set_interface_property  txdata  associatedReset             reset
set_interface_property  txdata  dataBitsPerSymbol           8
set_interface_property  txdata  errorDescriptor             ""
set_interface_property  txdata  firstSymbolInHighOrderBits  true
set_interface_property  txdata  maxChannel                  0
set_interface_property  txdata  readyLatency                0
set_interface_property  txdata  ENABLED                     true
set_interface_property  txdata  EXPORT_OF                   ""
set_interface_property  txdata  PORT_NAME_MAP               ""
set_interface_property  txdata  CMSIS_SVD_VARIABLES         ""
set_interface_property  txdata  SVD_ADDRESS_GROUP           ""

add_interface_port      txdata  asi_txData_data             data           Input   8
add_interface_port      txdata  asi_txData_valid            valid          Input   1
add_interface_port      txdata  asi_txData_ready            ready          Output  1
add_interface_port      txdata  asi_txData_startofpacket    startofpacket  Input   1
add_interface_port      txdata  asi_txData_endofpacket      endofpacket    Input   1

