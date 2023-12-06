package producer;

import java.util.*;

import org.apache.avro.generic.GenericRecord;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;

public class LambdaHandler implements RequestHandler<Map<String, Object>, Void> {

    private static final String bootstrapServersConfig = System.getenv("BOOTSTRAP_SERVERS_CONFIG");
    private static final String topic = System.getenv("TOPIC");
    private static final String awsRegion = System.getenv("AWS_REGION");
    private static final String registryName = System.getenv("REGISTRY_NAME");
    private static final String schemaName = System.getenv("SCHEMA_NAME");
    private static final String schemaNameSpace = System.getenv("SCHEMA_NAMESPACE");
    private static final String deviceId = System.getenv("DEVICE_ID");

    @Override
    public Void handleRequest(Map<String, Object> event, Context context) {

        SensorDataProducer sensorDataProducer = new SensorDataProducer(
                topic,
                bootstrapServersConfig,
                awsRegion,
                registryName,
                schemaName,
                true);

        SensorData sensorData = new SensorData(deviceId, event);

        GlueSchemaRegistryHandler glueSchemaRegistryHandler = new GlueSchemaRegistryHandler(awsRegion, registryName);

        AvroSchemaGenerator avroSchemaGenerator = new AvroSchemaGenerator(schemaNameSpace, schemaName, sensorData);
        GenericRecord sensorRecord = avroSchemaGenerator
                .getGenericRecord(glueSchemaRegistryHandler.getLatestSchemaFieldNamesAndTypes(schemaName));

        sensorDataProducer.putKafkaRecord(sensorRecord);

        return null;
    }

    public static void main(String[] args) {

        Map<String, Object> event = new HashMap<>();

        // Add key-value pairs to the map
        event.put("temperature", 25);
        event.put("New", "nrewnrw");
        event.put("alpha", 123);

        event.put("brandy", 123);

        SensorDataProducer sensorDataProducer = new SensorDataProducer(
                topic,
                bootstrapServersConfig,
                awsRegion,
                registryName,
                schemaName,
                false);

        SensorData sensorData = new SensorData(deviceId, event);

        GlueSchemaRegistryHandler glueSchemaRegistryHandler = new GlueSchemaRegistryHandler(awsRegion, registryName);

        AvroSchemaGenerator avroSchemaGenerator = new AvroSchemaGenerator(schemaNameSpace, schemaName, sensorData);
        GenericRecord sensorRecord = avroSchemaGenerator
                .getGenericRecord(glueSchemaRegistryHandler.getLatestSchemaFieldNamesAndTypes(schemaName));

        sensorDataProducer.putKafkaRecord(sensorRecord);
    }
}
