
from vunit import VUnit

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv(compile_builtins=False)
vu.add_builtins()
vu.add_verification_components()

# Create library 'lib'
lib = vu.add_library("lib")

# Add all files ending in .vhd in current working directory to library
lib.add_source_files("src/uart_rx.vhd")
lib.add_source_files("src/uart_tx.vhd")
lib.add_source_files("src/uart_axi.vhd")
lib.add_source_files("src/uart.vhd")

lib.add_source_files("test/tb_uart_rx.vhd")
lib.add_source_files("test/tb_uart_tx.vhd")
lib.add_source_files("test/tb_uart_axi.vhd")
lib.add_source_files("test/tb_uart.vhd")

# Run vunit function
#vu.set_sim_option("ghdl.sim_flags",["--wave=mywave.ghw"])
vu.main()
