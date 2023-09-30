
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity spi_tx is
  generic(
    clk_freq      : integer := 100000000;
    spi_freq      : integer := 3200000;
    cpol          : integer := 1;
    cpha          : integer := 1;
    csn_width     : integer := 1
  );
  port (
    aclk          : in  std_logic;
    aresetn       : in  std_logic;

    spi_csn       : out std_logic_vector(csn_width - 1 downto 0);
    spi_mosi      : out std_logic;
    spi_clk       : out std_logic;

    s_axis_tdest  : in  std_logic_vector(7 downto 0);
    s_axis_tdata  : in  std_logic_vector(7 downto 0);
    s_axis_tlast  : in  std_logic;
    s_axis_tvalid : in  std_logic;
    s_axis_tready : out std_logic
  );
end spi_tx;

architecture rtl_spi_tx of spi_tx is

  constant C_MAX_COUNT  : integer := clk_freq / spi_freq;

  type T_spi_state is (S_IDLE, S_SET_CSN, S_DATA, S_CLR_CSN, S_DONE);

  signal sig_spi_s      : T_spi_state := S_IDLE;

  signal sig_spi_csn    : std_logic_vector(spi_csn'range);
  signal sig_spi_mosi   : std_logic;
  signal sig_spi_clk    : std_logic;

  signal sig_cnt_done   : std_logic;
  signal sig_counter    : unsigned(31 downto 0);
  signal sig_bit_cnt    : integer range 0 to 7;
  signal sig_word_done  : std_logic;

begin

  spi_csn   <= sig_spi_csn;
  spi_mosi  <= sig_spi_mosi;

  UG_spi_clk_pol_0 : if cpol = 0 generate
    spi_clk <= not sig_spi_clk;
  end generate;

  UG_spi_clk_pol_1 : if cpol = 1 generate
    spi_clk <= sig_spi_clk;
  end generate;

  s_axis_tready <= '1' when sig_spi_s = S_DATA and sig_word_done = '1' and sig_cnt_done = '1' else '0';

  sig_word_done <= '1' when sig_bit_cnt = 0 else '0';

  PROC_sig_spi_csn : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_spi_csn <= (others => '1');
      else
        if sig_spi_s = S_SET_CSN then
          sig_spi_csn( to_integer(unsigned(s_axis_tdest)) ) <= '0';
        end if;

        if sig_spi_s = S_CLR_CSN then
          sig_spi_csn <= (others => '1');
        end if;
      end if;
    end if;
  end process;

  PROC_sig_spi_mosi : process(aclk) is
  begin
    if rising_edge(aclk) then
      case sig_spi_s is
        when S_IDLE => sig_spi_mosi <= '0';
        when others => sig_spi_mosi <= s_axis_tdata(sig_bit_cnt); -- send the data bits
      end case;
    end if;
  end process;

  PROC_sig_spi_clk : process(aclk) is
  begin
    if rising_edge(aclk) then
      if sig_spi_s = S_DATA then
        if cpha = 1 then
          if sig_counter = 0 then sig_spi_clk <= '0'; elsif sig_counter = C_MAX_COUNT / 2 then sig_spi_clk <= '1'; end if;
        else
          if sig_counter = 0 then sig_spi_clk <= '1'; elsif sig_counter = C_MAX_COUNT / 2 then sig_spi_clk <= '0'; end if;
        end if;
      elsif sig_spi_s = S_DONE and sig_spi_csn /= (sig_spi_csn'range => '1') then
        if cpha = 1 then
          if s_axis_tvalid = '1' then sig_spi_clk <= '0'; end if;
        else
          if s_axis_tvalid = '1' then sig_spi_clk <= '1'; end if;
        end if;
      else
        sig_spi_clk <= '1';
      end if;
    end if;
  end process;

  -- flag when the bit time is complete
  PROC_sig_cnt_done : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_cnt_done <= '0';
      else
        if sig_counter = C_MAX_COUNT - 2 then
          sig_cnt_done <= '1';
        else
          sig_cnt_done <= '0';
        end if;
      end if;
    end if;
  end process;

  -- counter for the length of each bit
  PROC_sig_counter : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_counter <= (others => '0');
      else
        if sig_cnt_done = '1' then
          sig_counter <= (others => '0');
        else
          sig_counter <= sig_counter + 1;
        end if;
      end if;
    end if;
  end process;

  PROC_sig_bit_cnt : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_bit_cnt <= 0;
      else
        if (sig_spi_s /= S_DATA or (sig_spi_s = S_DATA and sig_word_done = '1')) and sig_cnt_done = '1' then
          sig_bit_cnt <= 7;
        elsif sig_bit_cnt /= 0 and sig_cnt_done = '1' then
          sig_bit_cnt <= sig_bit_cnt - 1;
        end if;
      end if;
    end if;
  end process;

  PROC_sig_spi_s : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_spi_s <= S_IDLE;
      else
        case sig_spi_s is
          when S_IDLE =>
            if s_axis_tvalid = '1' and sig_cnt_done = '1' then
              sig_spi_s <= S_SET_CSN;
            end if;

          when S_SET_CSN =>
            if sig_cnt_done = '1' then
              sig_spi_s <= S_DATA;
            end if;

          when S_DATA =>
            if sig_word_done = '1' and sig_cnt_done = '1' then
              if s_axis_tlast = '1' then
                sig_spi_s <= S_CLR_CSN;
              else
                sig_spi_s <= S_DONE;
              end if;
            end if;

          when S_CLR_CSN =>
            if sig_cnt_done = '1' then
              sig_spi_s <= S_DONE;
            end if;

          when S_DONE =>
            if s_axis_tvalid = '1' and sig_spi_csn = (sig_spi_csn'range => '1') then
              sig_spi_s <= S_SET_CSN;
            elsif s_axis_tvalid = '1' then
              sig_spi_s <= S_DATA;
            else
              sig_spi_s <= S_IDLE;
            end if;

        end case;
      end if;
    end if;
  end process;

end rtl_spi_tx;

