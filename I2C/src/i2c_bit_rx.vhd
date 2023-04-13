
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

  use work.i2c_pkg.all;

entity i2c_bit_rx is
  generic (
    g_clock_freq_hz   : integer := 100000000;
    g_i2c_freq_hz     : integer := 100000
  );
  port (
    aclk              : in  std_logic;
    aresetn           : in  std_logic;

    sda_in            : in  std_logic;
    scl_in            : in  std_logic;

    m_axis_bit_tdata  : out std_logic_vector(1 downto 0);
    m_axis_bit_tvalid : out std_logic;
    m_axis_bit_tready : in  std_logic
  );
end i2c_bit_rx;

architecture rtl_i2c_bit_rx of i2c_bit_rx is

  constant c_cnt_max  : integer := integer(ceil(4.0*real(g_clock_freq_hz)/real(g_i2c_freq_hz)));

  type bit_state is (S_IDLE, S_START, S_WAIT, S_STOP, S_BIT);

  signal sig_bit_s      : bit_state;

  signal sig_sda_in     : std_logic;
  signal sig_scl_in     : std_logic;

  signal sig_sda_r      : std_logic;
  signal sig_sda_f      : std_logic;

  signal sig_scl_r      : std_logic;
  signal sig_scl_f      : std_logic;

  signal sig_sda        : std_logic_vector(1 downto 0);
  signal sig_scl        : std_logic_vector(1 downto 0);

  signal sig_bit        : std_logic_vector(1 downto 0);
  signal sig_bit_valid  : std_logic;

  signal sig_timeout    : unsigned(31 downto 0);

begin

  m_axis_bit_tdata  <= sig_bit;
  m_axis_bit_tvalid <= sig_bit_valid and m_axis_bit_tready;

  sig_sda_in        <= '1' when sda_in /= '0' else '0';
  sig_scl_in        <= '1' when scl_in /= '0' else '0';

  sig_sda_r         <= '1' when sig_sda = "01" else '0';
  sig_sda_f         <= '1' when sig_sda = "10" else '0';

  sig_scl_r         <= '1' when sig_scl = "01" else '0';
  sig_scl_f         <= '1' when sig_scl = "10" else '0';

  sig_sda_p : process(aclk) is
  begin
    if rising_edge(aclk) then
      sig_sda <= sig_sda(sig_sda'left - 1 downto 0) & sig_sda_in;
    end if;
  end process;

  sig_scl_p : process(aclk) is
  begin
    if rising_edge(aclk) then
      sig_scl <= sig_scl(sig_scl'left - 1 downto 0) & sig_scl_in;
    end if;
  end process;

  sig_timeout_p : process(aclk) is
  begin
    if rising_edge(aclk) then
      if sig_bit_s = S_IDLE then
        sig_timeout <= (others => '0');
      end if;
      if sig_bit_s /= S_IDLE and sig_timeout <= c_cnt_max - 1 then
        sig_timeout <= sig_timeout + 1;
      end if;
    end if;
  end process;

  bit_sm : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_bit       <= (others => '0');
        sig_bit_valid <= '0';
        sig_bit_s     <= S_IDLE;
      else
        sig_bit_valid <= '0';

        case sig_bit_s is
          when S_IDLE =>
            if sig_scl_r = '1' then
              sig_bit(0)    <= sig_sda(sig_sda'left);
              sig_bit_s     <= S_WAIT;
            elsif sig_sda_f = '1' and sig_scl(sig_scl'left) = '1' then
              sig_bit_s     <= S_START;
            end if;

          when S_START =>
            if sig_timeout = c_cnt_max - 1 then
              sig_bit_s     <= S_IDLE;
            end if;

            if sig_scl_f = '1' then
              sig_bit       <= C_START;
              sig_bit_valid <= '1';
              sig_bit_s     <= S_IDLE;
            end if;

          when S_WAIT =>
            if sig_timeout = c_cnt_max - 1 then
              sig_bit_s     <= S_IDLE;
            end if;

            if sig_sda_r = '1' then
              sig_bit_s     <= S_STOP;
            elsif sig_scl_f = '1' then
              sig_bit_s     <= S_BIT;
            end if;

          when S_STOP =>
            sig_bit       <= C_STOP;
            sig_bit_valid <= '1';
            sig_bit_s     <= S_IDLE;

          when S_BIT =>
            sig_bit(1)    <= '0';
            sig_bit_valid <= '1';
            sig_bit_s     <= S_IDLE;

        end case;
      end if;
    end if;
  end process;

end rtl_i2c_bit_rx;

