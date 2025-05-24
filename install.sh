#!/usr/bin/env bash

function get_symlink_target_dir () {
    local -r DOTFILES_REPO_ROOT=${1}
    local symlink_target_dir=

    if [ ! -d "${DOTFILES_REPO_ROOT}" ] ; then
        printf "no exists \"%s\"\n" ${DOTFILES_REPO_ROOT}
        return 1
    fi

    case "$(uname | tr \"[:upper:]\" \"[:lower:]\")" in
        'linux')
            if [ "$(uname -n)" = 'penguin' ] ; then
                # Crostini
                # NOTE: penguin only
                symlink_target_dir=${DOTFILES_REPO_ROOT}/crostini

                if [ -f '/etc/debian_version' ] ; then
                    symlink_target_dir=${symlink_target_dir}/debian
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
            symlink_target_dir=${DOTFILES_REPO_ROOT}/macos

            if [ "$(uname -m)" = 'arm64' ] ; then
                # M1 Mac
                # NOTE: Rosetta is disabled
                symlink_target_dir=${symlink_target_dir}/m1
            else
                # symlink_target_dir=${symlink_target_dir}/intel
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

    echo ${symlink_target_dir}
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

for df in $(find "$(pwd)" -maxdepth 1 -name ".*" -not -name ".git" -not -name ".gitignore") ; do
    exists_df="${HOME}/$(basename ${df})"

    if [ -L "${exists_df}" ] ; then
        unlink ${exists_df} &&
        printf "* unlink %s\n" ${exists_df}
    elif [ -f "${exists_df}" ] ; then
        mv ${exists_df} ${BACKUP_DIR} &&
        printf "* mv %s %s\n" ${exists_df} ${BACKUP_DIR}
    elif [ -d "${exists_df}" ] ; then
        # アプリケーション固有の設定データ
        [ "$(basename ${df})" = '.config' ] && symlink_application_config
        [ "$(basename ${df})" = '.ssh' ] && replace_ssh_config
        continue
    fi

    ln -s ${df} ${exists_df} &&
    printf "  %s -> %s\n" ${exists_df} ${df}
done

# cleanup empty backup directories
rmdir /tmp/dotfiles_backup/* 2&> /dev/null

exit 0
