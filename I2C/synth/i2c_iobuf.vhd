
library ieee;
use ieee.std_logic_1164.all;

entity i2c_iobuf is
  port (
    clk : in    std_logic;
    
    o   : out   std_logic;
    i   : in    std_logic;
    oe  : in    std_logic;
    
    io  : inout std_logic
  );
end i2c_iobuf;

architecture i2c_iobuf_a of i2c_iobuf is
  
  signal i_iob_o    : std_logic;
  signal i_iob_oe   : std_logic;
  signal i_iob_t    : std_logic;
  signal i_iob_i    : std_logic;
  
begin
  
  i_iob_o_r_p : process(clk) is
  begin
    if rising_edge(clk) then
      o <= i_iob_o;
    end if;
  end process;
  
  i_iob_i_p : process(clk) is
  begin
    if rising_edge(clk) then
      i_iob_i <= i;
    end if;
  end process;
  
  i_iob_oe_p : process(clk) is
  begin
    if rising_edge(clk) then
      i_iob_oe <= oe;
    end if;
  end process;
  
  i_iob_t <= not i_iob_oe;

  io      <= i_iob_i when i_iob_oe = '1' else 'Z';
  i_iob_o <= io;
  
end i2c_iobuf_a;
