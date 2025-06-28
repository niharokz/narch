#!/bin/bash

#   
#       ███╗   ██╗██╗██╗  ██╗ █████╗ ██████╗ ███████╗
#       ████╗  ██║██║██║  ██║██╔══██╗██╔══██╗██╔════╝
#       ██╔██╗ ██║██║███████║███████║██████╔╝███████╗
#       ██║╚██╗██║██║██╔══██║██╔══██║██╔══██╗╚════██║
#       ██║ ╚████║██║██║  ██║██║  ██║██║  ██║███████║
#       ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
#       DRAFTED BY [https://nih.ar] ON 10-04-2021
#       SOURCE [header.sh] LAST MODIFIED ON 23-10-2022.
#

BACKUP="$DATA/backup"
website="https://nih.ar"

if [ "${1##*.}" == "py" ]
 then cbang="#!/bin/python3"
 else cbang="#!/bin/bash"
fi

heading() {
	echo "$cbang" > $1
	echo "" >> $1
	echo "#" >> $1
 echo "#       ███╗   ██╗██╗██╗  ██╗ █████╗ ██████╗ ███████╗" >> $1
 echo "#       ████╗  ██║██║██║  ██║██╔══██╗██╔══██╗██╔════╝" >> $1
 echo "#       ██╔██╗ ██║██║███████║███████║██████╔╝███████╗" >> $1
 echo "#       ██║╚██╗██║██║██╔══██║██╔══██║██╔══██╗╚════██║" >> $1
 echo "#       ██║ ╚████║██║██║  ██║██║  ██║██║  ██║███████║" >> $1
 echo "#       ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝" >> $1
 echo "#       DRAFTED BY [$website] ON "`date +"%d-%m-%Y"`".">> $1
 echo "#       SOURCE ["$1"] LAST MODIFIED ON "`date +"%d-%m-%Y"`"." >> $1
	echo "#" >> $1
}

if [ -s $1 ];
then
    test=`sed -n 10p $1`
    cat $1>$1.bak
    if [ "${test:20:14}" != "$website" ];
    then
        heading $1
        cat $1.bak >> $1
    else
        test="#       SOURCE ["$1"] LAST MODIFIED ON "`date +"%d-%m-%Y"`"."
        sed -i "11s/.*/$test/" $1
    fi
    mv $1.bak $BACKUP
else
    heading $1
fi 

echo "" >>$1
$EDITOR +13 $1


