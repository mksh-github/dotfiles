#!/usr/bin/env bash
set -euCo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/utils/log.sh"

BACKUP_DIR="/tmp/dotfiles_backup/$(date '+%Y%m%d%H%M%S')"
readonly BACKUP_DIR
DOTFILES_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_REPO_ROOT
DRY_RUN=false
for arg in "$@"; do
    case "${arg}" in
        --dry-run)
            DRY_RUN=true
            ;;
        *)
            ;;
    esac
done
readonly DRY_RUN

function get_symlink_target_dir () {
    local platform_dotfiles_dir=""
    local os_type=""
    local machine_arch=""

    os_type="$(uname | tr '[:upper:]' '[:lower:]')"
    machine_arch="$(uname -m)"

    case "${os_type}" in
        linux)
            if [ "$(uname -n)" = 'penguin' ] ; then # Crostini
                # NOTE: penguin only
                platform_dotfiles_dir="${DOTFILES_REPO_ROOT}/crostini"
                if [ -f '/etc/debian_version' ] ; then
                    platform_dotfiles_dir=${platform_dotfiles_dir}/debian
                else
                    log ERROR 'Unsupported Linux distribution on Crostini. Debian is expected.'
                fi
            else
                log ERROR 'Unsupported Linux environment. This script is primarily for Crostini.'
            fi
            ;;
        darwin) # macOS
            platform_dotfiles_dir="${DOTFILES_REPO_ROOT}/macos"
            if [ "${machine_arch}" = 'arm64' ] ; then # Apple Silicon Mac
                platform_dotfiles_dir="${platform_dotfiles_dir}/m1"
            else # Intel Mac
                # platform_dotfiles_dir=${platform_dotfiles_dir}/intel
                log ERROR "Unsupported macOS architecture: ${machine_arch}."
            fi

            # TODO:
            log WARN 'macOS is unsupported. But this will be released in the future.'
            return 0
            ;;
        *)
            log ERROR "Unsupported OS: ${os_type}."
            ;;
    esac

    if [ ! -d "${platform_dotfiles_dir}" ] ; then
        log ERROR "Platform-specific dotfiles directory not found: ${platform_dotfiles_dir}"
        return 1
    fi

    printf '%s\n' "${platform_dotfiles_dir}"
    return 0
}

function main() {
    if [ "${DRY_RUN}" = true ] ; then
        printf "========================================\n"
        printf "           DRY RUN MODE ENABLED         \n"
        printf "     No actual changes will be made.    \n"
        printf "========================================\n\n"
    fi

    local platform_dir=""

    platform_dir="$(get_symlink_target_dir "$(dirname "${BASH_SOURCE[0]}")")"
    if [ -z "${platform_dir}" ] || [ ! -d "${platform_dir}" ] ; then
        log INFO "No platform detected"
        return 0
    else
        log INFO "Platform detected. Using dotfiles from: ${platform_dir}"
    fi

    # confirm
    printf "Existing dotfiles in your HOME directory will be backed up to \"%s\".\n" "${BACKUP_DIR}"
    printf 'Existing symlinks will be removed and re-linked.\n'
    read -r -p 'Would you like to continue? (y/N): ' -n 1 ; printf '\n'
    if [[ ! "${REPLY}" =~ ^[Yy]$ ]] ; then
        log INFO "Installation cancelled by user."
        return 0
    fi

    if [ "${DRY_RUN}" = true ] ; then
        log INFO "DRY RUN: Creating directory: ${BACKUP_DIR}"
    else
        mkdir -p "${BACKUP_DIR}";
    fi
    log INFO "Backup directory created: ${BACKUP_DIR}"

    # install
    log INFO "Changing current directory to ${platform_dir}"
    if [ "${DRY_RUN}" = true ] ; then
        log INFO "DRY RUN: Changed directory: ${platform_dir}"
    else
        cd "${platform_dir}"
    fi

    if [ -f "./scripts/install.func.sh" ] ; then
        log INFO "Loading platform-specific functions from ./scripts/install.func.sh"
        if [ "${DRY_RUN}" = true ] ; then
            log INFO "DRY RUN: Executing \"./scripts/install.func.sh\""
        else
            source "./scripts/install.func.sh" "$(pwd)" "${BACKUP_DIR}" # 第1引数: platform_dir, 第2引数: BACKUP_DIR
        fi
        log INFO "Loaded platform-specific functions."
    else
        log ERROR "Platform-specific install functions (./scripts/install.func.sh) not found in ${platform_dir}"
        return 1
    fi

    log INFO "Linking dotfiles in HOME directory..."

    find "$(pwd)" -maxdepth 1 -name ".*" \
        -not -name ".git" \
        -not -name ".gitignore" \
        -not -name ".DS_Store" | \
    while read -r dotfile_source ; do
        local filename
        local symlink_target_path

        filename="$(basename "${dotfile_source}")"
        symlink_target_path="${HOME}/${filename}"

        if [ -L "${symlink_target_path}" ] ; then
            log INFO "Removing existing symlink: \"${symlink_target_path}\""
            if [ "${DRY_RUN}" = true ] ; then
                log INFO "DRY RUN: Removing existing symbolic link: \"${symlink_target_path}\""
            else
                unlink "${symlink_target_path}"
            fi
        elif [ -f "${symlink_target_path}" ] ; then
            log INFO "Backing up existing file: \"${symlink_target_path}\" to \"${BACKUP_DIR}/${filename}\""
            if [ "${DRY_RUN}" = true ] ; then
                log INFO "DRY RUN: Backing up existing file: \"${symlink_target_path}\" to \"${BACKUP_DIR}/${filename}\""
            else
                mv "${symlink_target_path}" "${BACKUP_DIR}"
            fi
        elif [ -d "${symlink_target_path}" ] ; then
            # アプリケーション固有の設定データ
            if [ "${DRY_RUN}" = true ] ; then
                log INFO "DRY RUN: Handling the application-specific configuration directory: \"${symlink_target_path}\""
            else
                [ "${filename}" = '.config' ] && symlink_application_config
                [ "${filename}" = '.ssh' ] && replace_ssh_config
            fi
            continue
        fi

        log INFO "Linking \"${symlink_target_path}\" -> \"${dotfile_source}\""
        if [ "${DRY_RUN}" = true ] ; then
            log INFO "DRY RUN: Creating symbolic link: \"${symlink_target_path}\" -> \"${dotfile_source}\""
        else
            ln -s "${dotfile_source}" "${symlink_target_path}"
        fi
    done

    # cleanup empty backup directories
    if [ "${DRY_RUN}" = true ] ; then
        log INFO "DRY RUN: Cleaning up empty backup directory: ${BACKUP_DIR}"
    else
        find "${BACKUP_DIR}" -maxdepth 0 -type d -empty -delete 2>/dev/null || true
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    main "$@" || exit "$?"
fi
