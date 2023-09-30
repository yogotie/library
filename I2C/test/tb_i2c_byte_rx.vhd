
-- synthesis translate_off

library vunit_lib;
  context vunit_lib.vunit_context;
  context vunit_lib.vc_context;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  use work.i2c_pkg.all;

entity tb_i2c_byte_rx is
  generic (
    runner_cfg      : string
  );
end tb_i2c_byte_rx;

architecture behav_tb_i2c_byte_rx of tb_i2c_byte_rx is

  constant s_axis_bit       : axi_stream_master_t := new_axi_stream_master( data_length => 2 );
  constant m_axis_byte      : axi_stream_slave_t  := new_axi_stream_slave ( data_length => 8, user_length => 3 );
  
  signal END_OF_SIMULATION  : boolean := false;

  signal aclk               : std_logic := '0';
  signal aresetn            : std_logic;

  signal s_axis_bit_tdata   : std_logic_vector(1 downto 0);
  signal s_axis_bit_tvalid  : std_logic;
  signal s_axis_bit_tready  : std_logic;

  signal m_axis_byte_tuser  : std_logic_vector(2 downto 0); -- ERROR | EOP | SOP
  signal m_axis_byte_tdata  : std_logic_vector(7 downto 0);
  signal m_axis_byte_tvalid : std_logic;
  signal m_axis_byte_tready : std_logic;

begin

  UUT_i2c_byte_rx : entity work.i2c_byte_rx
    port map (
      aclk                        => aclk,
      aresetn                     => aresetn,

      s_axis_bit_tdata            => s_axis_bit_tdata,
      s_axis_bit_tvalid           => s_axis_bit_tvalid,
      s_axis_bit_tready           => s_axis_bit_tready,

      m_axis_byte_tuser           => m_axis_byte_tuser,
      m_axis_byte_tdata           => m_axis_byte_tdata,
      m_axis_byte_tvalid          => m_axis_byte_tvalid,
      m_axis_byte_tready          => m_axis_byte_tready
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

  PROC_s_axis_bit : process
    procedure send_byte( sop : std_logic; eop : std_logic; ack : std_logic; value : std_logic_vector(7 downto 0) ) is
    begin
      if sop = '1' then
        push_axi_stream( net, s_axis_bit, tdata => C_START );
      end if;

      for i in value'range loop
        if value(i) = '0' then push_axi_stream( net, s_axis_bit, tdata => C_BIT_0 ); end if;
        if value(i) = '1' then push_axi_stream( net, s_axis_bit, tdata => C_BIT_1 ); end if;
      end loop;

      if ack = '0' then push_axi_stream( net, s_axis_bit, tdata => C_BIT_0 ); end if;
      if ack = '1' then push_axi_stream( net, s_axis_bit, tdata => C_BIT_1 ); end if;

      if eop = '1' then
        push_axi_stream( net, s_axis_bit, tdata => C_STOP );
      end if;
    end procedure;
  begin
    wait until rising_edge(aclk) and aresetn = '1';

    send_byte( '1', '0', '0', X"01" );
    send_byte( '0', '0', '0', X"02" );
    send_byte( '0', '1', '1', X"03" );

    wait;
  end process;

  PROC_m_axis_byte : process
    procedure check_byte( sop : std_logic; eop : std_logic; err : std_logic; value : std_logic_vector(7 downto 0) ) is
      variable v_tuser : std_logic_vector(2 downto 0);
    begin
      v_tuser(0) := sop;
      v_tuser(1) := eop;
      v_tuser(2) := err;

      check_axi_stream( net, m_axis_byte, expected => value, tuser => v_tuser );
    end procedure;
  begin
    wait until rising_edge(aclk) and aresetn = '1';

    check_byte( '1', '0', '0', X"01" );
    check_byte( '0', '0', '0', X"02" );
    check_byte( '0', '1', '1', X"03" );

    END_OF_SIMULATION <= true;
    wait;
  end process;
  
  U_s_axis_bit : entity vunit_lib.axi_stream_master
    generic map(
      master  => s_axis_bit
    )
    port map(
      aclk     => aclk,
      areset_n => aresetn,
      tdata    => s_axis_bit_tdata,
      tvalid   => s_axis_bit_tvalid,
      tready   => s_axis_bit_tready
    );
  
  U_m_axis_byte : entity vunit_lib.axi_stream_slave
    generic map(
      slave   => m_axis_byte
    )
    port map(
      aclk     => aclk,
      areset_n => aresetn,
      tuser    => m_axis_byte_tuser,
      tdata    => m_axis_byte_tdata,
      tvalid   => m_axis_byte_tvalid,
      tready   => m_axis_byte_tready
    );

end behav_tb_i2c_byte_rx;

-- synthesis translate_on

