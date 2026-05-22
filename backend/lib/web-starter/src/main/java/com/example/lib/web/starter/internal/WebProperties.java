package com.example.lib.web.starter.internal.properties;

import java.util.List;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;
import org.springframework.validation.annotation.Validated;

@Validated
@ConfigurationProperties(prefix = "web")
public record WebProperties(
    @DefaultValue("*")
    List<String> allowedOrigins,
    
    @DefaultValue({"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"})
    List<String> allowedMethods,
    
    @DefaultValue("*")
    List<String> allowedHeaders,
    
    @DefaultValue("true")
    Boolean allowCredentials,
    
    @DefaultValue("3600")
    Long maxAge,

    @DefaultValue("com.example")
    List<String> responseFilterPrefixes
) {}
