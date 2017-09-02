Use lsyncd to synchronize the project file to the server.



```
$ sudo lsyncd -log scarce /path/to/lsyncd/proxy.lua
```

If you are running lsyncd as a daemon, you can read and kill the pid file.
```
$ kill -KILL $(cat /var/log/lsyncd-proxy.pid)
```