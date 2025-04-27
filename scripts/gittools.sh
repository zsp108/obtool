#!/bin/bash

# This script is used to manage git repositories.

# Usage:
# gittools.sh <command> [repository]

# Commands:
# update_main: Update the main branch of the current repository.

logfile=/dev/null
# 日志函数，记录操作系统，并且将输出打印到屏幕
function log {
    local msg
    local logtype
    logtype=$1
    msg=$2
    datetime=`date +'%F %H:%M:%S'`
    logformat="${datetime} ${FUNCNAME[@]/log/} [line:`caller 0 | awk '{print$1}'`] ${logtype}:${msg}"
    {
    case $logtype in
        debug)
            echo "${logformat}" &>> $logfile;;
        info)
            echo -e "\033[32m $datetime [info] ${msg} \t \033[0m"
            echo "${logformat}" &>> $logfile;;
        warn)
            echo -e "\033[33m $datetime [WARN] ${msg} \t \033[0m"
            echo "${logformat}" &>> $logfile;;
        error)
            echo -e "\033[31m $datetime [ERROR] ${msg} \033[0m"
            echo "${logformat}" &>> $logfile
            exit 15;;
    esac
    }
}




cur_bench=$(git branch --show-current)

log info "Current branch: $cur_bench"

function update_main() {
    log info "`git fetch && git merge origin/main`"
    if [ $? -ne 0 ]; then
        log error "Failed to update main branch."
    else
        log info "Updated main branch successfully."
    fi
}

function del_branch() {
    local branch=$1
    if [ -z $branch ]; then
        log error "No branch specified."
        exit 1
    fi
    log info "Deleting branch $branch..."
    git branch -D $branch
    if [ $? -ne 0 ]; then
        log error "Failed to delete branch $branch."
    else
        log info "Deleted branch $branch successfully."
        log info "Deleting remote branch git push origin --delete $branch"
    fi
}

if [ $# -eq 0 ]; then
    log error "No command specified."
elif [ $1 == "update_main" ]; then
    update_main
elif [ $1 == "del_branch" ]; then
    del_branch $2
else
    log error "Invalid command: $1"
fi
