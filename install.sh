#!/usr/bin/env bash

function get_symlink_target_dir () {
    local -r DOTFILES_REPO_ROOT=${1}
    local platform_dotfiles_dir=
    local os_type="$(uname | tr '[:upper:]' '[:lower:]')"

    if [ ! -d "${DOTFILES_REPO_ROOT}" ] ; then
        printf "no exists \"%s\"\n" ${DOTFILES_REPO_ROOT}
        return 1
    fi

    case "${os_type}" in
        'linux')
            if [ "$(uname -n)" = 'penguin' ] ; then
                # Crostini
                # NOTE: penguin only
                platform_dotfiles_dir=${DOTFILES_REPO_ROOT}/crostini

                if [ -f '/etc/debian_version' ] ; then
                    platform_dotfiles_dir=${platform_dotfiles_dir}/debian
                else
                    printf 'unsupported platform\n'
                    exit 1
                fi
            else
                printf 'unsupported platform\n'
                exit 1
            fi
            ;;
        'darwin')
            platform_dotfiles_dir=${DOTFILES_REPO_ROOT}/macos

            if [ "$(uname -m)" = 'arm64' ] ; then
                # M1 Mac
                # NOTE: Rosetta is disabled
                platform_dotfiles_dir=${platform_dotfiles_dir}/m1
            else
                # platform_dotfiles_dir=${platform_dotfiles_dir}/intel
                printf 'unsupported platform\n'
                exit 1
            fi

            # TODO:
            printf 'macOS is unsupported. But this will be released in the future.\n'
            exit 0
            ;;
        *)
            printf 'unsupported platform\n'
            exit 1
    esac

    echo ${platform_dotfiles_dir}
}

if [ ${0} != ${BASH_SOURCE} ] ; then
    printf 'exit\n'
    return 0
fi

readonly BACKUP_DIR="/tmp/dotfiles_backup/$(date '+%Y%m%d%H%M%S')"

# confirm
printf "If a file exists, the file will be moved to \"%s\".\n" ${BACKUP_DIR}
printf 'If a symbolic link exists, the link will be removed.\n'
read -p 'Would you like to continue? (y/N): ' -n 1 ; printf '\n'
if [[ ${REPLY} =~ ^[Yy]$ ]] ; then
    mkdir -p ${BACKUP_DIR}
    printf '\n'
else
    exit 0
fi

# install
cd "$(get_symlink_target_dir $(dirname ${BASH_SOURCE}))" || exit 1

source ./scripts/install.func.sh $(pwd) ${BACKUP_DIR}

for dotfile_source in $(find "$(pwd)" -maxdepth 1 -name ".*" -not -name ".git" -not -name ".gitignore") ; do
    symlink_target_path="${HOME}/$(basename ${dotfile_source})"

    if [ -L "${symlink_target_path}" ] ; then
        unlink ${symlink_target_path} &&
        printf "* unlink %s\n" ${symlink_target_path}
    elif [ -f "${symlink_target_path}" ] ; then
        mv ${symlink_target_path} ${BACKUP_DIR} &&
        printf "* mv %s %s\n" ${symlink_target_path} ${BACKUP_DIR}
    elif [ -d "${symlink_target_path}" ] ; then
        # アプリケーション固有の設定データ
        [ "$(basename ${dotfile_source})" = '.config' ] && symlink_application_config
        [ "$(basename ${dotfile_source})" = '.ssh' ] && replace_ssh_config
        continue
    fi

    ln -s ${dotfile_source} ${symlink_target_path} &&
    printf "  %s -> %s\n" ${symlink_target_path} ${dotfile_source}
done

# cleanup empty backup directories
rmdir /tmp/dotfiles_backup/* 2&> /dev/null

exit 0
