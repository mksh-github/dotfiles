#!/usr/bin/env bash

function get_symlink_target_dir () {
    local dotfiles_repo=${1}
    local symlink_target_dir=

    if [ ! -d "${dotfiles_repo}" ] ; then
        printf "no exists \"${dotfiles_repo}\"\n"
        return 1
    fi

    case "$(uname | tr \"[:upper:]\" \"[:lower:]\")" in
        'linux')
            if [ "$(uname -n)" = 'penguin' ] ; then
                # Crostini
                # NOTE: penguin only
                symlink_target_dir=${dotfiles_repo}/crostini

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
            symlink_target_dir=${dotfiles_repo}/macos

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

readonly _MOVE_EXIST_DOTFILES_TO="/tmp/dotfiles_backup/$(date '+%Y%m%d%H%M%S')"

# confirm
printf "If a file exists, the file will be moved to \"${_MOVE_EXIST_DOTFILES_TO}\".\n"
printf 'If a symbolic link exists, the link will be removed.\n'
read -p 'Would you like to continue? (y/N): ' -n 1 ; printf '\n'
if [[ ${REPLY} =~ ^[Yy]$ ]] ; then
    mkdir -p ${_MOVE_EXIST_DOTFILES_TO}
    printf '\n'
else
    exit 0
fi

# install
cd "$(get_symlink_target_dir ${HOME}/dotfiles)" || exit 1

for df in $(find "$(pwd)" -maxdepth 1 -name ".*" -not -name ".git" -not -name ".gitignore") ; do
    exists_df="${HOME}/$(basename ${df})"

    if [ -L "${exists_df}" ] ; then
        unlink ${exists_df} &&
        printf "* unlink ${exists_df}\n"
    elif [ -f "${exists_df}" ] ; then
        mv ${exists_df} ${_MOVE_EXIST_DOTFILES_TO} &&
        printf "* mv ${exists_df} ${_MOVE_EXIST_DOTFILES_TO}\n"
    elif [ -d "${exists_df}" ] ; then
        # TODO: .config .ssh
        printf "* ${exists_df} is directory\n"
        continue
    fi

    ln -s ${df} ${exists_df} &&
    printf "  ${exists_df} -> ${df}\n"
done

# cleanup empty backup directories
rmdir /tmp/dotfiles_backup/*

exit 0