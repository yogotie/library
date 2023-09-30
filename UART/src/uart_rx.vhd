
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity uart_rx is
  generic(
    g_clk_freq    : integer := 100000000;
    g_baud_rate   : integer := 115200
  );
  port(
    aclk          : in  std_logic;
    aresetn       : in  std_logic;

    rx            : in  std_logic;

    m_axis_tdata  : out std_logic_vector(7 downto 0);
    m_axis_tlast  : out std_logic;
    m_axis_tvalid : out std_logic;
    m_axis_tready : in  std_logic
  );
end uart_rx;

architecture rtl_uart_rx of uart_rx is

  constant C_MAX_COUNT  : integer := g_clk_freq / g_baud_rate;

  type T_rx_state is (S_IDLE, S_START, S_DATA, S_STOP);

  signal sig_rx_s       : T_rx_state := S_IDLE;         -- receiver state machine

  signal sig_rx         : std_logic_vector(2 downto 0); -- register incomming signal
  signal sig_edge       : std_logic;                    -- detects any edge
  signal sig_cnt_done   : std_logic;                    -- signals when the counter has finished
  signal sig_half_bit   : std_logic;                    -- signals when the counter is in the middle of a bit
  signal sig_counter    : unsigned(15 downto 0);        -- counts a bit time
  signal sig_bit_cnt    : unsigned(2 downto 0);         -- count the number of bits that have been receieved
  signal sig_data       : std_logic_vector(7 downto 0); -- shift register for incomming data

begin

  m_axis_tdata  <= sig_data;  -- output the data to the user
  m_axis_tlast  <= '1';

  sig_edge      <= sig_rx(sig_rx'left) xor sig_rx(sig_rx'left - 1);     -- an edge is detected when the last to input registers are different
  sig_cnt_done  <= '1' when sig_counter = C_MAX_COUNT - 1 else '0'; -- count is done once it has reached the max valud
  sig_half_bit  <= '1' when sig_counter = C_MAX_COUNT / 2 else '0'; -- half a bit time is done once count is at half

  PROC_m_axis_tvalid : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        m_axis_tvalid <= '0';  -- data output is not valid at aresetn
      else
        if sig_rx_s = S_STOP and sig_half_bit = '1' then  -- data is only valid once half the stop bit is receieved
          m_axis_tvalid <= '1';
        else
          m_axis_tvalid <= '0';
        end if;
      end if;
    end if;
  end process;

  -- register the input signal
  PROC_sig_rx : process(aclk) is
  begin
    if rising_edge(aclk) then
      sig_rx <= sig_rx(sig_rx'left - 1 downto 0) & rx;
    end if;
  end process;

  -- count the bit time
  PROC_sig_counter : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_counter <= (others => '0');
      else
        if sig_edge = '1' or sig_cnt_done = '1' then -- aresetn the counter when an edge is detected or the count is done
          sig_counter <= (others => '0');
        else
          sig_counter <= sig_counter + 1;
        end if;
      end if;
    end if;
  end process;

  -- count the number of bits
  PROC_sig_bit_cnt : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_bit_cnt <= (others => '0');
      else
        if sig_rx_s /= S_DATA then          -- aresetn the bit count when not in the data state
          sig_bit_cnt <= (others => '0');
        elsif sig_half_bit = '1' then     -- count the bit once half the bit has arrived [ detect bits at the center ]
          sig_bit_cnt <= sig_bit_cnt + 1;
        end if;
      end if;
    end if;
  end process;

  -- input shift register
  PROC_sig_data : process(aclk) is
  begin
    if rising_edge(aclk) then
      if sig_half_bit = '1' and sig_rx_s = S_DATA then
        sig_data <= sig_rx(sig_rx'left) & sig_data(sig_data'left downto 1);
      end if;
    end if;
  end process;

  -- receieve state machine
  PROC_sig_rx_s : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_rx_s <= S_IDLE;
      else
        case sig_rx_s is
          when S_IDLE => -- wait for the input to go low [ a start bit ]
            if sig_rx(sig_rx'left) = '0' then
              sig_rx_s <= S_START;
            end if;

          when S_START => -- wait for half the start bit to complete to move to the data state
            if sig_half_bit = '1' then
              sig_rx_s <= S_DATA;
            end if;

          when S_DATA => -- at bit 7 move to the stop bit at the half bit time
            if sig_half_bit = '1' and sig_bit_cnt = 7 then
              sig_rx_s <= S_STOP;
            end if;

          when S_STOP => -- got back to idle at the half bit
            if sig_half_bit = '1' then
              sig_rx_s <= S_IDLE;
            end if;

        end case;
      end if;
    end if;
  end process;

end rtl_uart_rx;

