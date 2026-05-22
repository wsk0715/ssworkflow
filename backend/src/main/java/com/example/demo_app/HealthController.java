package com.example.demo_app;

import com.example.demo_app.mapper.HealthMapper;
import com.example.demo_app.model.HealthCheck;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class HealthController {

    private final HealthMapper healthMapper;

    @GetMapping("/health")
    public HealthCheck health() {
        return healthMapper.check();
    }
}
