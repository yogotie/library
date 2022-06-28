
library ieee;
use ieee.std_logic_1164.all;

entity i2c_iobuf is
  port (
    aclk : in    std_logic;

    o    : out   std_logic;
    i    : in    std_logic;
    oe   : in    std_logic;

    io   : inout std_logic
  );
end i2c_iobuf;

architecture arch_i2c_iobuf of i2c_iobuf is

  signal sig_iob_o  : std_logic;
  signal sig_iob_oe : std_logic;
  signal sig_iob_t  : std_logic;
  signal sig_iob_i  : std_logic;

begin

  proc_o : process(aclk) is
  begin
    if rising_edge(aclk) then
      o <= sig_iob_o;
    end if;
  end process;

  proc_sig_iob_i : process(aclk) is
  begin
    if rising_edge(aclk) then
      sig_iob_i <= i;
    end if;
  end process;

  proc_sig_iob_oe : process(aclk) is
  begin
    if rising_edge(aclk) then
      sig_iob_oe <= oe;
    end if;
  end process;

  sig_iob_t <= not sig_iob_oe;

  io        <= sig_iob_i when sig_iob_oe = '1' else 'Z';
  sig_iob_o <= io;

end arch_i2c_iobuf;

