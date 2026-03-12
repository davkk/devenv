export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share

export HYPHEN_INSENSITIVE=false
export WORDCHARS=

set -o emacs
bind '"\C-y": accept-line'
bind '"\C-n": complete'

sd() {
    dirs=(~/ ~/git ~/projects ~/work ~/personal ~/university)
    selected=$(find "${dirs[@]}" -mindepth 1 -maxdepth 1 -type d | fzf --height ~60%)
    [ -n "$selected" ] && cd $selected || echo "no directory selected"
}

review() {
    local target=${1:-origin/main}
    local fork=$(git merge-base HEAD $target)
    local files=$(git diff --name-only $fork)
    if [[ -n "$files" ]]; then
        nvim -p $(echo "$files") +"tabdo GitDiff $fork" +tabfirst
    fi
}

alias l='ls --color -lahF --group-directories-first'
alias tmux='tmux -u'

export XDG_CURRENT_DESKTOP="sway"
export XDG_SESSION_DESKTOP="sway"
export XDG_CURRENT_SESSION_TYPE="wayland"

export MOZ_ENABLE_WAYLAND=1
export XCURSOR_SIZE=28

export GDK_BACKEND="wayland,x11"

export QT_QPA_PLATFORM="wayland"
export QT_QPA_PLATFORMTHEME="qt5ct"
export QT_ENABLE_HIGHDPI_SCALING=1

export HISTFILE=$XDG_DATA_HOME/bash_history
export HISTSIZE=100000000
export SAVEHIST=$HISTSIZE

export ANDROID_SDK_ROOT=$HOME/.android
export ANDROID_AVD_HOME=$HOME/.android

export NVM_DIR="$HOME/.local/nvm"
export CARGO_HOME="$HOME/.local/cargo"
export RUSTUP_HOME="$HOME/.local/rustup"
export OPAM_SWITCH_PREFIX="$HOME/.local/opam"
export NPM_CONFIG_PREFIX="$HOME/.local/npm"
export ZVM_HOME="$HOME/.local/zvm"
export GOBIN="$HOME/.local/go/bin"

export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:$HOME/.local/go/bin
export PATH=$PATH:$HOME/.local/rust/bin
export PATH=$PATH:$HOME/.local/luarocks/bin
export PATH=$PATH:$HOME/.local/opam/bin
export PATH=$PATH:$HOME/.local/zvm/bin
export PATH=$PATH:$ZVM_HOME/bin
export PATH=$PATH:$CARGO_HOME/bin
export PATH=$PATH:$NPM_CONFIG_PREFIX/bin
export PATH=$PATH:$HOME/.android/cmdline-tools/latest/bin
export PATH=$PATH:$HOME/.android/emulator
export PATH=$PATH:$HOME/.android/platform-tools

export FZF_BASE=$(which fzf 2>/dev/null || echo "/usr/bin/fzf")
export FZF_DEFAULT_OPTS="
--color=fg:#888888,bg:#111111,hl:#ffffff
--color=fg+:#888888,bg+:#222222,hl+:#ffffff
--color=border:#222222,header:#888888,gutter:#111111
--color=spinner:#ffffff,info:#888888
--color=pointer:#ffffff,marker:#ffffff,prompt:#ffffff
--bind ctrl-y:accept
"
source <(fzf --bash 2>/dev/null)

export GIT_CONFIG_GLOBAL=$HOME/.config/.gitconfig

export _JAVA_AWT_WM_NONREPARENTING=1

export SUDO_EDITOR=$(which nvim 2>/dev/null || echo "vim")
export EDITOR=$(which nvim 2>/dev/null || echo "vim")
export MANPAGER="$(which nvim 2>/dev/null || echo "vim") +Man!"

if [[ -s "$HOME/.local/nvm/nvm.sh" ]]; then
    export NVM_DIR="$HOME/.local/nvm"
    unset NPM_CONFIG_PREFIX
    . "$NVM_DIR/nvm.sh"
