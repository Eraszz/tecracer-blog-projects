package producer;

import java.util.*;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;

public class LambdaHandler implements RequestHandler<Map<String, Object>, Void> {

    private static final String bootstrapServersConfig = System.getenv("BOOTSTRAP_SERVERS_CONFIG");
    private static final String topic = System.getenv("TOPIC");
    private static final String awsRegion = System.getenv("AWS_REGION");
    private static final String registryName = System.getenv("REGISTRY_NAME");
    private static final String schemaName = System.getenv("SCHEMA_NAME");
    private static final String schemaPathname = System.getenv("SCHEMA_PATHNAME");
    private static final String deviceId = System.getenv("DEVICE_ID");

    @Override
    public Void handleRequest(Map<String, Object> event, Context context) {

        SensorDataProducer sensorRecord = new SensorDataProducer(
                topic,
                schemaPathname,
                bootstrapServersConfig,
                awsRegion,
                registryName,
                schemaName,
                true);

        GenericSensorData sensorData;
        int temperature = (int) event.get("temperature");

        if ("schema_v2.avsc".equals(schemaPathname)) {
            int humidity = (int) event.get("humidity");
            sensorData = new SensorDataV2(deviceId, temperature, humidity);
        } else {
            sensorData = new SensorData(deviceId, temperature);
        }
        
        sensorRecord.putKafkaRecord(sensorData);
        return null;
    }
}
