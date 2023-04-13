
-- synthesis translate_off

library vunit_lib;
  context vunit_lib.vunit_context;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_uart_tx is
  generic(
    runner_cfg  : string;
    g_clk_freq  : integer := 100000000;
    g_baud_rate : integer := 115200
  );
end tb_uart_tx;

architecture behave_tb_uart_tx of tb_uart_tx is
  
  signal END_OF_SIMULATION  : boolean := false;

  signal c_baud_period      : time := real(real(1) / real(g_baud_rate)) * 1 sec;
  signal c_clk_period       : time := real(real(1) / real(g_clk_freq)) * 1 sec;
  
  signal aclk               : std_logic := '0';
  signal aresetn            : std_logic;
  signal tx                 : std_logic;
  signal s_axis_tdata       : std_logic_vector(7 downto 0);
  signal s_axis_tlast       : std_logic;
  signal s_axis_tvalid      : std_logic;
  signal s_axis_tready      : std_logic;
  
begin
  
  UUT : entity work.uart_tx
    generic map(
      g_clk_freq      => g_clk_freq,
      g_baud_rate     => g_baud_rate
    )
    port map(
      aclk          => aclk,
      aresetn       => aresetn,
      tx            => tx,
      s_axis_tdata  => s_axis_tdata,
      s_axis_tlast  => s_axis_tlast,
      s_axis_tvalid => s_axis_tvalid,
      s_axis_tready => s_axis_tready
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

  p_tx : process
    procedure check_data( expected : std_logic_vector(7 downto 0) ) is
      variable actual : std_logic_vector(7 downto 0);
    begin
      wait until falling_edge(tx);
      wait for c_baud_period / 2;
      for i in 0 to 7 loop
        wait for c_baud_period;
        actual(i) := tx;
      end loop;

      assert actual = expected
        report "ERROR expected(0x" & to_hstring(expected) & ") : actual(0x" & to_hstring(actual) & ")"
        severity ERROR;

    end procedure;
  begin

    check_data( X"12" );
    check_data( X"34" );

    END_OF_SIMULATION <= true;

    wait;
  end process;
  
  s_axis_tlast    <= '1';

  p_s_axis : process
    procedure send_data( value : std_logic_vector(7 downto 0) ) is
    begin
      s_axis_tdata   <= value;
      s_axis_tvalid  <= '1';
      wait until rising_edge(aclk) and s_axis_tready = '1';
      s_axis_tvalid  <= '0';
      wait until rising_edge(aclk);
    end procedure;
  begin
    s_axis_tdata <= (others => '0');
    s_axis_tvalid <= '0';
    
    wait for 1 us;
    send_data( X"12" );
    send_data( X"34" );
    wait;
  end process;
  
end architecture behave_tb_uart_tx;

-- synthesis translate_on
