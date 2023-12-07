package producer;

import org.apache.avro.Schema;
import org.apache.avro.SchemaBuilder;
import org.apache.avro.generic.GenericData;
import org.apache.avro.generic.GenericRecord;

import java.util.List;
import java.util.Map;

public class AvroSchemaGenerator {
    String schemaNamespace;
    String schemaName;
    GenericSensorData dataObject;

    public AvroSchemaGenerator(
            String schemaNamespace,
            String schemaName,
            GenericSensorData dataObject) {
        this.schemaNamespace = schemaNamespace;
        this.schemaName = schemaName;
        this.dataObject = dataObject;
    }

    public GenericRecord getGenericRecord(Map<String, Object> previousSchemaFieldsAndTypes) {
        return convertSchemaToGenericRecord(generateAvroSchema(previousSchemaFieldsAndTypes));
    }

    public Schema generateAvroSchema(Map<String, Object> previousSchemaFieldsAndTypes) {
        SchemaBuilder.RecordBuilder<Schema> recordBuilder = SchemaBuilder.record(schemaName)
                .namespace(schemaNamespace);
        SchemaBuilder.FieldAssembler<Schema> fieldAssembler = recordBuilder.fields();

        Map<String, Object> sensorData = dataObject.getSensorData();

        for (Map.Entry<String, Object> entry : previousSchemaFieldsAndTypes.entrySet()) {
            String fieldName = entry.getKey();
            Object previousFieldTypes = entry.getValue();
            Schema Union = null;
            boolean setDefault = false;

            if (sensorData.containsKey(fieldName)) {
                String currentFieldType = getFieldType(sensorData.get(fieldName));
                sensorData.remove(fieldName);

                if (previousFieldTypes instanceof List) {
                    @SuppressWarnings("unchecked")
                    List<String> previousFieldTypesList = (List<String>) previousFieldTypes;
                    Union = createUnionSchemaForList(currentFieldType, fieldName, previousFieldTypesList);
                    setDefault = true;
                } else {
                    String previousFieldType = (String) previousFieldTypes;
                    Union = createUnionSchemaForSingleType(currentFieldType, fieldName, previousFieldType);
                }
            } else {
                setDefault = true;
                if (previousFieldTypes instanceof List) {
                    @SuppressWarnings("unchecked")
                    List<String> previousFieldTypesList = (List<String>) previousFieldTypes;
                    Union = createUnionSchemaForList(null, fieldName, previousFieldTypesList);
                } else {
                    String previousFieldType = (String) previousFieldTypes;
                    Union = createUnionSchemaForSingleType(null, fieldName, previousFieldType);
                }
            }

            if (setDefault) {
                fieldAssembler = fieldAssembler.name(fieldName).type(Union).withDefault(null);
            } else {
                fieldAssembler = fieldAssembler.name(fieldName).type(Union).noDefault();
            }
        }

        for (Map.Entry<String, Object> entry : sensorData.entrySet()) {
            String fieldName = entry.getKey();
            String currentFieldType = getFieldType(entry.getValue());
            Schema fieldSchema;

            if (previousSchemaFieldsAndTypes.size() > 0) {
                fieldSchema = Schema.createUnion(Schema.create(Schema.Type.NULL),
                        getFieldSchema(fieldName, currentFieldType));
                fieldAssembler = fieldAssembler.name(fieldName).type(fieldSchema).withDefault(null);
            } else {
                fieldSchema = getFieldSchema(fieldName, currentFieldType);
                fieldAssembler = fieldAssembler.name(fieldName).type(fieldSchema).noDefault();
            }
        }

        return fieldAssembler.endRecord();
    }

        public GenericRecord convertSchemaToGenericRecord(Schema schema) {
        GenericRecord genericRecord = new GenericData.Record(schema);

        for (Map.Entry<String, Object> entry : dataObject.getSensorData().entrySet()) {
            String fieldName = entry.getKey();
            Object fieldValue = entry.getValue();

            genericRecord.put(fieldName, fieldValue);
        }

        return genericRecord;
    }

    private Schema createUnionSchemaForList(String currentFieldType, String fieldName,
            List<String> previousFieldTypesList) {
        Schema unionSchema = null;
        Schema fieldSchema;

        for (String previousFieldType : previousFieldTypesList) {
            if (currentFieldType == null) {
                fieldSchema = getFieldSchema(fieldName, previousFieldType);
            } else if (!currentFieldType.equals(previousFieldType)) {
                fieldSchema = getFieldSchema(fieldName, previousFieldType);
            } else {
                fieldSchema = getFieldSchema(currentFieldType, fieldName, previousFieldType);
            }

            if (unionSchema == null) {
                unionSchema = fieldSchema;
            } else {
                unionSchema = Schema.createUnion(unionSchema, fieldSchema);
            }
        }
        return unionSchema;
    }

    private Schema createUnionSchemaForSingleType(String currentFieldType, String fieldName, String previousFieldType) {
        Schema fieldSchema;

        if (currentFieldType == null) {
            fieldSchema = Schema.createUnion(Schema.create(Schema.Type.NULL),
                    getFieldSchema(fieldName, previousFieldType));
        } else if (!currentFieldType.equals(previousFieldType)) {
            fieldSchema = Schema.createUnion(Schema.create(Schema.Type.NULL),
                    getFieldSchema(fieldName, previousFieldType));
        } else {
            fieldSchema = getFieldSchema(currentFieldType, fieldName, previousFieldType);
        }

        return fieldSchema;
    }

    private String getFieldType(Object fieldValue) {
        if (fieldValue instanceof Integer) {
            return "int";
        } else if (fieldValue instanceof String) {
            return "string";
        } else {
            return null;
        }
    }

    private Schema getFieldSchema(String currentFieldType, String fieldName, String previousFieldType) {
        if (!currentFieldType.equals(previousFieldType)) {
            throw new IllegalArgumentException(
                    "Type mismatch of field: " + fieldName + "; Previous Type = " + previousFieldType
                            + " Current Type = " + currentFieldType);
        } else {
            if ("int".equals(currentFieldType)) {
                return Schema.create(Schema.Type.INT);
            } else if ("string".equals(currentFieldType)) {
                return Schema.create(Schema.Type.STRING);
            } else {
                throw new IllegalArgumentException(
                        "Field " + fieldName + "; Unsupported data type: " + currentFieldType);
            }
        }
    }

    private Schema getFieldSchema(String fieldName, String fieldType) {
        if ("string".equals(fieldType)) {
            return Schema.create(Schema.Type.STRING);
        } else if ("int".equals(fieldType)) {
            return Schema.create(Schema.Type.INT);
        } else if ("null".equals(fieldType)) {
            return Schema.create(Schema.Type.NULL);
        } else {
            throw new IllegalArgumentException("Field " + fieldName + "; Unsupported data type: " + fieldType);
        }
    }

}