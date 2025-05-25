PROMPT='%n %c %% '

export LSCOLORS=cxfxcxdxbxegedabagacad
alias ls='ls -G'

# SSH keychain
if [[ "$(ssh-add -l)" == 'The agent has no identities.' ]] ; then
    ssh-add --apple-load-keychain
fi

# Homebrew & Rosetta2
function a64zsh () { (( $+commands[arch] )) && exec arch -arm64 /bin/zsh }
function x64zsh () { (( $+commands[arch] )) && exec arch -x86_64 /bin/zsh }

if [[ $+commands[brew] ]] ; then
  echo $(arch)
fi

typeset -U path PATH fpath

if [[ "$(uname -m)" == "arm64" ]] ; then
  path=(
    /opt/homebrew/bin(N-/)
    /opt/homebrew/sbin(N-/)
    /usr/local/bin(N-/)  # x86対応 (Dockerなど)
    ${HOME}/.local/bin(N-/)  # pipx
    ${HOME}/.volta/bin(N-/)
    ${HOME}/.jenv/bin(N-/)
    ${HOME}/.yarn/bin(N-/)
    ${HOME}/.config/yarn/global/node_modules/.bin(N-/)
    ${HOME}/.codeium/windsurf/bin(N-/)
    /usr/bin
    /usr/sbin
    /bin
    /sbin
    /Library/Apple/usr/bin
    ${path}
  )
else
  path=(
    /usr/local/bin(N-/)
    /usr/local/sbin(N-/)
    ${HOME}/.local/bin(N-/)
    ${HOME}/.volta/bin(N-/)
    ${HOME}/.jenv/bin(N-/)
    ${HOME}/.yarn/bin(N-/)
    ${HOME}/.config/yarn/global/node_modules/.bin(N-/)
    ${HOME}/.codeium/windsurf/bin(N-/)
    /usr/bin
    /usr/sbin
    /bin
    /sbin
    /Library/Apple/usr/bin
    ${path}
  )
fi

# Volta
export VOLTA_HOME="${HOME}/.volta"

# goenv
eval "$(goenv init -)"

# rye
source "${HOME}/.rye/env"

# jenv
eval "$(jenv init -)"

# rbenv
eval "$(rbenv init - --no-rehash zsh)"

if type brew &>/dev/null; then
  fpath=(
    $(brew --prefix)/share/zsh-completions
    ${fpath}
  )

  autoload -Uz compinit
  compinit
fi

# rbenv completions
if [[ -d "${HOME}/.rbenv/completions" ]] ; then
  fpath=(
    ${HOME}/.rbenv/completions
    ${fpath}
  )
fi

# 自前の .zfunc
if [[ -d "${HOME}/.zfunc" ]] ; then
  fpath=(
    ${HOME}/.zfunc
    ${fpath}
  )
fi
