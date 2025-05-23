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

echo "Please enter root password to setup"
read -s MYSQL_ROOT_PASSWORD

# Validation function
VALIDATE() {
    if [ $? -ne 0 ]; then
        echo -e "$2 ..... ${R}Failed${N}"
        exit 1
    else
        echo -e "$2 ...... ${G}Successful${N}"
    fi
}

dnf install maven -y & >> $LOGFILE
VALIDATE $? "Installing Maven"

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

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>> $LOGFILE
VALIDATE $? "Downloading cart.zip"

rm -rf /app/*
cd /app 
unzip /tmp/shipping.zip & >> $LOGFILE
VALIDATE $? "unzipping shipping.zip"

mvn clean package &>>$LOGFILE
VALIDATE $? "Packaging the shipping application"

mv target/shipping-1.0.jar shipping.jar &>>$LOGFILE
VALIDATE $? "Moving and renaming Jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>> $LOGFILE
VALIDATE $? "coping the shipping.service"

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "Reload daemon"

systemctl enable shipping &>> $LOGFILE
VALIDATE $? "Enabling shipping"

systemctl start shipping &>> $LOGFILE
VALIDATE $? "Starting shipping"

dnf install mysql -y &>> $LOGFILE
VALIDATE $? "Installing MySQL"

mysql -h mysql.pavandivi.online -u root -p$MYSQL_ROOT_PASSWORD -e 'use cities' &>>$LOGFILE
if [ $? -ne 0 ]
then
    mysql -h mysql.pavandivi.online -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql &>>$LOGFILE
    mysql -h mysql.pavandivi.online -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql  &>>$LOGFILE
    mysql -h mysql.pavandivi.online -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>>$LOGFILE
    VALIDATE $? "Loading data into MySQL"
else
    echo -e "Data is already loaded into MySQL ... $Y SKIPPING $N"
fi

systemctl restart shipping &>>$LOGFILE
VALIDATE $? "Restart shipping"