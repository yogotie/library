
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.i2c_pkg.all;

entity i2c_byte_rx is
  port (
    clk                     : in  std_logic;
    reset                   : in  std_logic;

    asi_bit_data            : in  std_logic_vector(1 downto 0);
    asi_bit_valid           : in  std_logic;
    asi_bit_ready           : out std_logic;

    aso_byte_data           : out std_logic_vector(7 downto 0);
    aso_byte_startofpacket  : out std_logic;
    aso_byte_endofpacket    : out std_logic;
    aso_byte_error          : out std_logic;
    aso_byte_valid          : out std_logic;
    aso_byte_ready          : in  std_logic
  );
end i2c_byte_rx;

architecture i2c_byte_rx_a of i2c_byte_rx is

  type array_slv2 is array(natural range<>) of std_logic_vector(1 downto 0);

  signal i_bit_data : array_slv2(15 downto 0);
  signal i_bit_cnt  : integer range 0 to 15;

begin

  asi_bit_ready <= '1';

  aso_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        aso_byte_data           <= (others => '0');
        aso_byte_startofpacket  <= '0';
        aso_byte_endofpacket    <= '0';
        aso_byte_error          <= '0';
        aso_byte_valid          <= '0';
      else
        if (i_bit_data(10) = C_START and i_bit_cnt >= 11) or i_bit_data(0) = C_STOP then
          aso_byte_error <= i_bit_data(1)(0);
          for i in 9 downto 2 loop
            aso_byte_data(i - 2) <= i_bit_data(i)(0);
          end loop;
        elsif i_bit_cnt >= 11 then
          aso_byte_error <= i_bit_data(2)(0);
          for i in 10 downto 3 loop
            aso_byte_data(i - 3) <= i_bit_data(i)(0);
          end loop;
        end if;

        if i_bit_data(10) = C_START and i_bit_cnt >= 11 then
          aso_byte_startofpacket <= '1';
        else
          aso_byte_startofpacket <= '0';
        end if;

        if i_bit_data(0) = C_STOP and i_bit_cnt >= 1 then
          aso_byte_endofpacket <= '1';
        else
          aso_byte_endofpacket <= '0';
        end if;

        if (i_bit_data(0) = C_STOP and i_bit_cnt /= 0) or i_bit_cnt >= 11 then
          aso_byte_valid <= '1';
        else
          aso_byte_valid <= '0';
        end if;
      end if;
    end if;
  end process;

  i_bit_data_p : process(clk) is
  begin
    if rising_edge(clk) then
      if asi_bit_valid = '1' then
        i_bit_data <= i_bit_data(i_bit_data'left - 1 downto 0) & asi_bit_data;
      end if;
    end if;
  end process;

  i_bit_cnt_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        i_bit_cnt <= 0;
      else
        if asi_bit_valid = '1' then
          i_bit_cnt <= i_bit_cnt + 1;
        elsif i_bit_data(0) = C_STOP then
          i_bit_cnt <= 0;
        elsif i_bit_data(10) = C_START and i_bit_cnt >= 11 then
          i_bit_cnt <= 1;
        elsif i_bit_cnt >= 11 then
          i_bit_cnt <= 2;
        end if;
      end if;
    end if;
  end process;

end i2c_byte_rx_a;

-- synthesis translate_off

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.i2c_pkg.all;

entity i2c_byte_rx_ut is
end i2c_byte_rx_ut;

architecture i2c_byte_rx_ut_a of i2c_byte_rx_ut is
  
  signal clk                    : std_logic := '0';
  signal reset                  : std_logic;

  signal asi_bit_data           : std_logic_vector(1 downto 0);
  signal asi_bit_valid          : std_logic;
  signal asi_bit_ready          : std_logic;

  signal aso_byte_data          : std_logic_vector(7 downto 0);
  signal aso_byte_startofpacket : std_logic;
  signal aso_byte_endofpacket   : std_logic;
  signal aso_byte_error         : std_logic;
  signal aso_byte_valid         : std_logic;
  signal aso_byte_ready         : std_logic;

begin
  
  u_i2c_byte_rx : entity work.i2c_byte_rx
    port map (
      clk                     => clk,
      reset                   => reset,

      asi_bit_data            => asi_bit_data,
      asi_bit_valid           => asi_bit_valid,
      asi_bit_ready           => asi_bit_ready,

      aso_byte_data           => aso_byte_data,
      aso_byte_startofpacket  => aso_byte_startofpacket,
      aso_byte_endofpacket    => aso_byte_endofpacket,
      aso_byte_error          => aso_byte_error,
      aso_byte_valid          => aso_byte_valid,
      aso_byte_ready          => aso_byte_ready
    );

  clk   <= not clk after 5 ns;
  reset <= '1', '0' after 100 ns;
  
  asi_bit_p : process
    procedure send_bit( value : std_logic_vector(1 downto 0) ) is
    begin
      asi_bit_data  <= value;
      asi_bit_valid <= '1';
      wait until rising_edge(clk) and asi_bit_ready = '1';
      asi_bit_valid <= '0';
      wait until rising_edge(clk);
    end procedure;
    procedure send_byte( sop : std_logic; eop : std_logic; ack : std_logic; value : std_logic_vector(7 downto 0) ) is
    begin
      if sop = '1' then
        send_bit( C_START );
      end if;

      for i in value'range loop
        if value(i) = '0' then send_bit( C_BIT_0 ); end if;
        if value(i) = '1' then send_bit( C_BIT_1 ); end if;
      end loop;

      if ack = '0' then send_bit( C_BIT_0 ); end if;
      if ack = '1' then send_bit( C_BIT_1 ); end if;

      if eop = '1' then
        send_bit( C_STOP );
      end if;
    end procedure;
  begin
    asi_bit_data  <= (others => '0');
    asi_bit_valid <= '0';
    
    wait until rising_edge(clk) and reset = '0';

    send_byte( '1', '0', '0', X"01" );
    send_byte( '0', '0', '0', X"02" );
    send_byte( '0', '1', '1', X"03" );

    wait;
  end process;

  aso_byte_p : process
    procedure check_byte( sop : std_logic; eop : std_logic; err : std_logic; value : std_logic_vector(7 downto 0) ) is
    begin
      aso_byte_ready  <= '1';
      wait until rising_edge(clk) and aso_byte_valid = '1';
      aso_byte_ready  <= '0';

      assert aso_byte_startofpacket = sop
        report "ERROR : startofpacket : expected(" & std_logic'image(sop) & ") : actual(" & std_logic'image(aso_byte_startofpacket) & ")"
        severity ERROR;

      assert aso_byte_endofpacket = eop
        report "ERROR : endofpacket : expected(" & std_logic'image(eop) & ") : actual(" & std_logic'image(aso_byte_endofpacket) & ")"
        severity ERROR;

      assert aso_byte_error = err
        report "ERROR : error : expected(" & std_logic'image(err) & ") : actual(" & std_logic'image(aso_byte_error) & ")"
        severity ERROR;

      assert aso_byte_data(value'range) = value
        report "ERROR : data : expected(0x" & to_hstring(value) & ") : actual(0x" & to_hstring(aso_byte_data(value'range)) & ")"
        severity ERROR;

    end procedure;
  begin
    aso_byte_ready  <= '0';

    wait until rising_edge(clk) and reset = '0';

    check_byte( '1', '0', '0', X"01" );
    check_byte( '0', '0', '0', X"02" );
    check_byte( '0', '1', '1', X"03" );

    report "END OF SIMULATION" severity FAILURE;

    wait;
  end process;
  
end i2c_byte_rx_ut_a;

-- synthesis translate_on
