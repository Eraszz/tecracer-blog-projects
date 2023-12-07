package consumer;

import java.util.Map;
import java.util.HashMap;
import com.fasterxml.jackson.databind.ObjectMapper;

import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.AttributeValue;
import software.amazon.awssdk.services.dynamodb.model.PutItemRequest;
import software.amazon.awssdk.http.urlconnection.UrlConnectionHttpClient;

public class DynamoDBRecordHandler {
    private String dynamodbTableName;

    public DynamoDBRecordHandler(String dynamodbTableName) {
        this.dynamodbTableName = dynamodbTableName;
    }

    public Void storeItem(String jsonString) {

        Map<String, AttributeValue> item = createAttributeMap(jsonString);

        DynamoDbClient dynamoDbClient = DynamoDbClient.builder().httpClient(UrlConnectionHttpClient.builder().build())
                .build();
        ;
        PutItemRequest putItemRequest = PutItemRequest.builder()
                .tableName(dynamodbTableName)
                .item(item)
                .build();

        dynamoDbClient.putItem(putItemRequest);

        return null;
    }

    @SuppressWarnings("unchecked")
    private Map<String, AttributeValue> createAttributeMap(String jsonString) {
        Map<String, AttributeValue> item = new HashMap<>();

        ObjectMapper objectMapper = new ObjectMapper();
        try {
            Map<String, Object> jsonData = objectMapper.readValue(jsonString, Map.class);

            for (Map.Entry<String, Object> entry : jsonData.entrySet()) {
                String key = entry.getKey();
                Object value = entry.getValue();

                AttributeValue attributeValue;

                if (value instanceof String) {
                    String stringValue = String.valueOf(value);
                    attributeValue = AttributeValue.builder().s(stringValue).build();
                    item.put(key, attributeValue);
                } else if (value instanceof Integer) {
                    String stringValue = String.valueOf(value);
                    attributeValue = AttributeValue.builder().n(stringValue).build();
                    item.put(key, attributeValue);
                }                
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return item;
    }
}