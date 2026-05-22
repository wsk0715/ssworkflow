package com.example.demo_app.dto;

import java.util.List;
import java.util.Map;

public record QueryResult (
    String generatedSql,
    List<Map<String, Object>> data,
    String answer
) {
    public QueryResult(String generatedSql) {
        this(generatedSql, null, null);
    }
}
