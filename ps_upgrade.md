# Zynq UltraScale+ PS IP Configuration — Upgrade Reference

When opening the PlusUltra block design in Vivado 2025.1, the Zynq UltraScale+ PS IP
will be upgraded from v3.2 (2018.2) to the current version. Major IP version upgrades
reset all customization to defaults. This document records the original settings and
explains how to restore them.

---

## Why the Configuration Is Lost

The PS IP undergoes major version increments between Vivado releases. When Vivado
upgrades a major IP version it cannot safely merge the old parameter schema into the new
one, so it resets to defaults. This affects DDR timing, MIO pin assignments, PLL
settings, and peripheral enables — everything configured in the PS customization wizard.

---

## Preventive Measure: Export Tcl Before Upgrading

The safest approach is to capture the full block design as a Tcl script in
**Vivado 2018.2, before opening the project in 2025.1**. This records every PS setting
as readable `set_property CONFIG.*` calls.

```tcl
# Run in Vivado 2018.2 Tcl console with the project open:
open_bd_design [get_files PlusUltra.bd]
write_bd_tcl -force /path/to/PlusUltra_bd_backup.tcl
```

The output contains lines like:

```tcl
set_property -dict [list \
  CONFIG.PSU__CRF_APB__ACPU_CTRL__FREQMHZ {1200} \
  CONFIG.PSU__CRF_APB__DDR_CTRL__FREQMHZ  {533}  \
  CONFIG.PSU__UART0__PERIPHERAL__ENABLE    {1}    \
  ...
] [get_bd_cells zynq_ultra_ps_e_0]
```

In Vivado 2025.1, after IP upgrade, run this script (with any edits needed for renamed
parameters) in the Tcl console to restore the entire configuration automatically.

---

## Original Configuration Reference

All values below are extracted from `PlusUltra_zynq_ultra_ps_e_0_0.xci` (IP v3.2,
Vivado 2018.2). The XCI file in git is the authoritative source of truth.

### Clocks and PLLs

| Setting | Value | Source |
|---|---|---|
| CPU (ACPU) | 1200 MHz | APLL — FBDIV=72, DIV2=1 |
| DDR clock (target) | 533 MHz | DPLL — FBDIV=64, DIV2=1, DIVISOR0=4 |
| DDR clock (actual) | 533.332825 MHz | — |
| DisplayPort video ref | 300 MHz | VPLL — DIVISOR0=4, fractional enabled |
| DisplayPort audio ref | 24.576 MHz | RPLL — DIVISOR0=16, fractional enabled |
| GDMA / DPDMA | 600 MHz | APLL — DIVISOR0=2 |
| PS reference clock | 33.333 MHz | PSS_REF_CLK |

### DDR Memory

| Setting | Value |
|---|---|
| Size | 2 GB |
| High address | 0x7FFFFFFF |
| Low address | 0x00000000 |
| Type | LPDDR4 |
| I/O standard (all banks) | LVCMOS18 |

### SD Controllers

| Setting | Value |
|---|---|
| SD0 bus width | 4-bit |
| SD1 bus width | 4-bit |

### MIO Pin Assignment

