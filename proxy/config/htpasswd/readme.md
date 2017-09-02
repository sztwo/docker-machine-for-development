# How to make basic authentication file

Create the htpasswd file with the domain name to be set as the file name.

## Create the htpasswd file

When creating the first user
```
$ htpasswd -c /path/to/proxy/config/htpasswd/www.your.domain basic_auth_name
```

To create a second or subsequent user
```
$ htpasswd /path/to/proxy/config/htpasswd/www.your.domain basic_auth_name_2
```
