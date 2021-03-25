#!/usr/bin/env bash

# Taken from: https://my.oops.org/201?category=18

HUMANREADABLE_SIZE_SUFFIX=( "B" "KB" "MB" "GB" "TB" )
# HUMANREADABLE_SIZE req_size base_suffix
function HUMANREADABLE_SIZE {
    local suffix=${2:-0}
    local size=$1
    local isize=${size}

    while [ 1 ]
    do
        (( isize < 1024 )) && break
        size="$( bc <<< "scale = 2; ${size} / 1024" )"
        isize=${size%%.*}
        let "suffix += 1"
    done

    echo "${size} ${HUMANREADABLE_SIZE_SUFFIX[suffix]}"
}

