# PlusUltra — Migration to AMD Embedded Development Framework (EDF)

This document outlines the steps to migrate the PlusUltra project from PetaLinux 2018.2
to the AMD Embedded Development Framework (EDF), targeting the Avnet Ultra96 v1 board.

AMD has announced PetaLinux is end-of-life, with formal deprecation scheduled for the
Vivado 2026.2 release cycle. EDF is its pure Yocto Project-based replacement.

---

## Background

### Tool Versions

| Tool | Old | New |
|---|---|---|
| Vivado | 2018.2 | 2025.1 |
| Build framework | PetaLinux 2018.2 | AMD EDF (rel-v2025.1) |
| Yocto release | Rocko (2.4) | Scarthgap (5.0) |
| Linux kernel | 4.14 LTS | 6.6 LTS |
| U-Boot | 2018.01 | 2024.x |

### How EDF Works

EDF is a pure Yocto build system — no PetaLinux abstraction layer. Google `repo` syncs
~19 Yocto layers from AMD's GitHub into a workspace. The hardware integration path is:

```
Vivado → XSA export → SDTGen → gen-machine-conf → machine .conf + device tree → BitBake
```

Key layers:

| Layer | Purpose |
|---|---|
| `meta-xilinx` | Core ZynqMP SoC support (drivers, kernel, TF-A, U-Boot) |
| `meta-amd-edf` | EDF glue: init scripts, bblayers/local.conf templates |
| `meta-amd-adaptive-socs` | Eval board machine configs (Kria, ZCU104, etc.) |
| `meta-avnet` | Avnet board BSPs (Ultra96 v2, MaaXBoard, etc.) — reference only |
| `poky`, `meta-openembedded`, `meta-arm` | Standard Yocto base |

---

## Hardware: Ultra96 v1 vs v2 Differences

Both boards use the **identical SoC and package** (xczu3eg-sbva484). All EDF layer reuse
comes from this fact. The Linux-visible differences are:

| Subsystem | Ultra96 v1 | Ultra96 v2 |
|---|---|---|
| WiFi chip | TI WL1831MOD (SDIO), driver: `wlcore`/`wl18xx` | Microchip WILC3000 (SDIO), driver: `wilc` |
| Bluetooth | TI WL1831MOD via **UART0** (MIO2/MIO3), HCI-UART | Microchip WILC3000 via SDIO (same chip as WiFi) |
| Power PMICs | LTC2954 power button (MIO26 polling), simple fixed regulators | 2× Infineon IRPS5401 + 1× IR38060 (I2C PMBus, addresses 0x43/0x44/0x45) |
| LPDDR4 | Dual-die Micron (EOL) | Single-die Micron (same capacity/timings) |

Everything else — mini-DP, USB3, microSD, 40-pin 96Boards header, PCA9548 I2C mux,
Renesas clock generator — is **identical** between v1 and v2.

### BSP Reuse Assessment

**No official Ultra96 v1 BSP exists in EDF.** AMD removed `ultra96-zynqmp.conf` from
`meta-xilinx` in the scarthgap branch. Avnet's `meta-avnet` only maintains `ultra96v2.conf`.
The v1 machine configuration must be built from scratch, using the v2 as a baseline.

The existing PlusUltra project used `CONFIG_SUBSYSTEM_MACHINE_NAME="zcu100-revc"` — the
same ZCU100 revC device tree base that `ultra96v2.conf` uses — making this a close starting
point.

**Fully reusable from v2 BSP (no changes needed):**
- ARM Trusted Firmware (TF-A / BL31)
- FSBL and PMU firmware base (same SoC)
- Linux kernel binary (same SoC family)
- U-Boot base configuration
- USB, DisplayPort, SD card, I2C, SPI, GPIO drivers
- All userspace packages: Python3, SSH, GPIO tools, etc.
- Build system infrastructure (all EDF/Yocto layers)

**Requires v1-specific customization:**
- WiFi/BT device tree: restore TI WL1831 SDIO node; restore Bluetooth child node under UART0
- Power management device tree: remove Infineon PMIC nodes (0x43/0x44/0x45); restore LTC2954
- PMU firmware patch: Avnet's MIO26 power-button polling patch
- Linux firmware package: `linux-firmware-wl18xx` instead of `wilc-firmware`
- UART0 is consumed by Bluetooth on v1 — it cannot be used as a general debug UART

---

## Migration Steps

### Phase 1 — Host Setup

Requires **Ubuntu 22.04 LTS**. Ubuntu 24.04 likely works but is not officially listed for
EDF 25.05. PetaLinux (and EDF) are Linux-only; Vivado for hardware work can run on Windows
separately. Minimum disk space: ~150 GB free for the full workspace and build output.

```bash
# Yocto host dependencies
sudo apt install -y curl gawk wget git diffstat unzip texinfo gcc build-essential \
  chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils \
  iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev \
  zstd liblz4-tool lz4 python3-subunit mesa-common-dev

# Google repo tool
mkdir -p ~/bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
export PATH="$HOME/bin:$PATH"
```

---

