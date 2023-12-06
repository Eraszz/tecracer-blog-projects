package producer;

import java.time.LocalDateTime;
import java.time.temporal.ChronoField;
import java.util.HashMap;
import java.util.Map;

public class SensorData implements GenericSensorData {
    String deviceId;
    int temperature;
    String timestamp;

    public SensorData(
            String deviceId,
            int temperature) {
        this.deviceId = deviceId;
        this.temperature = temperature;
        this.timestamp = createTimestamp();
    }

    public Map<String, Object> getSensorData() {
        Map<String, Object> dataMap = new HashMap<>();
        dataMap.put("deviceId", deviceId);
        dataMap.put("timestamp", timestamp);
        dataMap.put("temperature", temperature);
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

    public int getTemperature() {
        return temperature;
    }

    public String deviceId() {
        return deviceId;
    }

    public String getTimestamp() {
        return timestamp;
    }
}
