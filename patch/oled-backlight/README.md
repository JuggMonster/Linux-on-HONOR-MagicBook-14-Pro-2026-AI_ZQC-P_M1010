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
room and panel to panel variation. A second ZQC-P reported the same crossover
point, "cleaner after 3.55%", so the number is not specific to one unit.

Verified end to end on the reference unit: booted with the patched blob,
`parse_lfp_backlight()` logged `min brightness 12`, and the bottom of the range
renders cleanly where it used to be blotchy.

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
# 1. the parameter reached the driver
cat /sys/module/xe/parameters/vbt_firmware

# 2. request_firmware() succeeded at probe. A failure here is drm_err and is
#    printed unconditionally, so silence plus a set parameter is a good sign
journalctl -k -b | grep -i 'VBT firmware'

# 3. the blob is in the initramfs. xe is loaded from there by the kms hook,
#    before the root filesystem exists, so this is where it has to be
sudo lsinitcpio /boot/*/linux-cachyos/initramfs | grep zqc-p-vbt

# 4. the floor moved. Use 1, not 0 — writing 0 powers the panel off
echo 1 | sudo tee /sys/class/backlight/intel_backlight/brightness
```

For proof rather than inference, boot once with `drm.debug=0x4` appended to the
kernel command line. `parse_lfp_backlight()` logs what it read:

```
$ journalctl -k -b | grep -i 'VBT backlight PWM'
xe 0000:00:02.0: [drm] VBT backlight PWM modulation frequency 200 Hz, \
    active high, min brightness 12, level 35, controller 0
```

`min brightness 12` means the patched blob was used. `min brightness 6` means
it was not, and the driver fell back to the firmware's own copy.

### Do not verify with debugfs

Reading `/sys/kernel/debug/dri/0/i915_vbt` looks like the obvious check and it
is worthless. The node does not dump what the driver parsed at probe, it calls
`intel_bios_get_vbt()`, which starts with a fresh `request_firmware()`:

```c
static int intel_bios_vbt_show(struct seq_file *m, void *unused)
{
	vbt = intel_bios_get_vbt(display, &vbt_size);
	...
}

static const struct vbt_header *intel_bios_get_vbt(struct intel_display *display,
						   size_t *sizep)
{
	vbt = firmware_get_vbt(display, sizep);
	if (!vbt)
		vbt = intel_opregion_get_vbt(display, sizep);
	...
}
```

By the time you read it the root filesystem is mounted, so it reports the file
currently on disk even if the boot time load failed and the driver is running
on the factory VBT. Demonstrated here: with a kernel booted on a 12/255 blob,
replacing the file on disk with a 20/255 one and re-reading the node returned
20/255, while the boot log still said `min brightness 12`.

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
even. Pick the floor with `measure-floor.sh` rather than maximising it, and
mind the ceiling in the next section.

## Three floors in the stack, only one of them matters

This causes recurring confusion, so it is worth writing down. Three different
layers each impose a minimum, and they are not equivalent.

| layer | floor | when it applies |
|---|---|---|
| **kernel, from the VBT** | `panel->backlight.min`, 33/704 here after the patch | **every write**, it maps the sysfs range `[0..max]` onto `[min..max]` |
| systemd-backlight | `ID_BACKLIGHT_CLAMP` udev property, default 1% of max | only when restoring the saved level at boot |
| the desktop | KDE 1, GNOME `max/100` | only for what that desktop writes |

Only the first one applies to everything, which is why this fix lives there.

The desktop floors are in raw sysfs units and are chosen blind:

```c
/* powerdevil, daemon/controllers/backlightbrightness.cpp */
int BacklightBrightness::knownSafeMinBrightness() const
{
    // Some laptop displays have been known to turn off completely when set to 0.
    // ... Use 1 as the lowest value that we're actually sure won't turn off the display.
    return 1;
}
```

```c
/* mutter, src/backends/meta-backlight-sysfs.c */
max = g_udev_device_get_sysfs_attr_as_int (device, "max_brightness");
min = MAX (1, max / 100);
```

Neither reads the VBT, and neither can: **the kernel does not export the
hardware minimum at all.** `struct backlight_properties` has `brightness`,
`max_brightness`, `power`, `type`, `scale` and `state`, and the sysfs attribute
group is exactly

```c
static struct attribute *bl_device_attrs[] = {
	&dev_attr_bl_power.attr,
	&dev_attr_brightness.attr,
	&dev_attr_actual_brightness.attr,
	&dev_attr_max_brightness.attr,
	&dev_attr_scale.attr,
	&dev_attr_type.attr,
	NULL,
};
```

There is no minimum in either. `panel->backlight.min` exists only inside the
driver.

None of that matters once the VBT floor is right, because those raw values are
not luminance. What each desktop's floor actually produces on this panel:

| | KDE writes 1 | GNOME writes 7 |
|---|---|---|
| factory VBT, min 6/255 | 2.56% duty | 3.41% duty |
| **patched, min 12/255** | **4.83% duty** | **5.68% duty** |

The measured clean threshold is 3.98%. GNOME's floor is not just a code
reading: watching the backlight value while walking the range down shows it
stopping at `41 -> 7` and going no further, never reaching 0.

Before the patch *both* desktops sat
below it, which is why the same blotches show up under GNOME and KDE alike.
After it both are clear of it, and the difference between the two desktops is
17% in light output rather than the 7x it looks like in raw units. So there is
nothing desktop-specific to configure.

### The one thing the VBT cannot cover

Writing exactly `0`. That decision is made on the **user** value, before any
scaling:

```c
/* intel_backlight_device_update_status() */
bool enable = bd->props.power == BACKLIGHT_POWER_ON &&
              bd->props.brightness != 0;
