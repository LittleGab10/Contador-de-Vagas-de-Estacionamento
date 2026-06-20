LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;


ENTITY estacionamento_rtl IS

    PORT(
        clock      : IN  STD_LOGIC; 
        reset_n    : IN  STD_LOGIC; -- (Reseta o circuito)
        sw_entra   : IN  STD_LOGIC; -- (Chave de Entrada de Carro)
        sw_sai     : IN  STD_LOGIC; -- (Chave de Saída de Carro)
        led_lotado : OUT STD_LOGIC; -- (LED Vermelho de Lotado)
        display    : OUT STD_LOGIC_VECTOR(6 DOWNTO 0) -- ( Display de 7 Segmentos)

    );

END estacionamento_rtl;


ARCHITECTURE logica_do_projeto OF estacionamento_rtl IS


    -- Sinais dos Registradores de Estado da HLSM 

    SIGNAL ea1, ea0 : STD_LOGIC := '0';   -- Estado Atual
    SIGNAL pe1, pe0 : STD_LOGIC;   -- Próximo Estado



    -- Sinal do Contador de Vagas 

    SIGNAL vagas_reg : UNSIGNED(2 DOWNTO 0) := "100"; 

    
    -- Sinais de controle intermediários (Portas lógicas)

    SIGNAL diminui_vaga  : STD_LOGIC;
    SIGNAL aumenta_vaga  : STD_LOGIC;
    SIGNAL lotado, vazio : STD_LOGIC;

BEGIN



    -- SEÇÃO 1: REGISTRADORES E CONTADORES 

    REGISTRADORES_MEMORIA: PROCESS(clock)

    BEGIN

        IF rising_edge(clock) THEN
            IF (reset_n = '0') THEN 
               ea1       <= '0';    -- Força a HLSM para o Estado de Espera
               ea0       <= '0';
               vagas_reg <= "100";  -- Reinicializa o contador com 4 vagas livres

            ELSE

                -- Atualização dos registradores na batida do Clock
                ea1 <= pe1;
                ea0 <= pe0;

                
                -- Atualiza a memória do contador baseado nas ordens das portas lógicas

                IF (diminui_vaga = '1') THEN
                  vagas_reg <= vagas_reg - 1;
                ELSIF (aumenta_vaga = '1') THEN
                     vagas_reg <= vagas_reg + 1;
                END IF;
            END IF;
         END IF;
   END PROCESS;



    -- SEÇÃO 2: LÓGICA DA HLSM E TRAVAS 

	 
    -- Identificação combinacional de extremos (0 ou 4 vagas)

    lotado <= (NOT vagas_reg(2)) AND (NOT vagas_reg(1)) AND (NOT vagas_reg(0)); -- "000" (0 vagas)
    vazio  <= vagas_reg(2) AND (NOT vagas_reg(1)) AND (NOT vagas_reg(0));        -- "100" (4 vagas)



    -- O LED acende em '1' quando o estacionamento estiver lotado

    led_lotado <= lotado;



    -- Equações Booleanas das Portas Lógicas para o Próximo Estado (pe1 e pe0)

    -- Estado 00 (Espera), 01 (Trava Entrada), 10 (Trava Saída)

    pe1 <= ((NOT ea1) AND (NOT ea0) AND (NOT sw_entra) AND sw_sai AND (NOT vazio)) OR (ea1 AND (NOT ea0) AND sw_sai);
    pe0 <= ((NOT ea1) AND (NOT ea0) AND sw_entra AND (NOT sw_sai) AND (NOT lotado)) OR ((NOT ea1) AND ea0 AND sw_entra);



    -- Portas lógicas que geram o pulso de contagem (Saindo do estado 00)

	 diminui_vaga <= (NOT ea1) AND (NOT ea0) AND sw_entra AND (NOT sw_sai) AND (NOT lotado);
    aumenta_vaga <= (NOT ea1) AND (NOT ea0) AND (NOT sw_entra) AND sw_sai AND (NOT vazio);


    -- SEÇÃO 3: DECODIFICADOR PARA O DISPLAY

  

    -- Equações booleanas que decodificam de 0 a 4 direto para os leds do display.

    display(0) <= (NOT vagas_reg(2) AND NOT vagas_reg(1) AND vagas_reg(0)) OR (vagas_reg(2) AND NOT vagas_reg(1) AND NOT vagas_reg(0)); 
    display(1) <= '0';
    display(2) <= (NOT vagas_reg(2) AND vagas_reg(1) AND NOT vagas_reg(0)); 
    display(3) <= (NOT vagas_reg(2) AND NOT vagas_reg(1) AND vagas_reg(0)) OR (vagas_reg(2) AND NOT vagas_reg(1) AND NOT vagas_reg(0)); 
    display(4) <= (NOT vagas_reg(2) AND NOT vagas_reg(1) AND vagas_reg(0)) OR (NOT vagas_reg(2) AND vagas_reg(1) AND vagas_reg(0)) OR (vagas_reg(2) AND NOT vagas_reg(1) AND NOT vagas_reg(0)); 
    display(5) <= (NOT vagas_reg(2) AND NOT vagas_reg(1) AND vagas_reg(0)) OR (NOT vagas_reg(2) AND vagas_reg(1) AND NOT vagas_reg(0)) OR (NOT vagas_reg(2) AND vagas_reg(1) AND vagas_reg(0)); 
    display(6) <= (NOT vagas_reg(2) AND NOT vagas_reg(1) AND NOT vagas_reg(0)) OR (NOT vagas_reg(2) AND NOT vagas_reg(1) AND vagas_reg(0)); 

END logica_do_projeto;
