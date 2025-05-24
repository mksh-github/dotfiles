#!/usr/bin/env bash
set -euCo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/utils/log.sh"

readonly BACKUP_DIR="/tmp/dotfiles_backup/$(date '+%Y%m%d%H%M%S')"
readonly DOTFILES_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function get_symlink_target_dir () {
    local platform_dotfiles_dir=""
    local os_type="$(uname | tr '[:upper:]' '[:lower:]')"
    local machine_arch="$(uname -m)"

    case "${os_type}" in
        linux)
            if [ "$(uname -n)" = 'penguin' ] ; then # Crostini
                # NOTE: penguin only
                platform_dotfiles_dir="${DOTFILES_REPO_ROOT}/crostini"
                if [ -f '/etc/debian_version' ] ; then
                    platform_dotfiles_dir=${platform_dotfiles_dir}/debian
                else
                    log ERROR 'Unsupported Linux distribution on Crostini. Debian is expected.'
                    exit 1
                fi
            else
                log ERROR 'Unsupported Linux environment. This script is primarily for Crostini.'
                exit 1
            fi
            ;;
        darwin) # macOS
            platform_dotfiles_dir="${DOTFILES_REPO_ROOT}/macos"
            if [ "${machine_arch}" = 'arm64' ] ; then # Apple Silicon Mac
                platform_dotfiles_dir="${platform_dotfiles_dir}/m1"
            else # Intel Mac
                # platform_dotfiles_dir=${platform_dotfiles_dir}/intel
                log ERROR "Unsupported macOS architecture: ${machine_arch}."
                exit 1
            fi

            # TODO:
            log WARN 'macOS is unsupported. But this will be released in the future.'
            exit 0
            ;;
        *)
            log ERROR "Unsupported OS: ${os_type}."
            exit 1
            ;;
    esac

    if [ ! -d "${platform_dotfiles_dir}" ]; then
        error_exit "Platform-specific dotfiles directory not found: ${platform_dotfiles_dir}"
    fi
    printf "${platform_dotfiles_dir}\n"
}

function main() {
    # confirm
    printf "Existing dotfiles in your HOME directory will be backed up to \"%s\".\n" "${BACKUP_DIR}"
    printf 'Existing symlinks will be removed and re-linked.\n'
    read -p 'Would you like to continue? (y/N): ' -n 1 ; printf '\n\n'
    if [[ ! "${REPLY}" =~ ^[Yy]$ ]] ; then
        log INFO "Installation cancelled by user."
        exit 0
    fi

    mkdir -p "${BACKUP_DIR}"
    log INFO "Backup directory created: ${BACKUP_DIR}"

    # install
    platform_dir="$(get_symlink_target_dir $(dirname ${BASH_SOURCE}))"
    if [ -z "${platform_dir}" ] || [ ! -d "${platform_dir}" ]; then
        echo $platform_dir
        log ERROR "Failed to execute get_symlink_target_dir"
        exit 1
    fi

    log INFO "Changing current directory to ${platform_dir}"
    cd "${platform_dir}"

    source ./scripts/install.func.sh "$(pwd)" "${BACKUP_DIR}"

    for dotfile_source in $(find "$(pwd)" -maxdepth 1 -name ".*" \
        -not -name ".git" \
        -not -name ".gitignore" \
        -not -name ".DS_Store") ;
    do
        filename="$(basename ${dotfile_source})"
        symlink_target_path="${HOME}/${filename}"

        if [ -L "${symlink_target_path}" ] ; then
            log INFO "Removing existing symlink: \"${symlink_target_path}\""
            unlink ${symlink_target_path}
        elif [ -f "${symlink_target_path}" ] ; then
            log INFO "Backing up existing file: \"${symlink_target_path}\" to \"${BACKUP_DIR}/${filename}\""
            mv ${symlink_target_path} ${BACKUP_DIR}
        elif [ -d "${symlink_target_path}" ] ; then
            # アプリケーション固有の設定データ
            [ "${filename}" = '.config' ] && symlink_application_config
            [ "${filename}" = '.ssh' ] && replace_ssh_config
            continue
        fi

        log INFO "Linking \"${symlink_target_path}\" -> \"${dotfile_source}\""
        ln -s "${dotfile_source}" "${symlink_target_path}"
    done

    # cleanup empty backup directories
    rmdir /tmp/dotfiles_backup/* 2&> /dev/null
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
