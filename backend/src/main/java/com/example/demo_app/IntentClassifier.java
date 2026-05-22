package com.example.demo_app;

import dev.langchain4j.service.UserMessage;
import dev.langchain4j.service.V;

import dev.langchain4j.service.spring.AiService;

@AiService
public interface IntentClassifier {
    
    @UserMessage("""
        Analyze the user's request: '{{text}}'
        Current Time: {{currentTime}}
        Based on the following database schema, is this a request that can be answered by querying the database?
        
        Schema:
        {{schema}}
        
        Respond with ONLY 'YES' or 'NO'. (No punctuation)
        """)
    String classify(@V("text") String text, @V("schema") String schema, @V("currentTime") String currentTime);
}
