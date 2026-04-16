# Why Upgrade: PlusUltra 2018.2 → 2025.1

This document summarises the key capabilities gained by migrating from the 2018.2 tool
generation (Vivado / PetaLinux) to the 2025.1 generation (Vivado ML / AMD EDF), beyond
simply being more current. All points are specific to the xczu3eg on Ultra96 v1.

---

## Display: Proper Mainline DRM/KMS Driver

The biggest single functional improvement for the Ultra96. In kernel 4.14 the ZynqMP
DisplayPort driver lived only in Xilinx's out-of-tree kernel fork as a non-KMS,
non-compositing driver. The `zynqmp-dpsub` DRM/KMS driver is now **in mainline Linux
6.6**, backed by the `xilinx-dpdma` engine driver.

**What this enables:**
- Full atomic modesetting — compatible with Wayland compositors
- PL video plane integration: overlay compositing from PL-sourced DMA buffers
- ALSA audio output via DisplayPort
- Standard `modetest`, X11, and Wayland compositor support without out-of-tree patches

The workarounds in the 2018.2 project for DP limitations become unnecessary.

---

## Runtime FPGA Programming from Linux

In kernel 4.14, programming the PL from a running Linux system was unreliable and
required either FSBL or Xilinx out-of-tree patches. In kernel 6.6, the **FPGA Region /
FPGA Bridge / Device Tree Overlay** framework is fully mainlined:

```
write bitstream path → /sys/class/fpga_manager/fpga0/firmware
apply DT overlay     → /sys/kernel/config/device-tree/overlays/
```

The kernel programs the PL and adds the new device tree nodes atomically. This also
supports **authenticated and encrypted bitstreams** loaded directly from Linux — which
previously required FSBL intervention. **Partial Reconfiguration (DFX)** via child FPGA
regions is also supported end-to-end for the first time.

---

## Vivado: ML-Based Timing Closure

**Intelligent Design Runs (IDR)**, introduced in Vivado 2021.1, are the most impactful
daily workflow improvement for hardware development:

- ML-based delay estimation accuracy: ~65% (2018.2) → ~98% (2025.1)
- IDR automatically explores implementation strategies guided by internal models,
  replacing manual trial-and-error with `Performance_ExplorePostRoutePhysOpt` etc.
- Claimed average improvement: **~10% better worst negative slack**, **~5× faster**
  compile when exploring strategies in parallel via Abstract Shell
- **Incremental compile** is also substantially more reliable — a design change touching
  ≤5% of cells now reliably preserves placement and routing for unchanged logic,
  giving roughly **3× faster iteration** during IP development

On a timing-constrained xczu3eg-1 (commercial speed grade), both improvements are
directly relevant.

---

## U-Boot: Persistent Environment and Field Updates

The 2018.2 README documents the inability to save the U-Boot environment to SD card.
**`CONFIG_ENV_IS_IN_FAT=y` has been stable since U-Boot 2019.07** — this is simply
fixed, requiring no workaround.

Beyond that, three new update mechanisms are available:

| Mechanism | What it provides |
|---|---|
| **FWU Multi-Bank Update** | A/B boot banks for U-Boot, TF-A, and the FIT kernel image; automatic rollback if new firmware fails to boot three times |
| **EFI Capsule Update** | Drop a signed `.cap` file to the FAT partition; U-Boot applies it on next boot — no JTAG or serial console required |
| **FIT image signatures** | RSA public key embedded in U-Boot; a tampered kernel is rejected before executing a single instruction |

---

## Power Management: Actually Works

Two things that were broken or explicitly worked around in 4.14 are resolved in 6.6:

**Suspend-to-RAM** (`echo mem > /sys/power/state`) works correctly. In 4.14 on Ultra96,
suspend was flaky because PM domain support for ZynqMP peripherals was incomplete. In
6.6, `genpd` PM domain integration means SDHCI, USB, and DisplayPort peripherals
properly gate their power islands through PMUFW on suspend.

**CPU frequency scaling** — the 2018.2 kernel config explicitly sets
`CONFIG_CPU_FREQ=n` as a stability workaround. That instability is resolved. The A53
cores can now run at lower frequencies under light load, which is directly relevant to
thermal management and the on-board fan control system.

---

## Hardware Security: Open Toolchain

The ZynqMP security hardware (RSA-4096, AES-256 GCM, SHA-3, PUF, eFUSE) is unchanged
in silicon — it was present in 2018.2. What improved is the tooling:

- **Bootgen 2025.1** supports PKCS#11 HSM integration: the RSA signing key never needs
  to exist on the build machine; it lives in a hardware security token
- **SPK revocation tables** via eFUSE bits enable key rotation without reflashing the
  entire device
