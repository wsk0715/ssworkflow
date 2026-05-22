package com.example.demo_app;

import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import dev.langchain4j.service.V;
import dev.langchain4j.service.spring.AiService;

@AiService
public interface AnswerGenerator {

    @SystemMessage("""
        You are a data analyst. 
        Based on the user's question and the database result provided, give a clear and concise answer in Korean.
        If the result is empty, say that no information was found.
        """)
    @UserMessage("""
        question: {{question}}
        result: {{result}}
        """)
    String generateAnswer(@V("question") String question, @V("result") String result);
}
