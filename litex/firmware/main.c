// =========================================================================
// 1. PASTE YOUR LATEST LITEX CSR CONSTANTS HERE (From csr.h)
// =========================================================================

#ifndef CSR_BASE
#define CSR_BASE 0x82000000L
#endif /* ! CSR_BASE */

//--------------------------------------------------------------------------------
// CSR Registers/Fields Definition.
//--------------------------------------------------------------------------------

/* CTRL Registers */
#define CSR_CTRL_BASE (CSR_BASE + 0x0L)
#define CSR_CTRL_RESET_ADDR (CSR_BASE + 0x0L)
#define CSR_CTRL_RESET_SIZE 1
#define CSR_CTRL_SCRATCH_ADDR (CSR_BASE + 0x4L)
#define CSR_CTRL_SCRATCH_SIZE 1
#define CSR_CTRL_BUS_ERRORS_ADDR (CSR_BASE + 0x8L)
#define CSR_CTRL_BUS_ERRORS_SIZE 1

/* CTRL Fields */
#define CSR_CTRL_RESET_SOC_RST_OFFSET 0
#define CSR_CTRL_RESET_SOC_RST_SIZE 1
#define CSR_CTRL_RESET_CPU_RST_OFFSET 1
#define CSR_CTRL_RESET_CPU_RST_SIZE 1

/* TIMER0 Registers */
#define CSR_TIMER0_BASE (CSR_BASE + 0x800L)
#define CSR_TIMER0_LOAD_ADDR (CSR_BASE + 0x800L)
#define CSR_TIMER0_LOAD_SIZE 1
#define CSR_TIMER0_RELOAD_ADDR (CSR_BASE + 0x804L)
#define CSR_TIMER0_RELOAD_SIZE 1
#define CSR_TIMER0_EN_ADDR (CSR_BASE + 0x808L)
#define CSR_TIMER0_EN_SIZE 1
#define CSR_TIMER0_UPDATE_VALUE_ADDR (CSR_BASE + 0x80cL)
#define CSR_TIMER0_UPDATE_VALUE_SIZE 1
#define CSR_TIMER0_VALUE_ADDR (CSR_BASE + 0x810L)
#define CSR_TIMER0_VALUE_SIZE 1
#define CSR_TIMER0_EV_STATUS_ADDR (CSR_BASE + 0x814L)
#define CSR_TIMER0_EV_STATUS_SIZE 1
#define CSR_TIMER0_EV_PENDING_ADDR (CSR_BASE + 0x818L)
#define CSR_TIMER0_EV_PENDING_SIZE 1
#define CSR_TIMER0_EV_ENABLE_ADDR (CSR_BASE + 0x81cL)
#define CSR_TIMER0_EV_ENABLE_SIZE 1

/* TIMER0 Fields */
#define CSR_TIMER0_EV_STATUS_ZERO_OFFSET 0
#define CSR_TIMER0_EV_STATUS_ZERO_SIZE 1
#define CSR_TIMER0_EV_PENDING_ZERO_OFFSET 0
#define CSR_TIMER0_EV_PENDING_ZERO_SIZE 1
#define CSR_TIMER0_EV_ENABLE_ZERO_OFFSET 0
#define CSR_TIMER0_EV_ENABLE_ZERO_SIZE 1

/* UART Registers */
#define CSR_UART_BASE (CSR_BASE + 0x1000L)
#define CSR_UART_RXTX_ADDR (CSR_BASE + 0x1000L)
#define CSR_UART_RXTX_SIZE 1
#define CSR_UART_TXFULL_ADDR (CSR_BASE + 0x1004L)
#define CSR_UART_TXFULL_SIZE 1
#define CSR_UART_RXEMPTY_ADDR (CSR_BASE + 0x1008L)
#define CSR_UART_RXEMPTY_SIZE 1
#define CSR_UART_EV_STATUS_ADDR (CSR_BASE + 0x100cL)
#define CSR_UART_EV_STATUS_SIZE 1
#define CSR_UART_EV_PENDING_ADDR (CSR_BASE + 0x1010L)
#define CSR_UART_EV_PENDING_SIZE 1
#define CSR_UART_EV_ENABLE_ADDR (CSR_BASE + 0x1014L)
#define CSR_UART_EV_ENABLE_SIZE 1
#define CSR_UART_TXEMPTY_ADDR (CSR_BASE + 0x1018L)
#define CSR_UART_TXEMPTY_SIZE 1
#define CSR_UART_RXFULL_ADDR (CSR_BASE + 0x101cL)
#define CSR_UART_RXFULL_SIZE 1

/* UART Fields */
#define CSR_UART_EV_STATUS_TX_OFFSET 0
#define CSR_UART_EV_STATUS_TX_SIZE 1
#define CSR_UART_EV_STATUS_RX_OFFSET 1
#define CSR_UART_EV_STATUS_RX_SIZE 1
#define CSR_UART_EV_PENDING_TX_OFFSET 0
#define CSR_UART_EV_PENDING_TX_SIZE 1
#define CSR_UART_EV_PENDING_RX_OFFSET 1
#define CSR_UART_EV_PENDING_RX_SIZE 1
#define CSR_UART_EV_ENABLE_TX_OFFSET 0
#define CSR_UART_EV_ENABLE_TX_SIZE 1
#define CSR_UART_EV_ENABLE_RX_OFFSET 1
#define CSR_UART_EV_ENABLE_RX_SIZE 1


// =========================================================================
// 2. ROBUST FIRMWARE LOGIC (DO NOT CHANGE)
// =========================================================================

// Bind volatile pointers directly to the LiteX macros
#define UART_RXTX       (*(volatile unsigned int *)CSR_UART_RXTX_ADDR)
#define UART_TXFULL     (*(volatile unsigned int *)CSR_UART_TXFULL_ADDR)
#define UART_RXEMPTY    (*(volatile unsigned int *)CSR_UART_RXEMPTY_ADDR)
#define UART_EV_PENDING (*(volatile unsigned int *)CSR_UART_EV_PENDING_ADDR)

// Dynamically create the event bitmasks using the offsets
#define UART_EV_TX (1 << CSR_UART_EV_PENDING_TX_OFFSET)
#define UART_EV_RX (1 << CSR_UART_EV_PENDING_RX_OFFSET)

// Custom raw print function
void print_str(const char *str) {
    while (*str) {
        // Wait until there is space in the transmit buffer
        while (UART_TXFULL) { } 
        
        // Write the character
        UART_RXTX = *str++;
        
        // Clear the TX event so the state machine advances
        UART_EV_PENDING = UART_EV_TX;
    }
}

int main(void) {
    print_str("===   Processor is able to communicate through UART!   ===\n\r");
    print_str("Typing a letter will print it with it's case toggled.\n\r");
    print_str("Typing a digit will print it as it's distance from digit 9 (for example, \"123\" echoes back as \"876\".\n\r");
    print_str("Type something below:\n\r");

    while(1) {
        // If the receive buffer is not empty
        if (!UART_RXEMPTY) {
            // Read the character from the RX FIFO
            char c = (char)UART_RXTX;
            
            // Explicitly acknowledge the RX event
            UART_EV_PENDING = UART_EV_RX;
            
            // Wait for TX buffer space and echo it back
            while (UART_TXFULL) { }

            if (c >= 'a' && c <= 'z') c = c - 'a' + 'A';
            else if (c >= 'A' && c <= 'Z') c = c - 'A' + 'a';
            else if (c >= '0' && c <= '9') c = 9 - c + 2 * '0';

            UART_RXTX = c;
            UART_EV_PENDING = UART_EV_TX;
        }
    }
    return 0;
}
