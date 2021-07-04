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
#define LED1_NODE DT_ALIAS(led1)

#define LED0 DT_GPIO_LABEL(LED0_NODE, gpios)
#define PIN0 DT_GPIO_PIN(LED0_NODE, gpios)
#define FLAGS0 DT_GPIO_FLAGS(LED0_NODE, gpios)
#define LED1 DT_GPIO_LABEL(LED1_NODE, gpios)
#define PIN1 DT_GPIO_PIN(LED1_NODE, gpios)
#define FLAGS1 DT_GPIO_FLAGS(LED1_NODE, gpios)

#define SECOND 1000
#define PAIRING_TIME 20 //in seconds

static const struct gpio_dt_spec buttonA = GPIO_DT_SPEC_GET_OR(SW0_NODE, gpios, {0});
static struct gpio_callback button_cb_dataA;

const struct device *led_0;
const struct device *led_1;

static bool button_is_pressed = false;
static char connected_to[BT_ADDR_LE_STR_LEN];

static uint8_t mfg_data[] = {0xff, 0xff, 0x00};

static const struct bt_data ad[] = {
	BT_DATA(BT_DATA_MANUFACTURER_DATA, mfg_data, 3),
};

void initLED()
{
	led_0 = device_get_binding(LED0);

	gpio_pin_configure(led_0, PIN0, GPIO_OUTPUT_ACTIVE | FLAGS0);
	gpio_pin_set(led_0, PIN0, false);

	led_1 = device_get_binding(LED1);

	gpio_pin_configure(led_1, PIN1, GPIO_OUTPUT_ACTIVE | FLAGS1);
	gpio_pin_set(led_1, PIN1, false);
}

void ledon(const struct device *dev, gpio_pin_t pin)
{
	gpio_pin_set(dev, pin, true);
}
void ledoff(const struct device *dev, gpio_pin_t pin)
{
	gpio_pin_set(dev, pin, false);
}

static void buttonA_pressed(const struct device *dev, struct gpio_callback *cb, uint32_t pins)
{
	button_is_pressed = true;
}

void initButton()
{

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

		strcpy(connected_to, addr);

		printk("connected to %s\n", addr);
		button_is_pressed = false;
		ledoff(led_1, PIN1);

		ledon(led_0, PIN0);
	}
	else
	{
		bt_conn_disconnect(conn, BT_HCI_ERR_AUTH_FAIL);
	}
}

static void disconnected(struct bt_conn *conn, uint8_t reason)
{
	printk("disconnected\n");
	ledoff(led_0, PIN0);

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

	err = bt_le_adv_start(BT_LE_ADV_CONN_NAME, ad, ARRAY_SIZE(ad), NULL, 0);

	while (1)
	{
		k_msleep(100);
		if (button_is_pressed)
		{
			printk("button pressed\n");
			ledon(led_1, PIN1);
			k_msleep(PAIRING_TIME * SECOND);
			ledoff(led_1, PIN1);
			button_is_pressed = false;
			printk("times up \n");
		}
	}
}
