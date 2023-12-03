package producer;

import java.io.File;
import java.io.IOException;
import java.time.temporal.ChronoField;
import java.util.Properties;
import java.time.LocalDateTime;
import java.util.Random;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ExecutionException;
import java.net.URL;

import org.apache.kafka.clients.admin.AdminClient;
import org.apache.kafka.clients.admin.ListTopicsResult;
import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;

import org.apache.avro.Schema;
import org.apache.avro.Schema.Parser;
import org.apache.avro.generic.GenericData;
import org.apache.avro.generic.GenericRecord;
import com.amazonaws.services.schemaregistry.serializers.avro.AWSKafkaAvroSerializer;
import com.amazonaws.services.schemaregistry.utils.AWSSchemaRegistryConstants;

import software.amazon.awssdk.services.glue.model.Compatibility;

import com.amazonaws.services.lambda.runtime.Context;

import com.amazonaws.services.lambda.runtime.RequestHandler;

public class LambdaHandler implements RequestHandler<String, Void> {

    private static final Properties properties = new Properties();
    private static final String bootstrap_servers_config = System.getenv("BOOTSTRAP_SERVERS_CONFIG");
    private static final String topic = System.getenv("TOPIC");
    private static final String aws_region = System.getenv("AWS_REGION");
    private static final String registry_name = System.getenv("REGISTRY_NAME");
    private static final String schema_name = System.getenv("SCHEMA_NAME");
    private static final String schema_pathname = System.getenv("SCHEMA_PATHNAME");
    private static final String device_id = System.getenv("DEVICE_ID");

    @Override
    public Void handleRequest(String event, Context context) {

        setProperties();
        putRecord();

        return null;
    }

    public static String getTimestamp() {
        LocalDateTime now = LocalDateTime.now();
        int year = now.getYear();
        int month = now.getMonthValue();
        int day = now.getDayOfMonth();
        int hour = now.getHour();
        int minute = now.getMinute();
        int second = now.getSecond();
        int millis = now.get(ChronoField.MILLI_OF_SECOND);

        return String.format("%d-%02d-%02d %02d:%02d:%02d.%03d", year, month, day, hour, minute, second, millis);
    }

    static int getTemperature() {
        Random rand = new Random();

        return rand.nextInt(50);
    }

    static String getHumidity() {
        Random rand = new Random();
        int num = rand.nextInt(100);

        return num + "%";
    }

    boolean createTopic() {
        try (AdminClient adminClient = AdminClient.create(properties)) {
            ListTopicsResult listTopics = adminClient.listTopics();
            Set<String> names = listTopics.names().get();
            boolean contains = names.contains(topic);

            if (!contains) {
                List<NewTopic> newTopics = new ArrayList<NewTopic>();
                int partitions = 5;
                Short replication = 1;
                NewTopic newTopic = new NewTopic(topic, partitions, replication);
                newTopics.add(newTopic);
                adminClient.createTopics(newTopics);
                adminClient.close();
            }

        } catch (ExecutionException | InterruptedException ie) {
            ie.printStackTrace();
            return false;
        }
        return true;
    }

    Void setProperties() {
        properties.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrap_servers_config);
        properties.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, AWSKafkaAvroSerializer.class.getName());
        properties.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, AWSKafkaAvroSerializer.class.getName());
        properties.put("security.protocol", "SSL");
        properties.put(AWSSchemaRegistryConstants.AWS_REGION, aws_region);
        properties.put(AWSSchemaRegistryConstants.REGISTRY_NAME, registry_name);
        properties.put(AWSSchemaRegistryConstants.SCHEMA_NAME, schema_name);
        properties.put(AWSSchemaRegistryConstants.COMPATIBILITY_SETTING, Compatibility.FULL);
        properties.put(AWSSchemaRegistryConstants.SCHEMA_AUTO_REGISTRATION_SETTING, true);

        return null;
    }

    Properties getProperties() {
        return properties;
    }

    boolean putRecord() {
        if (!createTopic())
            return false;

        GenericRecord sensor;

        URL resource = this.getClass().getClassLoader().getResource(schema_pathname);  

        try {
            Schema schema_sensor = new Parser().parse(new File(resource.getPath().toString()));
            sensor = new GenericData.Record(schema_sensor);
        } catch (IOException ie) {
            ie.printStackTrace();
            return false;
        }

        KafkaProducer<String, GenericRecord> producer = new KafkaProducer<String, GenericRecord>(properties);
        final ProducerRecord<String, GenericRecord> record = new ProducerRecord<String, GenericRecord>(topic, sensor);

        sensor.put("device_id", device_id);
        sensor.put("temperature", getTemperature());
        sensor.put("timestamp", getTimestamp());

        if (schema_pathname == "schema_v2.avsc") {
            sensor.put("humidity", getHumidity());
        }

        producer.send(record);
        producer.flush();
        producer.close();

        return true;
    }
}