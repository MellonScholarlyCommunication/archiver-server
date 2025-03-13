module.exports = {
    apps : [
     {
      name   : "arch-inbox",
      script : "./run.sh" ,
      cron: '*/5 * * * *',
      autorestart: false 
     },
    ]
  }