export PATH="$HOME/bin:$PATH"
export PATH="$PATH:$(ruby -e 'puts Gem.user_dir')/bin"
export TERMINAL=xst
export GPG_TTY="$(tty)"
export GPG_AGENT_INFO=""
export ZSH="$HOME"/.oh-my-zsh

# Oh-my-zsh
ZSH_THEME="random"
DISABLE_UPDATE_PROMPT=true
DISABLE_AUTO_UPDATE=true

source "$ZSH"/oh-my-zsh.sh

alias vifm=vifmrun
