#
#		NAME		:	NIHAR SAMANTARAY
#		WEBSITE		:	HTTPS://NIHARS.COM
#		SOURCE		:	header.sh
#		CREATED ON	:	04-06-20
#		MODIFIED ON	:	06-06-20
#

heading() {
    echo "#" > $1
	echo "#		NAME		:	NIHAR SAMANTARAY" >> $1
	echo "#		WEBSITE		:	HTTPS://NIHARS.COM" >> $1
	echo "#		SOURCE		:	$1" >> $1
	echo "#		CREATED ON	:	`date +"%d-%m-%y"`" >> $1
    echo "#		MODIFIED ON	:	`date +"%d-%m-%y"`" >> $1
}

if [ -s $1 ];
then
    test=`sed -n 2p $1`
    cat $1>$1.bak
	echo ${test:11:5}
    if [ "${test:11:5}" != "NIHAR" ];
    then
        heading $1
        cat $1.bak >> $1
    else
		modifiedOn="#		MODIFIED ON	:	`date +"%d-%m-%y"`"
        sed -i "6s/.*/$modifiedOn/" $1
    fi
	mv $1.bak /data/workspace/backup
else
    heading $1
fi 

echo "" >>$1
vim +7 $1






