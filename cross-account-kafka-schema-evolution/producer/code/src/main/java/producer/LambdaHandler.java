package producer;

import java.io.File;
import java.io.IOException;
import java.time.LocalDateTime;
import java.time.temporal.ChronoField;
import java.util.*;
import java.net.URL;
import java.util.concurrent.ExecutionException;

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

public class LambdaHandler implements RequestHandler<Map<String, Object>, Void> {

    private static final Properties properties = new Properties();
    private static final String bootstrapServersConfig = System.getenv("BOOTSTRAP_SERVERS_CONFIG");
    private static final String topic = System.getenv("TOPIC");
    private static final String awsRegion = System.getenv("AWS_REGION");
    private static final String registryName = System.getenv("REGISTRY_NAME");
    private static final String schemaName = System.getenv("SCHEMA_NAME");
    private static final String schemaPathname = System.getenv("SCHEMA_PATHNAME");
    private static final String deviceId = System.getenv("DEVICE_ID");

    @Override
    public Void handleRequest(Map<String, Object> event, Context context) {
        int temperature = (int) event.get("temperature");

        setProperties();

        if (!createTopic()) {
            return null;
        }

        if ("schema_v2.avsc".equals(schemaPathname)) {
            int humidity = (int) event.get("humidity");
            putRecord(temperature, humidity);
        } else {
            putRecord(temperature);
        }
        
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
        return new Random().nextInt(50);
    }

    static String getHumidity() {
        return new Random().nextInt(100) + "%";
    }

    private boolean createTopic() {
        try (AdminClient adminClient = AdminClient.create(properties)) {
            ListTopicsResult listTopics = adminClient.listTopics();
            Set<String> names = listTopics.names().get();
            boolean contains = names.contains(topic);

            if (!contains) {
                List<NewTopic> newTopics = new ArrayList<>();
                int partitions = 5;
                short replication = 1;
                NewTopic newTopic = new NewTopic(topic, partitions, replication);
                newTopics.add(newTopic);
                adminClient.createTopics(newTopics);
            }

        } catch (ExecutionException | InterruptedException ie) {
            ie.printStackTrace();
            return false;
        }
        return true;
    }

    private Void setProperties() {
        properties.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServersConfig);
        properties.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, AWSKafkaAvroSerializer.class.getName());
        properties.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, AWSKafkaAvroSerializer.class.getName());
        properties.put("security.protocol", "SSL");
        properties.put(AWSSchemaRegistryConstants.AWS_REGION, awsRegion);
        properties.put(AWSSchemaRegistryConstants.REGISTRY_NAME, registryName);
        properties.put(AWSSchemaRegistryConstants.SCHEMA_NAME, schemaName);
        properties.put(AWSSchemaRegistryConstants.COMPATIBILITY_SETTING, Compatibility.FULL);
        properties.put(AWSSchemaRegistryConstants.SCHEMA_AUTO_REGISTRATION_SETTING, true);
        return null;
    }

    private boolean putRecord(int temperature) {

        GenericRecord sensor;

        URL resource = this.getClass().getClassLoader().getResource(schemaPathname);

        try {
            Schema schemaSensor = new Parser().parse(new File(resource.getPath()));
            sensor = new GenericData.Record(schemaSensor);
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        }

        KafkaProducer<String, GenericRecord> producer = new KafkaProducer<>(properties);
        final ProducerRecord<String, GenericRecord> record = new ProducerRecord<>(topic, sensor);

        sensor.put("device_id", deviceId);
        sensor.put("temperature", temperature);
        sensor.put("timestamp", getTimestamp());

        producer.send(record);
        producer.flush();
        producer.close();

        return true;
    }

    private boolean putRecord(int temperature, int humidity) {

        GenericRecord sensor;

        URL resource = this.getClass().getClassLoader().getResource(schemaPathname);

        try {
            Schema schemaSensor = new Parser().parse(new File(resource.getPath()));
            sensor = new GenericData.Record(schemaSensor);
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        }

        KafkaProducer<String, GenericRecord> producer = new KafkaProducer<>(properties);
        final ProducerRecord<String, GenericRecord> record = new ProducerRecord<>(topic, sensor);

        sensor.put("device_id", deviceId);
        sensor.put("temperature", temperature);
        sensor.put("timestamp", getTimestamp());
        sensor.put("humidity", humidity+"%");

        producer.send(record);
        producer.flush();
        producer.close();

        return true;
    }
}
