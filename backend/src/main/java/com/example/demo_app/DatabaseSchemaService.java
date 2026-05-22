package com.example.demo_app;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class DatabaseSchemaService {

    private final DataSource dataSource;

    public String getSchemaDescription() {
        StringBuilder schemaBuilder = new StringBuilder();
        try (Connection connection = dataSource.getConnection()) {
            DatabaseMetaData metaData = connection.getMetaData();
            String catalog = connection.getCatalog();
            
            try (ResultSet tables = metaData.getTables(catalog, null, "%", new String[]{"TABLE"})) {
                while (tables.next()) {
                    String tableName = tables.getString("TABLE_NAME");
                    schemaBuilder.append("Table: ").append(tableName).append("\n");
                    schemaBuilder.append("Columns: ");
                    
                    List<String> columns = new ArrayList<>();
                    try (ResultSet rsColumns = metaData.getColumns(catalog, null, tableName, "%")) {
                        while (rsColumns.next()) {
                            String columnName = rsColumns.getString("COLUMN_NAME");
                            String columnType = rsColumns.getString("TYPE_NAME");
                            columns.add(columnName + " (" + columnType + ")");
                        }
                    }
                    schemaBuilder.append(String.join(", ", columns)).append("\n");
                }
            }
        } catch (SQLException e) {
            return "Error fetching schema: " + e.getMessage();
        }
        return schemaBuilder.toString();
    }
}
