
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  use work.i2c_pkg.all;

entity i2c_byte_tx is
  port (
    aclk               : in  std_logic;
    aresetn            : in  std_logic;

    m_axis_bit_tdata   : out std_logic_vector(1 downto 0);
    m_axis_bit_tvalid  : out std_logic;
    m_axis_bit_tready  : in  std_logic;

    s_axis_byte_tuser  : in  std_logic_vector(2 downto 0);
    s_axis_byte_tdata  : in  std_logic_vector(7 downto 0);
    s_axis_byte_tvalid : in  std_logic;
    s_axis_byte_tready : out std_logic
  );
end i2c_byte_tx;

architecture rtl_i2c_byte_tx of i2c_byte_tx is

  type byte_state is (S_IDLE, S_START_BIT, S_DATA_BIT, S_ACK_BIT, S_STOP_BIT, S_DONE);

  signal byte_s                         : byte_state := S_IDLE;

  signal sig_s_axis_byte_terror         : std_logic;
  signal sig_s_axis_byte_tendofpacket   : std_logic;
  signal sig_s_axis_byte_tstartofpacket : std_logic;
  signal sig_s_axis_byte_tdata          : std_logic_vector(7 downto 0);
  signal sig_s_axis_byte_tvalid         : std_logic;

  signal sig_bit_idx                    : integer range 0 to 7;

begin

  s_axis_byte_tready  <= not sig_s_axis_byte_tvalid;

  m_axis_bit_tdata    <= C_START when byte_s = S_START_BIT else
                         C_STOP  when byte_s = S_STOP_BIT  else
                         '0' & sig_s_axis_byte_tdata(sig_bit_idx) when byte_s = S_DATA_BIT else
                         '0' & sig_s_axis_byte_terror when byte_s = S_ACK_BIT else
                         "01";

  m_axis_bit_tvalid   <= '0' when byte_s = S_IDLE or byte_s = S_DONE else '1';

  i_asi_p : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_s_axis_byte_terror          <= '0';
        sig_s_axis_byte_tendofpacket    <= '0';
        sig_s_axis_byte_tstartofpacket  <= '0';
        sig_s_axis_byte_tdata           <= (others => '0');
        sig_s_axis_byte_tvalid          <= '0';
      else
        if byte_s = S_DONE then
          sig_s_axis_byte_tvalid          <= '0';
        elsif s_axis_byte_tvalid = '1' and sig_s_axis_byte_tvalid = '0' then
          sig_s_axis_byte_terror          <= s_axis_byte_tuser(2);
          sig_s_axis_byte_tendofpacket    <= s_axis_byte_tuser(1);
          sig_s_axis_byte_tstartofpacket  <= s_axis_byte_tuser(0);
          sig_s_axis_byte_tdata           <= s_axis_byte_tdata;
          sig_s_axis_byte_tvalid          <= s_axis_byte_tvalid;
        end if;
      end if;
    end if;
  end process;

  sig_bit_idx_p : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_bit_idx <= 7;
      else
        if byte_s = S_IDLE then
          sig_bit_idx <= 7;
        elsif m_axis_bit_tready = '1' and byte_s = S_DATA_BIT and sig_bit_idx /= 0 then
          sig_bit_idx <= sig_bit_idx - 1;
        end if;
      end if;
    end if;
  end process;

  byte_sm : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        byte_s <= S_IDLE;
      else
        case byte_s is
          when S_IDLE =>
            if sig_s_axis_byte_tvalid = '1' and sig_s_axis_byte_tstartofpacket = '1' then
              byte_s <= S_START_BIT;
            elsif sig_s_axis_byte_tvalid = '1' then
              byte_s <= S_DATA_BIT;
            end if;

          when S_START_BIT =>
            if m_axis_bit_tready = '1' then
              byte_s <= S_DATA_BIT;
            end if;

          when S_DATA_BIT =>
            if m_axis_bit_tready = '1' and sig_bit_idx = 0 then
              byte_s <= S_ACK_BIT;
            end if;

          when S_ACK_BIT =>
            if m_axis_bit_tready = '1' then
              if sig_s_axis_byte_tendofpacket = '1' then
                byte_s <= S_STOP_BIT;
              else
                byte_s <= S_DONE;
              end if;
            end if;

          when S_STOP_BIT =>
            if m_axis_bit_tready = '1' then
              byte_s <= S_DONE;
            end if;

          when S_DONE =>
            byte_s <= S_IDLE;

        end case;
      end if;
    end if;
  end process;

end rtl_i2c_byte_tx:

