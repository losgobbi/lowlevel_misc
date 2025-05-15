#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/i2c.h>
#include <linux/of.h>

u32 i2c_func(struct i2c_adapter *adap)
{
	return 0;
}

static int i2c_xfer(struct i2c_adapter *adap, struct i2c_msg msgs[], int num)
{
	return 0;
}

static const struct i2c_algorithm i2c_dummy_algo = {
	.xfer = i2c_xfer,
	.functionality = i2c_func,
};

static int dummy_i2c_master_probe(struct platform_device *pdev)
{
	struct i2c_adapter *adap;
	int ret;

	adap = devm_kzalloc(&pdev->dev, sizeof(*adap), GFP_KERNEL);
	if (!adap)
		return -ENOMEM;

	adap->owner = THIS_MODULE;
	adap->class = I2C_CLASS_HWMON;
	adap->algo = &i2c_dummy_algo;
	adap->dev.parent = &pdev->dev;
	adap->dev.of_node = pdev->dev.of_node;
	adap->nr = -1;
	strscpy(adap->name, "dummy-i2c-master", sizeof(adap->name));

	ret = i2c_add_adapter(adap);
	if (ret) {
		dev_err(&pdev->dev, "failed to add i2c adapter\n");
		return ret;
	}

	platform_set_drvdata(pdev, adap);
	dev_info(&pdev->dev, "Dummy I2C controller registered\n");

	return 0;
}

static void dummy_i2c_master_remove(struct platform_device *pdev)
{
	struct i2c_adapter *adap = platform_get_drvdata(pdev);

	i2c_del_adapter(adap);
	return;
}

static const struct of_device_id dummy_i2c_master_of_match[] = {
	{ .compatible = "dummy,i2c-master" },
	{ /* sentinel */ }
};
MODULE_DEVICE_TABLE(of, dummy_i2c_master_of_match);

static struct platform_driver dummy_i2c_master_driver = {
	.probe = dummy_i2c_master_probe,
	.remove = dummy_i2c_master_remove,
	.driver = {
		.name = "dummy-i2c-master",
		.of_match_table = dummy_i2c_master_of_match,
	},
};
module_platform_driver(dummy_i2c_master_driver);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Foo bar");
MODULE_DESCRIPTION("Dummy I2C master to test I2C clients from DT");
