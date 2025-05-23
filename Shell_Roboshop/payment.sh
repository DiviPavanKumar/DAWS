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

dnf install python3 gcc python3-devel -y & >> $LOGFILE
VALIDATE $? "Installing Python"

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

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip  &>> $LOGFILE
VALIDATE $? "Downloading payment.zip"

rm -rf /app/*
cd /app 
unzip /tmp/payment.zip & >> $LOGFILE
VALIDATE $? "unzipping payment.zip"

pip3 install -r requirements.txt & >> $LOGFILE
VALIDATE $? "Dependencis configuration"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>> $LOGFILE
VALIDATE $? "coping the payment.service"

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "Reload daemon"

systemctl enable payment &>> $LOGFILE
VALIDATE $? "Enabling payment"

systemctl start payment &>> $LOGFILE
VALIDATE $? "Starting payment"
