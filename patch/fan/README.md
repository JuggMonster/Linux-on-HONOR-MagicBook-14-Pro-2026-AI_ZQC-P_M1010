# Fan RPM readout — `honor-zqcp-hwmon`

Read-only. Fan **control is not possible** on this machine; see below.

## The problem

Out of the box the laptop appears to have no fan sensor at all. The ACPI fan
participant (`INTC10D6`, hwmon `acpi_fan`) does register a `fan1_input`, but
reading it returns `-ENODEV` because the firmware's `_FST` is a stub. At idle
from a cold boot the fans are genuinely stopped, which reinforces the
impression that they do not work.

## The fix

The real tachometers live in EC RAM as two 16-bit little-endian words,
reachable over the standard ACPI EC interface:

```
0x2C/0x2D -> fan 0        0x2E/0x2F -> fan 1
```

`honor-zqcp-hwmon.c` is a small DMI-gated module (`HONOR` / `ZQC-P`) that reads
them via `ec_read()` and exposes `fan1_input` / `fan2_input` under the chip name
`honor_zqcp`, so `sensors`, `btop` and desktop widgets show fan RPM.

```sh
sudo bash patch/fan/install.sh
sensors        # look for "honor_zqcp-isa-0000"
```

Uses DKMS when available so it survives kernel updates. Accepts `KVER=...` to
pre-build for an installed-but-not-yet-booted kernel.

## Measured behaviour

On AC, `platform_profile=performance`, AVX FMA load. `EC-CPU` is the EC's own
CPU temperature byte (ECF0 `0x10`), which runs a few degrees above the
`coretemp` package reading:

| EC-CPU | fan 0 | fan 1 | |
|---|---|---|---|
| 49 °C (idle, cold boot) | 0 | 0 | genuinely stopped |
| 51-68 °C | 0 | 0 | still stopped under load |
| **72 °C** | **2355** | **1913** | **engagement point** |
| 79 °C | 2379 | 2136 | |
| 84 °C | 2455 | 2373 | |
| 89 °C | 3656 | 3276 | clearly audible |

**Long spin-down hysteresis.** After load stops the fans briefly rise *further*
(2859 / 2468 while soak heat is dumped), then step down slowly — still turning
at ~2450 / ~2130 a minute later at 48 °C, settling on a 2281 / 2003 plateau
that persists for a long while. A non-zero reading at low temperature means
"recently under load", not "idle speed".

The module rejects reads above 20000 rpm: the EC updates these bytes while we
sample them and torn reads do occur (35294 rpm was seen once during a spin-up
transient).

## Why control is not available

Every OS-side path was tested on hardware and the EC ignores all of them:

- **`\SFNS`** (WMI manual fan duty) is gated on the EC's `MFGM` master flag,
  and no AML path anywhere in the firmware ever sets `MFGM` — it reads `0x00`
  in every state observed. `\SFNM` writes `FWMD` without any gate and the write
  *does* land (values 1, 2, 3, 8, 0x0a all read back), but `MFGM` stays 0.
- **DPTF fan participant `TFN1`** (`INTC10D6`,
  `/sys/class/thermal/cooling_device0`, `max_state` 50) accepts `cur_state`
  writes with no effect — driving 0 → 50 produced zero change in either
  tachometer over 8 s at a steady 47 °C.
- **The five ACPI `Fan` objects** (`PNP0C0B`, `cooling_device1..5`, each
  `max_state` 1) likewise accept `cur_state = 1` and do nothing.
- **`acpitz`**, the thermal zone carrying the 40/45/50/55 °C active trip
  points, reports a constant 10 °C, so those trips can never fire. The `TCPU`
  zone's active trips all sit at 103-109 °C, above the 97 °C throttle target,
  so they never fire either.

`F0PD`/`F1PD` (ECF5 `0x3B`/`0x3C`) are the genuine PWM duty registers and
`F0EN`/`F1EN` (`0x3A`) the enable bits — both are only ever *read* from AML,
never written. They do mirror real EC state: idle with fans stopped reads
`EN=0, PD=32`; running while cooling reads `EN=1, PD=37/36`.

### Why 97 °C under sustained load is normal

