#!/bin/bash

date_var=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(basename "$0")
LOGFILE="/tmp/${SCRIPT_NAME}-${date_var}.log"

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

cp mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOGFILE
VALIDATE $? "copied mongo.repo into /etc/yum.repos.d/mongo.repo"

dnf install mongodb-org -y &>> $LOGFILE
VALIDATE $? "Installed MongoDB"

systemctl enable mongod &>> $LOGFILE
VALIDATE $? "Enabled MongoDB"

systemctl start mongod &>> $LOGFILE
VALIDATE $? "Started MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf &>> $LOGFILE

systemctl restart mongod &>> $LOGFILE
VALIDATE $? "Restarted MongoDB"