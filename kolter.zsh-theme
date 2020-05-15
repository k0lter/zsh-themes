#
# A simple theme based on kolter theme
#
# Authors:
#   kolter Ionescu <kolter.ionescu@gmail.com>
#   Emmanuel Bouthenot <kolter@openics.org>
#

#
# 16 Terminal Colors
# -- ---------------
#  0 black
#  1 red
#  2 green
#  3 yellow
#  4 blue
#  5 magenta
#  6 cyan
#  7 white
#  8 bright black
#  9 bright red
# 10 bright green
# 11 bright yellow
# 12 bright blue
# 13 bright magenta
# 14 bright cyan
# 15 bright white
#

# Load dependencies.
pmodload 'helper'

function prompt_kolter_chroot() {
    local chroot_info=""
    if [[ -f '/etc/debian_chroot' ]]; then
        chroot_info=$(</etc/debian_chroot)
        if [[ -n "${chroot_info}" ]]; then
            chroot_info="chroot:${chroot_info} "
        fi
    fi
    print ${chroot_info}
}

function prompt_kolter_pwd {
    setopt localoptions extendedglob

    local current_pwd="${PWD/#$HOME/~}"
    local ret_directory

    if [[ "$current_pwd" == (#m)[/~] ]]; then
        ret_directory="$MATCH"
        unset MATCH
    elif zstyle -m ':prezto:module:prompt' pwd-length 'full'; then
        ret_directory=${PWD}
    elif zstyle -m ':prezto:module:prompt' pwd-length 'long'; then
        ret_directory=${current_pwd}
    else
        ret_directory="${${${${(@j:/:M)${(@s:/:)current_pwd}##.#?}:h}%/}//\%/%%}/${${current_pwd:t}//\%/%%}"
    fi

    unset current_pwd

    print "$ret_directory"
}

function prompt_kolter_preexec {
  if [[ -n "${TMUX}" ]] && (( $+commands[tmux] )); then
    source <(tmux show-environment | sed -r -e '/^-/d' -e 's/^([^=]+)=(.*)$/\1="\2"/')
  fi
}

function prompt_kolter_async_callback {
  case $1 in
    prompt_kolter_async_git)
      # We can safely split on ':' because it isn't allowed in ref names.
      IFS=':' read _git_target _git_post_target <<<"$3"

      # The target actually contains 3 space separated possibilities, so we need to
      # make sure we grab the first one.
      _git_target=$(coalesce ${(@)${(z)_git_target}})

      if [[ -z "$_git_target" ]]; then
        # No git target detected, flush the git fragment and redisplay the prompt.
        if [[ -n "$_prompt_kolter_git" ]]; then
          _prompt_kolter_git=''
          zle && zle reset-prompt
        fi
      else
        # Git target detected, update the git fragment and redisplay the prompt.
        _prompt_kolter_git="${_git_target}${_git_post_target}"
        zle && zle reset-prompt
      fi
      ;;
    "[async]")
      # Code is 1 for corrupted worker output and 2 for dead worker.
      if [[ $2 -eq 2 ]]; then
      # Our worker died unexpectedly.
          typeset -g prompt_prezto_async_init=0
      fi
      ;;
  esac
}

function prompt_kolter_async_git {
  cd -q "$1"
  if (( $+functions[git-info] )); then
    git-info
    print ${git_info[status]}
  fi
}

function prompt_kolter_async_tasks {
  # Initialize async worker. This needs to be done here and not in
  # prompt_kolter_setup so the git formatting can be overridden by other prompts.
  if (( !${prompt_prezto_async_init:-0} )); then
    async_start_worker prompt_kolter -n
    async_register_callback prompt_kolter prompt_kolter_async_callback
    typeset -g prompt_prezto_async_init=1
  fi

  # Kill the old process of slow commands if it is still running.
  async_flush_jobs prompt_kolter

  # Compute slow commands in the background.
  async_job prompt_kolter prompt_kolter_async_git "$PWD"
}

function prompt_kolter_precmd {
  setopt LOCAL_OPTIONS
  unsetopt XTRACE KSH_ARRAYS

  # Format PWD.
  _prompt_kolter_pwd=$(prompt_kolter_pwd)

  # Handle updating git data. We also clear the git prompt data if we're in a
  # different git root now.
  if (( $+functions[git-dir] )); then
    local new_git_root="$(git-dir 2> /dev/null)"
    if [[ $new_git_root != $_kolter_cur_git_root ]]; then
      _prompt_kolter_git=''
      _kolter_cur_git_root=$new_git_root
    fi
  fi

  # Run python info (this should be fast and not require any async)
  if (( $+functions[python-info] )); then
    python-info
  fi

  prompt_kolter_async_tasks
}

function prompt_kolter_setup {
  setopt LOCAL_OPTIONS
  unsetopt XTRACE KSH_ARRAYS
  prompt_opts=(cr percent sp subst)

  # Load required functions.
  autoload -Uz add-zsh-hook
  autoload -Uz async && async

  # Add hook for calling git-info before each command.
  add-zsh-hook precmd prompt_kolter_precmd
  # Add hook to refresh
  add-zsh-hook precmd prompt_kolter_preexec

  # Tell prezto we can manage this prompt
  zstyle ':prezto:module:prompt' managed 'yes'

  # Set git-info parameters.
  zstyle ':prezto:module:git:info' verbose 'yes'
  zstyle ':prezto:module:git:info:action' format '%F{7}:%f%%B%F{9}%s%f%%b'
  zstyle ':prezto:module:git:info:added' format ' %%B%F{2}✚%f%%b'
  zstyle ':prezto:module:git:info:ahead' format ' %%B%F{13}⬆%f%%b'
  zstyle ':prezto:module:git:info:behind' format ' %%B%F{13}⬇%f%%b'
  zstyle ':prezto:module:git:info:branch' format ' %%B%F{11}%b%f%%b'
  zstyle ':prezto:module:git:info:commit' format ' %%B%F{3}%.7c%f%%b'
  zstyle ':prezto:module:git:info:deleted' format ' %%B%F{1}✖%f%%b'
  zstyle ':prezto:module:git:info:modified' format ' %%B%F{4}✱%f%%b'
  zstyle ':prezto:module:git:info:position' format ' %%B%F{13}%p%f%%b'
  zstyle ':prezto:module:git:info:renamed' format ' %%B%F{5}➜%f%%b'
  zstyle ':prezto:module:git:info:stashed' format ' %%B%F{6}✭%f%%b'
  zstyle ':prezto:module:git:info:unmerged' format ' %%B%F{3}═%f%%b'
  zstyle ':prezto:module:git:info:untracked' format ' %%B%F{7}◼%f%%b'
  zstyle ':prezto:module:git:info:keys' format \
    'status' '%b %p %c:%s%A%B%S%a%d%m%r%U%u'

  # Set python-info parameters.
  zstyle ':prezto:module:python:info:virtualenv' format '%f%F{3}(%v)%F{7} '

  # Set up non-zero return value display
  local show_return="✘ "
  # Default is to show the return value
  if zstyle -T ':prezto:module:prompt' show-return-val; then
    show_return+='%? '
  fi

  # Get the async worker set up.
  _kolter_cur_git_root=''

  _prompt_kolter_git=''
  _prompt_kolter_pwd=''
  _prompt_kolter_chroot=$(prompt_kolter_chroot)

  # Define prompts.
  PROMPT='%1(j.%F{9}%j%F{15}❫ .)${SSH_TTY:+"%F{13}%n%f%F{7}@%f%F{14}%m%f "}%F{10}${_prompt_kolter_pwd}%(!. %B%F{1}#%f%b.) %F{12}❱%F{15} '
  RPROMPT='$python_info[virtualenv]%(?:: %F{1}'
  RPROMPT+=${show_return}
  RPROMPT+='%f)${_prompt_kolter_chroot}${_prompt_kolter_git}'
  SPROMPT='zsh: correct %F{1}%R%f to %F{2}%r%f [nyae]? '
}

function prompt_kolter_preview {
  local +h PROMPT=''
  local +h RPROMPT=''
  local +h SPROMPT=''

  editor-info 2> /dev/null
  prompt_preview_theme 'kolter'
}

prompt_kolter_setup "$@"

# vim: ft=zsh
