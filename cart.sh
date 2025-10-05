#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

USERID=$(id -u)
if [ $USERID -ne 0 ]; then
    echo  "ERROR:: Please run this script with root previllages"
    exit 1
fi

LOGS_DIR="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo  $0 | cut -d "." -f1)
LOG_FILE="$LOGS_DIR/$SCRIPT_NAME.log"
SCRIPT_DIR=$(pwd)
mkdir -p $LOGS_DIR
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e  " $2 ... $R FAILURE $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi 
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disabling the default nginx"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling the default nginx 20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installing nginx"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "creating the system user(roboshop)"
else
    echo -e "system user roboshop us already exits $Y SKIPPING $N"
fi

mkdir -p /app 
curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading the cart zip file"

cd /app 
VALIDATE $? "changing to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/cart-v3.zip &>>$LOG_FILE
VALIDATE $? "unzippping the cart zip file"
 
npm install &>>$LOG_FILE
VALIDATE $? "installing dependency libs"

cp -r $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
VALIDATE $? "copying cart.service file"

systemctl daemon-reload
VALIDATE $? "reloading the system daemon"

systemctl enable cart &>>$LOG_FILE
VALIDATE $? "enabling cart service"
systemctl start cart &>>$LOG_FILE
VALIDATE $? "starting the cart service"