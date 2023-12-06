package producer;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.List;
import java.util.Iterator;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import com.amazonaws.services.schemaregistry.common.AWSSchemaRegistryClient;

import software.amazon.awssdk.http.urlconnection.UrlConnectionHttpClient;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.glue.GlueClient;
import software.amazon.awssdk.services.glue.model.ListSchemaVersionsRequest;
import software.amazon.awssdk.services.glue.model.ListSchemaVersionsResponse;
import software.amazon.awssdk.services.glue.model.ListSchemasRequest;
import software.amazon.awssdk.services.glue.model.ListSchemasResponse;
import software.amazon.awssdk.services.glue.model.RegistryId;
import software.amazon.awssdk.services.glue.model.SchemaId;
import software.amazon.awssdk.services.glue.model.SchemaVersionListItem;
import software.amazon.awssdk.services.glue.model.GetSchemaVersionResponse;

public class GlueSchemaRegistryHandler {
    private String awsRegion;
    private String registryName;

    public GlueSchemaRegistryHandler(String awsRegion, String registryName) {
        this.awsRegion = awsRegion;
        this.registryName = registryName;
    }

    public Map<String, Object> getLatestSchemaFieldNamesAndTypes(String schemaName) {
        Map<String, Object> latestSchemaFieldNamesAndTypes = new HashMap<>();

        GlueClient glueClient = GlueClient.builder().httpClient(UrlConnectionHttpClient.builder().build())
                .region(Region.of(awsRegion)).build();
        AWSSchemaRegistryClient awsSchemaRegistryClient = new AWSSchemaRegistryClient(glueClient);

        RegistryId registryId = RegistryId.builder()
                .registryName(registryName)
                .build();
        ListSchemasRequest listSchemasRequest = ListSchemasRequest.builder().registryId(registryId).build();

        ListSchemasResponse listSchemasResponse = glueClient.listSchemas(listSchemasRequest);

        if (listSchemasResponse.schemas().size() > 0) {
            SchemaId schemaId = SchemaId.builder().registryName(registryName).schemaName(schemaName).build();
            ListSchemaVersionsRequest schemaVersionsRequest = ListSchemaVersionsRequest.builder().schemaId(schemaId)
                    .build();

            ListSchemaVersionsResponse schemaList = glueClient.listSchemaVersions(schemaVersionsRequest);
            GetSchemaVersionResponse getSchemaVersionResponse = awsSchemaRegistryClient
                    .getSchemaVersionResponse(getHighestAvailableSchemaVersionId(schemaList.schemas()));

            try {
                latestSchemaFieldNamesAndTypes = extractFieldNamesAndTypes(getSchemaVersionResponse.schemaDefinition());
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        return latestSchemaFieldNamesAndTypes;
    }

    private String getHighestAvailableSchemaVersionId(List<SchemaVersionListItem> schemaList) {
        SchemaVersionListItem highestAvailableSchema = null;
        long maxVersionNumber = Integer.MIN_VALUE;

        for (SchemaVersionListItem schema : schemaList) {
            if ("AVAILABLE".equals(schema.statusAsString()) && schema.versionNumber() > maxVersionNumber) {
                maxVersionNumber = schema.versionNumber();
                highestAvailableSchema = schema;
            }
        }
        return highestAvailableSchema.schemaVersionId();
    }

    private static Map<String, Object> extractFieldNamesAndTypes(String jsonString) throws IOException {
        Map<String, Object> flatMap = new HashMap<>();

        ObjectMapper objectMapper = new ObjectMapper();
        JsonNode jsonNode = objectMapper.readTree(jsonString);

        if (jsonNode.has("fields") && jsonNode.get("fields").isArray()) {

            Iterator<JsonNode> fieldsIterator = jsonNode.get("fields").elements();
            while (fieldsIterator.hasNext()) {
                JsonNode fieldNode = fieldsIterator.next();
                if (fieldNode.has("name") && fieldNode.has("type")) {
                    String fieldName = fieldNode.get("name").asText();
                    JsonNode typeNode = fieldNode.get("type");

                    Object fieldTypes;
                    if (typeNode.isArray() && typeNode.size() > 1) {
                        List<String> typesList = new ArrayList<>();
                        for (JsonNode element : typeNode) {
                            typesList.add(element.asText());
                        }
                        fieldTypes = typesList;
                    } else {
                        fieldTypes = typeNode.asText();
                    }
                    flatMap.put(fieldName, fieldTypes);
                }
            }
        } else {
            System.out.println("Invalid JSON format - 'fields' not found or not an array.");
        }

        return flatMap;
    }
}
