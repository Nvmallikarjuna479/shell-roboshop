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
SCRIPT_DIR=$pwd
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
VALIDATE $? "disbaling the default nodej"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling the nodejs version 20 package"

dnf install nodejs -y
VALIDATE $? "installing the nodejs-20 package"
id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "creating the roboshop user"
else
    echo -e "
systemctl start mongod 
VALIDATE $? "starting the mongodb service"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "enabling mongodb service to acess from all the servers"

systemctl restart mongod
VALIDATE $? "Restarting the mongodb service"