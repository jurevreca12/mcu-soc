#define UART_CONF_OFF    0x0
#define UART_SPEED_OFF   0x4
#define UART_TX_OFF      0x8
#define UART_RX_OFF      0xC
#define UART_BASE_ADDR   0x40000000
#define UART_CONF_ADDR   (UART_BASE_ADDR + UART_CONF_OFF)
#define UART_SPEED_ADDR  (UART_BASE_ADDR + UART_SPEED_OFF)
#define UART_TX_ADDR     (UART_BASE_ADDR + UART_TX_OFF)
#define UART_RX_ADDR     (UART_BASE_ADDR + UART_RX_OFF)

int main() {
    
    return 0;
}