panel->backlight.power(connector, enable);
```

so no VBT value can prevent it. Both desktops avoid 0 deliberately, but
`brightnessctl set 0`, a script or another tool will blank the panel. If you
want that closed, the installer can add a guard that only ever fires on exactly
zero:

```sh
sudo GUARD_ZERO=1 bash patch/oled-backlight/install.sh
```

It is opt-in because it also overrides a deliberate blank through this
interface. The proper way to turn the panel off is `bl_power`, which the guard
does not touch.

Measured here: a write of 0 comes back as 1 after about 400 ms, which is udev
latency, so the panel does blank for a moment before recovering. It is a net
that catches a mistake, not something that makes 0 behave like a level.

## Do not raise the floor too far

There is an upper bound, and it is not obvious. HONOR advertises 4320 Hz
"flicker free" dimming for this panel and states that it engages **only at low
screen brightness**. That is the panel's own behaviour, layered under the
200 Hz PWM the SoC drives.

Photographed at 1/1250 s by [@inko32](https://github.com/inko32) on a second
ZQC-P: both the thick 200 Hz banding and thin high frequency banding are
present at 88/704 (12.5% duty), and the thin banding is gone at 105/704
(14.9%). So the panel leaves its high frequency mode somewhere between those
two, and above it you are left with the bare 200 Hz envelope.

Which means "pick a high floor to be safe" is bad advice on this machine:

| VBT value | duty | |
|---|---|---|
| 6/255 | 2.41% | factory, blotchy |
| 10/255 | 3.98% | first clean level measured here |
| **12/255** | **4.69%** | shipped default, well inside the high frequency region |
| 30/255 | 11.7% | practical ceiling, still inside it |
| 38/255 | 14.9% | high frequency dimming is gone, 200 Hz only |

Keep the floor below roughly 30/255. The driver would let you go to 64/255,
which is deep into the wrong side of that boundary.

Above about 15% the panel flickers at 200 Hz and there is nothing the VBT can
do about it: `cnp_setup_backlight()` takes the PWM period from the
`BXT_BLC_PWM_FREQ` register the BIOS already programmed, and only falls back to
the VBT frequency field if that register reads zero.

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
