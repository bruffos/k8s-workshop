import time
from sense_hat import SenseHat
import paho.mqtt.publish as mqtt

sense = SenseHat()
msleep = lambda x: time.sleep(x / 1000.0)

while True:
    temp = sense.get_temperature()
    mqtt.single("home/temperature", payload=temp, qos=0, retain=True, hostname="mosquitto-mqtt", will=None, auth={'username':"home", 'password':"PASSWORD"})

    msleep(2)

