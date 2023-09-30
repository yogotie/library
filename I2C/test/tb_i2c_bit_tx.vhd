
-- synthesis translate_off

library vunit_lib;
  context vunit_lib.vunit_context;
  context vunit_lib.vc_context;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  use work.i2c_pkg.all;

entity tb_i2c_bit_tx is
  generic (
    runner_cfg      : string;
    g_clock_freq_hz : integer := 100000000;
    g_i2c_freq_hz   : integer := 100000
  );
end tb_i2c_bit_tx;

architecture behav_tb_i2c_bit_tx of tb_i2c_bit_tx is

  constant s_axis_bit      : axi_stream_master_t := new_axi_stream_master( data_length => 2 );

  signal END_OF_SIMULATION : boolean := false;

  signal aclk              : std_logic := '0';
  signal aresetn           : std_logic;

  signal sda_out           : std_logic;
  signal scl_out           : std_logic;

  signal s_axis_bit_tdata  : std_logic_vector(1 downto 0);
  signal s_axis_bit_tvalid : std_logic;
  signal s_axis_bit_tready : std_logic;

begin

  UUT : entity work.i2c_bit_tx
    generic map (
      g_clock_freq_hz     => g_clock_freq_hz,
      g_i2c_freq_hz       => g_i2c_freq_hz
    )
    port map (
      aclk                => aclk,
      aresetn             => aresetn,

      sda_out             => sda_out,
      scl_out             => scl_out,

      s_axis_bit_tdata    => s_axis_bit_tdata,
      s_axis_bit_tvalid   => s_axis_bit_tvalid,
      s_axis_bit_tready   => s_axis_bit_tready
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

  PROC_i2c_check : process
    procedure check_bit( value : std_logic_vector(1 downto 0) ) is
    begin
      if scl_out /= '0' and scl_out /= '1' then
        wait until scl_out = '0' or scl_out = '1';
      end if;

      case value is
        when C_BIT_0 =>
          wait until rising_edge(scl_out);
          assert '0' = sda_out
            report "BIT(0) : ERROR expected sda_out = '0' : actual sda_out = '1'"
            severity ERROR;
          wait until falling_edge(scl_out);

        when C_BIT_1 =>
          wait until rising_edge(scl_out);
          assert '1' = sda_out
            report "BIT(1) : ERROR expected sda_out = '1' : actual sda_out = '0'"
            severity ERROR;
          wait until falling_edge(scl_out);

        when C_START =>
          wait until sda_out'event;
          assert '0' = sda_out
            report "START : ERROR expected sda_out = '0' : actual sda_out = '1'"
            severity ERROR;

          wait until scl_out'event;
          assert '0' = scl_out
            report "START : ERROR expected scl_out = '0' : actual scl_out = '1'"
            severity ERROR;

        when C_STOP =>
          wait until scl_out'event;
          assert '1' = scl_out
            report "STOP : ERROR expected scl_out = '1' : actual scl_out = '0'"
            severity ERROR;

          wait until sda_out'event;
          assert '1' = sda_out
            report "STOP : ERROR expected sda_out = '1' : actual sda_out = '0'"
            severity ERROR;

        when others =>

      end case;
    end procedure;
  begin

    check_bit( C_START );
    check_bit( C_BIT_0 );
    check_bit( C_BIT_1 );
    check_bit( C_STOP );

    wait for 10 us;

    END_OF_SIMULATION <= true;

    wait;
  end process;

  PROC_s_axis_bit : process
  begin
    wait until rising_edge(aclk) and aresetn = '1';

    push_axi_stream( net, s_axis_bit, tdata => C_START );
    push_axi_stream( net, s_axis_bit, tdata => C_BIT_0 );
    push_axi_stream( net, s_axis_bit, tdata => C_BIT_1 );
    push_axi_stream( net, s_axis_bit, tdata => C_STOP );

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
end behav_tb_i2c_bit_tx;

-- synthesis translate_on

