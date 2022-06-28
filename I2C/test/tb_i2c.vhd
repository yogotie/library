
-- synthesis translate_off

library vunit_lib;
  context vunit_lib.vunit_context;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  use work.i2c_pkg.all;

entity tb_i2c is
  generic (
    runner_cfg      : string;
    g_clock_freq_hz : integer := 100000000;
    g_i2c_freq_hz   : integer := 100000
  );
end tb_i2c;

architecture tb_i2c_a of tb_i2c is

  constant c_period        : time := integer(1.0e9/real(g_i2c_freq_hz)) * 1 ns;

  signal END_OF_SIMULATION : boolean := false;

  signal aclk              : std_logic := '0';
  signal aresetn           : std_logic;
  signal sda_inout         : std_logic := 'H';
  signal scl_inout         : std_logic := 'H';
  signal m_axis_rx_tuser   : std_logic_vector(2 downto 0);
  signal m_axis_rx_tdata   : std_logic_vector(7 downto 0);
  signal m_axis_rx_tvalid  : std_logic;
  signal m_axis_rx_tready  : std_logic;
  signal s_axis_tx_tuser   : std_logic_vector(2 downto 0);
  signal s_axis_tx_tdata   : std_logic_vector(7 downto 0);
  signal s_axis_tx_tvalid  : std_logic;
  signal s_axis_tx_tready  : std_logic;

begin

  UUT : entity work.i2c
    generic map(
      g_clock_freq_hz  => g_clock_freq_hz,
      g_i2c_freq_hz    => g_i2c_freq_hz
    )
    port map(
      aclk             => aclk,
      aresetn          => aresetn,

      sda_inout        => sda_inout,
      scl_inout        => scl_inout,

      m_axis_rx_tuser  => m_axis_rx_tuser,
      m_axis_rx_tdata  => m_axis_rx_tdata,
      m_axis_rx_tvalid => m_axis_rx_tvalid,
      m_axis_rx_tready => m_axis_rx_tready,

      s_axis_tx_tuser  => s_axis_tx_tuser,
      s_axis_tx_tdata  => s_axis_tx_tdata,
      s_axis_tx_tvalid => s_axis_tx_tvalid,
      s_axis_tx_tready => s_axis_tx_tready
    );

  aclk    <= not aclk after 5 ns;
  aresetn <= '0', '1' after 100 ns;

  test_runner_watchdog(runner, 10 ms);

  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait until END_OF_SIMULATION = true;
    test_runner_cleanup(runner); -- Simulation ends here
  end process;

  m_axis_rx_tp : process
    procedure check_byte(sop : std_logic; eop : std_logic; err : std_logic; value : std_logic_vector(7 downto 0)) is
    begin
      m_axis_rx_tready <= '1';
      wait until rising_edge(aclk) and m_axis_rx_tvalid = '1';
      m_axis_rx_tready <= '0';

      assert m_axis_rx_tuser(0) = sop
      report "ERROR : startofpacket : expected(" & std_logic'image(sop) & ") : actual(" & std_logic'image(m_axis_rx_tuser(0)) & ")"
        severity ERROR;

      assert m_axis_rx_tuser(1) = eop
      report "ERROR : endofpacket : expected(" & std_logic'image(eop) & ") : actual(" & std_logic'image(m_axis_rx_tuser(1)) & ")"
        severity ERROR;

      assert m_axis_rx_tuser(2) = err
      report "ERROR : error : expected(" & std_logic'image(err) & ") : actual(" & std_logic'image(m_axis_rx_tuser(2)) & ")"
        severity ERROR;

      assert m_axis_rx_tdata(value'range) = value
      report "ERROR : data : expected(0x" & to_hstring(value) & ") : actual(0x" & to_hstring(m_axis_rx_tdata(value'range)) & ")"
        severity ERROR;

    end procedure;
  begin
    m_axis_rx_tready <= '0';

    wait until rising_edge(aclk) and aresetn = '1';

    check_byte('1', '0', '1', X"01");
    check_byte('0', '0', '1', X"02");
    check_byte('0', '1', '0', X"03");

    wait for 1 us;

    END_OF_SIMULATION <= true;

    wait;
  end process;

  s_axis_tx_tbyte_p : process
    procedure send_byte(sop : std_logic; eop : std_logic; err : std_logic; value : std_logic_vector(7 downto 0)) is
    begin
      s_axis_tx_tuser(2) <= err;
      s_axis_tx_tuser(1) <= eop;
      s_axis_tx_tuser(0) <= sop;
      s_axis_tx_tdata    <= value;
      s_axis_tx_tvalid   <= '1';
      wait until rising_edge(aclk) and s_axis_tx_tready = '1';
      s_axis_tx_tuser    <= (others => '0');
      s_axis_tx_tdata    <= (others => '0');
      s_axis_tx_tvalid   <= '0';
    end procedure;
  begin
    s_axis_tx_tuser    <= (others => '0');
    s_axis_tx_tdata    <= (others => '0');
    s_axis_tx_tvalid   <= '0';

    wait until rising_edge(aclk) and aresetn = '1';

    send_byte('1', '0', '1', X"01");
    send_byte('0', '0', '1', X"02");
    send_byte('0', '1', '0', X"03");

    wait;
  end process;

end tb_i2c_a;

-- synthesis translate_on

