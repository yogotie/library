
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.i2c_pkg.all;

entity i2c_byte_rx is
  port (
    aclk               : in  std_logic;
    aresetn            : in  std_logic;

    s_axis_bit_tdata   : in  std_logic_vector(1 downto 0);
    s_axis_bit_tvalid  : in  std_logic;
    s_axis_bit_tready  : out std_logic;

    m_axis_byte_tuser  : out std_logic_vector(2 downto 0);
    m_axis_byte_tdata  : out std_logic_vector(7 downto 0);
    m_axis_byte_tvalid : out std_logic;
    m_axis_byte_tready : in  std_logic
  );
end i2c_byte_rx;

architecture i2c_byte_rx_a of i2c_byte_rx is

  type array_slv2 is array(natural range<>) of std_logic_vector(1 downto 0);

  signal sig_bit_data : array_slv2(15 downto 0);
  signal sig_bit_cnt  : integer range 0 to 15;

begin

  s_axis_bit_tready <= '1';

  aso_p : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        m_axis_byte_tuser  <= (others => '0');
        m_axis_byte_tdata  <= (others => '0');
        m_axis_byte_tvalid <= '0';
      else
        if (sig_bit_data(10) = C_START and sig_bit_cnt >= 11) or sig_bit_data(0) = C_STOP then
          m_axis_byte_tuser(2) <= sig_bit_data(1)(0);
          for i in 9 downto 2 loop
            m_axis_byte_tdata(i - 2) <= sig_bit_data(i)(0);
          end loop;
        elsif sig_bit_cnt >= 11 then
          m_axis_byte_tuser(2) <= sig_bit_data(2)(0);
          for i in 10 downto 3 loop
            m_axis_byte_tdata(i - 3) <= sig_bit_data(i)(0);
          end loop;
        end if;

        if sig_bit_data(10) = C_START and sig_bit_cnt >= 11 then
          m_axis_byte_tuser(0) <= '1';
        else
          m_axis_byte_tuser(0) <= '0';
        end if;

        if sig_bit_data(0) = C_STOP and sig_bit_cnt >= 1 then
          m_axis_byte_tuser(1) <= '1';
        else
          m_axis_byte_tuser(1) <= '0';
        end if;

        if (sig_bit_data(0) = C_STOP and sig_bit_cnt /= 0) or sig_bit_cnt >= 11 then
          m_axis_byte_tvalid <= '1';
        else
          m_axis_byte_tvalid <= '0';
        end if;
      end if;
    end if;
  end process;

  sig_bit_data_p : process(aclk) is
  begin
    if rising_edge(aclk) then
      if s_axis_bit_tvalid = '1' then
        sig_bit_data <= sig_bit_data(sig_bit_data'left - 1 downto 0) & s_axis_bit_tdata;
      end if;
    end if;
  end process;

  sig_bit_cnt_p : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_bit_cnt <= 0;
      else
        if s_axis_bit_tvalid = '1' then
          sig_bit_cnt <= sig_bit_cnt + 1;
        elsif sig_bit_data(0) = C_STOP then
          sig_bit_cnt <= 0;
        elsif sig_bit_data(10) = C_START and sig_bit_cnt >= 11 then
          sig_bit_cnt <= 1;
        elsif sig_bit_cnt >= 11 then
          sig_bit_cnt <= 2;
        end if;
      end if;
    end if;
  end process;

end i2c_byte_rx_a;

