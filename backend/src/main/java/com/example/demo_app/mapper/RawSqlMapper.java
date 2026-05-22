package com.example.demo_app.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;
import java.util.List;
import java.util.Map;

@Mapper
public interface RawSqlMapper {
    @Select("${sql}")
    List<Map<String, Object>> executeRawSql(String sql);
}
