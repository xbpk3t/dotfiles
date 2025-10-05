-- PAG Development Environment MySQL Initialization Script

-- 创建数据库
CREATE DATABASE IF NOT EXISTS pag_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS n9e_v6 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS categraf CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 切换到 pag_dev 数据库
USE pag_dev;

-- 创建基础表结构
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- 创建监控配置表
CREATE TABLE IF NOT EXISTS service_configs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    config_json JSON,
    version VARCHAR(20) DEFAULT '1.0',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- 创建告警历史表
CREATE TABLE IF NOT EXISTS alert_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    alert_name VARCHAR(200) NOT NULL,
    severity ENUM('critical', 'warning', 'info') NOT NULL,
    service_name VARCHAR(100) NOT NULL,
    message TEXT,
    status ENUM('active', 'resolved', 'suppressed') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    metadata JSON
);

-- 创建指标数据表 (用于存储自定义指标)
CREATE TABLE IF NOT EXISTS metrics_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    metric_name VARCHAR(200) NOT NULL,
    metric_value DOUBLE NOT NULL,
    metric_labels JSON,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_metric_name (metric_name),
    INDEX idx_timestamp (timestamp)
);

-- 创建测试数据
INSERT INTO users (username, email, password_hash) VALUES
('admin', 'admin@pag-dev.local', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.'),
('user1', 'user1@pag-dev.local', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.'),
('monitoring', 'monitoring@pag-dev.local', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.')
ON DUPLICATE KEY UPDATE username = VALUES(username);

-- 插入示例服务配置
INSERT INTO service_configs (service_name, config_json) VALUES
('prometheus', '{"retention": "15d", "scrape_interval": "15s", "evaluation_interval": "15s"}'),
('grafana', {"admin_password": "admin123", "anonymous_access": false}'),
('alertmanager', {"config": {"global": {"resolve_timeout": "5m"}}}'),
('mysql', {"max_connections": 200, "buffer_pool_size": "512MB"})
ON DUPLICATE KEY UPDATE config_json = VALUES(config_json);

-- 创建监控用户
USE mysql;

-- 创建监控用户
CREATE USER IF NOT EXISTS 'monitoring'@'%' IDENTIFIED BY 'monitoring_password';
CREATE USER IF NOT EXISTS 'readonly'@'%' IDENTIFIED BY 'readonly_password';
CREATE USER IF NOT EXISTS 'grafana'@'%' IDENTIFIED BY 'grafana_password';

-- 授予权限
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, INDEX, CREATE TEMPORARY TABLES, EXECUTE, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, EVENT, TRIGGER ON *.* TO 'monitoring'@'%' WITH GRANT OPTION;
GRANT SELECT, SHOW VIEW ON *.* TO 'readonly'@'%';
GRANT SELECT ON *.* TO 'grafana'@'%';

-- 授予特定数据库权限
GRANT ALL PRIVILEGES ON pag_dev.* TO 'pag_user'@'%';
GRANT ALL PRIVILEGES ON n9e_v6.* TO 'pag_user'@'%';
GRANT ALL PRIVILEGES ON categraf.* TO 'pag_user'@'%';
GRANT SELECT, REPLICATION CLIENT ON *.* TO 'monitoring'@'%';

-- 刷新权限
FLUSH PRIVILEGES;

-- 创建夜莺相关表结构 (如果需要)
USE n9e_v6;

-- 基础表结构
CREATE TABLE IF NOT EXISTS alerts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    rule_id INT NOT NULL,
    severity VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'firing',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS alert_rules (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    expression TEXT NOT NULL,
    duration VARCHAR(50) DEFAULT '1m',
    severity VARCHAR(20) DEFAULT 'warning',
    disabled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_alerts_rule_id ON alerts(rule_id);
CREATE INDEX IF NOT EXISTS idx_alerts_status ON alerts(status);
CREATE INDEX IF NOT EXISTS idx_alerts_created_at ON alerts(created_at);
CREATE INDEX IF NOT EXISTS idx_alert_rules_name ON alert_rules(name);
CREATE INDEX IF NOT EXISTS idx_alert_rules_severity ON alert_rules(severity);

-- 插入示例告警规则
INSERT INTO alert_rules (name, expression, duration, severity) VALUES
('High CPU Usage', 'rate(process_cpu_seconds_total[5m]) * 100 > 80', '5m', 'warning'),
('High Memory Usage', '(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85', '5m', 'warning'),
('Service Down', 'up == 0', '1m', 'critical')
ON DUPLICATE KEY UPDATE expression = VALUES(expression);

-- 完成
SELECT 'MySQL initialization completed successfully' as status;
