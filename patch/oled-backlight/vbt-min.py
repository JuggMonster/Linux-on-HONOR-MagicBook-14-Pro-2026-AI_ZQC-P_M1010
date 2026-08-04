#!/usr/bin/env python3
"""Inspect and patch the LFP minimum backlight level inside an Intel VBT.

    vbt-min.py show  <vbt.bin>
    vbt-min.py patch <in.bin> <out.bin> <min_1_64>

The value lives in bdb_lfp_backlight.brightness_min_level[panel_type] for VBT
version 234 and newer, and in the per-entry min_brightness byte before that.
i915/xe turn it into the hardware floor with

    pwm_level_min = scale(min_brightness, 0, 255, 0, pwm_level_max)

and then map the whole sysfs range [0..max] onto [pwm_level_min..max], so this
one byte decides what "0%" means in every desktop environment.

Layout is taken from drivers/gpu/drm/i915/display/intel_vbt_defs.h. Nothing
else in the blob is touched, and the VBT checksum is deliberately left alone:
the driver never verifies it (intel_bios_is_valid_vbt() checks the signature
and the sizes only), and the factory blob does not sum to zero over any
plausible range anyway.
"""
import struct
import sys

PWM_MAX_HINT = 704          # BXT_BLC_PWM_FREQ on ZQC-P, used for the printout only


def die(msg):
    print(f'vbt-min: {msg}', file=sys.stderr)
    sys.exit(1)


def parse(buf):
    """Locate the fields we care about. Returns a dict of absolute offsets."""
    if len(buf) < 48 or buf[:4] != b'$VBT':
        die('not a VBT blob (missing $VBT signature)')

    bdb_off = struct.unpack_from('<I', buf, 28)[0]
    if bdb_off + 22 > len(buf) or buf[bdb_off:bdb_off + 16] != b'BIOS_DATA_BLOCK ':
        die('BDB header not found')
    ver, hdr_size, _ = struct.unpack_from('<HHH', buf, bdb_off + 16)

    blocks, p = {}, hdr_size
    bdb = buf[bdb_off:]
    while p + 3 <= len(bdb):
        bid = bdb[p]
        size = struct.unpack_from('<H', bdb, p + 1)[0]
        if size == 0 or p + 3 + size > len(bdb):
            break
        blocks[bid] = (bdb_off + p + 3, size)
        p += 3 + size

    if 40 not in blocks:
        die('block 40 (LFP options) missing, cannot determine panel_type')
    if 43 not in blocks:
        die('block 43 (LFP backlight) missing')

    panel_type = buf[blocks[40][0]] & 0xf
    b43, b43_size = blocks[43]
    entry_size = buf[b43]
    if entry_size != 6:
        die(f'unexpected backlight entry size {entry_size}, refusing to guess')

    # data[16], level[16], backlight_control[16], then the 234+ tables
    after = b43 + 1 + 16 * entry_size + 16 + 16
    want = 1 + 16 * entry_size + 16 + 16
    if ver >= 234:
        want += 64 + 64                 # lfp_brightness_level is u16 + u16 reserved
    if ver >= 236:
        want += 16
    if ver >= 239:
        want += 32
    if b43_size != want:
        die(f'block 43 is {b43_size} bytes, expected {want} for VBT {ver}')

    info = {
        'version': ver,
        'panel_type': panel_type,
        'legacy_min_off': b43 + 1 + panel_type * entry_size + 3,
        'pwm_freq': struct.unpack_from('<H', buf, b43 + 1 + panel_type * entry_size + 1)[0],
        'control': buf[b43 + 1 + 16 * entry_size + 16 + panel_type],
    }
    if ver >= 234:
        info['min_off'] = after + 64 + panel_type * 4
        info['level'] = struct.unpack_from('<H', buf, after + panel_type * 4)[0]
        info['precision'] = buf[after + 128 + panel_type] if ver >= 236 else None
    else:
        info['min_off'] = info['legacy_min_off']
        info['level'] = buf[b43 + 1 + 16 * entry_size + panel_type]
        info['precision'] = None
    return info


def current_min(buf, info):
    if info['version'] >= 234:
        raw = struct.unpack_from('<H', buf, info['min_off'])[0]
        scale16 = (info['precision'] == 16) if info['precision'] is not None \
            else info['level'] > 255
        return raw // 255 if scale16 else raw
    return buf[info['min_off']]


def show(buf, label='VBT'):
    info = parse(buf)
    mn = current_min(buf, info)
    methods = {0: 'PMIC', 1: 'LPSS PWM', 2: 'DDI native PWM', 3: 'CABC/DSI',
               4: 'VESA AUX (eDP DPCD)', 5: 'Intel HDR AUX'}
    ctrl = info['control'] & 0xf
    print(f'{label}: version {info["version"]}, panel_type {info["panel_type"]}')
    print(f'  control method     {ctrl} ({methods.get(ctrl, "unknown")}), '
          f'{info["pwm_freq"]} Hz')
    print(f'  precision_bits     {info["precision"]}')
    print(f'  default level      {info["level"]}/255')
    print(f'  minimum level      {mn}/255 = {mn / 255 * 100:.2f}%')
    print(f'  hardware floor     {round(mn * PWM_MAX_HINT / 255)}/{PWM_MAX_HINT} '
          f'(assuming pwm_level_max {PWM_MAX_HINT})')
    if ctrl not in (2,):
        print('  note: this panel is not on the native PWM path, the floor may '
              'be computed differently')
    return mn


def patch(src, dst, newmin):
    buf = open(src, 'rb').read()
    info = parse(buf)
    old = show(buf, f'{src} (before)')

    if info['version'] >= 236 and info['precision'] not in (8, None):
        die(f'precision_bits is {info["precision"]}, the 16-bit scaling path is '
            'untested here, refusing')
    if not 1 <= newmin <= 64:
        die('i915 clamps the VBT minimum to 0..64/255, pick a value in 1..64')
    if newmin <= old:
        print(f'note: {newmin}/255 is not above the current {old}/255, '
              'this will not raise the floor')

    b = bytearray(buf)
    if info['version'] >= 234:
        struct.pack_into('<H', b, info['min_off'], newmin)
    b[info['legacy_min_off']] = newmin       # unused at 234+, kept consistent
    out = bytes(b)

    print()
    show(out, f'{dst} (after)')
    changed = [i for i in range(len(buf)) if buf[i] != out[i]]
    print(f'  changed offsets    {changed}')
    open(dst, 'wb').write(out)


if __name__ == '__main__':
    if len(sys.argv) == 3 and sys.argv[1] == 'show':
        show(open(sys.argv[2], 'rb').read(), sys.argv[2])
    elif len(sys.argv) == 5 and sys.argv[1] == 'patch':
        patch(sys.argv[2], sys.argv[3], int(sys.argv[4]))
    else:
        print(__doc__.strip(), file=sys.stderr)
        sys.exit(2)