| MIO | Peripheral | Signal |
|---|---|---|
| 0 | UART1 | txd |
| 1 | UART1 | rxd |
| 2 | UART0 | rxd (Bluetooth HCI on v1) |
| 3 | UART0 | txd (Bluetooth HCI on v1) |
| 4 | I2C1 | scl |
| 5 | I2C1 | sda |
| 6 | SPI1 | sclk |
| 7 | GPIO0 | gpio[7] |
| 8 | GPIO0 | gpio[8] |
| 9 | SPI1 | n\_ss\_out[0] |
| 10 | SPI1 | miso |
| 11 | SPI1 | mosi |
| 12 | GPIO0 | gpio[12] |
| 13 | SD0 (microSD) | data[0] |
| 14 | SD0 (microSD) | data[1] |
| 15 | SD0 (microSD) | data[2] |
| 16 | SD0 (microSD) | data[3] |
| 17 | GPIO0 | gpio[17] |
| 18 | GPIO0 | gpio[18] |
| 19 | GPIO0 | gpio[19] |
| 20 | GPIO0 | gpio[20] |
| 21 | SD0 (microSD) | cmd |
| 22 | SD0 (microSD) | clk |
| 23 | GPIO0 | gpio[23] |
| 24 | SD0 (microSD) | cd\_n |
| 25 | GPIO0 | gpio[25] |
| 26 | PMU GPI0 | gpi[0] — LTC2954 power button |
| 27 | DPAUX | dp\_aux\_data\_out |
| 28 | DPAUX | dp\_hot\_plug\_detect |
| 29 | DPAUX | dp\_aux\_data\_oe |
| 30 | DPAUX | dp\_aux\_data\_in |
| 31 | GPIO1 | gpio[31] |
| 32 | PMU GPO | gpo[0] |
| 33 | PMU GPO | gpo[1] |
| 34 | PMU GPO | gpo[2] |
| 35 | GPIO1 | gpio[35] |
| 36 | GPIO1 | gpio[36] |
| 37 | GPIO1 | gpio[37] |
| 38 | SPI0 | sclk |
| 39 | GPIO1 | gpio[39] |
| 40 | GPIO1 | gpio[40] |
| 41 | SPI0 | n\_ss\_out[0] |
| 42 | SPI0 | miso |
| 43 | SPI0 | mosi |
| 44 | GPIO1 | gpio[44] |
| 45 | GPIO1 | gpio[45] |
| 46 | SD1 (WiFi SDIO) | data[0] |
| 47 | SD1 (WiFi SDIO) | data[1] |
| 48 | SD1 (WiFi SDIO) | data[2] |
| 49 | SD1 (WiFi SDIO) | data[3] |
| 50 | SD1 (WiFi SDIO) | cmd |
| 51 | SD1 (WiFi SDIO) | clk |
| 52–63 | USB0 | full ULPI |
| 64–75 | USB1 | full ULPI |

---

## Restoring Configuration in Vivado 2025.1

### Option A — Tcl script (preferred)

If you exported `PlusUltra_bd_backup.tcl` from 2018.2 before upgrading, paste the
`set_property -dict` block from that file into the Vivado 2025.1 Tcl console. Most
parameter names are stable across versions. Renamed parameters will produce a warning;
look them up in the new IP customization GUI.

### Option B — GUI, page by page

Open the PS IP customization wizard and work through each page:

1. **PS-PL Configuration**
   - Enable `M_AXI_HPM0_LPD` — this master port is used and clocked by `clk_wiz_0`
     at 100 MHz

2. **I/O Configuration → MIO**
   - Re-enter the full pin table from the MIO section above
   - All banks: LVCMOS18
   - UART0 on MIO2/3, UART1 on MIO0/1
   - SD0 on MIO13–16/21/22/24, SD1 on MIO46–51
   - USB0 on MIO52–63, USB1 on MIO64–75
   - PMU GPI0 on MIO26 (power button)
   - DPAUX on MIO27–30

3. **Clock Configuration**
   - CPU: 1200 MHz (APLL)
   - DDR: 533 MHz (DPLL)
   - DP video: 300 MHz (VPLL, fractional on)
   - DP audio: 24.576 MHz (RPLL, fractional on)

4. **DDR Configuration**
   - Type: LPDDR4
   - Size: 2 GB (address range 0x00000000–0x7FFFFFFF)

### Verification

After saving the configuration, run the following in the Tcl console to confirm the DDR
frequency was applied correctly:

```tcl
get_property CONFIG.PSU__ACT_DDR_FREQ_MHZ [get_bd_cells zynq_ultra_ps_e_0]
# Expected: 533.3...
```

Then regenerate the top-level HDL wrapper:

```tcl
make_wrapper -files [get_files PlusUltra.bd] -top
```

---

## Notes

- **UART0 (MIO2/3) is used for Bluetooth HCI** on the Ultra96 v1. It is not available
  as a general-purpose debug UART. The console UART is UART1 (MIO0/1), which connects
  to the JTAG/console header.
- **MIO26 (PMU GPI0)** is the power button input from the LTC2954 controller. It
  requires the Avnet PMU firmware patch to function — see `EDF-MIGRATION.md`, Phase 7.
- All settings here apply to the **Ultra96 v1**. The v2 differs in WiFi/BT peripheral
  assignment (WILC3000 uses SDIO only, no Bluetooth UART) and power management
  (Infineon PMICs instead of LTC2954).
