--------------------------------------
-- Author: Yacin Belmihoub-Martel
-- Date: 01/03/2020
-- Title: gcd.vhd 
-- Description: Computes the greatest common
-- divider between two 32 bit unsigned integers 
-- using Stein's algorithm (https://en.wikipedia.org/wiki/Binary_GCD_algorithm)
--------------------------------------
-- NOTE: I chose to divide the process in small synchronous iterations
-- because it will reduce the computing time of each iteration, therefore
-- allowing for a faster clock speed when implementing this ALU inside
-- a CPU for example. This explains the larger number of signals.

library IEEE
use IEEE.std_logic_1164.all

entity gcd is 
    port
    (
        clk : in std_logic;                         -- Clock
        rst : in std_logic;                         -- Reset
        en  : in std_logic;                         -- Enable input read
        A : in std_logic_vector(31 downto 0);       -- Input word A
        B : in std_logic_vector(31 downto 0);       -- Input word B
        C : out std_logic_vector(31 downto 0);      -- Output word
        done : out std_logic                        -- Output ready
    );
end entity;

architecture beh_gcd of gcd is
-- Syncrhonous signals
signal s_op1 : std_logic_vector(31 downto 0);       -- Operands
signal s_op2 : std_logic_vector(31 downto 0);       
signal s_res : std_logic_vector(31 downto 0);       -- Final result
signal s_done : std_logic;                          -- Computation done 
signal s_shift: std_logic_vector(5 downto 0);       -- Shift counter memory

-- Asynchronous signals
signal a_res1: std_logic_vector(31 downto 0);       -- Iteration results
signal a_res2: std_logic_vector(31 downto 0);
signal a_done: std_logic;                           -- Computation done 
signal a_shift : std_logic_vector(5 downto 0);      -- Shift counter

-- Input mux signals
signal a_op1 : std_logic_vector(31 downto 0);
signal a_op2 : std_logic_vector(31 downto 0);

begin
    -- Connect internal signals to outputs
    done <= s_done;
    C <= s_res;

    -- en HIGH, select input signal
    -- en LOW, select result from previous iteration
    a_op1 <= A when en = '1' else
             a_res1;
    a_op2 <= B when en= '1' else 
             a_res2;

    SYNC_GCD : process(clk, rst)
    begin
        -- Reset internal signals when rst is HIGH
        if rst = '1' then
            s_done <= '0';
            s_shift <= (others => '0');
            s_op1 <= (others => '0');
            s_op2 <= (others => '0');
            s_res <= (others => '0');
        -- Synchronize I/Os
        elsif rising_edge(clk) then
            s_done <= a_done;
            s_shift <= a_shift;
            s_op1 <= a_op1;
            s_op2 <= a_op2;
            -- Update result if done
            if a_done = '1' then
                s_res <= a_op1 << a_shift;
            end if;
        end if;
    end process SYNC_GCD;

    -- Combinatory stage (implementation of the Stein's algorithm)
    COMB_GCD : process(s_op1, s_op2)
    begin 
        -- Computation is done
        if s_op1 = s_op2 then
            a_done <= '1';
            a_shift <= s_shift;
            a_res1 <= s_op1;
            a_res2 <= s_op2;
        -- Both operands are even
        elsif s_op1(0) nor s_op2(0) then
            a_done <= '0';
            a_shift <= s_shift + 1;
            a_res1 <= s_op1 >> 1;
            a_res2 <= s_op2 >> 1;
        -- Operand 1 is odd, operand 2 is even
        elsif s_op1(0) = '1' and s_op2(0) = '0' then
            a_done <= '0';
            a_shift <= s_shift;
            a_res1 <= s_op1;
            a_res2 <= s_op2 >> 1;
        -- Operand 1 is even, operand 2 is odd
        elsif s_op1(0) = '0' and s_op2(0) = '1' then
            a_done <= '0';
            a_shift <= s_shift;
            a_res1 <= s_op1 >> 1;
            a_res2 <= s_op2;
        -- Both operands are odd
        else
            a_done <= '0';
            a_shift <= s_shift;
            -- Divide by two the difference of the bigger and the smaller operand
            if s_op1 > s_op2 then
                a_res1 <= (s_op1 - s_op2) >> 1;
                a_res2 <= s_op2;
            else
                a_res1 <= s_op1;
                a_res2 <= (s_op2 - s_op1) >> 1;
            end if;
        end if;
    end process COMB_GCD;
end architecture;
