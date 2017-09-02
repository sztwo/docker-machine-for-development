settings {
  logfile      = "/var/log/lsyncd-proj_name.log",  -- change this name
  pidfile      = "/var/log/lsyncd-proj_name.pid",  -- change this name
  statusFile   = "/var/log/lsyncd-proj_name.status",  -- change this name
  nodaemon     = true, -- It can be run as daemon with false
  insist       = false, -- true can be reconnected indefinitely (or number can be specified).
}

sync {
  default.rsync,
  source = "/path/to/your/project/dir",  -- change this path
  target = 'login_name@your.server:/path/to/your/project/dir',  -- change this path
  delay  = 0,
  rsync  = {
    binary   = '/usr/local/bin/rsync',
    archive  = true,
    links    = true,
    update   = true,
    verbose  = false,
    compress = true,
    rsh = '/usr/bin/ssh -p 22 -i /path/to/.ssh/key'
  },
  exclude = {
    '.DS_Store',
    '*.bak',
    '*.backup',
    '.git/',
    '.sass-cache/',
    'log/',
    'tmp/',
    'vendor/bundle/',
  },
}