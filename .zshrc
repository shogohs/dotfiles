# env
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    PROMPT='%n@%m %~ %# '
else
    PROMPT='%~ %# '
fi

export CLICOLOR=1
export LSCOLORS='Gxfxcxdxbxegedabagacad'

# npm
export PATH=$HOME/.nodebrew/current/bin:$PATH

# aliases
alias grep='grep --color=auto'
alias ll='ls -laF'
alias python='python3'

alias claude='op run --env-file=$HOME/.env -- claude'

# sfw
alias npm='sfw npm'
alias npx='sfw npx'
alias yarn='sfw yarn'
alias pnpm='sfw pnpm'
alias pip='sfw pip'
alias uv='sfw uv'
alias cargo='sfw cargo'
