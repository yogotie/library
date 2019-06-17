
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package i2c_pkg is

  constant C_BIT_0  : std_logic_vector(1 downto 0) := "00";
  constant C_BIT_1  : std_logic_vector(1 downto 0) := "01";
  constant C_START  : std_logic_vector(1 downto 0) := "10";
  constant C_STOP   : std_logic_vector(1 downto 0) := "11";

end package i2c_pkg;
