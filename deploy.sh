#!/usr/bin/env bash

set -e

#########################################
# Constants
#########################################

readonly TIME=`date "+%Y%m%d-%H%M%S"`
readonly SLEEP_INTERVAL=3
readonly START_TIME=`date +%s`
readonly START_DIRECTORY=$(pwd)

# Colors
readonly C_ERROR="\e[1;31m"
readonly C_RESET="\e[0m"
readonly C_SUCCESS="\e[1;32m"
readonly C_INFO="\e[1;34m"

# Error codes
readonly E_DO_NOT_USE=1
readonly E_CANT_CREATE_BUILD_FOLDER=2
readonly E_CANT_CLONE=3
readonly E_DEPENDENCIES_INSTALL_FAILED=4
readonly E_BUILD_FAILED=5
readonly E_ALREADY_WAITING=6
readonly E_UNKNOWN_OPTION=7
readonly E_INVALID_OPTION=8
readonly E_RESTART_HOCK=9
readonly E_RESTART_NGINX=10
readonly E_RESTART_APACHE=11
readonly E_REMOVE_SITE=12
readonly E_COPY_BUILD=13
readonly E_CANT_CREATE_TEST_FOLDER=14

#########################################
# Text functions
#########################################

error () {
    echo -e "  ${C_ERROR}ERROR: ${1}${C_RESET}"
}

success () {
    echo -e "  ${C_SUCCESS}${1}${C_RESET}"
}

info () {
    echo -e "  ${C_INFO}${1}${C_RESET}"
}

text () {
    echo -e "  ${1}"
}

el () {
    echo ""
}

#########################################
# ART
#########################################

el
echo -e "  \e[1;30m######################################################\e[0m"
echo -e "  \e[1;30m##\e[0m                                                  \e[1;30m##\e[0m"
echo -e "  \e[1;30m##\e[0m  \e[1;31m####  \e[0m  \e[1;32m######\e[0m  \e[1;33m######\e[0m  \e[1;34m##    \e[0m  \e[1;35m######\e[0m  \e[1;36m##  ##\e[0m  \e[1;30m##\e[0m"
echo -e "  \e[1;30m##\e[0m  \e[1;31m##  ##\e[0m  \e[1;32m##    \e[0m  \e[1;33m##  ##\e[0m  \e[1;34m##    \e[0m  \e[1;35m##  ##\e[0m  \e[1;36m##  ##\e[0m  \e[1;30m##\e[0m"
echo -e "  \e[1;30m##\e[0m  \e[1;31m##  ##\e[0m  \e[1;32m##    \e[0m  \e[1;33m##  ##\e[0m  \e[1;34m##    \e[0m  \e[1;35m##  ##\e[0m  \e[1;36m##  ##\e[0m  \e[1;30m##\e[0m"
echo -e "  \e[1;30m##\e[0m  \e[1;31m##  ##\e[0m  \e[1;32m######\e[0m  \e[1;33m######\e[0m  \e[1;34m##    \e[0m  \e[1;35m##  ##\e[0m  \e[1;36m##  ##\e[0m  \e[1;30m##\e[0m"
echo -e "  \e[1;30m##\e[0m  \e[1;31m##  ##\e[0m  \e[1;32m##    \e[0m  \e[1;33m##    \e[0m  \e[1;34m##    \e[0m  \e[1;35m##  ##\e[0m  \e[1;36m  ##  \e[0m  \e[1;30m##\e[0m"
echo -e "  \e[1;30m##\e[0m  \e[1;31m##  ##\e[0m  \e[1;32m##    \e[0m  \e[1;33m##    \e[0m  \e[1;34m##    \e[0m  \e[1;35m##  ##\e[0m  \e[1;36m  ##  \e[0m  \e[1;30m##\e[0m"
echo -e "  \e[1;30m##\e[0m  \e[1;31m######\e[0m  \e[1;32m######\e[0m  \e[1;33m##    \e[0m  \e[1;34m######\e[0m  \e[1;35m######\e[0m  \e[1;36m  ##  \e[0m  \e[1;30m##\e[0m"
echo -e "  \e[1;30m##\e[0m                                                  \e[1;30m##\e[0m"
echo -e "  \e[1;30m######################################################\e[0m"
el
info "Repository: https://github.com/slexx1234/deploy"
info "Licence:    MIT"
el

