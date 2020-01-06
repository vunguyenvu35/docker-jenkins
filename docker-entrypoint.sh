#!/bin/bash
set -e

for var in "$@"
do
    if [ "$var" = 'crond' ]; then
        # start crond
        crontab /etc/crontab
    fi

    if [ "$var" = 'php' ]; then
        # start add pthreads
        # echo 'extension=pthreads' >> /etc/php/etc/php.d/pthreads.ini
    fi

done

# echo system
tail -f /dev/null