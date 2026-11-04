library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Тестбенч не має зовнішніх портів, оскільки він сам є "зовнішнім середовищем"
entity spi_master_tb is
end spi_master_tb;

architecture Behavioral of spi_master_tb is
    -- Оголошення нашого головного модуля SPI Master для підключення
    component spi_master
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
    end component;

    -- Сигнали для імітації підключень
    signal clk      : STD_LOGIC := '0';
    signal reset    : STD_LOGIC := '0';
    signal start    : STD_LOGIC := '0';
    signal tx_data  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal miso     : STD_LOGIC := '0';
    
    signal mosi     : STD_LOGIC;
    signal sck      : STD_LOGIC;
    signal ss       : STD_LOGIC;
    signal rx_data  : STD_LOGIC_VECTOR(7 downto 0);
    signal busy     : STD_LOGIC;

    -- Константа періоду для тактового сигналу (100 МГц)
    constant CLK_PERIOD : time := 10 ns;

begin
    -- Підключення нашого модуля до тестових сигналів
    UUT: spi_master port map (
        clk => clk, reset => reset, start => start,
        tx_data => tx_data, miso => miso,
        mosi => mosi, sck => sck, ss => ss,
        rx_data => rx_data, busy => busy
    );

    -- 1. Генерація тактового сигналу (CLK)
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- 3. Імітація передачі даних від іншого пристрою (Slave)
    -- Найкращий спосіб перевірити Rx - зробити "Loopback" (заглушку).
    -- Ми напряму з'єднуємо вихід передавача MOSI із входом приймача MISO.
    miso <= mosi; 

    -- 2. Подача тестових даних (Tx) та генерація скидання (RESET)
    stimulus_process: process
    begin
        -- Апаратне скидання системи перед початком роботи
        reset <= '1';
        wait for 20 ns;
        reset <= '0';
        wait for 20 ns;

        -- Підготовка конкретних даних для передачі (наприклад, байт 10101100)
        tx_data <= "10101100";
        wait for CLK_PERIOD;

        -- Імітація команди "Старт" від мікроконтролера
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0'; -- Сигнал старту має бути імпульсним (1 такт)

        -- Автоматичне очікування завершення транзакції
        wait until busy = '0';
        wait for 50 ns;

        -- Зупинка симуляції (інакше clk_process працюватиме нескінченно)
     assert false report "Simulation finished successfully! Check waveforms." severity failure;
    end process;
end Behavioral;