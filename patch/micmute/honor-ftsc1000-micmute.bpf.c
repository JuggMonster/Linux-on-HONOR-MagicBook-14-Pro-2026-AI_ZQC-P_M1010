// SPDX-License-Identifier: GPL-2.0-only
/*
 * HONOR MagicBook, FocalTech FTSC1000 touchscreen (I2C HID 2808:5662).
 *
 * Problem
 *   The touchscreen declares a vendor collection on HID usage page 0xff01:
 *   report ID 0x10, Report Size 8, Report Count 0x3b. It is a 59 byte raw
 *   data channel. Usage page 0xff01 is HID_UP_HPVENDOR2 in the kernel, the
 *   page HP uses for hotkey buttons, and drivers/hid/hid-input.c maps usage
 *   0xff010001 to KEY_MICMUTE with no vendor check:
 *
 *	case HID_UP_HPVENDOR2:
 *		set_bit(EV_REP, input->evbit);
 *		switch (usage->hid & HID_USAGE) {
 *		case 0x001: map_key_clear(KEY_MICMUTE);		break;
 *
 *   The collection is therefore exported as an input device whose only key
 *   is KEY_MICMUTE, fed by 59 eight-bit data fields that all carry that
 *   usage. Any non-zero byte is a key press, and because the same code path
 *   sets EV_REP the key ends up held down and auto-repeating at ~30 Hz. The
 *   microphone then mutes and unmutes on its own.
 *
 * Rule applied here
 *   A hotkey is either a single bit of a button bitmap or an entry of a
 *   usage array, never a multi-bit variable data field. hid-input already
 *   uses that same test in its own "unknown:" fallback. Where a wide
 *   variable field is found on page 0xff01, the usage page item is
 *   rewritten to 0xff00 (HID_UP_MSVENDOR), which hid-input ignores
 *   outright, so no input device is created for the collection.
 *
 *   Nothing else changes. The digitizer collections carry their own usage
 *   pages, so the touchscreen keeps working, and the real Fn+F7 key arrives
 *   over WMI rather than over HID.
 */

#include "vmlinux.h"
#include "hid_bpf.h"
#include "hid_bpf_helpers.h"
#include <bpf/bpf_tracing.h>

#define VID_FOCALTECH		0x2808
#define PID_FTSC1000		0x5662

HID_BPF_CONFIG(
	HID_DEVICE(BUS_I2C, HID_GROUP_MULTITOUCH_WIN_8, VID_FOCALTECH, PID_FTSC1000)
);

#define RDESC_MAX		4096		/* HID_MAX_DESCRIPTOR_SIZE */
#define RDESC_MASK		(RDESC_MAX - 1)
#define ITEM_MAX		512		/* loop bound */

/* short item prefix: bits 0-1 size, bits 2-3 type, bits 4-7 tag */
#define ITEM_SIZE(p)		((p) & 0x03)
#define ITEM_TYPE(p)		(((p) >> 2) & 0x03)
#define ITEM_TAG(p)		((p) >> 4)

#define TYPE_MAIN		0
#define TYPE_GLOBAL		1

#define TAG_INPUT		8
#define TAG_OUTPUT		9
#define TAG_FEATURE		11
#define TAG_USAGE_PAGE		0
#define TAG_REPORT_SIZE		7

#define LONG_ITEM_PREFIX	0xfe
#define MAIN_ITEM_VARIABLE	0x02

#define HPVENDOR2_PAGE		0xff01
#define MSVENDOR_PAGE		0xff00

struct walk_ctx {
	__u8 *data;
	__u32 size;
	__u32 pos;
	__u32 page;
	__u32 rsize;
	__u32 up_off;
	__u32 have_up;
	__u32 fixed;
};

static long walk_item(__u32 index, void *pctx)
{
	struct walk_ctx *c = pctx;
	__u8 *data = c->data;
	__u32 pos = c->pos & RDESC_MASK;
	__u8 prefix, tag, type;
	__u32 bsize, val;

	if (c->pos >= c->size)
		return 1;

	prefix = data[pos];

	if (prefix == LONG_ITEM_PREFIX) {
		c->pos += (__u32)data[(pos + 1) & RDESC_MASK] + 3;
		return 0;
	}

	bsize = ITEM_SIZE(prefix);
	if (bsize == 3)
		bsize = 4;

	val = 0;
	if (bsize >= 1)
		val |= (__u32)data[(pos + 1) & RDESC_MASK];
	if (bsize >= 2)
		val |= (__u32)data[(pos + 2) & RDESC_MASK] << 8;
	if (bsize >= 3)
		val |= (__u32)data[(pos + 3) & RDESC_MASK] << 16;
	if (bsize >= 4)
		val |= (__u32)data[(pos + 4) & RDESC_MASK] << 24;

	type = ITEM_TYPE(prefix);
	tag = ITEM_TAG(prefix);

	if (type == TYPE_GLOBAL) {
		if (tag == TAG_USAGE_PAGE) {
			c->page = val;
			c->up_off = pos;
			c->have_up = 1;
		} else if (tag == TAG_REPORT_SIZE) {
			c->rsize = val;
		}
	} else if (type == TYPE_MAIN &&
		   (tag == TAG_INPUT || tag == TAG_OUTPUT || tag == TAG_FEATURE) &&
		   c->page == HPVENDOR2_PAGE &&
		   c->rsize != 1 &&
		   (val & MAIN_ITEM_VARIABLE) &&
		   c->have_up) {
		/*
		 * Two byte usage page item: 0x06 <lo> <hi>. Clearing the low
		 * byte turns 0xff01 into 0xff00, which hid-input ignores.
		 */
		data[(c->up_off + 1) & RDESC_MASK] = 0x00;
		c->page = MSVENDOR_PAGE;
		c->fixed++;
	}

	c->pos += bsize + 1;
	return 0;
}

SEC(HID_BPF_RDESC_FIXUP)
int BPF_PROG(hid_fix_rdesc_ftsc1000, struct hid_bpf_ctx *hctx)
{
	__u8 *data = hid_bpf_get_data(hctx, 0 /* offset */, RDESC_MAX);
	struct walk_ctx c = {};
	__s32 size = hctx->size;

	if (!data)
		return 0;		/* EPERM check */

	if (size <= 0 || size > RDESC_MAX)
		return 0;

	c.data = data;
	c.size = (__u32)size;

	bpf_loop(ITEM_MAX, walk_item, &c, 0);

	return 0;
}

HID_BPF_OPS(honor_ftsc1000_micmute) = {
	.hid_rdesc_fixup = (void *)hid_fix_rdesc_ftsc1000,
};

char _license[] SEC("license") = "GPL";
