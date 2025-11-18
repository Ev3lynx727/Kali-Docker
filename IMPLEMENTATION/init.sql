-- PostgreSQL initialization script for dev environment

-- Create development database
CREATE DATABASE IF NOT EXISTS devdb;

-- Create development user with privileges
CREATE USER IF NOT EXISTS devuser WITH ENCRYPTED PASSWORD 'devpass123';
GRANT ALL PRIVILEGES ON DATABASE devdb TO devuser;

-- Create sample tables for development
\c devdb;

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS logs (
    id SERIAL PRIMARY KEY,
    level VARCHAR(10) NOT NULL,
    message TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO users (username, email) VALUES
    ('admin', 'admin@kali-docker.local'),
    ('user1', 'user1@kali-docker.local')
ON CONFLICT (username) DO NOTHING;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON logs(timestamp);