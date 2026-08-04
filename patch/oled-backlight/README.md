# OLED minimum brightness

| | |
|---|---|
| Symptom | at 0% the panel is dim, tinted and blotchy; the first brightness step triples the light output |
| Cause | the VBT declares a minimum of 6/255, which this OLED does not render evenly |
| Fix | feed the driver a VBT with a higher minimum |
| Needs | a reboot, no kernel rebuild, no module |

## What is actually going on

`intel_backlight` does not pass the sysfs value to the hardware. i915 and xe
map the user range `[0..max_brightness]` onto `[pwm_level_min..pwm_level_max]`:

```c
/* drivers/gpu/drm/i915/display/intel_backlight.c */
static u32 scale_user_to_hw(struct intel_connector *connector,
			    u32 user_level, u32 user_max)
{
	return scale(user_level, 0, user_max,
		     panel->backlight.min, panel->backlight.max);
}

static u32 get_backlight_min_vbt(struct intel_connector *connector)
{
	min = clamp_t(int, connector->panel.vbt.backlight.min_brightness, 0, 64);
	/* vbt value is a coefficient in range [0..255] */
	return scale(min, 0, 255, 0, panel->backlight.pwm_level_max);
}
```

`panel->backlight.max` is the `BXT_BLC_PWM_FREQ` register, 704 on this machine,
which is where `max_brightness` comes from. `panel->backlight.min` is the VBT
coefficient scaled into the same units.

The VBT on this unit, block 43 (`BDB_LFP_BACKLIGHT`), parsed with
[`vbt-min.py`](vbt-min.py):

| field | value |
|---|---|
| VBT version | 266 |
| panel_type | 2 |
| control method | 2, DDI native PWM, controller 0 |
| PWM frequency | 200 Hz, active high |
| `brightness_precision_bits[2]` | 8 |
| `brightness_level[2]` | 35/255 = 13.7%, the factory default level |
| **`brightness_min_level[2]`** | **6/255 = 2.35%** |

`brightness_level` is 255 in all sixteen slots except slot 2, which confirms
which slot describes the fitted panel.

So `pwm_level_min = round(6 * 704 / 255) = 17`, and the real mapping is:

| desktop shows | sysfs value | PWM duty |
|---|---|---|
| 0% | 1 | 18/704 = **2.6%** |
| 5% | 35 | 51/704 = 7.2% |
| 10% | 70 | 85/704 = 12.1% |
| 20% | 141 | 155/704 = 22.0% |
| 100% | 704 | 100% |

Desktops write 1 rather than 0 at their bottom end, and they are right to.
Writing 0 does not select the lowest level, it switches the panel off:

```c
/* intel_backlight_device_update_status() */
if (panel->backlight.enabled) {
	if (panel->backlight.power) {
		bool enable = bd->props.power == BACKLIGHT_POWER_ON &&
			bd->props.brightness != 0;
		panel->backlight.power(connector, enable);
	}
}
```

The scaling still happens, the hardware gets 17/704, and then the panel is
powered down by a separate signal. Verified here: `echo 0` blanks the screen
completely, `echo 1` leaves it dim and visible.

Two consequences, and both of the complaints people have about this panel fall
out of them:

* "0%" is not near zero, it is exactly the minimum HONOR declared in firmware.
  The panel does not render that duty evenly, hence the colour cast and the
  blotches.
* the first step of a linear 20 step scale goes from 2.41% to 7.24%, a **3.0x**
  jump in light output. The steps after it are 1.67x, 1.41x, 1.29x. The scale
  is uniform in raw units and wildly non-uniform in perceived brightness,
  purely because the bottom of the range is clipped by that floor.

## The fix

Raise the one VBT value. Both drivers can take the VBT from a file:

```
xe.vbt_firmware=honor/zqc-p-vbt.bin
```