#########################################
# Commands
#########################################

command_help () {
    text "Commands:"
    el
    echo -e "  ${C_INFO}help${C_RESET}               - Getting help"
    echo -e "  ${C_INFO}authors${C_RESET}            - Show authors"
    echo -e "  ${C_INFO}licence${C_RESET}            - Show licence"
    el
    text "Options:"
    el
    echo -e "  ${C_INFO}-r or --repository${C_RESET} - Github repository uri ${C_ERROR}(required)${C_RESET}"
    echo -e "  ${C_INFO}-d or --directory${C_RESET}  - Production site directory ${C_ERROR}(required)${C_RESET}"
    echo -e "  ${C_INFO}-D or --domain${C_RESET}     - Site domain ${C_ERROR}(required)${C_RESET}"
    echo -e "  ${C_INFO}-p or --permission${C_RESET} - Permissions for site directory ${C_SUCCESS}(default: 644)${C_RESET}"
    echo -e "  ${C_INFO}-o or --owner${C_RESET}      - Site owner ${C_SUCCESS}(default: www-data:www-data)${C_RESET}"
    echo -e "  ${C_INFO}-h or --home${C_RESET}       - Script home directory, script preserves here old"
    echo -e "                       builds and test build ${C_SUCCESS}(default: ~/deploy)${C_RESET}"
    el
    text "Flags:"
    el
    echo -e "  ${C_INFO}-n or --nginx${C_RESET}      - Restart nginx server after build"
    echo -e "  ${C_INFO}-a or --apache${C_RESET}     - Restart apache server after build"
    el
    text "Hocks:"
    text "Performed in the order that below"
    el
    echo -e "  ${C_INFO}--before-deploy${C_RESET}    - Before deploy command"
    echo -e "  ${C_INFO}--install${C_RESET}          - Install dependencies command"
    echo -e "  ${C_INFO}--build${C_RESET}            - Build command"
    echo -e "  ${C_INFO}--restart${C_RESET}          - Restart server command"
    echo -e "  ${C_INFO}--after-deploy${C_RESET}     - After deploy command"
    el
    exit 0
}

command_authors () {
    success "ALEKSEI SHCHEPKIN"
    info "Role:    Developer"
    info "Email:   slexx1234@gmail.com"
    info "GitHub:  https://github.com/slexx1234"
    info "WebSite: https://slexx1234.netlify.com/"
    el
    exit 0
}

command_licence () {
    text "MIT License"
    el
    text "Copyright (c) 2018 Aleksei Shchepkin"
    el
    text "Permission is hereby granted, free of charge, to any person obtaining a copy"
    text "of this software and associated documentation files (the \"Software\"), to deal"
    text "in the Software without restriction, including without limitation the rights"
    text "to use, copy, modify, merge, publish, distribute, sublicense, and/or sell"
    text "copies of the Software, and to permit persons to whom the Software is"
    text "furnished to do so, subject to the following conditions:"
    el
    text "The above copyright notice and this permission notice shall be included in all"
    text "copies or substantial portions of the Software."
    el
    text "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR"
    text "IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,"
    text "FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE"
    text "AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER"
    text "LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,"
    text "OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE"
    text "SOFTWARE."
    el
    exit 0
}

#########################################
# Run commands
#########################################

if [ -z $1 ]
then
    command_help
else
    case $1 in
        help)
        command_help
        ;;

        authors)
        command_authors
        ;;

        licence)
        command_licence
        ;;
    esac
fi


#########################################
# Parse options
#########################################

