package com.example.demo_app;

import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import dev.langchain4j.service.V;
import dev.langchain4j.service.spring.AiService;

@AiService
public interface SqlAssistant {
    
    @SystemMessage("""
        You are a MySQL expert. 
        Current Time: {{currentTime}}
        Database Schema:
        {{schema}}
        
        Rules:
        - Return ONLY the SQL query.
        - Do not use markdown backticks.
        - Only generate SELECT queries.
        """)
    String generateSql(@V("schema") String schema, @V("question") @UserMessage String question, @V("currentTime") String currentTime);
}
