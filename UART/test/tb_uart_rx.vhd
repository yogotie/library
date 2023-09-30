
-- synthesis translate_off

library vunit_lib;
  context vunit_lib.vunit_context;
  context vunit_lib.vc_context;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_uart_rx is
  generic(
    runner_cfg  : string;
    g_clk_freq  : integer := 100000000;
    g_baud_rate : integer := 115200
  );
end tb_uart_rx;

architecture behav_uart_rx_ut of tb_uart_rx is

  constant m_axis           : axi_stream_slave_t  := new_axi_stream_slave ( data_length => 8 );

  signal END_OF_SIMULATION  : boolean := false;
  
  constant c_buad_period    : time := real(real(1) / real(g_baud_rate)) * 1 sec;
  constant c_clk_period     : time := real(real(1) / real(g_clk_freq)) * 1 sec;

  signal aclk               : std_logic := '0';
  signal aresetn            : std_logic;
  signal rx                 : std_logic := '1';
  signal m_axis_tdata       : std_logic_vector(7 downto 0);
  signal m_axis_tlast       : std_logic;
  signal m_axis_tvalid      : std_logic;
  signal m_axis_tready      : std_logic;
  
begin
  
  UUT : entity work.uart_rx
    generic map(
      g_clk_freq    => g_clk_freq,
      g_baud_rate   => g_baud_rate
    )
    port map(
      aclk          => aclk,
      aresetn       => aresetn,

      rx            => rx,

      m_axis_tdata  => m_axis_tdata,
      m_axis_tlast  => m_axis_tlast,
      m_axis_tvalid => m_axis_tvalid,
      m_axis_tready => m_axis_tready
    );
  
  aclk    <= not aclk after c_clk_period / 2;
  aresetn <= '0', '1' after 100 ns;

  test_runner_watchdog(runner, 10 ms);

  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait until END_OF_SIMULATION = true;
    test_runner_cleanup(runner); -- Simulation ends here
  end process;
  
  -- procedure to simulate serial data
  p_rx : process
    -- procedure to generate the stimulus
    procedure send_data(d:std_logic_vector(7 downto 0)) is
    begin
      -- start bit
      rx <= '0';
      wait for c_buad_period;
      
      -- 8 data bits
      for i in 0 to 7 loop
        rx <= d(i);
        wait for c_buad_period;
      end loop;
      
      -- stop bit
      rx <= '1';
      wait for c_buad_period;
    end procedure send_data;
  begin
    wait for 1 us;
    
    send_data(X"12");
    send_data(X"34");
    
    wait;
  end process;

  p_m_axis : process
  begin
    check_axi_stream( net, m_axis, expected => X"12", tlast => '1' );
    check_axi_stream( net, m_axis, expected => X"34", tlast => '1' );

    END_OF_SIMULATION <= true;
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
  
end behav_uart_rx_ut;

-- synthesis translate_on
