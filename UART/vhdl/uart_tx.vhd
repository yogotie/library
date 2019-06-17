
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
  generic(
    clk_freq                : integer := 100000000;
    baud_rate               : integer := 115200
  );
  port(
    clk                     : in  std_logic;
    reset                   : in  std_logic;
    
    ------------------------
    -- uart_tx Interface
    ------------------------
    coe_tx_export           : out std_logic;
    
    ------------------------
    -- FPGA Fabric Transmit Interface
    ------------------------
    asi_data_data           : in  std_logic_vector(7 downto 0);
    asi_data_startofpacket  : in  std_logic;
    asi_data_endofpacket    : in  std_logic;
    asi_data_valid          : in  std_logic;
    asi_data_ready          : out std_logic
  );
end uart_tx;

architecture uart_tx_a of uart_tx is
  
  constant max_count  : integer := clk_freq / baud_rate;
  
  type tx_state is (S_IDLE, S_START, S_DATA, S_DONE);
  
  signal tx_s         : tx_state := S_IDLE;
  
  signal i_cnt_done   : std_logic;                    -- flags when a bit is done
  signal i_counter    : unsigned(15 downto 0);        -- counts the bit time
  signal i_bit_cnt    : unsigned(2 downto 0);         -- counts the number of bits transmitted
  signal i_data       : std_logic_vector(7 downto 0); -- shift register for transmitting data
  
begin
  
  asi_data_ready <= '1' when tx_s = S_DONE else '0';  -- return that asi_data_ready signal when the transmission is done
  
  tx_p : process(clk) is
  begin
    if rising_edge(clk) then
      case tx_s is
        when S_START  => coe_tx_export <= '0';       -- send that start bit
        when S_DATA   => coe_tx_export <= i_data(0); -- send the data bits
        when others   => coe_tx_export <= '1';       -- send the stop bit
      end case;
    end if;
  end process;
  
  -- flag when the bit time is complete
  i_cnt_done_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        i_cnt_done <= '0';
      else
        if i_counter = max_count - 2 then
          i_cnt_done <= '1';
        else
          i_cnt_done <= '0';
        end if;
      end if;
    end if;
  end process;
  
  -- counter for the length of each bit
  i_counter_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        i_counter <= (others => '0');
      else
        if i_cnt_done = '1' then
          i_counter <= (others => '0');
        else
          i_counter <= i_counter + 1;
        end if;
      end if;
    end if;
  end process;
  
  -- count the bits transmitted
  i_bit_cnt_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        i_bit_cnt <= (others => '0');
      else
        if tx_s /= S_DATA then  -- reset the count when not in the data state
          i_bit_cnt <= (others => '0');
        elsif i_cnt_done = '1' then
          i_bit_cnt <= i_bit_cnt + 1;
        end if;
      end if;
    end if;
  end process;

  -- shift data out
  i_data_p : process(clk) is
  begin
    if rising_edge(clk) then
      if tx_s = S_IDLE then -- get the data to send when in the idle state
        i_data <= asi_data_data(i_data'range);
      elsif i_cnt_done = '1' and tx_s = S_DATA then  -- move to the next bit at the end of a bit in the data state
        i_data <= i_data(0) & i_data(i_data'left downto 1);
      end if;
    end if;
  end process;

  tx_sm : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        tx_s <= S_IDLE;
      else
        case tx_s is
          when S_IDLE => -- only being at the end of a bit time
            if asi_data_valid = '1' and i_cnt_done = '1' then
              tx_s <= S_START;
            end if;
            
          when S_START => -- move to data at the end of the start bit
            if i_cnt_done = '1' then
              tx_s <= S_DATA;
            end if;
            
          when S_DATA => 
            if i_cnt_done = '1' and i_bit_cnt = 7 then
              tx_s <= S_DONE;
            end if;
            
          when S_DONE => 
            tx_s <= S_IDLE;
            
        end case;
      end if;
    end if;
  end process;
  
end architecture uart_tx_a;

-- synthesis translate_off

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx_ut is
  generic(
    clk_freq  : integer := 100000000;
    baud_rate : integer := 115200
  );
end uart_tx_ut;

architecture uart_tx_ut_a of uart_tx_ut is
  
  signal baud_period            : time := real(real(1) / real(baud_rate)) * 1 sec;
  signal clk_period             : time := real(real(1) / real(clk_freq)) * 1 sec;
  
  signal clk                    : std_logic := '0';
  signal reset                  : std_logic;
  signal coe_tx_export          : std_logic;
  signal asi_data_data          : std_logic_vector(7 downto 0);
  signal asi_data_startofpacket : std_logic;
  signal asi_data_endofpacket   : std_logic;
  signal asi_data_valid         : std_logic;
  signal asi_data_ready         : std_logic;
  
begin
  
  UUT : entity work.uart_tx
    generic map(
      clk_freq                => clk_freq,
      baud_rate               => baud_rate
    )
    port map(
      clk                     => clk,
      reset                   => reset,
      coe_tx_export           => coe_tx_export,
      asi_data_data           => asi_data_data,
      asi_data_startofpacket  => asi_data_startofpacket,
      asi_data_endofpacket    => asi_data_endofpacket,
      asi_data_valid          => asi_data_valid,
      asi_data_ready          => asi_data_ready
    );
  
  clk   <= not clk after clk_period / 2;
  reset <= '1', '0' after 100 ns;

  coe_tx_export_p : process
    procedure check_data( expected : std_logic_vector(7 downto 0) ) is
      variable actual : std_logic_vector(7 downto 0);
    begin
      wait until falling_edge(coe_tx_export);
      wait for baud_period / 2;
      for i in 0 to 7 loop
        wait for baud_period;
        actual(i) := coe_tx_export;
      end loop;

      assert actual = expected
        report "ERROR expected(0x" & to_hstring(expected) & ") : actual(0x" & to_hstring(actual) & ")"
        severity ERROR;

    end procedure;
  begin

    check_data( X"12" );
    check_data( X"34" );

    report "END OF SIMULATION" severity FAILURE;

  end process;
  
  asi_data_startofpacket  <= '1';
  asi_data_endofpacket    <= '1';

  asi_data_p : process
    procedure send_data( value : std_logic_vector(7 downto 0) ) is
    begin
      asi_data_data   <= value;
      asi_data_valid  <= '1';
      wait until rising_edge(clk) and asi_data_ready = '1';
      asi_data_valid  <= '0';
      wait until rising_edge(clk);
    end procedure;
  begin
    asi_data_data <= (others => '0');
    asi_data_valid <= '0';
    
    wait for 1 us;
    send_data( X"12" );
    send_data( X"34" );
    wait;
  end process;
  
end architecture uart_tx_ut_a;

-- synthesis translate_on
