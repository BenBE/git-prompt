#!/bin/bash

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
	if [ -f /usr/share/bash-completion/bash_completion ]; then
		. /usr/share/bash-completion/bash_completion
	elif [ -f /etc/bash_completion ]; then
		. /etc/bash_completion
	fi
fi

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

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

__gitdir() {
	if [ -z "${1-}" ]; then
		if [ -n "${__git_dir-}" ]; then
			echo "${__git_dir}"
		elif [ -n "${GIT_DIR-}" ]; then
			test -d "${GIT_DIR-}" || return 1
			echo "$GIT_DIR"
		elif [ -d .git ]; then
			echo .git
		else
			git rev-parse --git-dir 2>/dev/null
		fi
	elif [ -d "$1/.git" ]; then
		echo "$1/.git"
	else
		echo "$1"
	fi
}

__git_ps2_branch() {
	git rev-parse --abbrev-ref "HEAD" 2>/dev/null
}

__git_ps2_upstream() {
	git rev-parse --abbrev-ref "$1@{u}" 2>/dev/null
}

__git_ps2_upstream_repo() {
	for a in `git remote show 2>/dev/null|sort -ur`; do
		if [[ `__git_ps2_upstream` == $a/* ]]; then
			echo $a
			return
		fi
	done
}

__git_ps2_upstream_revdelta() {
	echo `git rev-list --count --left-right $(__git_ps2_upstream)...HEAD 2>/dev/null`
}

__git_ps2_diffstat() {
	if [[ "$1" == "" ]]; then
		echo -n 0 0 0
	elif [[ "$2" == "" ]]; then
		echo -n "$1" 0 0
	elif [[ "$3" == deletion* ]]; then
		echo -n "$1" 0 "$2"
	else
		echo -n "$1" "$2" "$4"
	fi
}

__git_ps2() {
	if ! __gitdir >/dev/null; then
		return
	fi

	if [[ $1 -ne 0 ]]; then
		local color_default="\033[0m"
		local color_red="\033[01;31m"
		local color_yellow="\033[01;33m"
		local color_green="\033[01;32m"
		local color_white="\033[01;37m"
	else
		local color_default=""
		local color_red=""
		local color_yellow=""
		local color_green=""
		local color_white=""
	fi

	local repo_info_gitdir=$(__gitdir)
	local repo_info_isgitdir=`git rev-parse --is-inside-git-dir 2>/dev/null`
	local repo_info_isbare=`git rev-parse --is-bare-repository 2>/dev/null`
	local repo_info_iswc=`git rev-parse --is-inside-work-tree 2>/dev/null`
	local repo_info_top=`git rev-parse --show-toplevel 2>/dev/null`

	local git_wc_branch=""
#	local git_wc_branch=$(__git_ps2_branch)
	local git_wc_state=""
	local git_wc_sha=`[[ "$repo_info_isbare" == "true" ]] || git rev-parse --short HEAD 2>/dev/null`

	local path_current=`pwd`

	local STAT_C=""
	local STAT_S=""
	local STAT_U=""

	if [[ "false" == "$repo_info_isbare" ]] && [[ "false" == "$repo_info_iswc" ]]; then
		cd ${repo_info_gitdir}/..
	fi

	STAT_S=`git diff --cached --stat 2>/dev/null|tail -1|awk '{print $1" "$4" "$5" "$6" "$7}'`
	STAT_U=`git diff --stat 2>/dev/null|tail -1|awk '{print  $1" "$4" "$5" "$6" "$7}'`
	STAT_C=`git diff --name-only --diff-filter=U 2>/dev/null|wc -l`

	[[ -z ${path_current} ]] || cd ${path_current}

	STAT_S=$(__git_ps2_diffstat $STAT_S)
	STAT_U=$(__git_ps2_diffstat $STAT_U)

#	if ! git diff --no-ext-diff --quiet --cached --exit-code 2>/dev/null; then
#		# staged changes
#		git_wc_state=${color_red}
#	elif ! git diff --no-ext-diff --quiet --exit-code 2>/dev/null; then
#		# unstaged changes
#		git_wc_state=${color_yellow}
#	else
#		# no changes
#		git_wc_state=${color_green}
#	fi
	if [[ "0 0 0" != "$STAT_S" ]]; then
		# staged changes
		git_wc_state=${color_red}
	elif [[ "0 0 0" != "$STAT_U" ]]; then
		# unstaged changes
		git_wc_state=${color_yellow}
	else
		# no changes
		git_wc_state=${color_green}
	fi

	local git_us_repo=$(__git_ps2_upstream_repo)
	local git_us_branch=$(__git_ps2_upstream)
	local git_us_delta=$(__git_ps2_upstream_revdelta)

	local git_op_flags=""

	local git_op_curr=""
	local git_op_total=""

	if [ -d "$repo_info_gitdir/rebase-merge" ]; then
		read git_wc_branch 2>/dev/null < "$repo_info_gitdir/rebase-merge/head-name"
		read git_op_curr 2>/dev/null < "$repo_info_gitdir/rebase-merge/msgnum"
		read git_op_total 2>/dev/null < "$repo_info_gitdir/rebase-merge/end"
		if [ -f "$repo_info_gitdir/rebase-merge/interactive" ]; then
			git_op_flags="REBASE -i"
		else
			git_op_flags="REBASE"
		fi
	else
		if [ -d "$repo_info_gitdir/rebase-apply" ]; then
			read git_op_curr 2>/dev/null <"$repo_info_gitdir/rebase-apply/next"
			read git_op_total 2>/dev/null <"$repo_info_gitdir/rebase-apply/last"
			if [ -f "$repo_info_gitdir/rebase-apply/rebasing" ]; then
				read b 2>/dev/null <"$repo_info_gitdir/rebase-apply/head-name"
				git_op_flags="REBASE"
			elif [ -f "$repo_info_gitdir/rebase-apply/applying" ]; then
				git_op_flags="AM"
			else
				git_op_flags="AM/REBASE"
			fi
		elif [ -f "$repo_info_gitdir/MERGE_HEAD" ]; then
			git_op_flags="MERGING"
		elif [ -f "$repo_info_gitdir/CHERRY_PICK_HEAD" ]; then
			git_op_flags="CHERRY"
		elif [ -f "$repo_info_gitdir/REVERT_HEAD" ]; then
			git_op_flags="REVERT"
		elif [ -f "$repo_info_gitdir/BISECT_LOG" ]; then
			git_op_flags="BISECT"
		fi

		if [ -n "$git_wc_branch" ]; then
			:
		elif [ -h "$repo_info_gitdir/HEAD" ]; then
			# symlink symbolic ref
			git_wc_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"
		else
			local head=""
			if ! read head 2>/dev/null <"$repo_info_gitdir/HEAD"; then
				return
			fi

			# is it a symbolic ref?
			git_wc_branch="${head#ref: }"
			if [ "$head" = "$git_wc_branch" ]; then
				detached=yes
				git_wc_branch="$(
					case "${GIT_PS1_DESCRIBE_STYLE-}" in
						(contains)
							git describe --contains HEAD ;;
						(branch)
							git describe --contains --all HEAD ;;
						(describe)
							git describe HEAD ;;
						(* | default)
							git describe --tags --exact-match HEAD ;;
					esac 2>/dev/null)" || git_wc_branch="$short_sha..."
				git_wc_branch="($git_wc_branch)"
			fi
		fi
	fi

	git_wc_branch=${git_wc_branch##refs/heads/}

	# Output the prompt

	[[ 0 == $1 ]] || echo -ne $color_white
	echo -n " ("

	[[ 0 == $1 ]] || echo -ne $git_wc_state
	echo -n $git_wc_branch

	if [[ "true" == $repo_info_isbare ]] || [[ "true" == $repo_info_isgitdir ]]; then
		[[ 0 == $1 ]] || echo -ne $color_white
		echo -n ":"
		if [[ "true" == $repo_info_isbare ]]; then
			echo -n "BARE"
		elif [[ "true" == $repo_info_isgitdir ]]; then
			echo -n "GIT_DIR"
		else
			echo -n "UNKNOWN"
		fi
	fi

	if ! [[ -z "$git_us_repo" ]]; then
		[[ 0 == $1 ]] || echo -ne $color_white
		echo -n "["
		[[ 0 == $1 ]] || echo -ne $color_green
		echo -n $git_us_repo
		[[ 0 == $1 ]] || echo -ne $color_white
		case $git_us_delta in
			"0 0")
				;;
			"0 "*)
				printf "`printf ":L+%s%%d" "$color_green"`" ${git_us_delta#0 }
				;;
			*" 0")
				printf "`printf ":R+%s%%d%s" "$color_red"`" ${git_us_delta% 0}
				;;
			*)
				printf "`printf ":R+%s%%d%s,L+%s%%d" "$color_red" "$color_white" "$color_green"`" $git_us_delta
				;;
		esac
		[[ 0 == $1 ]] || echo -ne $color_white
		echo -n "]"
	fi

	if ! [[ -z "$git_op_flags" ]]; then
		[[ 0 == $1 ]] || echo -ne $color_white
		echo -n '|'
		[[ 0 == $1 ]] || echo -ne $color_yellow
		echo -n $git_op_flags
		if [ -n "$git_op_curr" ] && [ -n "$git_op_total" ]; then
			[[ 0 == $1 ]] || echo -ne $color_white
			echo -n ' {'
			[[ 0 == $1 ]] || echo -ne $color_yellow
			echo -n $git_op_curr
			[[ 0 == $1 ]] || echo -ne $color_white
			echo -n '/'
			[[ 0 == $1 ]] || echo -ne $color_yellow
			echo -n $git_op_total
			[[ 0 == $1 ]] || echo -ne $color_white
			echo -n '}'
		fi
	fi

	[[ 0 == $1 ]] || echo -ne $color_white
	echo -n ")"

	if [ "$STAT_U" != "0 0 0" -o "$STAT_S" != "0 0 0" ]; then
		[[ 0 == $1 ]] || echo -ne $color_white
		echo -n '@'
		case $STAT_C in
			0)
				;;
			1)
				[[ 0 == $1 ]] || echo -ne $color_red
				echo -n '!'
				;;
			2)
				[[ 0 == $1 ]] || echo -ne $color_red
				echo -n '!!'
				;;
			*)
				[[ 0 == $1 ]] || echo -ne $color_red
				echo -n '!'$STAT_C'!'
		esac
		[[ 0 == $1 ]] || echo -ne $color_white
		echo -n '['
		printf "`printf 'T:%s%%d%s{%s+%%d%s/%s-%%d%s}' "$color_yellow" "$color_white" "$color_green" "$color_white" "$color_red" "$color_white"`" $STAT_U

		if [ "$STAT_S" != "0 0 0" ]; then
			echo -n ' '
			printf "`printf 'S:%s%%d%s{%s+%%d%s/%s-%%d%s}' "$color_yellow" "$color_white" "$color_green" "$color_white" "$color_red" "$color_white"`" $STAT_S
		fi
		echo -ne ']'
	fi

}

if [ "$color_prompt" = yes ]; then
	UIDCOLOR=32
	[[ 0 == $UID ]] && UIDCOLOR=31
	PS1='${debian_chroot:+($debian_chroot)}\[\033[01;'${UIDCOLOR}'m\]\u@\h\[\033[0m\]:\[\033[01;34m\]\w\[\0337\]$(__git_ps2 0)\[\0338$(__git_ps2 1)\]\[\033[0m\]\$ '
else
	PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w$(__git_ps2 0)\$ '
fi

unset color_prompt force_color_prompt UIDCOLOR
