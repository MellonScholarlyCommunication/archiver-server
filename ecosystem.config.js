module.exports = {
    apps : [
     {
      name   : "arch-server",
      script : "ldn-receiver"
     },
     {
      name   : "arch-inbox",
      script : "./run.sh" ,
      cron: '*/5 * * * *',
      autorestart: false 
     },
    ]
  }