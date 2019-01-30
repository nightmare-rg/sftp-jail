# What's that?

sftp-jail creates SFTP/SCP Jails with rssh and public/private keys

# How to use
**USAGE:** sftp-jail.sh -n|-a -u user -g group -d jail_path

**EXAMPLE:**
```bash
# create new jail with user storage
./sftp-jail.sh -n -u storage -g www-data -d /var/jail

# add user storage2 to existing jail
./sftp-jail.sh -a -u storage2 -g www-data -d /var/jail
```