for i in "$@"
do
case $i in
    -r=*|--repository=*)
    readonly O_REPOSITORY="${i#*=}"
    shift
    ;;

    -d=*|--directory=*)
    readonly O_DIRECTORY="${i#*=}"
    shift
    ;;

    -p=*|--permission=*)
    readonly O_PERMISSION="${i#*=}"
    shift
    ;;
    
    -o=*|--owner=*)
    readonly O_OWNER="${i#*=}"
    shift
    ;;

    -h=*|--home=*)
    # Trim slash
    h="${i#*=}"
    [[ ${h:length-1:1} == "/" ]] && h=${h:0:length-1}; :
    readonly O_HOME=h
    shift
    ;;

    -D=*|--domain=*)
    readonly O_DOMAIN="${i#*=}"
    shift
    ;;

    -n|--nginx)
    readonly F_NGINX=true
    shift
    ;;

    -a|--apache)
    readonly F_APACHE=true
    shift
    ;;

    --before-deploy=*)
    readonly H_BEFORE_DEPLOY="${i#*=}"
    shift
    ;;

    --install=*)
    readonly H_INSTALL="${i#*=}"
    shift
    ;;

    --build=*)
    readonly H_BUILD="${i#*=}"
    shift
    ;;

    --restart=*)
    readonly H_RESTART="${i#*=}"
    shift
    ;;

    --after-deploy=*)
    readonly H_AFTER_DEPLOY="${i#*=}"
    shift
    ;;

    *)
    error "Unknown option!"
    el
    exit ${E_UNKNOWN_OPTION}
    ;;
esac
done

if [ -z ${O_REPOSITORY} ]
then
    error "Repository option is required!"
    el
    exit ${E_INVALID_OPTION}
fi

if [ -z ${O_DOMAIN} ]
then
    error "Domain option is required!"
    el
    exit ${E_INVALID_OPTION}
fi

if [ -z ${O_DIRECTORY} ]
then
    error "Directory option is required!"
    el
    exit ${E_INVALID_OPTION}
fi

if [ -z ${O_PERMISSION} ]
then
    readonly O_PERMISSION=777
fi

if [ -z ${O_OWNER} ]
then
    readonly O_OWNER="www-data:www-data"
fi

if [ -z ${O_HOME} ]
then
    readonly O_HOME="~/deploy"
fi

if [ -z ${F_NGINX} ]
then
    readonly F_NGINX=false
fi

if [ -z ${F_APACHE} ]
then
    readonly F_APACHE=false
fi

#########################################
# Directories and files
#########################################

# Directories
readonly D_TEST=${O_HOME}/${O_DOMAIN}
readonly D_BUILD=${D_TEST}/build-${TIME}

# Files
readonly F_ARCHIVE=${D_BUILD}.tar.gz

# Indicators
readonly I_UPDATE=${D_TEST}/.indicator-update
readonly I_WAITING=${D_TEST}/.indicator-waiting

#########################################
# Hocks
#########################################

hock_before_deploy () {
    if ! [ -z ${H_BEFORE_DEPLOY} ]
    then
        eval ${H_BEFORE_DEPLOY}
    fi
}

hock_after_deploy () {
    if ! [ -z ${H_AFTER_DEPLOY} ]
    then
        eval ${H_AFTER_DEPLOY}
    fi
}

#########################################
# Functions
#########################################

remove_update_indicator () {
    rm -f ${I_UPDATE}
}

create_update_indicator () {
    touch ${I_UPDATE}
}

reset_directory () {
    cd ${START_DIRECTORY}
}

archive_build_directory_if_exists () {
    if [ -d ${D_BUILD} ] && ! file_exists ${F_ARCHIVE}
    then
        if tar -cv ${D_BUILD} | gzip > ${F_ARCHIVE}
        then
            success "build folder was successfully archived"
            if rm -dfr ${D_BUILD}
            then
                success "Build directory removed!"
            else
                error "Can't remove build directory!"
            fi
        else
            error "Can't archive build directory!"
        fi
    fi
}

finish () {
    archive_build_directory_if_exists
    remove_update_indicator
    print_execution_time
    reset_directory
    el
    exit $1
}

print_execution_time () {
    info "Script execution time $((`date +%s`-START_TIME)) seconds"
}

file_exists () {
    return test -f ${1}
}

exit_if_waiting () {
    if file_exists ${I_WAITING}
    then
        error "The script is already waiting";
        finish ${E_ALREADY_WAITING}
    fi
}

