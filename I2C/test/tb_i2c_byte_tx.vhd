
-- synthesis translate_off

library vunit_lib;
  context vunit_lib.vunit_context;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  use work.i2c_pkg.all;

entity tb_i2c_byte_tx is
  generic (
    runner_cfg      : string
  );
end tb_i2c_byte_tx;

architecture tb_i2c_byte_tx_a of tb_i2c_byte_tx is

  signal END_OF_SIMULATION  : boolean := false;

  signal aclk               : std_logic := '0';
  signal aresetn            : std_logic;

  signal m_axis_bit_tdata   : std_logic_vector(1 downto 0);
  signal m_axis_bit_tvalid  : std_logic;
  signal m_axis_bit_tready  : std_logic;

  signal s_axis_byte_tuser  : std_logic_vector(2 downto 0);
  signal s_axis_byte_tdata  : std_logic_vector(7 downto 0);
  signal s_axis_byte_tvalid : std_logic;
  signal s_axis_byte_tready : std_logic;

begin

  UUT : entity work.i2c_byte_tx
    port map (
      aclk               => aclk,
      aresetn            => aresetn,

      m_axis_bit_tdata   => m_axis_bit_tdata,
      m_axis_bit_tvalid  => m_axis_bit_tvalid,
      m_axis_bit_tready  => m_axis_bit_tready,

      s_axis_byte_tuser  => s_axis_byte_tuser,
      s_axis_byte_tdata  => s_axis_byte_tdata,
      s_axis_byte_tvalid => s_axis_byte_tvalid,
      s_axis_byte_tready => s_axis_byte_tready
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

  m_axis_bit_tp : process
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

    procedure check_byte( sop : std_logic; eop : std_logic; ack : std_logic; value : std_logic_vector(7 downto 0) ) is
    begin
      if sop = '1' then
        check_bit( C_START );
      end if;

      for i in 7 downto 0 loop
        if value(i) = '0' then check_bit( C_BIT_0 ); end if;
        if value(i) = '1' then check_bit( C_BIT_1 ); end if;
      end loop;

      if ack = '0' then check_bit( C_BIT_0 ); end if;
      if ack = '1' then check_bit( C_BIT_1 ); end if;

      if eop = '1' then
        check_bit( C_STOP );
      end if;
    end procedure;
  begin
    m_axis_bit_tready <= '0';

    check_byte( '1', '0', '1', X"01" );
    check_byte( '0', '0', '1', X"02" );
    check_byte( '0', '1', '0', X"03" );

    END_OF_SIMULATION <= true;

    wait;
  end process;

  s_axis_byte_tp : process
    procedure send_byte( sop : std_logic; eop : std_logic; err : std_logic; value : std_logic_vector(7 downto 0) ) is
    begin
      s_axis_byte_tuser(2) <= err;
      s_axis_byte_tuser(1) <= eop;
      s_axis_byte_tuser(0) <= sop;
      s_axis_byte_tdata    <= value;
      s_axis_byte_tvalid   <= '1';
      wait until rising_edge(aclk) and s_axis_byte_tready = '1';
      s_axis_byte_tuser    <= (others => '0');
      s_axis_byte_tdata    <= (others => '0');
      s_axis_byte_tvalid   <= '0';
    end procedure;
  begin
    s_axis_byte_tuser    <= (others => '0');
    s_axis_byte_tdata    <= (others => '0');
    s_axis_byte_tvalid   <= '0';

    wait until rising_edge(aclk) and aresetn = '1';

    send_byte( '1', '0', '1', X"01" );
    send_byte( '0', '0', '1', X"02" );
    send_byte( '0', '1', '0', X"03" );

    wait;
  end process;

end tb_i2c_byte_tx_a;

-- synthesis translate_on

