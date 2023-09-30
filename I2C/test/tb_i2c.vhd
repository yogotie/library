
-- synthesis translate_off

library vunit_lib;
  context vunit_lib.vunit_context;
  context vunit_lib.vc_context;

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

architecture behav_tb_i2c of tb_i2c is

  constant m_axis_rx      : axi_stream_slave_t  := new_axi_stream_slave ( data_length => 8, user_length => 3 );
  constant s_axis_tx      : axi_stream_master_t := new_axi_stream_master( data_length => 8, user_length => 3 );
  
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

  PROC_main : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait until END_OF_SIMULATION = true;
    test_runner_cleanup(runner); -- Simulation ends here
  end process;

  PROC_m_axis_rx : process
    procedure check_byte( sop : std_logic; eop : std_logic; err : std_logic; value : std_logic_vector(7 downto 0) ) is
      variable v_tuser : std_logic_vector(2 downto 0);
    begin
      v_tuser(0) := sop;
      v_tuser(1) := eop;
      v_tuser(2) := err;

      check_axi_stream( net, m_axis_rx, expected => value, tuser => v_tuser );
    end procedure;
  begin
    wait until rising_edge(aclk) and aresetn = '1';

    check_byte( '1', '0', '1', X"01" );
    check_byte( '0', '0', '1', X"02" );
    check_byte( '0', '1', '0', X"03" );

    END_OF_SIMULATION <= true;
    wait;
  end process;

  PROC_s_axis_tx : process
    procedure send_byte( sop : std_logic; eop : std_logic; err : std_logic; value : std_logic_vector(7 downto 0) ) is
      variable v_tuser : std_logic_vector(2 downto 0);
    begin
      v_tuser(2) := err;
      v_tuser(1) := eop;
      v_tuser(0) := sop;
      push_axi_stream( net, s_axis_tx, tdata => value, tuser => v_tuser );
    end procedure;
  begin
    wait until rising_edge(aclk) and aresetn = '1';

    send_byte( '1', '0', '1', X"01" );
    send_byte( '0', '0', '1', X"02" );
    send_byte( '0', '1', '0', X"03" );

    wait;
  end process;
  
  U_m_axis_rx : entity vunit_lib.axi_stream_slave
    generic map(
      slave   => m_axis_rx
    )
    port map(
      aclk     => aclk,
      areset_n => aresetn,
      tuser    => m_axis_rx_tuser,
      tdata    => m_axis_rx_tdata,
      tvalid   => m_axis_rx_tvalid,
      tready   => m_axis_rx_tready
    );
  
  U_s_axis_tx : entity vunit_lib.axi_stream_master
    generic map(
      master  => s_axis_tx
    )
    port map(
      aclk     => aclk,
      areset_n => aresetn,
      tuser    => s_axis_tx_tuser,
      tdata    => s_axis_tx_tdata,
      tvalid   => s_axis_tx_tvalid,
      tready   => s_axis_tx_tready
    );

end behav_tb_i2c;

-- synthesis translate_on

