// SPDX-License-Identifier: GPL-2.0
/*
 * hwmon driver for HONOR MagicBook Pro 14 AI (ZQC-P / M1010) EC fan tachometers.
 *
 * The EC exposes two 16-bit little-endian RPM words in its RAM (the standard
 * 0x62/0x66 ACPI EC address space, region ECF0 in the DSDT):
 *
 *   0x2C/0x2D - fan 0 (FA0L/FA0R in the DSDT field list)
 *   0x2E/0x2F - fan 1 (FA1L/FA1R)
 *
 * The DSDT field names split each word into two 8-bit fields, which is what
 * originally led us to read them as "PWM duty + status flag". They are in fact
 * one LE word per fan: idle reads ~2280/2000 rpm, and ~3650/3270 rpm was
 * observed at 89 degC under a sustained compile load. The same offsets were
 * independently confirmed on the sibling FMB-P by
 * colorcube/Linux-on-Honor-Magicbook-14-Pro PR #21.
 *
 * Read-only by design: the EC only accepts a manual duty via SFNS when its
 * MFGM master flag is set, and MFGM is never set from any AML path. The DPTF
 * fan participant (INTC10D6, cooling_device "TFN1", 51 states) accepts writes
 * to cur_state but the EC ignores them - verified: cur_state 0 -> 50 produced
 * no change in either tachometer. Fan speed is therefore EC-autonomous.
 */

#include <linux/acpi.h>
#include <linux/dmi.h>
#include <linux/hwmon.h>
#include <linux/module.h>
#include <linux/platform_device.h>

#define ZQCP_EC_FAN0_LO		0x2c
#define ZQCP_EC_FAN0_HI		0x2d
#define ZQCP_EC_FAN1_LO		0x2e
#define ZQCP_EC_FAN1_HI		0x2f

/* Anything above this is a bad EC read rather than a real fan speed. */
#define ZQCP_RPM_MAX		20000

static struct platform_device *zqcp_pdev;

static int zqcp_read_fan(u8 lo_addr, u8 hi_addr, long *rpm)
{
	u8 lo, hi;
	int ret;

	ret = ec_read(lo_addr, &lo);
	if (ret)
		return ret;
	ret = ec_read(hi_addr, &hi);
	if (ret)
		return ret;

	*rpm = (hi << 8) | lo;
	if (*rpm > ZQCP_RPM_MAX)
		return -EIO;

	return 0;
}

static int zqcp_hwmon_read(struct device *dev, enum hwmon_sensor_types type,
			   u32 attr, int channel, long *val)
{
	if (type != hwmon_fan || attr != hwmon_fan_input)
		return -EOPNOTSUPP;

	switch (channel) {
	case 0:
		return zqcp_read_fan(ZQCP_EC_FAN0_LO, ZQCP_EC_FAN0_HI, val);
	case 1:
		return zqcp_read_fan(ZQCP_EC_FAN1_LO, ZQCP_EC_FAN1_HI, val);
	default:
		return -EOPNOTSUPP;
	}
}

static const char * const zqcp_fan_labels[] = { "CPU fan", "System fan" };

static int zqcp_hwmon_read_string(struct device *dev,
				  enum hwmon_sensor_types type, u32 attr,
				  int channel, const char **str)
{
	if (type != hwmon_fan || attr != hwmon_fan_label ||
	    channel >= ARRAY_SIZE(zqcp_fan_labels))
		return -EOPNOTSUPP;

	*str = zqcp_fan_labels[channel];
	return 0;
}

static umode_t zqcp_hwmon_is_visible(const void *data,
				     enum hwmon_sensor_types type, u32 attr,
				     int channel)
{
	if (type == hwmon_fan && channel < ARRAY_SIZE(zqcp_fan_labels))
		return 0444;

	return 0;
}

static const struct hwmon_channel_info * const zqcp_hwmon_info[] = {
	HWMON_CHANNEL_INFO(fan,
			   HWMON_F_INPUT | HWMON_F_LABEL,
			   HWMON_F_INPUT | HWMON_F_LABEL),
	NULL
};

static const struct hwmon_ops zqcp_hwmon_ops = {
	.is_visible = zqcp_hwmon_is_visible,
	.read = zqcp_hwmon_read,
	.read_string = zqcp_hwmon_read_string,
};

static const struct hwmon_chip_info zqcp_hwmon_chip_info = {
	.ops = &zqcp_hwmon_ops,
	.info = zqcp_hwmon_info,
};

/*
 * Gate on DMI so the module is inert on any other machine - these EC offsets
 * are pure driver knowledge, there is no firmware method that describes them.
 */
static const struct dmi_system_id zqcp_dmi_table[] = {
	{
		.matches = {
			DMI_MATCH(DMI_SYS_VENDOR, "HONOR"),
			DMI_MATCH(DMI_PRODUCT_NAME, "ZQC-P"),
		},
	},
	{}
};
MODULE_DEVICE_TABLE(dmi, zqcp_dmi_table);

static int zqcp_hwmon_probe(struct platform_device *pdev)
{
	struct device *hwmon_dev;

	hwmon_dev = devm_hwmon_device_register_with_info(&pdev->dev,
							"honor_zqcp", NULL,
							&zqcp_hwmon_chip_info,
							NULL);

	return PTR_ERR_OR_ZERO(hwmon_dev);
}

static struct platform_driver zqcp_hwmon_driver = {
	.driver = {
		.name = "honor-zqcp-hwmon",
	},
	.probe = zqcp_hwmon_probe,
};

static int __init zqcp_hwmon_init(void)
{
	long rpm;
	int ret;

	if (!dmi_check_system(zqcp_dmi_table))
		return -ENODEV;

	/* Refuse to register if the EC does not answer plausibly. */
	ret = zqcp_read_fan(ZQCP_EC_FAN0_LO, ZQCP_EC_FAN0_HI, &rpm);
	if (ret) {
		pr_info("honor-zqcp-hwmon: EC fan read failed (%d), not loading\n",
			ret);
		return -ENODEV;
	}

	ret = platform_driver_register(&zqcp_hwmon_driver);
	if (ret)
		return ret;

	zqcp_pdev = platform_device_register_simple("honor-zqcp-hwmon", -1,
						    NULL, 0);
	if (IS_ERR(zqcp_pdev)) {
		platform_driver_unregister(&zqcp_hwmon_driver);
		return PTR_ERR(zqcp_pdev);
	}

	return 0;
}

static void __exit zqcp_hwmon_exit(void)
{
	platform_device_unregister(zqcp_pdev);
	platform_driver_unregister(&zqcp_hwmon_driver);
}

module_init(zqcp_hwmon_init);
module_exit(zqcp_hwmon_exit);

MODULE_DESCRIPTION("HONOR MagicBook Pro 14 AI (ZQC-P) EC fan hwmon driver");
MODULE_LICENSE("GPL");
