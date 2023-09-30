
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_misc.all;
  use ieee.numeric_std.all;

entity spi_rx is
  generic(
    clk_freq        : integer := 100000000;
    spi_freq        : integer := 3200000;
    cpol            : integer := 1;
    cpha            : integer := 1;
    csn_width       : integer := 1
  );
  port (
    aclk            : in  std_logic;
    aresetn         : in  std_logic;

    spi_csn         : in  std_logic_vector(csn_width - 1 downto 0);
    spi_miso        : in  std_logic;
    spi_clk         : in  std_logic;

    m_axis_tdest    : out std_logic_vector(7 downto 0);
    m_axis_tdata    : out std_logic_vector(7 downto 0);
    m_axis_tlast    : out std_logic;
    m_axis_tvalid   : out std_logic;
    m_axis_tready   : in  std_logic
  );
end spi_rx;

architecture rtl_spi_rx of spi_rx is

  constant C_MAX_COUNT      : integer := (clk_freq / spi_freq) * 2;

  type T_spi_state is (S_IDLE, S_START, S_DATA, S_VALID_WAIT, S_STOP, S_VALID);

  signal sig_spi_s          : T_spi_state := S_IDLE;

  signal sig_m_axis_tdest   : std_logic_vector(7 downto 0);
  signal sig_m_axis_tdata   : std_logic_vector(7 downto 0);
  signal sig_m_axis_tlast   : std_logic;
  signal sig_m_axis_tvalid  : std_logic;

  signal sig_spi_csn        : std_logic_vector(csn_width - 1 downto 0);
  signal sig_spi_miso       : std_logic;
  signal sig_spi_clk        : std_logic_vector(1 downto 0);

  signal sig_bit_valid      : std_logic;
  signal sig_bit_cnt        : integer range 0 to 7;
  signal sig_bit_time       : unsigned(31 downto 0);
  signal sig_bit_timeout    : std_logic;

  signal sig_tdest          : std_logic_vector(7 downto 0);
  signal sig_tdest_valid    : std_logic_vector(1 downto 0);
  signal sig_tdata          : std_logic_vector(7 downto 0);
  signal sig_tlast          : std_logic;
  signal sig_tvalid         : std_logic;

begin

  m_axis_tdest    <= sig_m_axis_tdest;
  m_axis_tdata    <= sig_m_axis_tdata;
  m_axis_tlast    <= sig_m_axis_tlast;
  m_axis_tvalid   <= sig_m_axis_tvalid;

  sig_bit_valid   <= '1' when sig_tdest_valid(sig_tdest_valid'left) = '1' and (
                                (sig_spi_clk = "01" and ((cpol = 0 and cpha = 0) or (cpol = 1 and cpha = 1))) or
                                (sig_spi_clk = "10" and ((cpol = 0 and cpha = 1) or (cpol = 1 and cpha = 0)))
                              ) else '0';

  sig_bit_timeout <= sig_bit_time(sig_bit_time'left);

  PROC_sig_spi_csn  : process(aclk) is begin if rising_edge(aclk) then sig_spi_csn  <= spi_csn;  end if; end process;
  PROC_sig_spi_miso : process(aclk) is begin if rising_edge(aclk) then sig_spi_miso <= spi_miso; end if; end process;
  PROC_sig_spi_clk  : process(aclk) is begin if rising_edge(aclk) then sig_spi_clk  <= sig_spi_clk(sig_spi_clk'left - 1 downto 0) & spi_clk; end if; end process;

  PROC_sig_m_axis : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_m_axis_tdest    <= (others => '0');
        sig_m_axis_tdata    <= (others => '0');
        sig_m_axis_tlast    <= '0';
        sig_m_axis_tvalid   <= '0';
      else
        if sig_m_axis_tvalid = '0' and sig_spi_s = S_VALID then
          sig_m_axis_tdest    <= sig_tdest;
          sig_m_axis_tdata    <= sig_tdata;
          sig_m_axis_tlast    <= sig_tlast;
          sig_m_axis_tvalid   <= '1';
        elsif sig_m_axis_tvalid = '1' and m_axis_tready = '1' then
          sig_m_axis_tvalid   <= '0';
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
        if sig_tdest_valid = "10" or sig_tdest_valid = "00" then
          sig_bit_cnt <= 0;
        elsif sig_bit_valid = '1' and sig_bit_cnt /= 7 then
          sig_bit_cnt <= sig_bit_cnt + 1;
        elsif sig_bit_valid = '1' then
          sig_bit_cnt <= 0;
        end if;
      end if;
    end if;
  end process;

  PROC_sig_bit_time : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_bit_time <= (others => '1');
      else
        if sig_bit_valid = '1' or (sig_bit_timeout = '0' and sig_tdest_valid = "10") then
          sig_bit_time <= '0' & to_unsigned( C_MAX_COUNT - 1, sig_bit_time'length - 1 );
        elsif sig_bit_time(sig_bit_time'left) = '0' then
          sig_bit_time <= sig_bit_time - 1;
        end if;
      end if;
    end if;
  end process;

  PROC_sig_tdest : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_tdest       <= (others => '0');
        sig_tdest_valid <= (others => '0');
      else
        for i in sig_spi_csn'range loop
          if sig_spi_csn(i) = '0' then
            sig_tdest       <= std_logic_vector( to_unsigned(i, sig_tdest'length) );
          end if;
        end loop;

        sig_tdest_valid <= sig_tdest_valid(sig_tdest_valid'left - 1 downto 0) & (not and_reduce( sig_spi_csn ));
      end if;
    end if;
  end process;

  PROC_sig_tdata : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_tdata <= (others => '0');
      else
        if sig_bit_valid = '1' then
          sig_tdata( 7 - sig_bit_cnt ) <= sig_spi_miso;
        end if;
      end if;
    end if;
  end process;

  PROC_sig_tlast : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_tlast   <= '0';
      else
        if sig_spi_s = S_IDLE then
          sig_tlast   <= '0';
        end if;

        if sig_spi_s = S_STOP then
          sig_tlast   <= '1';
        end if;
      end if;
    end if;
  end process;

  PROC_sig_tvalid : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_tvalid <= '0';
      else
        if (sig_bit_cnt = 7 and sig_bit_valid = '1') or sig_tdest_valid = "10" or sig_bit_timeout = '1' then
          sig_tvalid <= '1';
        else
          sig_tvalid <= '0';
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
            if sig_tdest_valid = "01" or sig_bit_timeout = '1' then
              sig_spi_s <= S_START;
            elsif sig_bit_valid = '1' then
              sig_spi_s <= S_DATA;
            end if;

          when S_START =>
            if sig_bit_timeout = '0' then
              sig_spi_s <= S_DATA;
            end if;

          when S_DATA =>
            if sig_bit_cnt = 7 and sig_bit_valid = '1' then
              sig_spi_s <= S_VALID_WAIT;
            elsif sig_tdest_valid = "10" or sig_bit_timeout = '1' then
              sig_spi_s <= S_STOP;
            end if;

          when S_VALID_WAIT =>
            if sig_bit_valid = '1' then
              sig_spi_s <= S_VALID;
            elsif sig_tdest_valid = "10" or sig_bit_timeout = '1' then
              sig_spi_s <= S_STOP;
            end if;

          when S_STOP =>
            sig_spi_s <= S_VALID;

          when S_VALID =>
            sig_spi_s <= S_IDLE;

        end case;
      end if;
    end if;
  end process;

end rtl_spi_rx;

