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

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "disabling the default nginx version"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "enabling the nginx-1.24 version"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "installing nginx version"

systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "enabling nginx package"

systemctl start nginx 
VALIDATE $? "starting nginx service"

rm -rf /usr/share/nginx/html/*
VALIDATE $? "removing the default content of nginx html data"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading the front end zip"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "unzipping the front end zip file"

rm -rf /etc/nginx/nginx.conf
cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "updating the nginx configuration"

systemctl restart nginx 
VALIDATE $? "Restarting Nginx"
