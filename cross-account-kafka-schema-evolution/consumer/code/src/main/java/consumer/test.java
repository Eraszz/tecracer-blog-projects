package consumer;

import java.io.IOException;
import java.util.Map;
import java.io.File;

import com.fasterxml.jackson.databind.ObjectMapper;

public class test {

    private static final String awsRegion = System.getenv("AWS_REGION");
    private static final String registryName = System.getenv("REGISTRY_NAME");
    private static final String roleArn = System.getenv("ROLE_ARN");
    public static void main(String[] args) {

        String jsonFilePath = "test.json";
        Map<String, Object> event = null;

        try {
            // Use Jackson ObjectMapper to read JSON file and convert to Map
            ObjectMapper objectMapper = new ObjectMapper();
            File jsonFile = new File(jsonFilePath);
            event = objectMapper.readValue(jsonFile, Map.class);

            // Print the Map
            System.out.println("Content of Map:");
            for (Map.Entry<String, Object> entry : event.entrySet()) {
                System.out.println(entry.getKey() + ": " + entry.getValue());
            }
        } catch (IOException e) {
            e.printStackTrace();
        }

        LambdaDeserializer deserializer = new LambdaDeserializer(awsRegion, registryName, roleArn);

        if (event.containsKey("records")) {
            @SuppressWarnings("unchecked")
            Map<String, Object> recordsMap = (Map<String, Object>) event.get("records");

            for (Map.Entry<String, Object> entry : recordsMap.entrySet()) {
                Object records = entry.getValue();

                if (records instanceof Iterable) {
                    for (Object record : (Iterable<?>) records) {
                        if (record instanceof Map) {
                            @SuppressWarnings("unchecked")
                            EventRecord eventRecord = new EventRecord((Map<String, Object>) record);
                            System.out.println(eventRecord.parseRecord(deserializer, false));
                        }
                    }
                }
            }
        }
    }
}
