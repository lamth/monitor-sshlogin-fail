# Theo dõi file config của các dịch vụ openstack


## Cài đặt các dịch vụ
- cài gcc
  - Redhat base:
    ```
    yum groupinstall "Development Tools"
    ```
  - Debian base:
    ```
    apt-get install build-essential
    ```
- Cài `fswatch` để theo dõi file:
```
wget https://github.com/emcrisostomo/fswatch/releases/download/1.14.0/fswatch-1.14.0.tar.gz
tar -xvzf fswatch-1.14.0.tar.gz
cd fswatch-1.14.0
./configure
make
sudo make install 
```

