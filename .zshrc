if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git nvm colored-man-pages zsh-syntax-highlighting zsh-autosuggestions zsh-vi-mode fast-syntax-highlighting zsh-autocomplete)

source $ZSH/oh-my-zsh.sh
source $HOME/.dvm/dvm.sh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
# EXA
if [ -x "$(command -v eza)" ]; then
    alias ls="eza"
    alias la="eza --long --all --group"
fi


