#!/usr/bin/env bash

# Taken from: https://my.oops.org/198?category=18

# USAGE: compare_version OLD NEW
# RETURN:
#      (OLD == NEW) return 0
#      (OLD < NEW) return 1
#      (OLD > NEW ) return 2
function compare_version {
    local opt
    [[ $1 == $2 ]] && return 0

    # -V option 이 지원되지 않을 경우, 숫자 이외의 문자가 들어간 버전 비교가
    # 정확하지 않을 수 있다. 예) 2.1.9-3el6_7.2
    sort -V >& /dev/null <<< "aa"
    [[ $? == 0 ]] && opt="V"

    test "$(printf '%s\n' "$@" | sort -r${opt} | head -n 1)" != "$1";
    res=$?
    [[ $res == 0 ]] && return 1 || return 2
}
