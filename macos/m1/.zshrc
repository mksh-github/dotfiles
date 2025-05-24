PROMPT='%n %c %% '

export LSCOLORS=cxfxcxdxbxegedabagacad
alias ls='ls -G'

# SSH keychain
if [ "$(ssh-add -l)" = 'The agent has no identities.' ] ; then
    ssh-add --apple-load-keychain
fi

# Homebrew & Rosetta2
function a64zsh () { (( $+commands[arch] )) && exec arch -arm64 /bin/zsh }
function x64zsh () { (( $+commands[arch] )) && exec arch -x86_64 /bin/zsh }

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
