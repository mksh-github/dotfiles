# Homebrew & Rosetta2
# NOTE: reference: https://zenn.dev/sprout2000/articles/aad599d3625242
function a64zsh () {
  if ! (( $+commands[arch] )) ; then
    return
  fi

  # echo "switch to 'arm64e'"
  exec arch -arm64e /bin/zsh
}

function x64zsh () {
  if ! (( $+commands[arch] )) ; then
    return
  fi

  # echo "switch to 'x86_64'"
  exec arch -x86_64 /bin/zsh
}
  
if [ "$(uname -m)" = "arm64" ] ; then
  typeset -U path PATH
  path=(
    /opt/homebrew/bin(N-/)
    /opt/homebrew/sbin(N-/)
    /usr/local/bin(N-/)  # docker
    # /usr/local/sbin(N-/)
    /usr/bin
    /usr/sbin
    /bin
    /sbin
    /Library/Apple/usr/bin
  )
else
  typeset -U path PATH
  path=(
    /usr/local/bin(N-/)
    /usr/local/sbin(N-/)
    /usr/bin
    /usr/sbin
    /bin
    /sbin
    /Library/Apple/usr/bin
  )
fi

if (( $+commands[brew] )) ; then
  echo $(arch)
  # echo "$(brew config)" | cat | grep 'Rosetta'
  # echo "$(which brew)"
fi

# Pyenv
if [ "$(uname -m)" = "arm64" ] ; then
  export PYENV_ROOT="${HOME}/.pyenv_a64"
  export PATH="$(brew --prefix pyenv)/bin:$PATH"
else
  export PYENV_ROOT="${HOME}/.pyenv_x64"
  export PATH="$(brew --prefix pyenv)/bin:$PATH"
fi
eval "$($(brew --prefix pyenv)/bin/pyenv init -)"
eval "$($(brew --prefix pyenv)/bin/pyenv init --path)"

# nvm path
if [ "$(uname -m)" = "arm64" ] ; then
  export NVM_DIR="${HOME}/.nvm_a64"
else
  export NVM_DIR="${HOME}/.nvm_x64"
fi
[ -s "$(brew --prefix nvm)/nvm.sh" ] && . "$(brew --prefix nvm)/nvm.sh" # This loads nvm
[ -s "$(brew --prefix nvm)/etc/bash_completion.d/nvm" ] && . "$(brew --prefix nvm)/etc/bash_completion.d/nvm" # This loads nvm bash_completion

# SSH keychain
if [ "$(ssh-add -l)" = 'The agent has no identities.' ] ; then
    ssh-add --apple-load-keychain
fi
