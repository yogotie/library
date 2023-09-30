
-- synthesis translate_off

library vunit_lib;
  context vunit_lib.vunit_context;
  context vunit_lib.vc_context;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_uart is
  generic(
    runner_cfg          : string;
    g_clk_freq          : integer := 100000000;
    g_baud_rate         : integer := 115200
  );
end tb_uart;

architecture behav_tb_uart of tb_uart is

  constant s_axis           : axi_stream_master_t := new_axi_stream_master( data_length => 8 );
  constant m_axis           : axi_stream_slave_t  := new_axi_stream_slave ( data_length => 8 );

  signal END_OF_SIMULATION  : boolean := false;
  
  signal c_clk_period       : time := real(real(1) / real(g_clk_freq)) * 1 sec;
  
  signal aclk               : std_logic := '0';
  signal aresetn            : std_logic;
  signal rx                 : std_logic;
  signal tx                 : std_logic;
  signal m_axis_tdata       : std_logic_vector(7 downto 0);
  signal m_axis_tlast       : std_logic;
  signal m_axis_tvalid      : std_logic;
  signal m_axis_tready      : std_logic;
  signal s_axis_tdata       : std_logic_vector(7 downto 0);
  signal s_axis_tlast       : std_logic;
  signal s_axis_tvalid      : std_logic;
  signal s_axis_tready      : std_logic;
  
begin
  
  UUT : entity work.uart
    generic map(
      g_clk_freq    => g_clk_freq,
      g_baud_rate   => g_baud_rate
    )
    port map(
      aclk          => aclk,
      aresetn       => aresetn,
      rx            => rx,
      tx            => tx,
      m_axis_tdata  => m_axis_tdata,
      m_axis_tlast  => m_axis_tlast,
      m_axis_tvalid => m_axis_tvalid,
      m_axis_tready => m_axis_tready,
      s_axis_tdata  => s_axis_tdata,
      s_axis_tlast  => s_axis_tlast,
      s_axis_tvalid => s_axis_tvalid,
      s_axis_tready => s_axis_tready
    );
  
  aclk    <= not aclk after c_clk_period / 2;
  aresetn <= '0', '1' after 100 ns;

  rx <= tx;

  test_runner_watchdog(runner, 10 ms);

  PROC_main : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait until END_OF_SIMULATION = true;
    test_runner_cleanup(runner); -- Simulation ends here
  end process;

  PROC_m_axis : process
  begin
    check_axi_stream( net, m_axis, expected => X"12", tlast => '1' );
    check_axi_stream( net, m_axis, expected => X"34", tlast => '1' );

    END_OF_SIMULATION <= true;
    wait;
  end process;
  
  PROC_s_axis : process
  begin
    wait for 1 us;
    push_axi_stream( net, s_axis, tdata => X"12", tlast => '1' );
    push_axi_stream( net, s_axis, tdata => X"34", tlast => '1' );

    wait;
  end process;
  
  U_m_axis : entity vunit_lib.axi_stream_slave
    generic map(
      slave   => m_axis
    )
    port map(
      aclk     => aclk,
      areset_n => aresetn,
      tdata    => m_axis_tdata,
      tlast    => m_axis_tlast,
      tvalid   => m_axis_tvalid,
      tready   => m_axis_tready
    );
  
  U_s_axis : entity vunit_lib.axi_stream_master
    generic map(
      master  => s_axis
    )
    port map(
      aclk     => aclk,
      areset_n => aresetn,
      tdata    => s_axis_tdata,
      tlast    => s_axis_tlast,
      tvalid   => s_axis_tvalid,
      tready   => s_axis_tready
    );

end behav_tb_uart;

-- synthesis translate_on
