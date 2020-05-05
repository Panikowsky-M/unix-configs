#!/bin/sh
# (1)
#!/bin/bash
# (2)
# (1) if this text is update-motd.d's scripts (2) if this text is normal
# bash script
#i3-nagbar -t warning -m 'Проверка вызова нагбара через скрипт' -b 'Закрыть' 
curHour=$(date "+%H")
if [ $curHour -lt 12 -a $curHour -ge 0 ]; then curTime="Доброе утро"
elif [ $curHour -lt 17 -a $curHour -ge 12 ]; then curTime="Добрый день"
else curTime="Добрый вечер"
fi

clever=`fortune`

#System uptime
uptime=`cat /proc/uptime | cut -f1 -d.`
Days=$((uptime/60/60/24))
Hours=$((uptime/60/60%24))
Mins=$((uptime/60%60))
Mem1=`free -t -m | grep "buffers/cache" | awk '{print $3" MB";}'`
Mem2=`free -t -m | grep "Mem" | awk '{print $2" MB";}'`
Procs=`ps aux | wc -l`

if [ $curHour -lt 12 -a $curHour -ge 0 ]; then echo $curTime $USER\
" с момента запуска прошло $Days дней $Hours часов $Mins минут(ы)" | cowsay -b
elif [ $curHour -lt 17 -a $curHour -ge 12 ]; then printf "$curTime $USER\n  
 с момента запуска прошло $Days дней $Hours час(ов) $Mins минут(ы)\n  $Procs процессов запущено\n
 $clever"| cowsay
else echo $curTime $USER | cowsay -d
fi

echo ля-ля-ля
echo $Mem1
echo $Mem2