### Phase 2 — Sync the EDF Workspace

```bash
mkdir ~/plus-ultra-edf && cd ~/plus-ultra-edf
repo init -u https://github.com/Xilinx/yocto-manifests.git \
  -b rel-v2025.1 -m default-edf.xml
repo sync
```

Clone Avnet's layer for reference (device tree fragments, machine config baseline):

```bash
git clone https://github.com/Avnet/meta-avnet sources/meta-avnet
```

> **Note:** `meta-avnet` master is oriented around PetaLinux. Do not add it to
> `bblayers.conf` directly. Use it as a reference to extract `ultra96v2.conf`,
> device tree files, and the PMU firmware patch.

---

### Phase 3 — Migrate the Vivado Block Design and Export Hardware

Open `hardware/PlusUltra/PlusUltra.xpr` in **Vivado 2025.1** (tool version must match EDF
version exactly). Vivado will trigger IP upgrade dialogs for every core in the block design.

**Critical:** After auto-upgrading IPs, manually verify the **Zynq UltraScale+ PS IP
configuration** (DDR timing, MIO assignments, clock settings). Major IP version upgrades
can reset these customizations. Regenerate the top-level HDL wrapper after all upgrades.

Then export the hardware and generate the System Device Tree (SDT):

```tcl
# In Vivado Tcl Console:
write_hw_platform -fixed -force /path/to/PlusUltra.xsa

sdtgen
set_dt_param -dir /path/to/SDT -xsa /path/to/PlusUltra.xsa
generate_sdt
exit
```

The SDT output (`system-top.dts` and companion files) describes all hardware — PS
configuration, custom AXI peripherals, clocks — and replaces the old `.hdf`-based XSCT
device tree generation.

---

### Phase 4 — Create the Custom BSP Layer

```bash
source ./edf-init-build-env    # populates build/conf/bblayers.conf + local.conf
cd build
bitbake-layers create-layer ../sources/meta-plusultra-bsp
bitbake-layers add-layer ../sources/meta-plusultra-bsp
```

Use the v2 machine config as the starting point:

```bash
mkdir -p ../sources/meta-plusultra-bsp/conf/machine
cp ../sources/meta-avnet/conf/machine/ultra96v2.conf \
   ../sources/meta-plusultra-bsp/conf/machine/ultra96v1.conf
```

Generate SDT-derived machine includes:

```bash
gen-machine-conf parse-sdt \
  --hw-description /path/to/SDT/ \
  --machine-name ultra96v1-plusultra \
  --config-dir ../sources/meta-plusultra-bsp/conf/
```

---

### Phase 5 — Adapt Machine Configuration for v1

Edit `sources/meta-plusultra-bsp/conf/machine/ultra96v1.conf`. Key changes from the v2
baseline:

```bitbake
# Remove the WILC v2 firmware version pin:
# PREFERRED_VERSION_wilc-firmware = "15.2"    <-- delete this line

# Add TI WL18xx firmware for v1 WiFi chip:
MACHINE_ESSENTIAL_EXTRA_RRECOMMENDS += "linux-firmware-wl18xx"

# Use the v1-specific U-Boot defconfig (available in mainline U-Boot):
UBOOT_MACHINE = "avnet_ultra96_rev1_defconfig"

# Keep ZCU100 revC as the kernel DT base — same as v2:
KERNEL_DEVICETREE = "xilinx/zynqmp-zcu100-revC.dtb"
```

---

### Phase 6 — Device Tree: v1-Specific Overrides

Create a `device-tree.bbappend` in
`sources/meta-plusultra-bsp/recipes-bsp/device-tree/` that applies a
`system-user-v1.dtsi`. This file makes the following changes relative to the ZCU100
revC base DT:

**Restore v1 WiFi on sdhci1 (TI WL1831 via SDIO):**

```dts
&sdhci1 {
    wifi@2 {
        compatible = "ti,wl1831";
        reg = <0x2>;
        interrupts-extended = <&gpio 76 IRQ_TYPE_EDGE_RISING>;
    };
};
```

**Restore v1 Bluetooth on UART0 (HCI-UART, MIO2/MIO3):**

```dts
&serial0 {
    bluetooth {
        compatible = "ti,wl1831-st";
        enable-gpios = <&gpio 8 GPIO_ACTIVE_HIGH>;
    };
};
```

**Power management — remove v2 Infineon PMICs, restore v1 LTC2954 power button:**

The v2 device tree adds Infineon IRPS5401/IR38060 nodes at I2C addresses 0x43, 0x44,
0x45 on `i2csw_4`. Do not include those. Instead restore the v1 power button node:

```dts
&i2c_switch_4 {
    pmic@5e {
        compatible = "lltc,ltc2954";
        /* power button connected to MIO26; polling handled by PMU firmware patch */
    };
};
```

**Add PlusUltra custom PL IP nodes** from the SDT-generated overlay: fan control PWM,
AXI GPIO, and any other custom AXI peripherals from the Vivado block design.

---

### Phase 7 — PMU Firmware Patch for v1 Power Button

