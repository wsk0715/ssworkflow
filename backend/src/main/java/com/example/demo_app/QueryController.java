package com.example.demo_app;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo_app.dto.QueryRequest;
import com.example.demo_app.dto.QueryResult;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@RestController
@RequestMapping("/api/query")
@RequiredArgsConstructor
public class QueryController {

    private final Nl2SqlService nl2sqlService;

    @PostMapping
    public QueryResult query(
            @RequestBody QueryRequest query,
            @RequestHeader(value = "X-Employee-Id", required = false) String employeeId) {
        log.info("Request from Employee ID: {}", employeeId);
        return nl2sqlService.ask(query.question(), employeeId);
    }
}
