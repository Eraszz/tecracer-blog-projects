package consumer;

import java.util.HashMap;
import java.util.Map;
import org.apache.kafka.common.serialization.Deserializer;
import com.amazonaws.services.schemaregistry.deserializers.GlueSchemaRegistryKafkaDeserializer;
import com.amazonaws.services.schemaregistry.utils.AWSSchemaRegistryConstants;
import software.amazon.awssdk.auth.credentials.AwsCredentialsProvider;
import software.amazon.awssdk.auth.credentials.AwsSessionCredentials;
import software.amazon.awssdk.services.sts.StsClient;
import software.amazon.awssdk.services.sts.model.AssumeRoleResponse;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.sts.model.AssumeRoleRequest;
import software.amazon.awssdk.services.sts.model.Credentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.http.urlconnection.UrlConnectionHttpClient;

public class LambdaDeserializer implements Deserializer<Object> {
    private String awsRegion;
    private String registryName;
    private String roleArn;

    public LambdaDeserializer(String awsRegion, String registryName, String roleArn) {
        this.awsRegion = awsRegion;
        this.registryName = registryName;
        this.roleArn = roleArn;
    }

    private AwsCredentialsProvider getCredentialsProvider() {
        StsClient stsClient = StsClient.builder().httpClient(UrlConnectionHttpClient.builder().build()).region(Region.of(awsRegion)).build();
        AssumeRoleRequest roleRequest = AssumeRoleRequest.builder()
                .roleArn(roleArn)
                .roleSessionName("cross-account")
                .build();
        
        AssumeRoleResponse roleResponse = stsClient.assumeRole(roleRequest);
        Credentials myCreds = roleResponse.credentials();
        AwsSessionCredentials awsCredentials = AwsSessionCredentials.create(
                    myCreds.accessKeyId(),
                    myCreds.secretAccessKey(),
                    myCreds.sessionToken());
        return StaticCredentialsProvider.create(awsCredentials);
    }

    private Map<String, Object> getConfiguration() {
        Map<String, Object> config = new HashMap<>();
        config.put(AWSSchemaRegistryConstants.AWS_REGION, awsRegion);
        config.put(AWSSchemaRegistryConstants.REGISTRY_NAME, registryName);
        config.put(AWSSchemaRegistryConstants.AVRO_RECORD_TYPE, "GENERIC_RECORD");
        
        return config;
    }

    private GlueSchemaRegistryKafkaDeserializer getDeserializer(AwsCredentialsProvider credentialsProvider, Map<String, Object> RegistryConfig) {
        return new GlueSchemaRegistryKafkaDeserializer(credentialsProvider, RegistryConfig);
    }

    @Override
    public Object deserialize(String topic, byte[] data) {

        AwsCredentialsProvider credentialsProvider = getCredentialsProvider();
        Map<String, Object> RegistryConfig = getConfiguration();

        return getDeserializer(credentialsProvider, RegistryConfig).deserialize(topic, data);
    }
}
