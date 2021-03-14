#!/bin/bash

#
#       ███╗░░██╗██╗██╗░░██╗░█████╗░██████╗░░█████╗░██╗░░██╗███████╗
#       ████╗░██║██║██║░░██║██╔══██╗██╔══██╗██╔══██╗██║░██╔╝╚════██║
#       ██╔██╗██║██║███████║███████║██████╔╝██║░░██║█████═╝░░░███╔═╝
#       ██║╚████║██║██╔══██║██╔══██║██╔══██╗██║░░██║██╔═██╗░██╔══╝░░
#       ██║░╚███║██║██║░░██║██║░░██║██║░░██║╚█████╔╝██║░╚██╗███████╗
#       ╚═╝░░╚══╝╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝╚══════╝
#
#       DRAFTED BY NIHAR SAMANTARAY ON 13-03-21. [https://nihars.com]
#       SOURCE [note.sh] LAST MODIFIED ON 14-03-21

export NOTE_DIR="$DATA/cloud/dropbox/notes"

case "$1" in
	n*)	read -erp "Title of the note:" title; 
		echo "#$title"> "$NOTE_DIR/$title.md"; 
		$EDITOR "$NOTE_DIR/$title.md";;
	l*) ls -lart $NOTE_DIR;;
	o*) ls $NOTE_DIR; read -erp "File name to be opened:" title; $EDITOR "$NOTE_DIR/$title";;
	d*) ls $NOTE_DIR; read -erp "File name to be deleted:" title; rm -i "$NOTE_DIR/$title";;
	s*) rclone -P sync $DATA/cloud/dropbox/notes dropbox:/notes ;;
	*)	printf "note.sh by niharokz \\nUsage:\\n  note.sh n:\\tnew note\\n  note.sh l:\\tlist all notes\\n  note.sh o:\\topen note\\n  note.sh d:\\tdelete note\\n  note.sh s:\\tsync with dropbox\\n" ;;
esac	


