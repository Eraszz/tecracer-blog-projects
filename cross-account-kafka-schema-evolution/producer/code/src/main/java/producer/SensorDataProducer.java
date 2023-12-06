package producer;

import java.util.*;
import java.util.concurrent.ExecutionException;

import org.apache.avro.generic.GenericRecord;
import org.apache.kafka.clients.admin.AdminClient;
import org.apache.kafka.clients.admin.ListTopicsResult;
import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;

import com.amazonaws.services.schemaregistry.serializers.avro.AWSKafkaAvroSerializer;
import com.amazonaws.services.schemaregistry.utils.AWSSchemaRegistryConstants;

import software.amazon.awssdk.services.glue.model.Compatibility;

public class SensorDataProducer {
    private Properties properties;
    private String topic;
    private String bootstrapServersConfig;
    private String awsRegion;
    private String registryName;
    private String schemaName;
    private boolean enableSSL;

    public SensorDataProducer(
            String topic,
            String bootstrapServersConfig,
            String awsRegion,
            String registryName,
            String schemaName,
            boolean enableSSL) {
        this.topic = topic;
        this.bootstrapServersConfig = bootstrapServersConfig;
        this.awsRegion = awsRegion;
        this.registryName = registryName;
        this.schemaName = schemaName;
        this.enableSSL = enableSSL;
        properties = setProperties();
    }

    private Properties setProperties() {
        Properties properties = new Properties();
        properties.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServersConfig);
        properties.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, AWSKafkaAvroSerializer.class.getName());
        properties.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, AWSKafkaAvroSerializer.class.getName());
        properties.put(AWSSchemaRegistryConstants.AWS_REGION, awsRegion);
        properties.put(AWSSchemaRegistryConstants.REGISTRY_NAME, registryName);
        properties.put(AWSSchemaRegistryConstants.SCHEMA_NAME, schemaName);
        properties.put(AWSSchemaRegistryConstants.COMPATIBILITY_SETTING, Compatibility.FULL);
        properties.put(AWSSchemaRegistryConstants.SCHEMA_AUTO_REGISTRATION_SETTING, true);
        if (enableSSL)
            properties.put("security.protocol", "SSL");

        return properties;
    }

    public boolean putKafkaRecord(GenericRecord sensorRecord) {

        if (!createKafkaTopic()) {
            return false;
        }

        KafkaProducer<String, GenericRecord> producer = new KafkaProducer<>(properties);
        final ProducerRecord<String, GenericRecord> record = new ProducerRecord<>(topic, sensorRecord);

        producer.send(record);
        producer.flush();
        producer.close();

        return true;
    }

    private boolean createKafkaTopic() {
        try (AdminClient adminClient = AdminClient.create(properties)) {
            ListTopicsResult listTopics = adminClient.listTopics();
            Set<String> names = listTopics.names().get();
            boolean contains = names.contains(topic);

            if (!contains) {
                List<NewTopic> newTopics = new ArrayList<>();
                int partitions = 2;
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

}