wait_update () {
    if file_exists ${I_UPDATE}
    then
        info "Expect for the end of another update"
        touch ${I_WAITING}
        while test -f ${I_UPDATE}
        do
            sleep ${SLEEP_INTERVAL}
        done
        rm -f ${I_WAITING}
    fi
}

remove_test_directory_if_exists () {
    if [ -d ${D_BUILD} ]
    then
        rm -dfr ${D_BUILD}
    fi
}

create_test_directory () {
    if ! [ -d ${D_TEST} ]
    then
        if mkdir -p ${D_TEST}
        then
            success "Created folder for test"
        else
            error "Can't create folder for test"
            finish ${E_CANT_CREATE_TEST_FOLDER}
        fi
    fi
}

create_build_directory () {
    if mkdir -p ${D_BUILD}
    then
        success "Created folder for build"
    else
        error "Can't create folder for build"
        finish ${E_CANT_CREATE_BUILD_FOLDER}
    fi
}

clone_project () {
    if git clone ${O_REPOSITORY} ${D_BUILD}
    then
        success "Project cloned"
    else
        error "Can't clone project"
        finish ${E_CANT_CLONE}
    fi
}

install_dependencies () {
    cd ${D_BUILD}

    # TODO Yarn

    if file_exists "${D_BUILD}/package.json"
    then
        if npm install
        then
            success "Npm dependencies installed"
        else
            error "Npm dependencies install failed"
            finish ${E_DEPENDENCIES_INSTALL_FAILED}
        fi
    fi

    if file_exists "${D_BUILD}/bower.json"
    then
        if bower install
        then
            success "Npm dependencies installed"
        else
            error "Npm dependencies install failed"
            finish ${E_DEPENDENCIES_INSTALL_FAILED}
        fi
    fi

    if file_exists "${D_BUILD}/composer.json"
    then
        if composer update
        then
            success "Npm dependencies installed"
        else
            error "Npm dependencies install failed"
            finish ${E_DEPENDENCIES_INSTALL_FAILED}
        fi
    fi

    if ! [ -z ${H_INSTALL} ]
    then
        if eval ${H_INSTALL}
        then
            success "Hock dependencies installed"
        else
            error "Hock dependencies install failed"
            finish ${E_DEPENDENCIES_INSTALL_FAILED}
        fi
    fi
}

build_project () {
    if ! [ -z ${H_BUILD} ]
    then
        if eval ${H_BUILD}
        then
            success "Build successful"
        else
            error "Build failed"
            finish ${E_BUILD_FAILED}
        fi
    fi
}

set_rights () {
    chmod -R ${O_PERMISSION} ${O_DIRECTORY}
    chown -R ${O_OWNER} ${O_DIRECTORY}
}

move_build_to_production_directory () {
    if rm -dfr ${O_DIRECTORY}
    then
        success "Old site removed!"
    else
        error "Can't remove old site!"
        finish ${E_REMOVE_SITE}
    fi

    if cp -r ${D_BUILD} ${O_DIRECTORY}
    then
        success "Build copied to production directory!"
    else
        error "Can't copy build to production directory!"
        finish ${E_COPY_BUILD}
    fi

    archive_build_directory_if_exists
}

restart_server () {
    if ! [ -z ${H_RESTART} ]
    then
        if eval ${H_RESTART}
        then
            success "Server restarted"
        else
            error "Restart server failed"
            finish ${E_RESTART_HOCK}
        fi
    fi

    if ${F_NGINX}
    then
        if service nginx restart
        then
            success "Nginx restarted"
        else
            error "Nginx restart failed"
            finish ${E_RESTART_NGINX}
        fi
    fi

    if ${F_APACHE}
    then
        if service apache2 restart
        then
            success "Apache restarted"
        else
            error "Apache restart failed"
            finish ${E_RESTART_APACHE}
        fi
    fi
}

deploy () {
    exit_if_waiting
    wait_update
    create_update_indicator
    remove_test_directory_if_exists
    create_build_directory
    clone_project
    hock_after_deploy
    install_dependencies
    build_project
    move_build_to_production_directory
    set_rights
    restart_server
    hock_before_deploy
    finish 0
}

#########################################
# Update project
#########################################

deploy
