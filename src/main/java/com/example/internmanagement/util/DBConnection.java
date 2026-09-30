package com.example.internmanagement.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBConnection {

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(
                requiredEnvironmentVariable("IMS_DB_URL"),
                requiredEnvironmentVariable("IMS_DB_USER"),
                requiredEnvironmentVariable("IMS_DB_PASSWORD"));
    }

    private static String requiredEnvironmentVariable(String name) throws SQLException {
        String value = System.getenv(name);
        if (value == null || value.isBlank()) {
            throw new SQLException("Required environment variable " + name + " is not set");
        }
        return value;
    }
}