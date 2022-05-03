#!/usr/bin/env bash

if [ ${0} != ${BASH_SOURCE} ] ; then
    printf 'exit\n'
    return 1
fi

readonly MOVE_EXIST_DOTFILES_TO="/tmp/dotfiles_backup/$(date '+%Y%m%d%H%M%S')"

source_dir=${1}
if [ ! "${source_dir}" ] ; then
    source_dir=${HOME}/dotfiles
fi

# determination of target directory
case "$(uname | tr \"[:upper:]\" \"[:lower:]\")" in
    'linux')
        if [ "$(uname -n)" = 'penguin' ] ; then
            # Crostini
            # NOTE: penguin only
            source_dir=${source_dir}/crostini

            if [ -f '/etc/debian_version' ] ; then
                source_dir=${source_dir}/debian
            fi
        fi
        ;;
    'darwin')
        source_dir=${source_dir}/macos

        if [ "$(uname -m)" = 'arm64' ] ; then
            # M1 Mac
            # NOTE: Rosetta is disabled
            source_dir=${source_dir}/m1
        fi

        # TODO: 
        printf 'macOS is not supported. But this will be released in the future.\n'
        exit 0
        ;;
    *)
        printf 'not supported platform\n'
        exit 1
esac

if [ ! -d ${source_dir} ] ; then
    printf "no exists \"${source_dir}\"\n"
    exit 1
else
    :
fi

# suggest
dotfiles=$(find ${source_dir} -maxdepth 1 -name ".*" -not -name ".config" -not -name ".ssh")
printf 'The target files are as follows:\n'
for df in ${dotfiles[@]} ; do
    printf "  $(basename ${df})\n"
done

# confirm
printf '\n'
printf "If a file exists, the file will be moved to \"${MOVE_EXIST_DOTFILES_TO}\".\n"
printf 'If a symbolic link exists, the link will be removed.\n'
read -p 'Would you like to continue? (y/N): ' -n 1 ; printf '\n'
if [[ ${REPLY} =~ ^[Yy]$ ]] ; then
    :
else
    exit 0
fi

# do
mkdir -p ${MOVE_EXIST_DOTFILES_TO}

exists_df=
grep_pattern=

for df in ${dotfiles[@]} ; do
    exists_df="${HOME}/$(basename ${df})"
    grep_pattern="${grep_pattern} -e ${df}"

    if [ -L ${exists_df} ] ; then
        printf "* unlink ${exists_df}\n"
        unlink ${exists_df}
    elif [ -f ${exists_df} ] ; then
        printf "* mv ${exists_df} ${MOVE_EXIST_DOTFILES_TO}\n"
        mv ${exists_df} ${MOVE_EXIST_DOTFILES_TO}
    fi

    ln -s ${source_dir}/$(basename ${df}) ${exists_df}
done

printf '\nresults:\n'
ls -aloX --color='always' ${HOME} | grep ${grep_pattern}

exit 0