`firmware_get_vbt()` runs the blob through `intel_bios_is_valid_vbt()` and
falls back to the firmware's own copy on any failure, so a bad or missing file
means stock behaviour rather than a dark screen. The validation checks the
`$VBT` signature and that the sizes are consistent, nothing else. The checksum
is never verified, and the factory blob does not sum to zero over any plausible
range, so byte 26 is deliberately left as the OEM wrote it.

The change is two bytes: `brightness_min_level[2]`, and the legacy per-entry
`min_brightness` byte which is unused at VBT >= 234 but kept consistent.

Raising the floor rescales the whole slider instead of clipping it, so it
improves the step distribution as well.

## Measured on the reference unit

Stepped through the bottom of the range on a flat grey background, reading the
panel by eye at each level:

| PWM duty | sysfs | VBT value | result |
|---|---|---|---|
| 2.41% | 0 | 6/255 | screen off (the `brightness == 0` special case, not a level) |
| 2.56% | 1 | 7/255 | lit, colour cast and blotches, this is the reported symptom |
| 3.12% | 5 | 8/255 | still blotchy |
| 3.55% | 8 | 9/255 | still blotchy |
| **3.98%** | **11** | **10/255** | **clean** |
| 4.26% | 13 | 11/255 | clean |
| 6.25% | 28 | 16/255 | clean |

The transition is sharp and sits between 3.55% and 3.98%. The shipped default
is **12/255 = 4.69%**, two steps of margin above it, which also covers a darker
room and panel to panel variation.

What that does to the 20 step scale a desktop lays over the range:

| | factory 6/255 | measured 12/255 |
|---|---|---|
| 0% | 2.41% duty | 4.69% duty |
| 5% | 7.24%, **3.00x** | 9.38%, **2.00x** |
| 10% | 12.07%, 1.67x | 14.20%, 1.52x |
| 15% | 17.05%, 1.41x | 19.03%, 1.34x |
| 20% | 22.02%, 1.29x | 23.72%, 1.25x |

The first keypress still moves more than the rest, but it stops tripling the
light output.

## Installing

The blob is extracted from the running machine and patched in place. Nothing
panel-specific is stored in this repository, because a VBT belongs to the BIOS
revision of the unit it came from.

```sh
sudo bash patch/oled-backlight/measure-floor.sh   # find the right value first
sudo VBT_MIN=<value> bash patch/oled-backlight/install.sh
sudo reboot
```

`measure-floor.sh` walks the bottom of the range in duty terms and prints, for
each step, the VBT value that would put the floor there. Note the first step
where the tint and the blotches are gone and pass that number. The script
restores your brightness on every exit path.

Without `VBT_MIN` the installer uses 12/255 (33/704 = 4.69% duty), the value
measured above. OLED behaviour at the bottom of the range varies between
panels, so measuring your own is still worth the two minutes.

The installer keeps the extracted factory blob at
`/var/lib/honor-zqcp/vbt-factory.bin` and always patches from it, so re-running
with a different `VBT_MIN` does the right thing.

`uninstall.sh` reverts everything. Dropping the kernel parameter alone is
already enough to restore stock behaviour.

## Verifying after reboot

```sh
# the parameter is on the cmdline
grep -o 'xe.vbt_firmware=[^ ]*' /proc/cmdline

# the driver accepted the blob — this must print nothing
sudo dmesg | grep -i 'VBT firmware'

# and the floor moved: the bottom of the range should be visibly brighter.
# Use 1, not 0 — writing 0 powers the panel off instead of dimming it.
echo 1 | sudo tee /sys/class/backlight/intel_backlight/brightness
```

To read back what the driver is now using:

```sh
sudo cp /sys/kernel/debug/dri/0/i915_vbt /tmp/vbt.bin
python3 patch/oled-backlight/vbt-min.py show /tmp/vbt.bin
```

## What this does not do

**It does not make the steps perceptually uniform.** The desktop still divides
the range linearly. PowerDevil, for instance, returns exactly 20 steps for any
`max_brightness >= 100`:

