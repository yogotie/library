
from vunit import VUnit

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv(compile_builtins=False)
vu.add_builtins()

# Create library 'lib'
lib = vu.add_library("lib")

# Add all files ending in .vhd in current working directory to library
lib.add_source_files("src/i2c_pkg.vhd")
lib.add_source_files("src/i2c_iobuf.vhd")
lib.add_source_files("src/i2c_bit_rx.vhd")
lib.add_source_files("src/i2c_bit_tx.vhd")
lib.add_source_files("src/i2c_byte_rx.vhd")
lib.add_source_files("src/i2c_byte_tx.vhd")
lib.add_source_files("src/i2c.vhd")

lib.add_source_files("test/tb_i2c_bit_rx.vhd")
lib.add_source_files("test/tb_i2c_bit_tx.vhd")
lib.add_source_files("test/tb_i2c_byte_rx.vhd")
lib.add_source_files("test/tb_i2c_byte_tx.vhd")
lib.add_source_files("test/tb_i2c.vhd")

# Run vunit function
#vu.set_sim_option("ghdl.sim_flags",["--wave=mywave.ghw"])
vu.main()

