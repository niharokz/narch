#!/bin/bash

#
#       ███╗   ██╗██╗██╗  ██╗ █████╗ ██████╗ ███████╗
#       ████╗  ██║██║██║  ██║██╔══██╗██╔══██╗██╔════╝
#       ██╔██╗ ██║██║███████║███████║██████╔╝███████╗
#       ██║╚██╗██║██║██╔══██║██╔══██║██╔══██╗╚════██║
#       ██║ ╚████║██║██║  ██║██║  ██║██║  ██║███████║
#       ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
#       DRAFTED BY [https://nihar.page] ON 14-03-21.
#       SOURCE [one_piece.sh] LAST MODIFIED ON 18-04-21.
#

[ ! -d movie ] && mkdir -p movie
for file in *
do
	if [[ "$file" =~ [0-9] ]];then
		if [[ "$file" == *"movie"* ]] || [[ "$file" != *".mkv" ]]; then
			mv "$file" movie
		else
			fnh="one_piece_"
			ab=`echo $file | sed -r 's/^([^.]+).*$/\1/; s/^[^0-9]*([0-9]+).*$/\1/'`
			fnh+=`printf %4s $ab | tr ' ' 0`
			fnh+=".mkv"
			mv "$file" "$fnh"
		fi
	else
		mv "$file" movie
	fi
done

