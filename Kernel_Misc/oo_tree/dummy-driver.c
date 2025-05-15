#include <linux/module.h>
#include <linux/i2c.h>
#include <linux/of.h>
#include <linux/regulator/consumer.h>
#include <linux/slab.h>

struct dummy_data {
	struct regulator *vdd_reg;
};

static int dummy_probe(struct i2c_client *client)
{
	struct dummy_data *data;

	dev_info(&client->dev, "Calling dummy_probe\n");
	data = devm_kzalloc(&client->dev, sizeof(*data), GFP_KERNEL);
	if (!data)
		return -ENOMEM;

	data->vdd_reg = devm_regulator_get(&client->dev, "vdd");
	if (IS_ERR(data->vdd_reg))
		return dev_err_probe(&client->dev, PTR_ERR(data->vdd_reg),
				     "failed to get VDD regulator!\n");

	dev_info(&client->dev, "Dummy I2C device probed successfully\n");
	i2c_set_clientdata(client, data);
	return 0;
}

static void dummy_remove(struct i2c_client *client)
{
	dev_info(&client->dev, "Dummy I2C device removed\n");
	return;
}

static const struct of_device_id dummy_of_match[] = {
	{ .compatible = "foo,dummydriver" },
	{ /* sentinel */ }
};
MODULE_DEVICE_TABLE(of, dummy_of_match);

static const struct i2c_device_id dummy_id[] = {
	{ "dummydriver", 0 },
	{ }
};
MODULE_DEVICE_TABLE(i2c, dummy_id);

static struct i2c_driver dummy_i2c_driver = {
	.driver = {
		.name = "dummydriver",
		.of_match_table = dummy_of_match,
	},
	.probe = dummy_probe,
	.remove = dummy_remove,
	.id_table = dummy_id,
};

module_i2c_driver(dummy_i2c_driver);

MODULE_DESCRIPTION("Dummy I2C Driver Example");
MODULE_AUTHOR("Foo bar");
MODULE_LICENSE("GPL");
