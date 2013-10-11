# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

__git_ps2_filter() {
    if [ "0$1" -eq "0" ]; then
        echo -ne "0 0 0"
    elif [ "0$2" -eq "0" ]; then
        echo -ne "$1 0 0"
    elif [ "0$4" -eq "0" -a "$3" == "deletions(-)" ]; then
        echo -ne "$1 0 $2"
    else
        echo -ne "$1 $2 $4"
    fi
}

__git_ps2() {
    if __gitdir >/dev/null; then
        if ! git diff --no-ext-diff --quiet --cached --exit-code; then
            # staged changes
            [ $1 -ne 0 ] && echo -ne '\033[01;31m'
        elif ! git diff --no-ext-diff --quiet --exit-code; then
            # unstaged changes
            [ $1 -ne 0 ] && echo -ne '\033[01;33m'
        else
            # no changes
            [ $1 -ne 0 ] && echo -ne '\033[01;32m'
        fi
        STAT_S=`git diff --cached --shortstat|awk '{print $1" "$4" "$5" "$6}'`
        STAT_U=`git diff --shortstat|awk '{print $1" "$4" "$5" "$6}'`
        STAT_C=`git diff --name-only --diff-filter=U|wc -l`

        STAT_S=$(__git_ps2_filter $STAT_S)
        STAT_U=$(__git_ps2_filter $STAT_U)
        __git_ps1
        if [ $1 -ne 0 ]; then
            if [ "$STAT_U" != "0 0 0" -o "$STAT_S" != "0 0 0" ]; then
                echo -ne '\033[01;37m@'
                if [ $STAT_C -eq 1 ]; then
                    echo -ne '\033[01;31m!'
                elif [ $STAT_C -gt 1 ]; then
                    echo -ne '\033[01;31m!'$STAT_C'!'
                fi
                echo -ne '\033[01;37m['
                printf 'T:\033[01;33m%d\033[01;37m{\033[01;32m+%d\033[01;37m/\033[01;31m-%d\033[01;37m}' $STAT_U
                if [ "$STAT_S" != "0 0 0" ]; then
                    echo -ne ' '
                    printf 'S:\033[01;33m%d\033[01;37m{\033[01;32m+%d\033[01;37m/\033[01;31m-%d\033[01;37m}' $STAT_S
                fi
                echo -ne ']'
            fi
        else
            if [ "$STAT_U" != "0 0 0" -o "$STAT_S" != "0 0 0" ]; then
                echo -ne '@'
                if [ $STAT_C -eq 1 ]; then
                    echo -ne '!'
                elif [ $STAT_C -gt 1 ]; then
                    echo -ne '!'$STAT_C'!'
                fi
                echo -ne '['
                printf 'T:%d{+%d/-%d}' $STAT_U
                if [ "$STAT_S" != "0 0 0" ]; then
                    echo -ne ' '
                    printf 'S:%d{+%d/-%d}' $STAT_S
                fi
                echo -ne ']'
            fi
        fi
    fi
}

if [ "$color_prompt" = yes ]; then
    UIDCOLOR=32
    [[ 0 == $UID ]] && UIDCOLOR=31
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;'${UIDCOLOR}'m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[01;37m\]\[\0337\]$(__git_ps2 0)\[\0338$(__git_ps2 1)\]\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w$(__git_ps1 " (%s)")\$ '
fi
unset color_prompt force_color_prompt

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi
