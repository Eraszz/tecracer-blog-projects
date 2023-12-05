package consumer;

import java.util.Map;

import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.HashMap;
import java.util.ArrayList;
import java.util.Base64;

public class EventRecord {
    private String topic;
    private int partition;
    private int offset;
    private long timestamp;
    private String timestampType;
    private String value;
    private ArrayList<String> headers;

    @SuppressWarnings("unchecked")
    public EventRecord(Map<String, Object> record) {
        this.topic = (String) record.get("topic");
        this.partition = (int) record.get("partition");
        this.offset = (int) record.get("offset");
        this.timestamp = (long) record.get("timestamp");
        this.timestampType = (String) record.get("timestampType");
        this.value = (String) record.get("value");
        this.headers = (ArrayList<String>) record.get("headers");
    }

    public Object parseValue(LambdaDeserializer deserializer) {
        byte[] decodedValue = Base64.getDecoder().decode(this.value);
        return deserializer.deserialize(this.topic, decodedValue);
    }

    public Map<String, Object> parseRecord(LambdaDeserializer deserializer, boolean toJson) {
        Map<String, Object> rec = new HashMap<>(Map.of(
                "topic", this.topic,
                "partition", this.partition,
                "offset", this.offset,
                "timestamp", this.timestamp,
                "timestampType", this.timestampType,
                "value", this.parseValue(deserializer),
                "headers", this.headers
        ));

        if (toJson) {
            return serialize(rec);
        }

        return rec;
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> serialize(Map<String, Object> obj) {
        ObjectMapper objectMapper = new ObjectMapper();
        
        return objectMapper.convertValue(obj, Map.class);
    }

    public String getTopic() {
        return topic;
    }

    public int getPartition() {
        return partition;
    }

    public int getOffset() {
        return offset;
    }

    public long getTimestamp() {
        return timestamp;
    }

    public String getTimestampType() {
        return timestampType;
    }

    public String getValue() {
        return value;
    }

    public ArrayList<String> getHeaders() {
        return headers;
    }
}
