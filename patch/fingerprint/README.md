# Fingerprint reader — Goodix `27c6:6f94`

Working: enroll and verify both succeed.

## The device

The power-button reader is a Goodix **match-on-chip** sensor on USB:

```
27c6:6f94  "Goodix USB2.0 MISC"
vendor-specific class, 2 bulk endpoints, firmware 01010106
device id UID579A0DC6_XXXX_MOC_B0
```

It is a **pure USB device and has nothing to do with the ACPI override** this
repo ships. The DSDT does contain a fingerprint node, but on the wrong bus:
`\_SB.PC00.SPI1.FPNT` is a generic SPI sensor slot for other SKUs, whose `_HID`
resolves through an EC-provided selector byte `FPTT` (FPC1011 / FPC1020 /
VFSI6101 / VFSI7500 / EGIS0300 / FPC1021). On this unit `FPTT == 0`, so `_HID`
resolves to `"DUMY0000"` and `_STA` returns 0 — the node is absent by design.

A USB device enumerates entirely from its own descriptors, so nothing was ever
missing in firmware. The only place to fix it is the USB driver.

## The fix

The sensor speaks the ordinary `goodixmoc` protocol that `libfprint` has
supported for years. It was simply not in the driver's id table: upstream
already carries `0x6984`, `0x6A94`, `0x6594` and the rest of the family, but
not `0x6F94`. Two additions cover it — the id itself, and the
`max_enroll_stage = 12` case the whole family shares:

```c
     case 0x6984:
+    case 0x6F94:
       self->max_enroll_stage = 12;
...
   { .vid = 0x27c6,  .pid = 0x6984,  },
+  { .vid = 0x27c6,  .pid = 0x6F94,  },
```

No protocol reverse-engineering, no TOD blob, no vendor driver. (Contrast the
sibling FMB-P, whose FPC `10a5:9924` needed real driver logic for an opaque
identity token — this device needs none of that.)

```sh
sudo bash patch/fingerprint/install.sh

# then as your normal user:
fprintd-enroll -f right-index-finger     # 12 touches on the power button
fprintd-verify
```

To use it for login and sudo:

- **Arch/CachyOS** — add `auth sufficient pam_fprintd.so` above the `pam_unix`
  line in `/etc/pam.d/system-local-login` and `/etc/pam.d/sudo`
- **Debian/Ubuntu** — `sudo pam-auth-update --enable fprintd`
- **Fedora** — `sudo authselect enable-feature with-fingerprint`

## Packaging matters here

On Arch/CachyOS the installer does **not** drop files into `/usr`. It derives a
package from Arch's own PKGBUILD with the patch applied in `prepare()`, bumps
`pkgrel` past the repo's so the result is unambiguously newer, and installs it
with `pacman -U`. `PKGBUILD` in this directory is the tested recipe.

This is not cosmetic. A bare `ninja install` leaves unowned files in `/usr`, and
the next `pacman -S fprintd` then fails outright:

```
error: failed to commit transaction (conflicting files)
libfprint: /usr/lib/libfprint-2.so exists in filesystem
```

because `fprintd` pulls `libfprint` in as a dependency. Letting pacman own the
files avoids that and makes the patch visible in `pacman -Qi libfprint`.

A future distro update to a **newer** `libfprint` version will still replace
it — re-run the installer then.

## Build note

`libfprint`'s `tests/meson.build` has an upstream bug in the
`introspection=false` branch that trips newer meson with

```
Foreach expects exactly 2 variables for iterating over objects of type dict
```

so the build forces `-Dintrospection=true`.

## Upstream

`0x6F94` was absent from `libfprint` master as of 2026-07-30 (checked at commit
`c4654fd`). This is a trivially reviewable id addition and should be sent
upstream; once it lands, drop the local patch and this directory.

## Verified state

```
$ pacman -Q libfprint fprintd
libfprint 1.94.100-1.2
fprintd 1.94.5-2.1

$ fprintd-list $USER
found 1 devices
Device at /net/reactivated/Fprint/Device/0
... Goodix MOC Fingerprint Sensor
```
