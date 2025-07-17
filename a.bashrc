#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- == *i* ]] && source /usr/share/blesh/ble.sh --noattach

#[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

[[ ${BLE_VERSION-} ]] && ble-attach

# Enable auto-cd (change dir by typing path)
shopt -s autocd  # Bash built-in
bleopt accept_line_after_command=always  # ble.sh enhancement