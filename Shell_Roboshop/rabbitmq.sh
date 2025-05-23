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

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>> $LOGFILE
VALIDATE $? "coping the rebbitmq.repo"

dnf install rabbitmq-server -y &>> $LOGFILE
VALIDATE $? "Installing rabbitMQ server"

systemctl enable rabbitmq-server &>> $LOGFILE
VALIDATE $? "Enabling rabbitmq server"

systemctl start rabbitmq-server &>> $LOGFILE
VALIDATE $? "Starting rabbitmq server"

id roboshop
if [ $? -ne 0 ]
then 
   rabbitmqctl add_user roboshop roboshop123
   VALIDATE $? "roboshop user creation"
else
   echo "user already exits"
fi

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $LOGFILE
VALIDATE $? "Set Permissions for user"