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

typeset -U path PATH

if [[ "$(uname -m)" == "arm64" ]] ; then
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
