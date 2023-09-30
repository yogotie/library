
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

  use work.i2c_pkg.all;

entity i2c_bit_tx is
  generic (
    g_clock_freq_hz : integer := 100000000;
    g_i2c_freq_hz   : integer := 100000
  );
  port (
    aclk              : in  std_logic;
    aresetn           : in  std_logic;

    sda_out           : out std_logic;
    scl_out           : out std_logic;

    s_axis_bit_tdata  : in  std_logic_vector(1 downto 0);
    s_axis_bit_tvalid : in  std_logic;
    s_axis_bit_tready : out std_logic
  );
end i2c_bit_tx;

architecture rtl_i2c_bit_tx of i2c_bit_tx is

  constant c_cnt_max        : integer := integer(ceil(2.0*real(g_clock_freq_hz)/real(g_i2c_freq_hz)));

  signal sig_bit            : std_logic_vector(1 downto 0);
  signal sig_bit_tvalid     : std_logic;
  signal sig_sda            : std_logic;
  signal sig_scl            : std_logic;
  signal sig_bit_done       : std_logic;
  signal sig_bit_phase_done : std_logic;
  signal sig_bit_phase      : unsigned(1 downto 0);
  signal sig_bit_phase_cnt  : unsigned(31 downto 0);

begin

  sda_out             <= sig_sda;
  scl_out             <= sig_scl;
  s_axis_bit_tready   <= '1' when sig_bit_done = '1' else '0';

  sig_bit_done        <= '1' when sig_bit_phase_cnt = c_cnt_max - 1 and sig_bit_phase = "11" else '0';
  sig_bit_phase_done  <= '1' when sig_bit_phase_cnt = c_cnt_max - 1 else '0';

  sig_bit_p : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_bit        <= (others => '1');
        sig_bit_tvalid <= '0';
      else
        if s_axis_bit_tvalid = '1' and sig_bit_done = '1' then
          sig_bit        <= s_axis_bit_tdata;
          sig_bit_tvalid <= '1';
        elsif s_axis_bit_tvalid = '0' and sig_bit_done = '1' then
          sig_bit        <= (others => '0');
          sig_bit_tvalid <= '0';
        end if;
      end if;
    end if;
  end process;

  sig_sda_scl_p : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_sda <= '1';
        sig_scl <= '1';
      else
        if sig_bit_tvalid = '0' then
          sig_sda <= '1';
          sig_scl <= '1';
        else
          case sig_bit is
            when C_BIT_0 | C_BIT_1 =>
              case sig_bit_phase is
                when "00"   => sig_sda <= sig_bit(0); sig_scl <= '0';
                when "01"   => sig_sda <= sig_bit(0); sig_scl <= '1';
                when "10"   => sig_sda <= sig_bit(0); sig_scl <= '1';
                when "11"   => sig_sda <= sig_bit(0); sig_scl <= '0';
                when others => sig_sda <= '1'; sig_scl <= '1';
              end case;

            when C_START =>
              case sig_bit_phase is
                when "00"   => sig_sda <= '1'; sig_scl <= '1';
                when "01"   => sig_sda <= '1'; sig_scl <= '1';
                when "10"   => sig_sda <= '0'; sig_scl <= '1';
                when "11"   => sig_sda <= '0'; sig_scl <= '0';
                when others => sig_sda <= '1'; sig_scl <= '1';
              end case;

            when C_STOP =>
              case sig_bit_phase is
                when "00"   => sig_sda <= '0'; sig_scl <= '0';
                when "01"   => sig_sda <= '0'; sig_scl <= '1';
                when "10"   => sig_sda <= '1'; sig_scl <= '1';
                when "11"   => sig_sda <= '1'; sig_scl <= '1';
                when others => sig_sda <= '1'; sig_scl <= '1';
              end case;

            when others => sig_sda <= '1'; sig_scl <= '1';

          end case;
        end if;
      end if;
    end if;
  end process;

  sig_bit_phase_p : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_bit_phase <= (others => '0');
      else
        if sig_bit_phase_done = '1' then
          sig_bit_phase <= sig_bit_phase + 1;
        end if;
      end if;
    end if;
  end process;

  sig_bit_phase_cnt_p : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_bit_phase_cnt <= (others => '0');
      else
        if sig_bit_phase_cnt >= c_cnt_max - 1 then
          sig_bit_phase_cnt <= (others => '0');
        else
          sig_bit_phase_cnt <= sig_bit_phase_cnt + 1;
        end if;
      end if;
    end if;
  end process;

end rtl_i2c_bit_tx;

