#!/usr/bin/env bash

function get_symlink_target_dir () {
    local dotfiles_repo=${1}
    local symlink_target_dir=

    case "$(uname | tr \"[:upper:]\" \"[:lower:]\")" in
        'linux')
            if [ "$(uname -n)" = 'penguin' ] ; then
                # Crostini
                # NOTE: penguin only
                symlink_target_dir=${dotfiles_repo}/crostini

                if [ -f '/etc/debian_version' ] ; then
                    symlink_target_dir=${symlink_target_dir}/debian
                fi
            fi
            ;;
        'darwin')
            symlink_target_dir=${dotfiles_repo}/macos

            if [ "$(uname -m)" = 'arm64' ] ; then
                # M1 Mac
                # NOTE: Rosetta is disabled
                symlink_target_dir=${symlink_target_dir}/m1
            fi

            # TODO: 
            printf 'macOS is not supported. But this will be released in the future.\n'
            exit 0
            ;;
        *)
            printf 'not supported platform\n'
            exit 1
    esac

    echo ${symlink_target_dir}
}

if [ ${0} != ${BASH_SOURCE} ] ; then
    printf 'exit\n'
    return 1
fi

readonly _MOVE_EXIST_DOTFILES_TO="/tmp/dotfiles_backup/$(date '+%Y%m%d%H%M%S')"

_dotfiles_repo=${1}
if [ ! "${_dotfiles_repo}" ] ; then
    _dotfiles_repo=${HOME}/dotfiles
fi

_symlink_target_dir=$(get_symlink_target_dir ${_dotfiles_repo})
if [ ! -d ${_symlink_target_dir} ] ; then
    printf "no exists \"${_symlink_target_dir}\"\n"
    exit 1
else
    :
fi

# suggest
_dotfiles=$(find ${_symlink_target_dir} -maxdepth 1 -name ".*" -not -name ".config" -not -name ".ssh")
printf 'The target files are as follows:\n'
for df in ${_dotfiles[@]} ; do
    printf "  $(basename ${df})\n"
done

# confirm
printf '\n'
printf "If a file exists, the file will be moved to \"${_MOVE_EXIST_DOTFILES_TO}\".\n"
printf 'If a symbolic link exists, the link will be removed.\n'
read -p 'Would you like to continue? (y/N): ' -n 1 ; printf '\n'
if [[ ${REPLY} =~ ^[Yy]$ ]] ; then
    mkdir -p ${_MOVE_EXIST_DOTFILES_TO}
else
    exit 0
fi

# install
_exists_df=
_grep_pattern=
for df in ${_dotfiles[@]} ; do
    _exists_df="${HOME}/$(basename ${df})"
    _grep_pattern="${_grep_pattern} -e ${df}"

    if [ -L ${_exists_df} ] ; then
        printf "  * unlink ${_exists_df}\n"
        unlink ${_exists_df}
    elif [ -f ${_exists_df} ] ; then
        printf "  * mv ${_exists_df} ${_MOVE_EXIST_DOTFILES_TO}\n"
        mv ${_exists_df} ${_MOVE_EXIST_DOTFILES_TO}
    fi

    ln -s ${_symlink_target_dir}/$(basename ${df}) ${_exists_df}
done

printf '\nresults:\n'
ls -aloX --color='always' ${HOME} | grep ${_grep_pattern}

exit 0