package consumer;

import java.util.Map;
import java.util.HashMap;
import com.fasterxml.jackson.databind.ObjectMapper;

import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.*;

public class StoreRecord {

    private String dynamodbTableName;

    public StoreRecord(String dynamodbTableName) {
        this.dynamodbTableName = dynamodbTableName;
    }

    public Void putItem(String jsonString) {

        Map<String, AttributeValue> item = getAttributeMap(jsonString);

        DynamoDbClient dynamoDbClient = DynamoDbClient.create();
        PutItemRequest putItemRequest = PutItemRequest.builder()
        .tableName(dynamodbTableName)
        .item(item)
        .build();

        dynamoDbClient.putItem(putItemRequest);

        return null;
    }
    
    @SuppressWarnings("unchecked")
    private Map<String, AttributeValue> getAttributeMap(String jsonString){
        Map<String, AttributeValue> item = new HashMap<>();

        ObjectMapper objectMapper = new ObjectMapper();
        try {
            Map<String, Object> jsonData = objectMapper.readValue(jsonString, Map.class);

            for (Map.Entry<String, Object> entry : jsonData.entrySet()) {
                String key = entry.getKey();
                Object value = entry.getValue();
                String stringValue = (String) value;

                AttributeValue attributeValue;

                if (value instanceof String) {
                    attributeValue = AttributeValue.builder().s(stringValue).build();
                } else if (value instanceof Integer) {
                    attributeValue = AttributeValue.builder().n(stringValue).build();
                } else {
                    System.out.println(key + " has an unknown type");
                    return null;
                }

                item.put(entry.getKey(), attributeValue);
            }
        } catch (Exception e) {
            e.printStackTrace();
        } 

        return item;
    }
}
