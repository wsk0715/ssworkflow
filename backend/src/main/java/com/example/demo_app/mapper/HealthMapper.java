package com.example.demo_app.mapper;

import com.example.demo_app.model.HealthCheck;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface HealthMapper {
    HealthCheck check();
}
