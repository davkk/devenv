#!/usr/bin/env bash

tmpdir=/tmp/swaylock
mkdir -p $tmpdir

outputs=`swaymsg -t get_outputs | jq -r '.[] | select(.active == true) | .name'`
args=""

for output in $outputs; do
    image=/tmp/swaylock/${output}.jpg
    grim -o $output - | ffmpeg -y -i pipe: -vf "gblur=sigma=50:steps=6,eq=brightness=0.03" $image
    args="$args -i $output:$image"
done

if [ ! -z "`ls -A $tmpdir`" ]; then
    swaylock -f -s fill $args
else
    swaylock -f -c 111111 -s fill
fi

rm -rf $tmpdir
