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

dnf module disable nodejs -y &>> "$LOGFILE"
VALIDATE $? "Disabling module nodejs"

dnf module enable nodejs:20 -y &>> "$LOGFILE"
VALIDATE $? "Enabling module nodejs:20"

dnf install nodejs -y &>> "$LOGFILE"
VALIDATE $? "Installing NodeJS"

id roboshop
if [ $? -ne 0 ]
then 
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   VALIDATE $? "roboshop user creation"
else
   echo "user already exits"
fi

mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>> $LOGFILE
VALIDATE $? "Downloading user.zip"

rm -rf /app/*
cd /app 
unzip /tmp/user.zip & >> $LOGFILE
VALIDATE $? "unzipping user"

npm install -y &>> $LOGFILE
VALIDATE $? "Installing npm"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service &>> $LOGFILE
VALIDATE $? "coping the user.service"

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "Reload daemon"

systemctl enable user &>> $LOGFILE
VALIDATE $? "Enabling user"

systemctl start user &>> $LOGFILE
VALIDATE $? "starting user"