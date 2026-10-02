# install-ntp-client-linux
Script to install and configure NTP client for Linux

Step 1
Login to server, create and execute the script

sudo nano configure-chrony-ntp.sh

Step 2
Copy and past the script Script
To save, press CTRL+O
To exit, press CTRL+X

Step 3
Make the script executable
sudo chmod +x configure-chrony-ntp.sh

Step 4
Execute the script and validate.
sudo ./configure-chrony-ntp.sh
chronyc sources -vchronyc tracking
