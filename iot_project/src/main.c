/*
 * Copyright (c) 2018 Jan Van Winkel <jan.van_winkel@dxplore.eu>
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <zephyr/types.h>
#include <stddef.h>
#include <sys/printk.h>
#include <sys/util.h>
#include <stdio.h>

#include <string.h>

#include <bluetooth/bluetooth.h>
#include <bluetooth/hci.h>
#include <bluetooth/conn.h>
#include <bluetooth/uuid.h>
#include <bluetooth/gatt.h>
#include <sys/byteorder.h>

#include <inttypes.h>
#include <drivers/gpio.h>

#define SW0_NODE DT_ALIAS(sw0)
#define LED0_NODE DT_ALIAS(led0)

#define LED0 DT_GPIO_LABEL(LED0_NODE, gpios)
#define PIN DT_GPIO_PIN(LED0_NODE, gpios)
#define FLAGS DT_GPIO_FLAGS(LED0_NODE, gpios)

#define SECOND 1000
#define ADVERTISING_PERIOD 20 // in seconds
#define TIMES_TILL_OFF 100

static const struct gpio_dt_spec buttonA = GPIO_DT_SPEC_GET_OR(SW0_NODE, gpios, {0});
static struct gpio_callback button_cb_dataA;

const struct device *dev;
static bool led_is_on = false;
static bool button_is_pressed = false;
static char connected_to[BT_ADDR_LE_STR_LEN];

//static struct bt_conn *conn;

static uint8_t mfg_data[] = {0xff, 0xff, 0x00};

static const struct bt_data ad[] = {
	BT_DATA(BT_DATA_MANUFACTURER_DATA, mfg_data, 3),
};

// static struct bt_le_scan_param scan_param = {
// 	.type = BT_HCI_LE_SCAN_PASSIVE,
// 	.options = BT_LE_SCAN_OPT_NONE,
// 	.interval = 0x0010,
// 	.window = 0x0010,
// };

void initLED()
{
	dev = device_get_binding(LED0);

	gpio_pin_configure(dev, PIN, GPIO_OUTPUT_ACTIVE | FLAGS);
	gpio_pin_set(dev, PIN, (int)led_is_on);
}

void toggleLED()
{
	led_is_on = !led_is_on;
	gpio_pin_set(dev, PIN, (int)led_is_on);
}

void ledon()
{
	led_is_on = true;
	gpio_pin_set(dev, PIN, (int)led_is_on);
}
void ledoff()
{
	led_is_on = false;
	gpio_pin_set(dev, PIN, (int)led_is_on);
}

static void buttonA_pressed(const struct device *dev, struct gpio_callback *cb, uint32_t pins)
{
	button_is_pressed = true;
}

void initButton()
{
	// if (!device_is_ready(button.port)) {
	// 	printk("Error: button device %s is not ready\n", button.port->name);
	// 	return;
	// }

	gpio_pin_configure_dt(&buttonA, GPIO_INPUT);
	gpio_pin_interrupt_configure_dt(&buttonA, GPIO_INT_EDGE_TO_ACTIVE);
	gpio_init_callback(&button_cb_dataA, buttonA_pressed, BIT(buttonA.pin));
	gpio_add_callback(buttonA.port, &button_cb_dataA);
}

static void connected(struct bt_conn *conn, uint8_t err)
{
	char addr[BT_ADDR_LE_STR_LEN];

	printk("connection established, button is_pressed: %d\n", button_is_pressed);

	bt_addr_le_to_str(bt_conn_get_dst(conn), addr, BT_ADDR_LE_STR_LEN);

	if (button_is_pressed || !strcmp(addr, connected_to))
	{
		int er = bt_le_adv_stop();
		if (er)
		{
			printk("Advertising failed to stop (err %d)\n", err);
		}
		else
		{
			printk("advertising stopped ... \n");
		}

		strcpy(connected_to, addr);

		printk("connected to %s\n", addr);

		ledon();
	}
	else
	{
		bt_conn_disconnect(conn, BT_HCI_ERR_AUTH_FAIL);
	}
}

static void disconnected(struct bt_conn *conn, uint8_t reason)
{
	printk("disconnected\n");
	ledoff();
	bt_le_adv_start(BT_LE_ADV_CONN_NAME, ad, ARRAY_SIZE(ad), NULL, 0);
}

static struct bt_conn_cb conn_callbacks = {
	.connected = connected,
	.disconnected = disconnected,
};

void main(void)
{
	int err;

	/* Initialize the Bluetooth Subsystem */
	err = bt_enable(NULL);
	if (err)
	{
		printk("Bluetooth init failed (err %d)\n", err);
		return;
	}

	initLED();
	initButton();

	printk("Bluetooth initialized\n");

	bt_conn_cb_register(&conn_callbacks);
	//bt_conn_auth_cb_register(&auth_cb_display);
	err = bt_le_adv_start(BT_LE_ADV_CONN_NAME, ad, ARRAY_SIZE(ad), NULL, 0);

	while (1)
	{
		k_msleep(10);
		if (button_is_pressed)
		{
			printk("button pressed\n");
			k_msleep(20 * SECOND);
			button_is_pressed = false;
			printk("times up \n");
		}
	}
}
