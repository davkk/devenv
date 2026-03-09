#!/usr/bin/env zsh

output=$1
state=$2

lock=/tmp/lid_lock

case "$state" in
    disable)
        if [ -f $lock ]; then exit 0; fi
        light -O && swaymsg output $output disable
        ;;
    enable)
        sleep 0.5
        if [ -f $lock ]; then rm $lock; exit 0; fi
        swaymsg output $output enable && light -I
        ;;
    *)
        echo "Usage: $0 <output name> {enable|disable}"
        exit 1
        ;;
esac