Tjmax is 100 °C and the firmware sets a TCC offset of 3, so the silicon
throttle target is 97 °C. The EC's job is to stay under that, not to keep the
chip cool, and it spends the headroom on silence. If you want a lower ceiling,
`/sys/class/thermal/cooling_device24/cur_state` (TCC Offset) is writable — an
offset of 25 held the package at 71-73 °C instead of climbing toward 97 °C.
That is not better cooling, though: it throttles the CPU earlier. The value
resets to 3 on every boot.

### Why Windows behaves differently

HONOR PC Manager runs a userspace loop that polls temperatures every ~200 ms
and writes EC fields (`SVRF` / `SPPM`) to widen the thermal envelope, so the EC
starts spinning the fans much earlier, around 55 °C. Nothing equivalent exists
in mainline `huawei-wmi`, so the EC keeps its conservative default profile.
Under Linux the machine is quieter and throttles earlier.

Intel RAPL package power is firmware-capped at **50 W**, not the 88 W the
`intel_rapl` constraints advertise. The cap is enforced by the EC through the
`VCCC` register, not by RAPL. Per-core clocks under sustained load settle
around 3.3 GHz.

## EC register map

Source of truth: `win11_dump/OEM/SSDT21.dsl` (method `WMAA`) and
`win11_dump/OEM/DSDT.dsl` (the EC `OperationRegion` definitions).

| Field | Region | Offset | Meaning |
|---|---|---|---|
| `FA0L`+`FA0R` / `FA1L`+`FA1R` | ECF0 @ `0xFE0B0000` | `0x2C-0x2D` / `0x2E-0x2F` | per-fan tachometer, 16-bit little-endian RPM, read-only |
| `MFGM` | ECF0 | `0x0F` bit 0 | master manual-fan enable. Not writable from ASL, only the EC sets it |
| `F0EN` / `F1EN` | ECF5 @ `0xFE0B0500` | `0x3A` | per-fan enable bits, read-only from AML |
| `F0PD` / `F1PD` | ECF5 | `0x3B` / `0x3C` | per-fan PWM duty. Written by `SFNS`, but only when `MFGM == 1` |
| `FWMD` | ECF5 | `0x31` | fan working mode. Written by `SFNM`, ungated, but has no effect while `MFGM == 0` |
| `SCPM` | ECF5 | `0x32` | system CPU performance mode. Written by `SPPM`; accepts 0-3 with no observable effect on PL1 or clocks |
| `VCCC` / `VCCG` / `VCCS` / `VCCL` | ECF6 @ `0xFE0B0600` | `0x20-0x23` | per-rail power limits, 1..51 W, `0xFF` unlocks. Written by `SVRF` |
| `PPL4` | ECF6 | `0x24` | power limit 4, peak. Written by `SVRF` |

`ECF0`, the first 256 bytes of EC RAM, is reachable through the standard ACPI
EC interface: `sudo modprobe ec_sys`, then read `/sys/kernel/debug/ec/ec0/io`.
`ECF5` / `ECF6` / `ECF7` are extended banks that interface cannot see; they need
`/dev/mem` mmap or an ACPI method call through `acpi_call`.

The one remaining lever nobody has pulled is indirect: a daemon that polls
temperatures and lowers `VCCC` through `SVRF` (MFID `0x07`, SFID `0x0F`) so the
EC decides to cool harder. Unwritten.

## Note on an earlier misreading

Older revisions of this repo described `FA0L`/`FA1L` as "PWM duty 0..255" and
`FA0R`/`FA1R` as status flags. That was wrong. The DSDT declares each
tachometer as two named 8-bit fields, which made the low byte look like a duty
value and the high byte like a flag. The firmware itself treats them as a
pair — `\GFNS` copies `FA0L` and `FA0R` into two adjacent buffer bytes for the
caller to combine. A load test settles it: the pair reads 0/0 with the fans
stopped and 2355/1913 the instant they engage, which no single duty byte can
hold.

## Reproducing the measurements

Bash busy-loops and `openssl speed` across all threads do **not** meaningfully
heat this Panther Lake part — the package stayed at 50 °C under 16 threads. A
tight AVX FMA loop built with `-O3 -march=native`, one process per core, on AC
with `platform_profile=performance`, reaches 85 °C in about 80 seconds.