```cpp
/* powerdevil/daemon/powerdevilscreenbrightnesslogic.cpp */
if (maxValue >= 100 || maxValue % 20 == 0 || (maxValue >= 80 && maxValue % 4 == 0)) {
    // In this case all 20 steps are perfect.
    return 20;
}
```

A perceptual curve was proposed for PowerDevil and rejected as an
implementation detail. Raising the floor takes the worst of it away, but if you
want geometric steps you have to take the brightness keys away from the desktop
and drive the sysfs node yourself.

**It costs you the very dim end.** The panel does not render its rated minimum
cleanly, so the choice is between dim and blotchy, and slightly brighter and
even. Pick the floor with `measure-floor.sh` rather than maximising it.

**A BIOS update invalidates the blob.** The installed VBT is a copy of the one
that shipped with the BIOS present at install time. `install.sh` records the
BIOS version in `/var/lib/honor-zqcp/oled-backlight.stamp`; re-run it after any
firmware update.

## Approaches that were ruled out

**DPCD/AUX backlight** (`xe.enable_dpcd_backlight=1` or `=2`). The panel does
advertise it:

```
0x701 EDP_GENERAL_CAP_1        = 0x87   TCON_BACKLIGHT_ADJUSTMENT_CAP = 1
0x702 BACKLIGHT_ADJUSTMENT_CAP = 0xa6   BRIGHTNESS_AUX_SET_CAP = 1
                                        BRIGHTNESS_PWM_PIN_CAP = 0
0x721 BACKLIGHT_MODE_SET       = 0x00   mode = PWM pin, what is in use today
0x725 PWMGEN_BIT_COUNT_CAP_MIN = 0x08
0x726 PWMGEN_BIT_COUNT_CAP_MAX = 0x08
```

but switching makes both problems worse. From `intel_dp_aux_backlight.c`:

```c
} else if (panel->backlight.edp.vesa.info.aux_set) {
	panel->backlight.max = panel->backlight.edp.vesa.info.max;
	panel->backlight.min = 0;
```

The minimum becomes a real zero, and the resolution drops from 704 steps to 255
because the PWM generator bit count is capped at 8 at both ends. A real zero on
an OLED is how you end up with a screen that will not come back, which is a
known failure mode in desktop brightness handling.

The Intel proprietary HDR AUX interface was already tried by the driver on its
own: the VBT says `INTEL_BACKLIGHT_DISPLAY_DDI`, which in AUTO mode sets
`try_intel_interface = true`. Since `max_brightness` ends up as 704, that is the
`BXT_BLC_PWM_FREQ` register, so `intel_dp_aux_supports_hdr_backlight()` returned
false and the driver fell back to PWM by itself.

**A udev floor.** Clamping the sysfs value after the fact works, but it corrects
after the write rather than before it, so there is a visible flicker on the way
down; it leaves the desktop showing a brightness it is not at; it does not cover
the greeter or a TTY; and because it clips instead of rescaling, the bottom of
the slider collapses onto one level.

**A kernel change.** amdgpu grew a `min_backlight_quirk` DMI table for exactly
this class of problem. i915 and xe have nothing equivalent by design, they take
the number from the VBT. A local patch to `get_backlight_min_vbt()` would mean
rebuilding the kernel after every update, for the same result.

**ACPI.** Not involved. `_BCL` in SSDT12 and `PBCL` in the DSDT both return the
generic 0..100 list in steps of 1 starting at zero, so the firmware declares no
floor at that level either, and an Intel iGPU does not use the ACPI backlight
path anyway.

## Files

| file | |
|---|---|
| [`vbt-min.py`](vbt-min.py) | inspect or patch `brightness_min_level` in a VBT blob |
| [`measure-floor.sh`](measure-floor.sh) | walk the bottom of the range, print the matching VBT value |
| [`install.sh`](install.sh) | extract, patch, install, wire into initramfs and cmdline |
| [`uninstall.sh`](uninstall.sh) | revert |
