export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share

shopt -s histappend
export HISTCONTROL=ignoredups:erasedups
export HISTSIZE=100000000
export SAVEHIST=$HISTSIZE

export VOLTA_HOME="$HOME/.local/volta"
export CARGO_HOME="$HOME/.local/cargo"
export RUSTUP_HOME="$HOME/.local/rustup"
export OPAM_SWITCH_PREFIX="$HOME/.local/opam"
export NPM_CONFIG_PREFIX="$HOME/.local/npm"
export ZVM_PATH="$HOME/.local/zvm"
export GOPATH="$HOME/.local/golang"
export GOBIN="$GOPATH/bin"

export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:$HOME/.local/go/bin
export PATH=$PATH:$HOME/.local/rust/bin
export PATH=$PATH:$HOME/.local/luarocks/bin
export PATH=$PATH:$HOME/.local/opam/bin
export PATH=$PATH:$HOME/.local/zvm/bin
export PATH=$PATH:$VOLTA_HOME/bin
export PATH=$PATH:$ZVM_HOME/bin
export PATH=$PATH:$CARGO_HOME/bin
export PATH=$PATH:$NPM_CONFIG_PREFIX/bin

export EDITOR=$(which nvim 2>/dev/null || echo vim)
export SUDO_EDITOR=$EDITOR

export FZF_DEFAULT_OPTS="--reverse"

sd() {
    local dirs=(~/ ~/git ~/projects ~/work ~/personal)
    local selected=$(find "${dirs[@]}" -mindepth 1 -maxdepth 1 -type d | fzf --height ~60% --reverse)
    [ -n "$selected" ] && cd $selected || echo "no directory selected"
}

# ---- prompt config ----
last_exit=0
git_info=""
git_root=""
virt_info=""
docker_info=""

PS0="\e]133;C\a"

_prompt_precmd() {
    last_exit=$?
    printf "\e]133;D;%s\a" "$last_exit"
    history -a

    # virtual environment
    virt_info=""
    [[ -n "$VIRTUAL_ENV" ]] && virt_info=" \[\e[33m\]${VIRTUAL_ENV##*/}\[\e[0m\]"

    # docker/podman detection
    docker_info=""
    if [[ -f /.dockerenv ]]; then
        docker_info="\[\e[1m\]\[\e[36m\]docker:\[\e[0m\]"
    elif [[ -f /run/.containerenv ]]; then
        docker_info="\[\e[1m\]\[\e[36m\]podman:\[\e[0m\]"
    fi

    # git
    git_info=""
    git_root=""
    local st
    st=$(git status --porcelain -b 2>/dev/null) || { _build_ps1; return; }
    git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    IFS= read -r line <<< "$st"
    local branch=${line#\#\# }
    branch=${branch%%...*}
    local ahead=0 behind=0 dirty=""
    if [[ $branch == "HEAD (no branch)" || $branch == "No commits yet on "* ]]; then
        branch="@$(git rev-parse --short HEAD 2>/dev/null)"
    fi
    [[ $line =~ ahead\ ([0-9]+)  ]] && ahead=${BASH_REMATCH[1]}
    [[ $line =~ behind\ ([0-9]+) ]] && behind=${BASH_REMATCH[1]}
    [[ $st == *$'\n'?* ]] && dirty="*"
    git_info=" \[\e[35m\]${branch}${dirty}\[\e[0m\]"
    (( ahead  )) && git_info+="\[\e[36m\] +${ahead}\[\e[0m\]"
    (( behind )) && git_info+="\[\e[36m\] -${behind}\[\e[0m\]"
    _build_ps1
}

_build_ps1() {
    local d
    if [[ -n "$git_root" ]]; then
        d="${git_root##*/}${PWD#$git_root}"
    else
        d="${PWD/#$HOME/\~}"
    fi

    local prompt_ssh=""
    [[ -n "${SSH_CLIENT:-}${SSH_TTY:-}${SSH_CONNECTION:-}" ]] && prompt_ssh="\[\e[1m\]\[\e[32m\]\h:\[\e[0m\]"

    local prompt_dir="\[\e[1m\]\[\e[34m\]${d}\[\e[0m\]"

    local job_count prompt_jobs=""
    job_count=$(jobs -p 2>/dev/null | wc -l)
    (( job_count > 0 )) && prompt_jobs="\[\e[90m\]+${job_count}\[\e[0m\] "

    local symbol="%"; (( EUID == 0 )) && symbol="#"
    local prompt_char="\[\e[1m\]\[\e[37m\]${symbol}\[\e[0m\]"
    (( last_exit )) && prompt_char="\[\e[1m\]\[\e[31m\]${symbol}\[\e[0m\]"

    local osc_a="\[\e]133;A\a\]"
    local osc_b="\[\e]133;B\a\]"
    PS1="${osc_a}${prompt_ssh}${docker_info}${prompt_dir}${git_info}${virt_info}\n${prompt_jobs}${prompt_char} ${osc_b}"
}

PROMPT_COMMAND="_prompt_precmd"
# ---- prompt config ----

source <(fzf --bash 2>/dev/null)

if command -v direnv >/dev/null 2>&1; then
    export DIRENV_LOG_FORMAT=
    eval "$(direnv hook bash 2>/dev/null)" 2>/dev/null
fi
