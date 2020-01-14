#!/bin/bash

### CONFIG ###
OUT=dump
##############

usage(){
    echo -e "usage: \n\
         (currently only VirtualBox supported) \n\
         $0 -r <name of VM>            (acquire RAM)\n\
         $0 -h <path to vdi harddisk>  (acquire HD)\n\
         $0 -s <path to vdi snapshot>  (acquire HD with snapshot)\n\
         "
    exit 1
}

#error check
if [ $# -ne 2 ]; then
    usage
fi

if [ "$1" == "-r" ]; then
    TEMP=$OUT.elf

    #acquire RAM
    #get debug infos from vbox
    vboxmanage debugvm "$2" dumpvmcore --filename $TEMP || exit 1
    #cut out RAM
    size=0x$(objdump -h $TEMP | egrep -w "(load1)" | tr -s " " | cut -d " " -f 4 | tr /a-z/ /A-Z/)
    offset=0x$(objdump -h $TEMP | egrep -w "(load1)" | tr -s " " | cut -d " " -f 7 | tr /a-z/ /A-Z/)
    head -c $(($size+$offset)) $TEMP | tail -c +$(($offset+1)) > $OUT

    #rename with current date and sha
    mv $OUT "$(date +'%Y-%m-%d')_${OUT}_$(sha512sum $OUT | cut -d ' ' -f 1).vmem"
    #cleanup
    rm $TEMP
elif [ "$1" == "-h" ]; then
    #harddisk
    qemu-img convert -f vdi "$2" -O raw $OUT
    
    #rename with current date and sha
    mv $OUT "$(date +'%Y-%m-%d')_${OUT}_$(sha512sum $OUT | cut -d ' ' -f 1).img"
elif [ "$1" == "-s" ]; then
    TEMP=$OUT.tmp
    
    #harddisk with snapshot
    vboxmanage clonehd "$2" $TEMP
    qemu-img convert -f vdi $TEMP -O raw $OUT

    #rename with current date and sha
    mv $OUT "$(date +'%Y-%m-%d')_${OUT}_$(sha512sum $OUT | cut -d ' ' -f 1).img"
    #cleanup
    vboxmanage closemedium disk $TEMP --delete
else
    usage
fi


