[
    {
        "id": "4f7b8a73.6f5b2c",
        "type": "tab",
        "label": "Flow 1",
        "disabled": false,
        "info": ""
    },
    {
        "id": "1761b8a6.89ad17",
        "type": "mqtt in",
        "z": "4f7b8a73.6f5b2c",
        "name": "Kitchen temp outside",
        "topic": "tellstick/sensors/fineoffset/temperature/136/temp",
        "qos": "1",
        "broker": "751b7056.1a69c",
        "x": 493.5,
        "y": 265.5,
        "wires": [
            [
                "e8355bc3.c2b6b",
                "61c5aa57.a0b6dc"
            ]
        ]
    },
    {
        "id": "211ebc87.80a6e4",
        "type": "influxdb out",
        "z": "4f7b8a73.6f5b2c",
        "influxdb": "d69ae370.e143",
        "name": "",
        "measurement": "",
        "precision": "",
        "retentionPolicy": "",
        "x": 996.5,
        "y": 258.5,
        "wires": []
    },
    {
        "id": "61c5aa57.a0b6dc",
        "type": "function",
        "z": "4f7b8a73.6f5b2c",
        "name": "Transform",
        "func": "msg.payload = parseFloat(msg.payload) \nmsg.measurement=\"KitchenOutdoorTemp\"\nreturn msg;",
        "outputs": 1,
        "noerr": 0,
        "x": 733.5,
        "y": 255.5,
        "wires": [
            [
                "e8355bc3.c2b6b",
                "211ebc87.80a6e4"
            ]
        ]
    },
    {
        "id": "e8355bc3.c2b6b",
        "type": "debug",
        "z": "4f7b8a73.6f5b2c",
        "name": "",
        "active": true,
        "tosidebar": true,
        "console": false,
        "tostatus": false,
        "complete": "true",
        "x": 1024.5,
        "y": 439,
        "wires": []
    },
    {
        "id": "2a47095b.705b5e",
        "type": "mqtt in",
        "z": "4f7b8a73.6f5b2c",
        "name": "Kitchen temp intside",
        "topic": "tellstick/sensors/fineoffset/temperaturehumidity/135/temp",
        "qos": "1",
        "broker": "751b7056.1a69c",
        "x": 486,
        "y": 557,
        "wires": [
            [
                "c63d1285.868268"
            ]
        ]
    },
    {
        "id": "b88a3831.4b20a",
        "type": "mqtt in",
        "z": "4f7b8a73.6f5b2c",
        "name": "Kitchen humidity intside",
        "topic": "tellstick/sensors/fineoffset/temperaturehumidity/135/humidity",
        "qos": "1",
        "broker": "751b7056.1a69c",
        "x": 536,
        "y": 627,
        "wires": [
            [
                "a2cff4f8.335c28"
            ]
        ]
    },
    {
        "id": "c63d1285.868268",
        "type": "function",
        "z": "4f7b8a73.6f5b2c",
        "name": "Transform",
        "func": "msg.payload = parseFloat(msg.payload) \nmsg.measurement=\"KitchenIndoorTemp\"\nreturn msg;",
        "outputs": 1,
        "noerr": 0,
        "x": 766,
        "y": 538,
        "wires": [
            [
                "e8355bc3.c2b6b"
            ]
        ]
    },
    {
        "id": "a2cff4f8.335c28",
        "type": "function",
        "z": "4f7b8a73.6f5b2c",
        "name": "Transform",
        "func": "msg.payload = parseFloat(msg.payload) \nmsg.measurement=\"KitchenIndoorhum\"\nreturn msg;",
        "outputs": 1,
        "noerr": 0,
        "x": 783,
        "y": 625,
        "wires": [
            [
                "e8355bc3.c2b6b"
            ]
        ]
    },
    {
        "id": "751b7056.1a69c",
        "type": "mqtt-broker",
        "z": "",
        "name": "k8s-mosquitto",
        "broker": "mosquitto-mqtt",
        "port": "1883",
        "clientid": "",
        "usetls": false,
        "compatmode": true,
        "keepalive": "60",
        "cleansession": true,
        "willTopic": "",
        "willQos": "0",
        "willPayload": "",
        "birthTopic": "",
        "birthQos": "0",
        "birthPayload": ""
    },
    {
        "id": "d69ae370.e143",
        "type": "influxdb",
        "z": "",
        "hostname": "influxdb-int",
        "port": "8086",
        "protocol": "http",
        "database": "openhab2",
        "name": "",
        "usetls": false,
        "tls": ""
    }
]
