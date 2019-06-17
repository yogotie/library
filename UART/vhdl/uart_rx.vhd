
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
  generic(
    clk_freq                : integer := 100000000;
    baud_rate               : integer := 115200
  );
  port(
    clk                     : in  std_logic;
    reset                   : in  std_logic;
    
    ------------------------
    -- uart_rx Interface
    ------------------------
    coe_rx_export           : in  std_logic;
    
    ------------------------
    -- FPGA Fabric Receive Interface
    ------------------------
    aso_data_data           : out std_logic_vector(7 downto 0);
    aso_data_startofpacket  : out std_logic;
    aso_data_endofpacket    : out std_logic;
    aso_data_valid          : out std_logic;
    aso_data_ready          : in  std_logic
  );
end uart_rx;

architecture uart_rx_a of uart_rx is
  
  constant max_count  : integer := clk_freq / baud_rate;
  
  type rx_state is (S_IDLE, S_START, S_DATA, S_STOP);
  
  signal rx_s         : rx_state := S_IDLE;           -- receiver state machine
  
  signal i_rx         : std_logic_vector(2 downto 0); -- register incomming signal
  signal i_edge       : std_logic;                    -- detects any edge
  signal i_cnt_done   : std_logic;                    -- signals when the counter has finished
  signal i_half_bit   : std_logic;                    -- signals when the counter is in the middle of a bit
  signal i_counter    : unsigned(15 downto 0);        -- counts a bit time
  signal i_bit_cnt    : unsigned(2 downto 0);         -- count the number of bits that have been receieved
  signal i_data       : std_logic_vector(7 downto 0); -- shift register for incomming data
  
begin
  
  aso_data_data           <= i_data;  -- output the data to the user
  aso_data_startofpacket  <= '1';
  aso_data_endofpacket    <= '1';
  
  aso_data_valid_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        aso_data_valid <= '0';  -- data output is not valid at reset
      else
        if rx_s = S_STOP and i_half_bit = '1' then  -- data is only valid once half the stop bit is receieved
          aso_data_valid <= '1';
        else
          aso_data_valid <= '0';
        end if;
      end if;
    end if;
  end process;
  
  i_edge      <= i_rx(i_rx'left) xor i_rx(i_rx'left - 1);     -- an edge is detected when the last to input registers are different
  i_cnt_done  <= '1' when i_counter = max_count - 1 else '0'; -- count is done once it has reached the max valud
  i_half_bit  <= '1' when i_counter = max_count / 2 else '0'; -- half a bit time is done once count is at half
  
  -- register the input signal
  i_rx_p : process(clk) is
  begin
    if rising_edge(clk) then
      i_rx <= i_rx(i_rx'left - 1 downto 0) & coe_rx_export;
    end if;
  end process;
  
  -- count the bit time
  i_counter_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        i_counter <= (others => '0');
      else
        if i_edge = '1' or i_cnt_done = '1' then -- reset the counter when an edge is detected or the count is done
          i_counter <= (others => '0');
        else
          i_counter <= i_counter + 1;
        end if;
      end if;
    end if;
  end process;
  
  -- count the number of bits 
  i_bit_cnt_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        i_bit_cnt <= (others => '0');
      else
        if rx_s /= S_DATA then          -- reset the bit count when not in the data state
          i_bit_cnt <= (others => '0');
        elsif i_half_bit = '1' then     -- count the bit once half the bit has arrived [ detect bits at the center ]
          i_bit_cnt <= i_bit_cnt + 1;
        end if;
      end if;
    end if;
  end process;
  
  -- input shift register
  i_data_p : process(clk) is
  begin
    if rising_edge(clk) then
      if i_half_bit = '1' and rx_s = S_DATA then
        i_data <= i_rx(i_rx'left) & i_data(i_data'left downto 1);
      end if;
    end if;
  end process;
  
  -- receieve state machine
  rx_sm : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        rx_s <= S_IDLE;
      else
        case rx_s is
          when S_IDLE => -- wait for the input to go low [ a start bit ]
            if i_rx(i_rx'left) = '0' then
              rx_s <= S_START;
            end if;
            
          when S_START => -- wait for half the start bit to complete to move to the data state
            if i_half_bit = '1' then
              rx_s <= S_DATA;
            end if;
            
          when S_DATA => -- at bit 7 move to the stop bit at the half bit time
            if i_half_bit = '1' and i_bit_cnt = 7 then
              rx_s <= S_STOP;
            end if;
            
          when S_STOP => -- got back to idle at the half bit
            if i_half_bit = '1' then
              rx_s <= S_IDLE;
            end if;
            
        end case;
      end if;
    end if;
  end process;
  
end uart_rx_a;

-- synthesis translate_off

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx_ut is
  generic(
    clk_freq  : integer := 100000000;
    baud_rate : integer := 115200
  );
end uart_rx_ut;

architecture uart_rx_ut_a of uart_rx_ut is
  
  signal baud_period    : time := real(real(1) / real(baud_rate)) * 1 sec;
  signal clk_period     : time := real(real(1) / real(clk_freq)) * 1 sec;
  
  signal clk            : std_logic := '0';
  signal reset          : std_logic;
  signal coe_rx_export  : std_logic := '1';
  signal aso_data_data  : std_logic_vector(7 downto 0);
  signal aso_data_valid : std_logic;
  signal aso_data_ready : std_logic;
  
begin
  
  UUT : entity work.uart_rx
    generic map(
      clk_freq        => clk_freq,
      baud_rate       => baud_rate
    )
    port map(
      clk             => clk,
      reset           => reset,
      coe_rx_export   => coe_rx_export,
      aso_data_data   => aso_data_data,
      aso_data_valid  => aso_data_valid,
      aso_data_ready  => aso_data_ready
    );
  
  clk   <= not clk after clk_period / 2;
  reset <= '1', '0' after 100 ns;
  
  -- procedure to simulate serial data
  coe_rx_export_p : process
    -- procedure to generate the stimulus
    procedure send_data(d:std_logic_vector(7 downto 0)) is
    begin
      -- start bit
      coe_rx_export <= '0';
      wait for baud_period;
      
      -- 8 data bits
      for i in 0 to 7 loop
        coe_rx_export <= d(i);
        wait for baud_period;
      end loop;
      
      -- stop bit
      coe_rx_export <= '1';
      wait for baud_period;
    end procedure send_data;
  begin
    wait for 1 us;
    
    send_data(X"12");
    send_data(X"34");
    
    wait;
  end process;

  aso_data_p : process
    procedure check_data( expected : std_logic_vector(7 downto 0) ) is
    begin
      wait until rising_edge(clk) and aso_data_valid = '1';
      assert aso_data_data = expected
        report "ERROR expected(0x" & to_hstring(expected) & ") : actual(0x" & to_hstring(aso_data_data) & ")"
        severity ERROR;
    end procedure;
  begin
    check_data( X"12" );
    check_data( X"34" );

    report "END OF SIMULATION" severity FAILURE;

  end process;

  aso_data_ready <= '1';
  
end uart_rx_ut_a;

-- synthesis translate_on
