# monitor-sshlogin-fail
Telegram bot for logging ssh login for Linux.



Mục tiêu: Lập trình bot telegram theo dõi mỗi lần đang nhập fail vào hệ thống qua ssh và gửi tin nhắn đến Telegram.

Các bước cần thực hiện:
  1. Làm sao để theo dõi được những lần login fail trong linux dùng cli
  2. Làm sao để dùng python theo dõi login fail đấy.
  3. Làm sao để gửi về telegram. telegram bot là gì?




# 1. Theo dõi login fail trên linux bằng cli

sau một hồi mày mò thì mình tim thấy cái file log trong linux có thông tin kiểu này: `/var/log/secure` (Centos), và `/var/log/auth.log`(Ubuntu): nó sẽ kiểu này

```log
May 21 17:17:16 localhost sshd[17041]: Invalid user hkd from 192.168.99.9 port 60250
May 21 17:17:16 localhost sshd[17041]: input_userauth_request: invalid user hkd [preauth]
May 21 17:17:16 localhost sshd[17041]: pam_unix(sshd:auth): check pass; user unknown
May 21 17:17:16 localhost sshd[17041]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=192.168.99.9
May 21 17:17:18 localhost sshd[17041]: Failed password for invalid user hkd from 192.168.99.9 port 60250 ssh2
May 21 17:17:18 localhost sshd[17041]: Received disconnect from 192.168.99.9 port 60250:11: Bye Bye [preauth]
May 21 17:17:18 localhost sshd[17041]: Disconnected from 192.168.99.9 port 60250 [preauth]
May 21 17:17:32 localhost sshd[17441]: reverse mapping checking getaddrinfo for 177-139-195-214.dsl.telesp.net.br [177.139.195.214] failed - POSSIBLE BREAK-IN ATTEMPT!
```

Để lọc được login fail bằng password, chúng ta chỉ cần dòng có cụm "Failed password" vì đăng nhập sai user hay password thì đều có dòng này cả. Do đó chúng ta có thể log login fail bằng lệnh sau:
```
cat /var/log/auth.log | grep "Failed password"
```

Cần thì grep thêm ssh cũng được. cơ mà đây chỉ là bước đầu thôi, làm sao mà dùng python lọc mấy cái này và gửi về tele mới là vấn đề.


# 2. tạo Bot

Dữ liệu cứ coi là có rồi đi, thế làm sao để mày đẩy về telegram.
Telegram hỗ trợ tạo các bot - tương tự một tài khoản do phần mềm quản lý chứ không phải con người quản lý. 
Bot làm được nhiều thứ như nói chuyện, chơi game, quảng bá tin tức, nhắc nhở, tạo poll, tìm kiếm hoặc thậm chí có thể gửi lệnh đến các thiết bị iot.

![](http://i.imgur.com/5XANpWE.png)

Vì nó là máy nên ở đây sẽ sử dụng nó như một thằng nhận log đăng nhập sai ssh để hiển thị cho người dùng trên telegram.

Còn việc làm sao nó lấy được thông tin đăng nhập từ máy chủ muốn theo dõi thì theo dõi thêm phần sau

Có một con bot được dùng để tạo ra các con bot khác nên con bot này được gọi là BotFather https://telegram.me/botfather

- Vào Botfather, chọn **Start** hoặc gõ lệnh `/start`

![](https://i.imgur.com/apl8e4l.png)
- Tiếp theo chọn `/newbot`

![](http://i.imgur.com/kChwaSy.png)

- Sau khi gửi lệnh tạo bot mới, botfather sẽ yêu cầu đặt tên cho bot mới:

![](http://i.imgur.com/EFEO8YD.png)

- Đặt user cho bot, user phải kết thúc với `bot` ví dụ:

![](http://i.imgur.com/QhuKlJ9.png)

Sau đó botfather sẽ gửi cho chúng ta access token để truy cập api của bot mới như hình trên. Không nên được để lộ access token này vì người khác có thể sử dụng nó để điều khiển bot của bạn. 
Nếu bị lộ, bạn có thể sử dụng lệnh `/revoke` sau đó chọn bot để botfather tạo lại access token mới cho bot của bạn.

Để có thể chỉ sửa một số thông tin của bot như tên hay ảnh đại diện, sử dụng lệnh `/mybots` sau đó chọn bot muốn cấu hình.


- Sau khi tạo ra bot, Tạo một nhóm chat và thêm thành viên là bot mới tạo, khi đó, bot có thể gửi tin nhắn đến những người trong nhóm về những lần đăng nhập ssh fail.

- Sau khi thêm vào nhóm, dùng curl để lấy thông tin *Chat ID* là id của group để bot nhắn tin đến:
```
https://api.telegram.org/bot[TOKEN]/getUpdates | json_pp
```
- Kết quả trả về sẽ là đoạn mã json chứa một số thông tin về tin nhắn, người gửi, nhóm chat, tin nhắn, điều chúng ta quan tâm là chat id lấy thông tin trong mục: `{"message" : {"chat" : {"id": 12345678} } }` trong ví dụ này CHAT ID là `12345678`.

- Test gửi tin nhắn đến group với lệnh:
```
curl -X POST "https://api.telegram.org/bot<ACCESS TOKEN>/sendMessage" -d "chat_id=<CHAT ID>&text=<MESSAGE>"
```
- Ví dụ: curl -X POST "https://api.telegram.org/bot234213241:KVCUJ38DKI92F9I834JO0OFOIEJ/sendMessage" -d "chat_id=12345678&text=đây là tin nhắn test"

![](http://i.imgur.com/E8xCGfg.png)


OK coi như xong phần gửi tin nhắn.

## 3. Viết script để theo dõi và gửi thông tin đăng nhập ssh fail về telegram

- Môi trường: Centos 7
- User: root

- Cài đặt phu thuộc:
```
yum install inotify-tools -y
```

- tạo file ssh-alert.sh
```
vi /root/ssh-alert.sh
```
```sh
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

```
- Thêm quyền execute cho script
``` 
chmod u+x /root/ssh-alert
```
- Chạy script: 
```
bash script > /dev/null 2>&1 
```