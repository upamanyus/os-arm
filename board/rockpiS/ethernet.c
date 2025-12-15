#include "board/rockpiS/ethernet.h"
#include "stdint.h"
#include "kernel/panic.h"
#include "kernel/uart.h"

#define GRF_BASE 0xFF000000
#define GRF_REG(offset) (*((volatile unsigned int*)(GRF_BASE + offset)))
#define GRF_GPIO1B_IOMUX_L GRF_REG(0x0028)
#define GRF_GPIO1B_IOMUX_H GRF_REG(0x002c)
#define GRF_GPIO1B_IOMUX_H GRF_REG(0x002c)
#define GRF_GPIO1C_IOMUX_L GRF_REG(0x0030)
#define GRF_GPIO1C_IOMUX_H GRF_REG(0x0034)

#define MAC_BASE 0xFF4E0000
#define MAC_REG(offset) (*((volatile unsigned int*)(MAC_BASE + offset)))

// UART Register physical addresses as volatile pointers
#define MAC_MAC_CONF MAC_REG(0x0000)
#define MAC_MAC_FRM_FILT MAC_REG(0x0004)
#define MAC_HASH_TAB_HI MAC_REG(0x0008)
#define MAC_HASH_TAB_LO MAC_REG(0x000c)
#define MAC_GMII_ADDR MAC_REG(0x0010)
#define MAC_GMII_DATA MAC_REG(0x0014)
#define MAC_FLOW_CTRL MAC_REG(0x0018)
#define MAC_VLAN_TAG MAC_REG(0x001c)
#define MAC_DEBUG MAC_REG(0x0024)
#define MAC_PMT_CTRL_STA MAC_REG(0x002c)
#define MAC_INT_STATUS MAC_REG(0x0038)
#define MAC_INT_MASK MAC_REG(0x003c)
#define MAC_MAC_ADDR0_HI MAC_REG(0x0040)
#define MAC_MAC_ADDR0_LO MAC_REG(0x0044)
#define MAC_AN_CTRL MAC_REG(0x00c0)
#define MAC_AN_STATUS MAC_REG(0x00c4)
#define MAC_AN_ADV MAC_REG(0x00c8)
#define MAC_AN_LINK_PART_AB MAC_REG(0x00cc)
#define MAC_AN_EXP MAC_REG(0x00d0)
#define MAC_INTF_MODE_STA MAC_REG(0x00d8)

#define MAC_BUS_MODE MAC_REG(0x1000)
#define MAC_TX_POLL_DEMAND MAC_REG(0x1004)
#define MAC_RX_POLL_DEMAND MAC_REG(0x1008)
#define MAC_RX_DESC_LIST_ADDR  MAC_REG(0x100c)
#define MAC_TX_DESC_LIST_ADDR  MAC_REG(0x1010)
#define MAC_STATUS MAC_REG(0x1014)
#define MAC_OP_MODE MAC_REG(0x1018)
#define MAC_INT_ENA MAC_REG(0x101c)
#define MAC_OVERFLOW_CNT MAC_REG(0x1020)

#define MAC_CUR_HOST_TX_DESC MAC_REG(0x1048)
#define MAC_CUR_HOST_RX_DESC MAC_REG(0x104c)
#define MAC_CUR_HOST_TX_BUF_ADDR MAC_REG(0x1050)
#define MAC_CUR_HOST_RX_BUF_ADDR MAC_REG(0x1054)

static void reset() {
    MAC_BUS_MODE = 1;
    while (MAC_BUS_MODE & 0x1);
}

static void pin_init() {
    // TRM section 23.5
    uint32_t gpio1b_iomux_l = (0b11 << 8) | (0b11 << 10) | (0b011 << 12);
    uint32_t gpio1b_iomux_l_mask = (0b11 << (16 + 8)) | (0b11 << (16 + 10)) | (0b111 << (16 + 12));
    GRF_GPIO1B_IOMUX_L = gpio1b_iomux_l | gpio1b_iomux_l_mask;

    uint32_t gpio1c_iomux_l = (0b11 << 0) | (0b11 << 2) | (0b011 << 4) | (0b011 << 8) | (0b011 << 12);
    uint32_t gpio1c_iomux_l_mask = (0b11 << 16) | (0b11 << (16 + 2)) | (0b111 << (16 + 4)) | (0b111 << (16 + 8)) | (0b111 << (16 + 12));
    GRF_GPIO1C_IOMUX_L = gpio1c_iomux_l | gpio1c_iomux_l_mask;

    uint32_t gpio1b_iomux_h = (0b011 << 0);
    uint32_t gpio1b_iomux_h_mask = (0b111 << 16);
    GRF_GPIO1B_IOMUX_H = gpio1b_iomux_h | gpio1b_iomux_h_mask;

    uint32_t gpio1c_iomux_h = (0b011 << 0);
    uint32_t gpio1c_iomux_h_mask = (0b111 << 16);
    GRF_GPIO1C_IOMUX_H = gpio1c_iomux_h | gpio1c_iomux_h_mask;
}

static uint16_t read_gmii(uint8_t phy_addr, uint8_t reg) {
    if (phy_addr >= 32) {
        panic("phy_addr out of bounds");
    }
    if (reg >= 32) {
        panic("phy_addr out of bounds");
    }
    while (MAC_GMII_ADDR & 0x1); // wait for Busy bit to be 0
    MAC_GMII_ADDR = (phy_addr << 11) | (0b0011 << 2) | (reg << 6) | 1;
    while (MAC_GMII_ADDR & 0x1); // wait for Busy bit to be 0
    return (uint16_t)MAC_GMII_DATA;
}

static void print_gmii_registers(uint8_t phy) {
    uart_puts("\nMII registers:");
    for (int reg = 0; reg < 32; reg++) {
        uart_printf("%d: \t%d ", reg, read_gmii(phy, reg));
    }
}

static void write_gmii() {
}

void rockpis_ethernet_init() {
    pin_init();
    reset();
    for (int phy = 0; phy < 32; phy++) {
        print_gmii_registers(phy);
    }
}
