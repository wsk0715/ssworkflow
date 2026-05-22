package com.example.demo_app;

import dev.langchain4j.data.message.ChatMessage;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class ChatHistoryService {

    private final Map<String, List<ChatMessage>> history = new ConcurrentHashMap<>();
    private static final int MAX_MESSAGES = 10;

    public void addMessage(String userId, ChatMessage message) {
        history.compute(userId, (id, messages) -> {
            List<ChatMessage> list = (messages == null) ? new ArrayList<>() : messages;
            list.add(message);
            if (list.size() > MAX_MESSAGES) {
                list.remove(0);
            }
            return list;
        });
    }

    public List<ChatMessage> getHistory(String userId) {
        return history.getOrDefault(userId, new ArrayList<>());
    }

    public void clearHistory(String userId) {
        history.remove(userId);
    }
}
