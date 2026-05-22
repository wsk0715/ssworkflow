package com.example.demo_app;

import dev.langchain4j.data.message.UserMessage;
import dev.langchain4j.data.message.AiMessage;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.example.demo_app.dto.QueryResult;
import com.example.demo_app.mapper.RawSqlMapper;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@RequiredArgsConstructor
public class Nl2SqlService {

    private final SqlAssistant sqlAssistant;
    private final IntentClassifier intentClassifier;
    private final AnswerGenerator answerGenerator;
    private final RawSqlMapper rawSqlMapper;
    private final DatabaseSchemaService databaseSchemaService;
    private final ChatHistoryService chatHistoryService;

    public QueryResult ask(String question, String employeeId) {
        log.info("\nQuestion: {} (Employee: {}) \n", question, employeeId);
        
        String answer;
        String currentTime = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        String history = chatHistoryService.getHistory(employeeId).toString();

        // Step 0: Get dynamic schema
        String schema = databaseSchemaService.getSchemaDescription();
        log.info("\nStep 0 (Schema):\n{}", schema);

        // Step 1: Intent Classification
        String rawIntent = intentClassifier.classify(question, schema, currentTime);
        String intent = rawIntent != null ? rawIntent.toUpperCase().replaceAll("[^A-Z]", "") : "";
        log.info("\nStep 1 (Intent Raw):\n{}", rawIntent);

        if (intent.contains("NO")) {
            return new QueryResult(null, null, "데이터 조회와 관련 없는 질문입니다.");
        }

        // Step 2: SQL Generation
        String contextWithHistory = schema + "\n\nPrevious Conversation History:\n" + history;
        String sql = sqlAssistant.generateSql(contextWithHistory, question, currentTime);
        sql = sanitize(sql);
        log.info("Step 2 (SQL): {}", sql);

        // Step 2.5: Security Validation
        if (!isSafeQuery(sql)) {
            log.error("Security Block: Invalid or dangerous SQL detected.");
            return new QueryResult(sql, null, "보안 정책상 허용되지 않는 쿼리이거나 부적절한 요청입니다.");
        }

        // Step 3: Execution
        List<Map<String, Object>> data;
        try {
            data = rawSqlMapper.executeRawSql(sql);
        } catch (Exception e) {
            log.error("Execution Error: {}", e.getMessage());
            return new QueryResult(sql, null, "쿼리 실행 중 오류가 발생했습니다: " + e.getMessage());
        }
        log.info("\nStep 3 (Data):\n{} ", data);

        // Step 4: Answer Generation
        answer = answerGenerator.generateAnswer(question, data.toString());
        log.info("\nStep 4 (Answer):\n{} ", answer);
        
        // Save to history
        chatHistoryService.addMessage(employeeId, UserMessage.from(question));
        chatHistoryService.addMessage(employeeId, AiMessage.from(answer));
        
        return new QueryResult(sql, data, answer);
    }

    private String sanitize(String sql) {
        return sql.replace("```sql", "").replace("```", "").trim();
    }

    private boolean isSafeQuery(String sql) {
        if (sql == null || sql.isEmpty()) return false;
        
        String upperSql = sql.toUpperCase().trim();
        int length = upperSql.length();
        
        // 1. Must start with SELECT or SHOW
        if (!upperSql.startsWith("SELECT") && !upperSql.startsWith("SHOW")) return false;
        
        // 2. No multi-statements (allowing only trailing semicolon)
        int semicolonIndex = upperSql.indexOf(';');
        if (semicolonIndex != -1 && semicolonIndex < length - 1) {
            return false;
        }
        
        // 3. Block dangerous keywords
        String[] forbiddenKeywords = {"INSERT", "UPDATE", "DELETE", "DROP", "ALTER", "TRUNCATE", "CREATE"};
        for (String keyword : forbiddenKeywords) {
            if (upperSql.contains(" " + keyword + " ") || upperSql.contains("\n" + keyword + "\n")) {
                return false;
            }
        }
        
        return true;
    }
}
