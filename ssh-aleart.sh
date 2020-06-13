#!/bin/bash
#===========================
# Script alert SSH login fail to Telegram
#==========================


## Telegram bot config
ACCESS_TOKEN=
CHAT_ID=


## File config
LOGFILE=/var/log/secure


# main 
# Inode of file when script run
LOGFILEINO=$(ls -i $LOGFILE | awk '{print $1}')

while true
  do
    if [ ! -f $LOGFILE  ]; then
      touch $LOGFILE
    fi
    #chown syslog:syslog $LOGFILE ## for ubuntu
    while inotifywait -e modify,move_self $LOGFILE
      do
        LOGFILEINONEW=$(ls -i $LOGFILE | awk '{print $1}')
        # Check if log file rotated
	      if [[ $LOGFILEINO != $LOGFILEINONEW ]];
        then
          LOGFILEINO=$LOGFILEINONEW
          break
        fi
        # If new line from log file have "Failed password", script will send
	      ## this log line as a message to telegram.
        alert=$(tail -n1 $LOGFILE)
        if echo $alert | grep "Failed password";
        then
          curl -X POST "https://api.telegram.org/bot$ACCESS_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$alert"
        fi
    done
  done