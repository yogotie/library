
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
    clk             : in  std_logic;
    reset           : in  std_logic;

    coe_sda_export  : out std_logic;
    coe_scl_export  : out std_logic;

    asi_bit_data    : in  std_logic_vector(1 downto 0);
    asi_bit_valid   : in  std_logic;
    asi_bit_ready   : out std_logic
  );
end i2c_bit_tx;

architecture i2c_bit_tx_a of i2c_bit_tx is
  
  constant c_cnt_max      : integer := integer(ceil(2.0*real(g_clock_freq_hz)/real(g_i2c_freq_hz)));

  signal i_bit            : std_logic_vector(1 downto 0);
  signal i_bit_valid      : std_logic;
  signal i_sda            : std_logic;
  signal i_scl            : std_logic;
  signal i_bit_done       : std_logic;
  signal i_bit_phase_done : std_logic;
  signal i_bit_phase      : unsigned(1 downto 0);
  signal i_bit_phase_cnt  : unsigned(31 downto 0);

begin

  coe_sda_export    <= i_sda;
  coe_scl_export    <= i_scl;
  asi_bit_ready     <= '1' when i_bit_done = '1' else '0';

  i_bit_done        <= '1' when i_bit_phase_cnt = c_cnt_max - 1 and i_bit_phase = "11" else '0';
  i_bit_phase_done  <= '1' when i_bit_phase_cnt = c_cnt_max - 1 else '0';

  i_bit_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        i_bit       <= (others => '1');
        i_bit_valid <= '0';
      else
        if asi_bit_valid = '1' and i_bit_done = '1' then
          i_bit       <= asi_bit_data;
          i_bit_valid <= '1';
        elsif asi_bit_valid = '0' and i_bit_done = '1' then
          i_bit       <= (others => '0');
          i_bit_valid <= '0';
        end if;
      end if;
    end if;
  end process;

  i_sda_scl_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        i_sda <= '1';
        i_scl <= '1';
      else
        if i_bit_valid = '0' then
          i_sda <= '1';
          i_scl <= '1';
        else
          case i_bit is
            when C_BIT_0 | C_BIT_1 => 
              case i_bit_phase is
                when "00" => i_sda <= i_bit(0); i_scl <= '0';
                when "01" => i_sda <= i_bit(0); i_scl <= '1';
                when "10" => i_sda <= i_bit(0); i_scl <= '1';
                when "11" => i_sda <= i_bit(0); i_scl <= '0';
                when others => i_sda <= '1'; i_scl <= '1';
              end case;

            when C_START => 
              case i_bit_phase is
                when "00" => i_sda <= '1'; i_scl <= '1';
                when "01" => i_sda <= '1'; i_scl <= '1';
                when "10" => i_sda <= '0'; i_scl <= '1';
                when "11" => i_sda <= '0'; i_scl <= '0';
                when others => i_sda <= '1'; i_scl <= '1';
              end case;

            when C_STOP => 
              case i_bit_phase is
                when "00" => i_sda <= '0'; i_scl <= '0';
                when "01" => i_sda <= '0'; i_scl <= '1';
                when "10" => i_sda <= '1'; i_scl <= '1';
                when "11" => i_sda <= '1'; i_scl <= '1';
                when others => i_sda <= '1'; i_scl <= '1';
              end case;

            when others   => i_sda <= '1'; i_scl <= '1';

          end case;
        end if;
      end if;
    end if;
  end process;

  i_bit_phase_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        i_bit_phase <= (others => '0');
      else
        if i_bit_phase_done = '1' then
          i_bit_phase <= i_bit_phase + 1;
        end if;
      end if;
    end if;
  end process;

  i_bit_phase_cnt_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        i_bit_phase_cnt <= (others => '0');
      else
        if i_bit_phase_cnt >= c_cnt_max - 1 then
          i_bit_phase_cnt <= (others => '0');
        else
          i_bit_phase_cnt <= i_bit_phase_cnt + 1;
        end if;
      end if;
    end if;
  end process;

