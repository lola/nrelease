autoload -U compinit promptinit
compinit
zmodload -i zsh/complist

alias ls='ls -G -F -h'
alias df='df -h'
alias vi='vim'
alias du='du -hsc *'

PS1="$(print '%{\e[1;34m%}(%{\e[1;31m%}%M%{\e[1;34m%})%{\e[1;36m%}-%{\e[1;34m%}(%{\e[0m%}%C%{\e[1;34m%})%{\e[1;36m%}-%{\e[1;31m%}%#%{\e[0m%}') "

bindkey "[7~" beginning-of-line
bindkey "[8~" end-of-line
bindkey "[3~" delete-char

export PAGER=less
export EDITOR=vim
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE=~/.history
export CVS_RSH=ssh
setopt append_history SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_REDUCE_BLANKS
setopt NO_FLOW_CONTROL

case $TERM in
    cons25)
	;;
	*)
        precmd () {print -Pn "\e]0;%n@%m: %~\a"}
	;;
esac

# autostart X
if [ ! -f /tmp/.firstLogin ]; then 
 	echo "Starting X..."
 	touch /tmp/.firstLogin
	startx
fi

zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
