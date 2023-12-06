package producer;

import java.time.LocalDateTime;
import java.time.temporal.ChronoField;
import java.util.HashMap;
import java.util.Map;

public class SensorDataGeneric {
    String deviceId;
    String timestamp;
    Map<String, Object> dataObject;

    public SensorDataGeneric(
            String deviceId,
            int temperature,
            Map<String, Object> dataObject) {
        this.deviceId = deviceId;
        this.timestamp = createTimestamp();
        this.dataObject = dataObject;
    }

    public Map<String, Object> getSensorData() {
        Map<String, Object> dataMap = new HashMap<>();
        dataMap.put("deviceId", deviceId);
        dataMap.put("timestamp", timestamp);

        for (Map.Entry<String, Object> entry : dataObject.entrySet()) {
            String key = entry.getKey();
            Object value = entry.getValue();

            dataMap.put(key, value);
        }

        return dataMap;
    }

    private String createTimestamp() {
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

    public Map<String, Object> getDataObject() {
        return dataObject;
    }

    public String deviceId() {
        return deviceId;
    }

    public String getTimestamp() {
        return timestamp;
    }
}