end i2c_bit_tx_a;

-- synthesis translate_off

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.i2c_pkg.all;

entity i2c_bit_tx_ut is
  generic (
    g_clock_freq_hz : integer := 100000000;
    g_i2c_freq_hz   : integer := 100000
  );
end i2c_bit_tx_ut;

architecture i2c_bit_tx_ut_a of i2c_bit_tx_ut is
  
  signal clk             : std_logic := '0';
  signal reset           : std_logic;
  signal coe_sda_export  : std_logic;
  signal coe_scl_export  : std_logic;
  signal asi_bit_data    : std_logic_vector(1 downto 0);
  signal asi_bit_valid   : std_logic;
  signal asi_bit_ready   : std_logic;

begin

  UUT : entity work.i2c_bit_tx
    generic map (
      g_clock_freq_hz => g_clock_freq_hz,
      g_i2c_freq_hz   => g_i2c_freq_hz
    )
    port map (
      clk             => clk,
      reset           => reset,

      coe_sda_export  => coe_sda_export,
      coe_scl_export  => coe_scl_export,

      asi_bit_data    => asi_bit_data,
      asi_bit_valid   => asi_bit_valid,
      asi_bit_ready   => asi_bit_ready
    );

  clk   <= not clk after 5 ns;
  reset <= '1', '0' after 100 ns;

  i2c_check_p : process
    procedure check_bit( value : std_logic_vector(1 downto 0) ) is
    begin
      if coe_scl_export /= '0' and coe_scl_export /= '1' then
        wait until coe_scl_export = '0' or coe_scl_export = '1';
      end if;

      case value is
        when C_BIT_0 => 
          wait until rising_edge(coe_scl_export);
          assert '0' = coe_sda_export
            report "BIT(0) : ERROR expected coe_sda_export = '0' : actual coe_sda_export = '1'"
            severity ERROR;
          wait until falling_edge(coe_scl_export);

        when C_BIT_1 => 
          wait until rising_edge(coe_scl_export);
          assert '1' = coe_sda_export
            report "BIT(1) : ERROR expected coe_sda_export = '1' : actual coe_sda_export = '0'"
            severity ERROR;
          wait until falling_edge(coe_scl_export);

        when C_START => 
          wait until coe_sda_export'event;
          assert '0' = coe_sda_export
            report "START : ERROR expected coe_sda_export = '0' : actual coe_sda_export = '1'"
            severity ERROR;
            
          wait until coe_scl_export'event;
          assert '0' = coe_scl_export
            report "START : ERROR expected coe_scl_export = '0' : actual coe_scl_export = '1'"
            severity ERROR;

        when C_STOP => 
          wait until coe_scl_export'event;
          assert '1' = coe_scl_export
            report "STOP : ERROR expected coe_scl_export = '1' : actual coe_scl_export = '0'"
            severity ERROR;
            
          wait until coe_sda_export'event;
          assert '1' = coe_sda_export
            report "STOP : ERROR expected coe_sda_export = '1' : actual coe_sda_export = '0'"
            severity ERROR;

        when others => 

      end case;
    end procedure;
  begin

    check_bit( C_START );
    check_bit( C_BIT_0 );
    check_bit( C_BIT_1 );
    check_bit( C_STOP );

    report "END OF SIMULATION" severity FAILURE;

    wait;
  end process;

  asi_bit_p : process
    procedure send_bit( value : std_logic_vector(1 downto 0) ) is
    begin
      asi_bit_data  <= value;
      asi_bit_valid <= '1';
      wait until rising_edge(clk) and asi_bit_ready = '1';
      asi_bit_valid <= '0';
      wait until rising_edge(clk);
    end procedure;
  begin
    asi_bit_data  <= (others => '0');
    asi_bit_valid <= '0';
    
    wait for 1 us;
    send_bit( C_START );
    send_bit( C_BIT_0 );
    send_bit( C_BIT_1 );
    send_bit( C_STOP );

    wait;
  end process;

end i2c_bit_tx_ut_a;

-- synthesis translate_on
