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


dnf module disable redis -y  &>>$LOG_FILE
VALIDATE $? "disabling the default redis"

dnf module enable redis:7 -y  &>>$LOG_FILE
VALIDATE $? "enabling the redis 7"

dnf install redis -y  &>>$LOG_FILE
VALIDATE $? "installing redis package"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Allowing Remote connections to Redis"

systemctl enable redis  &>>$LOG_FILE
VALIDATE $? "enabling the redis"

systemctl start redis  &>>$LOG_FILE
VALIDATE $? "starting the redis "