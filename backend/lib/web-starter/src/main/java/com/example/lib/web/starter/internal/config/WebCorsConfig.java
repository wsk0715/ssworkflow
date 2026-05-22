package com.example.lib.web.starter.internal.config;

import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.core.Ordered;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

import com.example.lib.web.starter.internal.properties.WebProperties;

import lombok.RequiredArgsConstructor;

/**
 * 웹 모듈의 CORS(Cross-Origin Resource Sharing) 전역 설정을 담당하는 자동 구성 클래스
 * WebProperties에 정의된 설정값을 기반으로 CorsFilter 빈을 등록
 */
@AutoConfiguration
@RequiredArgsConstructor
@EnableConfigurationProperties(WebProperties.class)
public class WebCorsConfig {

    private final WebProperties webProperties;

    @Bean
    public FilterRegistrationBean<CorsFilter> corsFilter() {
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        CorsConfiguration config = new CorsConfiguration();
        
        config.setAllowedOriginPatterns(webProperties.allowedOrigins());
        config.setAllowedMethods(webProperties.allowedMethods());
        config.setAllowedHeaders(webProperties.allowedHeaders());
        config.setAllowCredentials(webProperties.allowCredentials());
        config.setMaxAge(webProperties.maxAge());

        source.registerCorsConfiguration("/**", config);
        
        FilterRegistrationBean<CorsFilter> bean = new FilterRegistrationBean<>(new CorsFilter(source));
        bean.setOrder(Ordered.HIGHEST_PRECEDENCE);
        return bean;
    }
}
