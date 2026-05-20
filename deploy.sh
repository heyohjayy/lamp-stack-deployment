#!/usr/bin/env bash

# =========================================================
# LAMP STACK DEPLOYMENT SCRIPT
# Loreon Learning Platform
# Ubuntu 22.04 / 24.04
# =========================================================

set -euo pipefail

# =========================================================
# VARIABLES
# =========================================================

LOG_FILE="/var/log/lamp-deploy.log"

DB_NAME="learningdb"
DB_USER="learninguser"
DB_PASSWORD="StrongPassword123!"

APP_DIR="/var/www/html"

REPO_URL="https://github.com/Loreon-Learning-c001-26-07/loreon-learning-platform.git"

# =========================================================
# LOGGING FUNCTION
# =========================================================

log() {
    echo "$(date '+%d-%m-%Y %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# =========================================================
# COMMAND EXECUTION FUNCTION
# =========================================================

run_command() {
    log "Running: $1"
    eval "$1"
}

# =========================================================
# PACKAGE INSTALLATION FUNCTION
# =========================================================

install_package() {
    local package="$1"

    if dpkg -s "$package" >/dev/null 2>&1; then
        log "$package is already installed. Skipping."
    else
        log "Installing $package..."
        run_command "apt-get install $package -y"
    fi
}

# =========================================================
# SERVICE MANAGEMENT FUNCTION
# =========================================================

enable_service() {
    local service="$1"

    log "Starting $service service..."
    run_command "systemctl start $service"

    log "Enabling $service service..."
    run_command "systemctl enable $service"
}

# =========================================================
# FIREWALL CONFIGURATION FUNCTION
# =========================================================

open_firewall_port() {
    local port="$1"

    log "Opening firewall port $port..."
    run_command "firewall-cmd --permanent --add-port=$port"
}

# =========================================================
# DATABASE CREATION FUNCTION
# =========================================================

create_database() {

    log "Creating database $DB_NAME..."

    mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"

    log "Creating database user $DB_USER..."

    mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"

    log "Granting privileges on $DB_NAME to $DB_USER..."

    mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"

    mysql -e "FLUSH PRIVILEGES;"
}

# =========================================================
# COURSES TABLE CREATION FUNCTION
# =========================================================

create_courses_table() {

    log "Creating courses table..."

    mysql "$DB_NAME" <<EOF
CREATE TABLE IF NOT EXISTS courses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(255),
    Duration VARCHAR(100),
    ImageUrl VARCHAR(500),
    Description TEXT
);
EOF
}

# =========================================================
# SEED DATA INSERTION FUNCTION
# =========================================================

insert_seed_data() {

    log "Inserting seed course data..."

    mysql -e "USE $DB_NAME; DELETE FROM courses;"

    mysql "$DB_NAME" <<EOF
INSERT INTO courses (Name, Duration, ImageUrl, Description)
VALUES
('Linux Fundamentals', '6 Weeks', 'linux.jpg', 'Learn Linux administration basics.'),
('AWS Cloud Engineering', '8 Weeks', 'aws.jpg', 'Master AWS infrastructure and deployment.'),
('Docker Essentials', '4 Weeks', 'docker.jpg', 'Containerisation using Docker.'),
('Kubernetes Administration', '10 Weeks', 'kubernetes.jpg', 'Learn Kubernetes orchestration.'),
('Terraform Automation', '5 Weeks', 'terraform.jpg', 'Infrastructure as Code with Terraform.'),
('CI/CD Pipelines', '6 Weeks', 'cicd.jpg', 'Build automated deployment pipelines.'),
('Python for DevOps', '7 Weeks', 'python.jpg', 'Automation scripting using Python.'),
('Monitoring and Logging', '4 Weeks', 'monitoring.jpg', 'Infrastructure monitoring and observability.');
EOF
}

# =========================================================
# SCRIPT START
# =========================================================

log "Starting LAMP stack deployment..."

# =========================================================
# SYSTEM UPDATE
# =========================================================

log "Updating package lists..."
run_command "apt-get update -y"

log "Upgrading installed packages..."
run_command "apt-get upgrade -y"

# =========================================================
# PACKAGE INSTALLATION
# =========================================================

install_package apache2
install_package mysql-server
install_package php
install_package php-mysql
install_package firewalld
install_package git

log "Base package installation phase completed."

# =========================================================
# SERVICE MANAGEMENT
# =========================================================

enable_service apache2
enable_service mysql
enable_service firewalld

log "Service management phase completed."

# =========================================================
# FIREWALL CONFIGURATION
# =========================================================

open_firewall_port 80/tcp
open_firewall_port 3306/tcp

log "Reloading firewall rules..."
run_command "firewall-cmd --reload"

log "Firewall configuration phase completed."

# =========================================================
# DATABASE PROVISIONING
# =========================================================

create_database
create_courses_table
insert_seed_data

log "Database provisioning phase completed."

# =========================================================
# APPLICATION DEPLOYMENT PHASE
# =========================================================

log "Starting application deployment phase..."

log "Cleaning Apache web root directory..."
run_command "rm -rf $APP_DIR/*"
run_command "rm -rf $APP_DIR/.[!.]*"

log "Cloning Loreon Learning platform repository..."
run_command "git clone $REPO_URL $APP_DIR"

log "Setting correct ownership for Apache..."
run_command "chown -R www-data:www-data $APP_DIR"

log "Setting correct permissions..."
run_command "chmod -R 755 $APP_DIR"

log "Restarting Apache service..."
run_command "systemctl restart apache2"

log "Application deployment phase complete."

# =========================================================
# DEPLOYMENT COMPLETE
# =========================================================

log "LAMP stack deployment completed successfully."
