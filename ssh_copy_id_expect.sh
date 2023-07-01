#!/usr/bin/expect -f

set timeout 60
set ip [lindex $argv 0]
set password [lindex $argv 1]

spawn ssh-copy-id -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null adminuser@$ip

expect {
    "assword:" {
        send "$password\r"
        exp_continue
    }
    "Permission denied" {
        send_user "Permission denied\n"
        exit 1
    }
    eof {
        send_user "SSH key copied\n"
    }
}