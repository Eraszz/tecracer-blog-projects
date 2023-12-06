package producer;

import java.util.HashMap;
import java.util.Map;

public class SensorDataV2 extends SensorData {
    int humidity;

    public SensorDataV2(
            String deviceId,
            int temperature,
            int humidity) {
        super(deviceId, temperature);
        this.humidity = humidity;
    }

    public Map<String, Object> getSensorData() {
        Map<String, Object> dataMap = new HashMap<>();
        dataMap.put("deviceId", deviceId);
        dataMap.put("timestamp", timestamp);
        dataMap.put("temperature", temperature);
        dataMap.put("humidity", humidity+"%");
        return dataMap;
    }

    public int getHumidity() {
        return humidity;
    }
}
