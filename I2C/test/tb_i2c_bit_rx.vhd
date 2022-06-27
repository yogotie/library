
-- synthesis translate_off

library vunit_lib;
  context vunit_lib.vunit_context;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

  use work.i2c_pkg.all;

entity tb_i2c_bit_rx is
  generic (
    runner_cfg      : string;
    g_clock_freq_hz : integer := 100000000;
    g_i2c_freq_hz   : integer := 100000
  );
end tb_i2c_bit_rx;

architecture arch_tb_i2c_bit_rx of tb_i2c_bit_rx is

  constant c_period         : time := integer( 1.0e9/real(g_i2c_freq_hz) ) * 1 ns;

  signal END_OF_SIMULATION  : boolean := false;

  signal aclk               : std_logic := '0';
  signal aresetn            : std_logic;

  signal sda_in             : std_logic;
  signal scl_in             : std_logic;

  signal m_axis_bit_tdata   : std_logic_vector(1 downto 0);
  signal m_axis_bit_tvalid  : std_logic;
  signal m_axis_bit_tready  : std_logic;

begin

  UUT : entity work.i2c_bit_rx
    generic map (
      g_clock_freq_hz     => g_clock_freq_hz,
      g_i2c_freq_hz       => g_i2c_freq_hz
    )
    port map (
      aclk                => aclk,
      aresetn             => aresetn,

      sda_in              => sda_in,
      scl_in              => scl_in,

      m_axis_bit_tdata    => m_axis_bit_tdata,
      m_axis_bit_tvalid   => m_axis_bit_tvalid,
      m_axis_bit_tready   => m_axis_bit_tready
    );

  aclk    <= not aclk after 5 ns;
  aresetn <= '0', '1' after 100 ns;

  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait until END_OF_SIMULATION = true;
    test_runner_cleanup(runner); -- Simulation ends here
  end process;

  i2c_bit_p : process
    procedure send_bit( value : std_logic_vector(1 downto 0) ) is
    begin
      case value is
        when C_BIT_0 =>
          sda_in  <= '0';
          scl_in  <= '0';
          wait for c_period / 4;
          scl_in  <= 'H';
          wait for c_period / 2;
          scl_in  <= '0';
          wait for c_period / 4;

        when C_BIT_1 =>
          sda_in  <= 'H';
          scl_in  <= '0';
          wait for c_period / 4;
          scl_in  <= 'H';
          wait for c_period / 2;
          scl_in  <= '0';
          wait for c_period / 4;

        when C_START =>
          sda_in  <= 'H';
          scl_in  <= 'H';
          wait for c_period / 2;
          sda_in  <= '0';
          wait for c_period / 4;
          scl_in  <= '0';
          wait for c_period / 4;

        when C_STOP =>
          sda_in  <= '0';
          scl_in  <= '0';
          wait for c_period / 4;
          scl_in  <= 'H';
          wait for c_period / 4;
          sda_in  <= 'H';
          wait for c_period / 2;

        when others =>
      end case;
    end procedure;
  begin
    sda_in <= 'H';
    scl_in <= 'H';

    wait for 1 us;

    send_bit( C_START );
    send_bit( C_BIT_0 );
    send_bit( C_BIT_1 );
    send_bit( C_STOP );

    wait;
  end process;

  aso_bit_p : process
    procedure check_bit( expected : std_logic_vector(1 downto 0) ) is
    begin
      m_axis_bit_tready <= '1';
      wait until rising_edge(aclk) and m_axis_bit_tvalid = '1';

      assert m_axis_bit_tdata = expected
        report "ERROR expected(0x" & to_hstring(expected) & ") : actual(0x" & to_hstring(m_axis_bit_tdata) & ")"
        severity ERROR;

      m_axis_bit_tready <= '0';
      wait until rising_edge(aclk);

    end procedure;
  begin

    check_bit( C_START );
    check_bit( C_BIT_0 );
    check_bit( C_BIT_1 );
    check_bit( C_STOP );

    END_OF_SIMULATION <= true;

    wait;
  end process;

end arch_tb_i2c_bit_rx;

-- synthesis translate_on

