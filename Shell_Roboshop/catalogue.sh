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

dnf module disable nodejs -y &>> $LOGFILE
VALIDATE $? "Disabling"

dnf module enable nodejs:20 -y  &>> $LOGFILE
VALIDATE $? "Enabling"

dnf install nodejs -y &>> $LOGFILE
VALIDATE $? "Installing"

id roboshop
if [ $? -ne 0 ]
then 
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   VALIDATE $? "robo user creation"
else
   echo "user exits"
fi

mkdir -p /app &>> $LOGFILE  # -p if the app folder is available it will ignore if not create 
VALIDATE $? "Creatig app dir"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $LOGFILE
VALIDATE $? "Downloading catloguge.zip"

rm -rf /app/*
cd /app 

unzip -o /tmp/catalogue.zip &>> $LOGFILE  # o is to overwrite
VALIDATE $? "Unzip"

npm install &>> $LOGFILE
VALIDATE $? "Installing npm depncdies" 

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>> $LOGFILE
VALIDATE $? "Coping catalogue services"

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "daemon loading"

systemctl enable catalogue &>> $LOGFILE
VALIDATE $? "cenabling"

systemctl start catalogue &>> $LOGFILE
VALIDATE $? "starting"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOGFILE
VALIDATE $? "copied"

dnf install mongodb-mongosh -y &>> $LOGFILE
VALIDATE $? "installng shl"

STATUS=$(mongosh --host mongodb.pavandivi.online --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
mongosh --host mongodb.pavandivi.online </app/db/master-data.js &>> $LOGFILE
VALIDATE $? "Loading data into MongoDB"
else
echo -e "Data is already loaded...$Y Skipping $N"
fi