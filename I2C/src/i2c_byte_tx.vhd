
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.i2c_pkg.all;

entity i2c_byte_tx is
  port (
    clk                     : in  std_logic;
    reset                   : in  std_logic;

    aso_bit_data            : out std_logic_vector(1 downto 0);
    aso_bit_valid           : out std_logic;
    aso_bit_ready           : in  std_logic;

    asi_byte_data           : in  std_logic_vector(7 downto 0);
    asi_byte_startofpacket  : in  std_logic;
    asi_byte_endofpacket    : in  std_logic;
    asi_byte_error          : in  std_logic;
    asi_byte_valid          : in  std_logic;
    asi_byte_ready          : out std_logic
  );
end i2c_byte_tx;

architecture i2c_byte_tx_a of i2c_byte_tx is

  type byte_state is (S_IDLE, S_START_BIT, S_DATA_BIT, S_ACK_BIT, S_STOP_BIT, S_DONE);
  
  signal byte_s                   : byte_state := S_IDLE;

  signal i_asi_byte_data          : std_logic_vector(7 downto 0);
  signal i_asi_byte_startofpacket : std_logic;
  signal i_asi_byte_endofpacket   : std_logic;
  signal i_asi_byte_error         : std_logic;
  signal i_asi_byte_valid         : std_logic;

  signal i_bit_idx                : integer range 0 to 7;

begin

  asi_byte_ready  <= not i_asi_byte_valid;

  aso_bit_data    <= C_START when byte_s = S_START_BIT else
                     C_STOP  when byte_s = S_STOP_BIT  else
                     '0' & i_asi_byte_data(i_bit_idx) when byte_s = S_DATA_BIT else
                     '0' & i_asi_byte_error when byte_s = S_ACK_BIT else
                     "01";

  aso_bit_valid   <= '0' when byte_s = S_IDLE or byte_s = S_DONE else '1';

  i_asi_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        i_asi_byte_data           <= (others => '0');
        i_asi_byte_startofpacket  <= '0';
        i_asi_byte_endofpacket    <= '0';
        i_asi_byte_error          <= '0';
        i_asi_byte_valid          <= '0';
      else
        if byte_s = S_DONE then
          i_asi_byte_valid          <= '0';
        elsif asi_byte_valid = '1' and i_asi_byte_valid = '0' then
          i_asi_byte_data           <= asi_byte_data;
          i_asi_byte_startofpacket  <= asi_byte_startofpacket;
          i_asi_byte_endofpacket    <= asi_byte_endofpacket;
          i_asi_byte_error          <= asi_byte_error;
          i_asi_byte_valid          <= asi_byte_valid;
        end if;
      end if;
    end if;
  end process;

  i_bit_idx_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        i_bit_idx <= 7;
      else
        if byte_s = S_IDLE then
          i_bit_idx <= 7;
        elsif aso_bit_ready = '1' and byte_s = S_DATA_BIT and i_bit_idx /= 0 then
          i_bit_idx <= i_bit_idx - 1;
        end if;
      end if;
    end if;
  end process;

  byte_sm : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        byte_s <= S_IDLE;
      else
        case byte_s is
          when S_IDLE => 
            if i_asi_byte_valid = '1' and i_asi_byte_startofpacket = '1' then
              byte_s <= S_START_BIT;
            elsif i_asi_byte_valid = '1' then
              byte_s <= S_DATA_BIT;
            end if;

          when S_START_BIT => 
            if aso_bit_ready = '1' then
              byte_s <= S_DATA_BIT;
            end if;

          when S_DATA_BIT => 
            if aso_bit_ready = '1' and i_bit_idx = 0 then
              byte_s <= S_ACK_BIT;
            end if;

          when S_ACK_BIT => 
            if aso_bit_ready = '1' then
              if i_asi_byte_endofpacket = '1' then
                byte_s <= S_STOP_BIT;
              else
                byte_s <= S_DONE;
              end if;
            end if;

          when S_STOP_BIT => 
            if aso_bit_ready = '1' then
              byte_s <= S_DONE;
            end if;

          when S_DONE => 
            byte_s <= S_IDLE;

        end case;
      end if;
    end if;
  end process;

end i2c_byte_tx_a;

-- synthesis translate_off

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.i2c_pkg.all;

entity i2c_byte_tx_ut is
end i2c_byte_tx_ut;

architecture i2c_byte_tx_ut_a of i2c_byte_tx_ut is
  
  signal clk                    : std_logic := '0';
  signal reset                  : std_logic;

  signal aso_bit_data           : std_logic_vector(1 downto 0);
  signal aso_bit_valid          : std_logic;
  signal aso_bit_ready          : std_logic;

  signal asi_byte_data          : std_logic_vector(7 downto 0);
  signal asi_byte_startofpacket : std_logic;
  signal asi_byte_endofpacket   : std_logic;
  signal asi_byte_error         : std_logic;
  signal asi_byte_valid         : std_logic;
  signal asi_byte_ready         : std_logic;
  
begin

  UUT : entity work.i2c_byte_tx
    port map (
      clk                     => clk,
      reset                   => reset,

      aso_bit_data            => aso_bit_data,
      aso_bit_valid           => aso_bit_valid,
      aso_bit_ready           => aso_bit_ready,

      asi_byte_data           => asi_byte_data,
      asi_byte_startofpacket  => asi_byte_startofpacket,
      asi_byte_endofpacket    => asi_byte_endofpacket,
      asi_byte_error          => asi_byte_error,
      asi_byte_valid          => asi_byte_valid,
      asi_byte_ready          => asi_byte_ready
    );

  clk   <= not clk after 5 ns;
  reset <= '1', '0' after 100 ns;

  aso_bit_p : process
    procedure check_bit( expected : std_logic_vector(1 downto 0) ) is
    begin
      aso_bit_ready <= '1';
      wait until rising_edge(clk) and aso_bit_valid = '1';
      
      assert aso_bit_data = expected
        report "ERROR expected(0x" & to_hstring(expected) & ") : actual(0x" & to_hstring(aso_bit_data) & ")"
        severity ERROR;

      aso_bit_ready <= '0';
      wait until rising_edge(clk);

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
    aso_bit_ready <= '0';

    check_byte( '1', '0', '1', X"01" );
    check_byte( '0', '0', '1', X"02" );
    check_byte( '0', '1', '0', X"03" );

    report "END OF SIMULATION" severity FAILURE;

    wait;
  end process;

  asi_byte_p : process
    procedure send_byte( sop : std_logic; eop : std_logic; err : std_logic; value : std_logic_vector(7 downto 0) ) is
    begin
      asi_byte_data           <= value;
      asi_byte_startofpacket  <= sop;
      asi_byte_endofpacket    <= eop;
      asi_byte_error          <= err;
      asi_byte_valid          <= '1';
      wait until rising_edge(clk) and asi_byte_ready = '1';
      asi_byte_data           <= (others => '0');
      asi_byte_startofpacket  <= '0';
      asi_byte_endofpacket    <= '0';
      asi_byte_error          <= '0';
      asi_byte_valid          <= '0';
    end procedure;
  begin
    asi_byte_data           <= (others => '0');
    asi_byte_startofpacket  <= '0';
    asi_byte_endofpacket    <= '0';
    asi_byte_error          <= '0';
    asi_byte_valid          <= '0';

    wait until rising_edge(clk) and reset = '0';

    send_byte( '1', '0', '1', X"01" );
    send_byte( '0', '0', '1', X"02" );
    send_byte( '0', '1', '0', X"03" );

    wait;
  end process;

end i2c_byte_tx_ut_a;

-- synthesis translate_on