The v1 requires a PMU firmware patch that polls MIO26 every 10 ms for the LTC2954
power button. The patch is available in Avnet's PetaLinux repo.

Create `sources/meta-plusultra-bsp/recipes-bsp/pmu-firmware/pmu-firmware_%.bbappend`:

```bitbake
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://0001-zynqmp_pmufw-Add-support-for-Ultra96-power-button.patch"
```

Copy the patch file from:
`https://github.com/Avnet/petalinux/blob/master/configs/meta-user/ultra96v1_full/recipes-bsp/pmu-firmware/files/`

into `sources/meta-plusultra-bsp/recipes-bsp/pmu-firmware/files/`.

---

### Phase 8 — Port the Fan Control Application

Port the existing `Ultra96FanControl` submodule as a BitBake recipe. Since it uses GPIO,
no kernel changes are needed — just a standard autotools or CMake recipe.

Create `sources/meta-plusultra-bsp/recipes-apps/plusultra-fan-control/`:

```bitbake
# plusultra-fan-control.bb
SUMMARY = "PlusUltra fan control for Ultra96 v1"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "..."

SRC_URI = "git://..."
# ... standard cmake/autotools recipe boilerplate ...

inherit cmake
```

---

### Phase 9 — Image Recipe

Create `sources/meta-plusultra-bsp/recipes-core/images/plusultra-image.bb` to reproduce
the feature set of the original PetaLinux project:

```bitbake
require recipes-core/images/core-image-minimal.bb

IMAGE_INSTALL:append = " \
    openssh \
    openssh-sftp-server \
    python3 \
    python3-pip \
    libgpiod \
    libgpiod-tools \
    usbutils \
    plusultra-fan-control \
"

# Enable serial console on ttyPS0 (UART1 — UART0 is used by Bluetooth on v1)
SERIAL_CONSOLES = "115200;ttyPS1"
```

---

### Phase 10 — Configure and Build

Set the machine in `build/conf/local.conf`:

```
MACHINE = "ultra96v1-plusultra"
DISTRO ?= "edf-linux"
```

Then build:

```bash
bitbake plusultra-image
```

Build output in `build/tmp/deploy/images/ultra96v1-plusultra/`:

| File | Contents |
|---|---|
| `BOOT.BIN` | FSBL + PMU firmware + TF-A (BL31) + U-Boot |
| `fitImage` | Linux kernel + DTB |
| `rootfs.ext4` / `rootfs.wic` | Root filesystem |

Flash to SD card: FAT32 partition for `BOOT.BIN` + `fitImage`, ext4 partition for rootfs.

---

## Boot Flow

The EDF build produces a modern ZynqMP boot sequence with TF-A as a mandatory stage —
this is the standard for all supported tool versions from ~2020 onward:

```
ROM → FSBL → PMU Firmware → TF-A (BL31) → U-Boot → Linux
```

The old 2018.2 `BOOT.BIN` format did not include TF-A. The new format and BIF structure
are handled automatically by the EDF build.

---

## Effort Summary

| Work Item | Source | Effort |
|---|---|---|
| EDF workspace setup | AMD docs / `yocto-manifests` | Low |
| Vivado block design migration (2018.2 → 2025.1) | Manual IP upgrade + verification | Medium |
| XSA export + SDT generation | Vivado Tcl | Low |
| Custom BSP layer skeleton | `gen-machine-conf` + v2 baseline | Low |
| Machine conf v1 adaptations | From v2 | Low |
| Device tree: WiFi/BT/PMIC v1 nodes | Historical v1 DTs + schematics | Medium |
| PMU firmware power-button patch | Avnet petalinux repo | Low |
| Fan control app BitBake recipe | Port from existing source | Low |
| **Total** | | **~1–2 focused weeks** |

The biggest unknown is the state of `meta-avnet` relative to the EDF/pure-Yocto workflow.
If it still assumes a PetaLinux environment, do not attempt to use it as a live layer —
extract the needed files and build `meta-plusultra-bsp` cleanly from those ingredients.

---

## Key References

- [AMD EDF Overview](https://www.amd.com/en/products/software/adaptive-socs-and-fpgas/embedded-software/embedded-development-framework.html)
- [AMD EDF Wiki](https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/3250585601/AMD+Embedded+Development+Framework+EDF)
- [EDF Getting Started — ZynqMP](https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/3268149250/AMD+EDF+Getting+started+-+Operating+System+Integration+and+Development+AMD+ZynqMP+device+portfolio)
- [PetaLinux to EDF Migration Guide](https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/3467935747/PetaLinux+to+EDF+Migration+Guide)
- [GitHub: Xilinx/yocto-manifests](https://github.com/Xilinx/yocto-manifests)
- [GitHub: Xilinx/meta-amd-edf](https://github.com/Xilinx/meta-amd-edf)
- [GitHub: Xilinx/gen-machine-conf](https://github.com/Xilinx/gen-machine-conf)
- [GitHub: Avnet/meta-avnet](https://github.com/Avnet/meta-avnet)
- [GitHub: Avnet/petalinux (Ultra96 v1 configs)](https://github.com/Avnet/petalinux)
