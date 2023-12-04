package consumer;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;

import java.util.Map;

public class LambdaHandler implements RequestHandler<Map<String, Object>, Void> {

    private static final String awsRegion = System.getenv("AWS_REGION");
    private static final String registryName = System.getenv("REGISTRY_NAME");
    private static final String roleArn = System.getenv("ROLE_ARN");

    @Override
    public Void handleRequest(Map<String, Object> event, Context context) {
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

        return null;
    }
}
