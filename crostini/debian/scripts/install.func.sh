#!/usr/bin/env bash

readonly _CURRENT_PLATFORM_DIR=${1}
readonly _BACKUP_DIR=${2}

function _symlink_config () {
    # $EXISTS_CF -> $SYMLINK_CF

    local -r EXISTS_CF=${1}
    local -r SYMLINK_CF=${2}
    local -r MOVE_EXIST_CONFIG_TO=${3}

    if [ -L "${EXISTS_CF}" ] ; then
        unlink "${EXISTS_CF}" &&
        printf "* unlinked %s\n" ${EXISTS_CF}
    elif [ -f "${EXISTS_CF}" ] ; then
        mkdir -p ${MOVE_EXIST_CONFIG_TO} &&
        mv ${EXISTS_CF} ${MOVE_EXIST_CONFIG_TO} &&
        printf "* moved %s to %s\n" ${EXISTS_CF} ${MOVE_EXIST_CONFIG_TO}
    fi

    ln -s ${SYMLINK_CF} ${EXISTS_CF} &&
    printf "  %s -> %s\n" ${EXISTS_CF} ${SYMLINK_CF}
}

function _symlink_vscode_config () {
    local -r VSCODE_CONFIG_DIR='.config/Code/User'
    local -r MOVE_EXIST_CONFIG_TO="${_BACKUP_DIR}/vscode"
    local cf=

    if [[ ! -d "${HOME}/${VSCODE_CONFIG_DIR}" || \
          ! -d "${_CURRENT_PLATFORM_DIR}/${VSCODE_CONFIG_DIR}" ]]
    then
        echo 'no exists VSCode config directories'
        return 1
    fi

    cf='settings.json'
    _symlink_config \
        "${HOME}/${VSCODE_CONFIG_DIR}/${cf}" \
        "${_CURRENT_PLATFORM_DIR}/${VSCODE_CONFIG_DIR}/${cf}" \
        "${MOVE_EXIST_CONFIG_TO}/"
}

function _symlink_fcitx_config () {
    local -r FCITX_CONFIG_DIR='.config/fcitx'
    local -r MOVE_EXIST_CONFIG_TO="${_BACKUP_DIR}/fcitx"
    local cf=

    if [[ ! -d "${HOME}/${FCITX_CONFIG_DIR}" || \
          ! -d "${_CURRENT_PLATFORM_DIR}/${FCITX_CONFIG_DIR}" ]]
    then
        echo 'no exists Fcitx config directories'
        return 1
    fi

    cf='config'
    _symlink_config \
        "${HOME}/${FCITX_CONFIG_DIR}/${cf}" \
        "${_CURRENT_PLATFORM_DIR}/${FCITX_CONFIG_DIR}/${cf}" \
        "${MOVE_EXIST_CONFIG_TO}/"
    
    cf='profile'
    _symlink_config \
        "${HOME}/${FCITX_CONFIG_DIR}/${cf}" \
        "${_CURRENT_PLATFORM_DIR}/${FCITX_CONFIG_DIR}/${cf}" \
        "${MOVE_EXIST_CONFIG_TO}/"
}

function _symlink_gtk3_config () {
    local -r GTK3_CONFIG_DIR='.config/gtk-3.0'
    local -r MOVE_EXIST_CONFIG_TO="${_BACKUP_DIR}/gtk3"
    local cf=

    if [[ ! -d "${HOME}/${GTK3_CONFIG_DIR}" || \
          ! -d "${_CURRENT_PLATFORM_DIR}/${GTK3_CONFIG_DIR}" ]]
    then
        echo 'no exists GTK3 config directories'
        return 1
    fi

    cf='bookmarks'
    _symlink_config \
        "${HOME}/${GTK3_CONFIG_DIR}/${cf}" \
        "${_CURRENT_PLATFORM_DIR}/${GTK3_CONFIG_DIR}/${cf}" \
        "${MOVE_EXIST_CONFIG_TO}/"
    
    cf='settings.ini'
    _symlink_config \
        "${HOME}/${GTK3_CONFIG_DIR}/${cf}" \
        "${_CURRENT_PLATFORM_DIR}/${GTK3_CONFIG_DIR}/${cf}" \
        "${MOVE_EXIST_CONFIG_TO}/"
}

function _symlink_gtk4_config () {
    local -r GTK4_CONFIG_DIR='.config/gtk-4.0'
    local -r MOVE_EXIST_CONFIG_TO="${_BACKUP_DIR}/gtk4"
    local cf=

    if [[ ! -d "${HOME}/${GTK4_CONFIG_DIR}" || \
          ! -d "${_CURRENT_PLATFORM_DIR}/${GTK4_CONFIG_DIR}" ]]
    then
        echo 'no exists GTK4 config directories'
        return 1
    fi

    cf='bookmarks'
    _symlink_config \
        "${HOME}/${GTK4_CONFIG_DIR}/${cf}" \
        "${_CURRENT_PLATFORM_DIR}/${GTK4_CONFIG_DIR}/${cf}" \
        "${MOVE_EXIST_CONFIG_TO}/"
    
    cf='settings.ini'
    _symlink_config \
        "${HOME}/${GTK4_CONFIG_DIR}/${cf}" \
        "${_CURRENT_PLATFORM_DIR}/${GTK4_CONFIG_DIR}/${cf}" \
        "${MOVE_EXIST_CONFIG_TO}/"
}

function symlink_application_config () {
    _symlink_vscode_config
    _symlink_fcitx_config
    _symlink_gtk3_config
    _symlink_gtk4_config
}

function replace_ssh_config () {
    local -r SSH_CONFIG_DIR='.ssh'
    local -r MOVE_EXIST_CONFIG_TO="${_BACKUP_DIR}/ssh"

    if [[ ! -d "${HOME}/${SSH_CONFIG_DIR}" || \
          ! -d "${_CURRENT_PLATFORM_DIR}/${SSH_CONFIG_DIR}" ]]
    then
        echo 'no exists .ssh directories'
        return 1
    fi

    cf='config'
    _symlink_config \
        "${HOME}/${SSH_CONFIG_DIR}/${cf}" \
        "${_CURRENT_PLATFORM_DIR}/${SSH_CONFIG_DIR}/${cf}" \
        "${MOVE_EXIST_CONFIG_TO}/"
}