library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_master is
    Port (
        clk      : in  STD_LOGIC;
        reset    : in  STD_LOGIC;
        start    : in  STD_LOGIC;
        tx_data  : in  STD_LOGIC_VECTOR(7 downto 0);
        miso     : in  STD_LOGIC;
        mosi     : out STD_LOGIC;
        sck      : out STD_LOGIC;
        ss       : out STD_LOGIC;
        rx_data  : out STD_LOGIC_VECTOR(7 downto 0);
        busy     : out STD_LOGIC
    );
end spi_master;

architecture Structural of spi_master is
    -- ?????????? ??????????? Tx ?? Rx
    component spi_tx is
        Port ( clk, reset, tx_start, shift_en : in STD_LOGIC;
               tx_data_in : in STD_LOGIC_VECTOR(7 downto 0);
               mosi : out STD_LOGIC );
    end component;

    component spi_rx is
        Port ( clk, reset, sample_en, miso : in STD_LOGIC;
               rx_data_out : out STD_LOGIC_VECTOR(7 downto 0) );
    end component;

    -- ????????? ??????? ??'???? (??????? ????? FSM)
    type state_type is (IDLE, TRANSFER, DONE);
    signal state : state_type := IDLE;
    
    signal sck_internal : STD_LOGIC := '0';
    signal bit_count    : integer range 0 to 8 := 0;
    
    -- ??????? ????????? ???????? Tx ?? Rx
    signal tx_start_sig, shift_en_sig, sample_en_sig : STD_LOGIC := '0';

begin
    -- ??????????? ?????? SCK
    sck <= sck_internal;

    -- ?????????????? ?????? ?????????? (Tx)
    TX_INST: spi_tx port map (
        clk => clk, reset => reset, tx_start => tx_start_sig, 
        shift_en => shift_en_sig, tx_data_in => tx_data, mosi => mosi
    );

    -- ?????????????? ?????? ???????? (Rx)
    RX_INST: spi_rx port map (
        clk => clk, reset => reset, sample_en => sample_en_sig, 
        miso => miso, rx_data_out => rx_data
    );

    -- ?????? ???????? ?????? ?? ????????? ???????? ?????????
    process(clk, reset)
    begin
        if reset = '1' then
            state <= IDLE;
            ss <= '1';
            sck_internal <= '0';
            busy <= '0';
            bit_count <= 0;
            tx_start_sig <= '0';
            shift_en_sig <= '0';
            sample_en_sig <= '0';
        elsif rising_edge(clk) then
            -- ???????? ?????????? ???????? ?????????
            tx_start_sig <= '0';
            shift_en_sig <= '0';
            sample_en_sig <= '0';

            case state is
                when IDLE =>
                    ss <= '1';
                    sck_internal <= '0';
                    busy <= '0';
                    if start = '1' then
                        tx_start_sig <= '1'; -- ??????? Tx ?? ???????????? ?????
                        busy <= '1';
                        ss <= '0';
                        bit_count <= 0;
                        state <= TRANSFER;
                    end if;

                when TRANSFER =>
                    -- ????????? SCK (??????????? ????? ??????? ????? clk)
                    sck_internal <= not sck_internal;
                    
                    if sck_internal = '0' then
                        -- ??????????? ????? SCK (?????????? ????? ?????????)
                        sample_en_sig <= '1';
                    else
                        -- ????????? ????? SCK (???? ????? ???????????)
                        if bit_count = 7 then
                            state <= DONE;
                        else
                            shift_en_sig <= '1';
                            bit_count <= bit_count + 1;
                        end if;
                    end if;

                when DONE =>
                    ss <= '1';
                    sck_internal <= '0';
                    busy <= '0';
                    state <= IDLE;
            end case;
        end if;
    end process;
end Structural;