fi

if command -v direnv >/dev/null 2>&1; then
    export DIRENV_LOG_FORMAT=
    eval "$(direnv hook bash)" 2>/dev/null
fi

last_exit=0
git_info=''
git_root=''
virt_info=''
cmd_start=0
cmd_duration=0

_prompt_preexec() {
    [[ "${COMP_LINE:-}" != "" ]]             && return  # skip during tab completion
    [[ "$BASH_COMMAND" == "_prompt_precmd" ]] && return  # skip PROMPT_COMMAND itself
    cmd_start=$SECONDS
}
trap '_prompt_preexec' DEBUG

_prompt_precmd() {
    last_exit=$?

    # execution time
    if (( cmd_start )); then
        cmd_duration=$(( SECONDS - cmd_start ))
    else
        cmd_duration=0
    fi
    cmd_start=0

    # virtual environment
    virt_info=''
    [[ -n "$VIRTUAL_ENV" ]] && virt_info=" \[\e[33m\]${VIRTUAL_ENV##*/}\[\e[0m\]"

    # git
    git_info=''
    git_root=''
    local st
    st=$(git status --porcelain -b 2>/dev/null) || { _build_ps1; return; }

    git_root=$(git rev-parse --show-toplevel 2>/dev/null)

    local line=${st%%$'\n'*}
    local branch=${line#\#\# }
    branch=${branch%%...*}
    local ahead=0 behind=0 dirty=''

    # detached HEAD fallback
    if [[ $branch == 'HEAD (no branch)' || $branch == 'No commits yet on '* ]]; then
        branch="@$(git rev-parse --short HEAD 2>/dev/null)"
    fi

    [[ $line =~ ahead\ ([0-9]+)  ]] && ahead=${BASH_REMATCH[1]}
    [[ $line =~ behind\ ([0-9]+) ]] && behind=${BASH_REMATCH[1]}
    [[ $st == *$'\n'?* ]] && dirty='*'

    git_info=" \[\e[35m\]${branch}${dirty}\[\e[0m\]"
    (( ahead  )) && git_info+="\[\e[36m\] +${ahead}\[\e[0m\]"
    (( behind )) && git_info+="\[\e[36m\] -${behind}\[\e[0m\]"

    _build_ps1
}

_build_ps1() {
    # dir
    local d
    if [[ -n "$git_root" ]]; then
        d="${git_root##*/}${PWD#$git_root}"
    else
        d="${PWD/#$HOME/~}"
    fi
    (( ${#d} > 80 )) && d="${d:0:77}..."
    local prompt_dir="\[\e[1m\]\[\e[34m\]${d}\[\e[0m\]"

    # exec time
    local prompt_time=''
    if (( cmd_duration >= 5 )); then
        local secs=$cmd_duration out=''
        (( secs >= 86400 )) && out+="$(( secs/86400 ))d " && secs=$(( secs%86400 ))
        (( secs >= 3600  )) && out+="$(( secs/3600  ))h " && secs=$(( secs%3600  ))
        (( secs >= 60    )) && out+="$(( secs/60    ))m " && secs=$(( secs%60    ))
        prompt_time=" \[\e[90m\]${out}${secs}s\[\e[0m\]"
    fi

    # background jobs
    local prompt_jobs=''
    local job_count
    job_count=$(jobs -p 2>/dev/null | wc -l)
    (( job_count > 0 )) && prompt_jobs="\[\e[90m\]+${job_count}\[\e[0m\] "

    # prompt char
    local prompt_char
    if (( last_exit )); then
        prompt_char="\[\e[1m\]\[\e[31m\]%\[\e[0m\]"
    else
        prompt_char="\[\e[1m\]\[\e[37m\]%\[\e[0m\]"
    fi

    PS1="${prompt_dir}${git_info}${virt_info}${prompt_time}\n${prompt_jobs}${prompt_char} "
}

PROMPT_COMMAND='_prompt_precmd'
