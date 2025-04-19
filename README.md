Hi, this is my folder of status scripts for my newtwork of raspberry pis

Some useful notes mostly for myself to remember
ssh_log.sh has a wrapper situated at /etc/profile.d/ssh_log_wrapper.sh incase the script runs but not on ssh
boot_status creates a .service file at /etc/systemd/system/ to automate the script on bootup
currently hourly_status has a line in crontab to run it every hour, although i may stop using crontab altogether soon
