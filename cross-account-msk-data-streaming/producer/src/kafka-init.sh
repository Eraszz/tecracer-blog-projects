#!/bin/bash

sudo yum update -y
sudo yum -y install java-1.8.0-openjdk

cd /home/ec2-user

wget https://archive.apache.org/dist/kafka/2.8.1/kafka_2.13-2.8.1.tgz
tar -xzf kafka_2.13-2.8.1.tgz
rm kafka_2.13-2.8.1.tgz

cd kafka_2.13-2.8.1/bin/

sudo bash -c 'echo "security.protocol=SSL" > client.properties'

sudo ./kafka-topics.sh --create --bootstrap-server ${bootstrap_servers} --command-config client.properties --topic ${kafka_topic} --if-not-exists

cd -

sudo python3 -m pip install kafka-python

mkdir kafka-python-producer
cd kafka-python-producer

cat > producer.py << EOF
#!/usr/bin/env python3
from kafka import KafkaProducer
import json
import datetime
import random
import time
import sys
# Messages will be serialized as JSON
def serializer(message):
    return json.dumps(message).encode('utf-8')
# Kafka Producer
producer = KafkaProducer(
    security_protocol="SSL",
    bootstrap_servers=[sys.argv[1]],
    value_serializer=serializer
)
if __name__ == '__main__':
    # Infinite loop - runs until you kill the program
   temperature = random.randint(25,35)
   
   while True:
        # Generate a message
        timestamp = datetime.datetime.now().isoformat()
        temperature = temperature + random.randint(-1,1)
        message = {"device_id": int(sys.argv[3]), "timestamp":timestamp , "temperature":temperature}
        # Send it to the kafka topic
        producer.send(sys.argv[2], message)
        # Sleep for 100ms
        time.sleep(0.1)
EOF

sudo chmod +x producer.py
sudo ./producer.py ${bootstrap_servers} ${kafka_topic} ${device_id}