#!/usr/bin/env bash

# Taken from: https://my.oops.org/197?category=18

function sortv {
    local var
    local i

    if [[ $# == 0 ]]; then
        i=0
        while read var_t
        do
            var[i++]="${var_t}"
        done < /dev/stdin
    else
        var=( $* )
    fi

    (
        for i in ${var[@]}
        do
            printf "ibase=2; %07d\n" "$(bc <<< "obase=2; ${i}")"
        done
    ) | sort | bc
}

function sortva {
    local var
    local i
    if [[ $# == 0 ]]; then
        i=0
        while read var_t
        do
            var[i++]="${var_t}"
        done < /dev/stdin
    else
        var=( $* )
    fi

    (
        for i in "${var[@]}"
        do
            perl -p -e 's/([0-9]{4})/$1#~~#/g; s/([0-9]+)/`bc <<< "obase=2; $1" | xargs printf "%020d~~"`/eg' <<< "${i}"
        done
    ) | sort | perl -pe 's/([0-9]{20})~~/`bc <<< "ibase=2; $1" | xargs printf "%s"`/eg; s/[0-9]{4}#~~#/$1/g'
}

