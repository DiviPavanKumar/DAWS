#!/bin/bash
date_var=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(basename "$0")
LOGFILE="/tmp/${SCRIPT_NAME}-${date_var}.log"
SCRIPT_DIR=$PWD

# Define color codes for output
R="\e[31m"  # Red (Failure)
G="\e[32m"  # Green (Success)
Y="\e[33m"  # Yellow (Info)
N="\e[0m"   # Reset color

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${R}Error: Please run this script with sudo access.${N}"
    exit 1
fi

# Validation function
VALIDATE() {
    if [ $? -ne 0 ]; then
        echo -e "$2 ..... ${R}Failed${N}"
        exit 1
    else
        echo -e "$2 ...... ${G}Successful${N}"
    fi
}

dnf module disable nginx -y &>> $LOGFILE
VALIDATE $? "disabling module nginx"

dnf module enable nginx:1.24 -y &>> $LOGFILE
VALIDATE $? "enabling module nginx"

dnf install nginx -y &>> $LOGFILE
VALIDATE $? "Installing nginx"

systemctl enable nginx &>> $LOGFILE
VALIDATE $? "Enabling nginx"

systemctl start nginx &>> $LOGFILE
VALIDATE $? "Starting nginx"

rm -rf /usr/share/nginx/html/* &>> $LOGFILE
VALIDATE $? "Removing the html file"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>> $LOGFILE
VALIDATE $? "Curl"

cd /usr/share/nginx/html &>> $LOGFILE
VALIDATE $? "cd html"

unzip /tmp/frontend.zip &>> $LOGFILE
VALIDATE $? "unzip"

rm -rf /etc/nginx/nginx.conf & >> $LOGFILE
VALIDATE $? "Remove default nginx conf"

cp $SCRIPT_DIR/roboshop.conf /etc/nginx/nginx.conf >> $LOGFILE
VALIDATE $? "coping the roboshop.conf"

systemctl restart nginx &>> $LOGFILE
VALIDATE $? "restarting nginx"