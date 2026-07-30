# Patched SSDT27 — touchpad, touchscreen, internal keyboard

**This is the prerequisite fix.** Without it the machine is barely usable under
Linux: the touchpad does not enumerate, and the internal keyboard misbehaves.
Everything else in `patch/` is independent of it.

Applied by `apply_patch.sh` in the repository root — you normally do not invoke
anything here directly.

## What is wrong in the firmware

The touchpad is a Goodix **TOPS0102** on `\_SB.PC00.I2C1.TPD0` (I²C HID, address
`0x5D`), described in `SSDT27` (`OEM Table ID "I2C_DEVT"`).

Inside the device's resource scope the firmware executes

```asl
CreateWordField (SBGF, 0x17, INT1)
INT1 = GNUM (0x001A088A)          // <-- at table-load time, in device scope
```

The `GNUM()` call — which resolves a GPIO pin number into the interrupt
descriptor of the resource buffer — is placed at **table-load time** rather than
inside an initialisation method. Windows' AML interpreter tolerates this;
Linux's ACPICA evaluates the scope differently and the interrupt number never
gets patched into the descriptor, so the touchpad is never wired to a working
IRQ and `i2c_hid` finds nothing.

## What the patch changes

Two edits, both in `SSDT27_TPD0.dsl`:

1. **Move the `GNUM()` call into a proper `_INI` method**, so it runs as device
   initialisation instead of at table load:

   ```asl
   Method (_INI, 0, NotSerialized)
   {
       INT1 = GNUM (0x001A088A)
   }
   ```

2. Normalise a package of raw byte constants to named ASL constants
   (`0x01`/`0x00` → `One`/`Zero`). Cosmetic; a by-product of the
   disassemble/recompile round trip, semantically identical.

The table header's OEM Revision is bumped `0x1000` → `0x2000` so the override is
distinguishable from the stock table at a glance.

## How it is applied

`apply_patch.sh` installs the compiled table and an initramfs hook:

```
patch/acpi-override/SSDT27_TPD0.aml     -> /usr/lib/firmware/acpi/SSDT27_TPD0.aml
patch/acpi-override/acpi_override.install -> /etc/initcpio/install/acpi_override
```

then adds `acpi_override` to `HOOKS=` in `/etc/mkinitcpio.conf` (right after
`autodetect`) and regenerates the initramfs. The kernel loads the override table
early, before the ACPI namespace is built.

It also appends **`i8042.dumbkbd=1`** to the kernel command line, which the
internal keyboard needs. That has one known side effect: it disables atkbd's
`SET_LEDS` path, so the **Caps Lock LED stays dark**. The keyboard itself works.

`uninstall_patch.sh` reverts all of it.

## Rebuilding the table

`SSDT27_TPD0.aml` is generated from the `.dsl`:

```sh
bash build/build_patch.sh
```

`reference/` holds the untouched `SSDT27_orig.dsl` / `.aml` and `ssdt27.patch`,
the diff between stock and patched sources — useful when a BIOS update changes
the table and the edits have to be re-derived.

`build/extract_oem_acpi.sh` dumps the machine's own ACPI tables, which is where
you start after any firmware update.

## If a BIOS update breaks this

Re-dump the tables, disassemble `SSDT27`, and re-apply the `_INI` change by
hand — match on the method and object names, not on line numbers, since those
drift between firmware revisions. The current tables were taken from BIOS 1.09.