- **Authenticated bitstream loading from Linux**: previously required FSBL; now handled
  by the mainline FPGA manager

---

## SDR and DSP Performance

**GCC 7.2 → 13.2**: AArch64 NEON auto-vectorisation is substantially better. DSP
kernels looping over float arrays will be faster without any source changes. Link-time
optimisation (LTO) is also more stable and produces measurably smaller binaries.

**io_uring** (not present in 4.14): A userspace SDR application reading from a DMA
buffer can submit async DMA reads without a syscall per transfer — directly relevant to
VFIO-based DMA throughput.

**eBPF with ARM64 JIT**: Runtime packet filtering and syscall tracing without kernel
recompilation. Useful for debugging AXI DMA transfer timing from userspace.

---

## OTA Updates: Production-Grade Options

The 2018.2 / Rocko Yocto baseline had no viable over-the-air update story. Scarthgap
has three well-supported options:

**RAUC** (recommended starting point)
- A/B atomic rootfs + bootloader updates with cryptographic bundle signing
- dm-verity rootfs integrity: any modification detected at block-read time
- Integrates with the open-source Hawkbit update server for fleet management
- Production-used at scale (e.g. Valve Steam Deck)

**Mender**
- Complete A/B update client with Lua scripting for coordinated rootfs + FPGA bitstream
  updates in a single atomic transaction
- Hosted or self-hosted server

**EFI Capsule** (lighter weight)
- SD-card-delivered signed updates without a server
- Suitable for bench and lab use; no rollback

---

## Software Ecosystem

| Component | 2018.2 (Rocko) | 2025.1 (Scarthgap) |
|---|---|---|
| Linux kernel | 4.14 LTS | 6.6 LTS |
| GCC | 7.2 | 13.2 |
| glibc | 2.26 | 2.39 |
| Python | 3.5 | 3.12 |
| OpenSSL | 1.0.2 (EOL) | 3.2 |
| systemd | 235 | 255 |
| Rust | External layer, manual | In `openembedded-core`; `inherit cargo` works natively |
| Containers | None | Podman (rootless OCI) via `meta-virtualization` |
| CVE scanning | None | Built-in `cve-check` against NVD database |

**Python 3.12** brings a 10–60% interpreter speedup (from 3.11 onwards), modern
language features (`match`/`case`, exception groups, self-documenting f-strings), and a
functional `pip` in the image. Current NumPy, SciPy, and GNURadio recipes are available
in `meta-openembedded`.

**Rust** is now a first-class Yocto citizen. Writing a high-performance DSP core in
Rust and exposing it to Python via PyO3/maturin is straightforward within the normal
build — no external layers or manual toolchain downloads required.

---

## Developer Workflow: CI Without Vivado

The old HDF flow required XSCT (Xilinx's proprietary Tcl tool, bundled with Vivado) to
generate device trees — meaning the CI pipeline needed a Vivado installation and
licence just to build the Linux image.

The new SDT flow uses **`sdtgen`** and **`gen-machine-conf`**, which are open-source
Python tools. A CI runner that builds the Linux image no longer needs Vivado at all.

The **Lopper** tool also replaces hand-maintained OpenAMP device tree overlays. Given
the System Device Tree output from `sdtgen`, Lopper automatically generates
per-domain device trees for Linux and R5 bare-metal firmware from the same source,
without manual `.dtsi` authoring.

**OpenOCD 0.12.0** (released 2023) gained full ZynqMP support, including cross-trigger
matrix access to all four A53 cores and both R5 cores. Open-source JTAG debugging no
longer requires Xilinx's proprietary `xsdb`.

---

## Summary

| Area | Key Gain |
|---|---|
| **Display** | Mainline ZynqMP DRM/KMS — Wayland-capable without out-of-tree patches |
| **FPGA manager** | Runtime PL reprogramming from Linux, including authenticated bitstreams |
| **Vivado IDR** | ~10% better timing, ~5× faster implementation exploration on xczu3eg-1 |
| **U-Boot** | Persistent environment (known 2018.2 deficiency fixed); A/B rollback; EFI capsule update |
| **Power management** | Suspend-to-RAM works; dynamic CPU frequency scaling works |
| **Security toolchain** | PKCS#11 HSM signing; SPK revocation; Linux-side authenticated bitstream loading |
| **OTA updates** | RAUC / Mender / EFI Capsule — production-grade A/B update with rollback |
| **DSP performance** | GCC 13 NEON auto-vectorisation; io_uring async DMA; eBPF tracing |
| **CI pipeline** | `sdtgen` is open-source Python — no Vivado licence required to build Linux images |
| **Rust** | Native Yocto support; high-performance DSP modules without external layers |
