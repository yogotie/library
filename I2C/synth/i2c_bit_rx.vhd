
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.i2c_pkg.all;

entity i2c_bit_rx is
  generic (
    g_clock_freq_hz : integer := 100000000;
    g_i2c_freq_hz   : integer := 100000
  );
  port (
    clk             : in  std_logic;
    reset           : in  std_logic;

    coe_sda_export  : in  std_logic;
    coe_scl_export  : in  std_logic;

    aso_bit_data    : out std_logic_vector(1 downto 0);
    aso_bit_valid   : out std_logic;
    aso_bit_ready   : in  std_logic
  );
end i2c_bit_rx;

architecture i2c_bit_rx_a of i2c_bit_rx is

  constant c_cnt_max  : integer := integer(ceil(2.0*real(g_clock_freq_hz)/real(g_i2c_freq_hz)));

  type bit_state is (S_IDLE, S_START, S_WAIT, S_STOP, S_BIT);

  signal bit_s        : bit_state;

  signal i_sda_in     : std_logic;
  signal i_scl_in     : std_logic;

  signal i_sda_r      : std_logic;
  signal i_sda_f      : std_logic;

  signal i_scl_r      : std_logic;
  signal i_scl_f      : std_logic;

  signal i_sda        : std_logic_vector(1 downto 0);
  signal i_scl        : std_logic_vector(1 downto 0);

  signal i_bit        : std_logic_vector(1 downto 0);
  signal i_bit_valid  : std_logic;

  signal i_timeout    : unsigned(31 downto 0);

begin

  aso_bit_data  <= i_bit;
  aso_bit_valid <= i_bit_valid and aso_bit_ready;

  i_sda_in      <= '1' when coe_sda_export /= '0' else '0';
  i_scl_in      <= '1' when coe_scl_export /= '0' else '0';

  i_sda_r       <= '1' when i_sda = "01" else '0';
  i_sda_f       <= '1' when i_sda = "10" else '0';

  i_scl_r       <= '1' when i_scl = "01" else '0';
  i_scl_f       <= '1' when i_scl = "10" else '0';

  i_sda_p : process(clk) is
  begin
    if rising_edge(clk) then
      i_sda <= i_sda(i_sda'left - 1 downto 0) & i_sda_in;
    end if;
  end process;

  i_scl_p : process(clk) is
  begin
    if rising_edge(clk) then
      i_scl <= i_scl(i_scl'left - 1 downto 0) & i_scl_in;
    end if;
  end process;

  i_timeout_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        i_timeout <= (others => '0');
      else
        if bit_s /= S_IDLE and i_timeout <= c_cnt_max - 1 then
          i_timeout <= i_timeout + 1;
        elsif bit_s = S_IDLE then
          i_timeout <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  bit_sm : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        i_bit       <= (others => '0');
        i_bit_valid <= '0';
        bit_s       <= S_IDLE;
      else
        i_bit_valid <= '0';

        case bit_s is
          when S_IDLE =>
            if i_scl_r = '1' then
              i_bit(0)    <= i_sda(i_sda'left);
              bit_s       <= S_WAIT;
            elsif i_sda_f = '1' and i_scl(i_scl'left) = '1' then
              bit_s       <= S_START;
            end if;

          when S_START =>
            if i_timeout = c_cnt_max - 1 then
              bit_s       <= S_IDLE;
            end if;

            if i_scl_f = '1' then
              i_bit       <= C_START;
              i_bit_valid <= '1';
              bit_s       <= S_IDLE;
            end if;

          when S_WAIT =>
            if i_timeout = c_cnt_max - 1 then
              bit_s       <= S_IDLE;
            end if;

            if i_sda_r = '1' then
              bit_s <= S_STOP;
            elsif i_scl_f = '1' then
              bit_s <= S_BIT;
            end if;

          when S_STOP =>
            i_bit       <= C_STOP;
            i_bit_valid <= '1';
            bit_s       <= S_IDLE;

          when S_BIT =>
            i_bit(1)    <= '0';
            i_bit_valid <= '1';
            bit_s       <= S_IDLE;

        end case;
      end if;
    end if;
  end process;

end i2c_bit_rx_a;

