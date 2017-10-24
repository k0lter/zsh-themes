
function prompt_kolter_precmd {
    git-info
}

function prompt_kolter_preexec {
  if [[ -n "${TMUX}" ]] && (( $+commands[tmux] )); then
    source <(tmux show-environment | sed -r -e '/^-/d' -e 's/^([^=]+)=(.*)$/\1="\2"/')
  fi
}

function prompt_kolter_setup {
  setopt LOCAL_OPTIONS
  unsetopt XTRACE KSH_ARRAYS
  prompt_opts=(cr percent subst)

  # Load required functions.
  autoload -Uz add-zsh-hook

  # Add hook for calling vcs_info before each command.
  add-zsh-hook precmd prompt_kolter_precmd
  add-zsh-hook precmd prompt_kolter_preexec

  # Use extended color pallete if available.
  if [[ $TERM = *256color* || $TERM = *rxvt* ]]; then
    _color_red="%F{196}"
    _color_green="%F{49}"
    _color_yellow="%F{226}"
    _color_blue="%F{21}"
    _color_magenta="%F{97}"
    _color_cyan="%F{26}"
    _color_white="%F{253}"
    _color_brightred="%F{197}"
    _color_brightgreen="%F{148}"
    _color_brightyellow="%F{228}"
    _color_brightblue="%F{39}"
    _color_brightmagenta="%F{139}"
    _color_brightcyan="%F{38}"
    _color_brightwhite="%F{231}"
    _color_reset="%f"
  else
    _color_red="%F{red}"
    _color_green="%F{green}"
    _color_yellow="%F{yellow}"
    _color_blue="%F{blue}"
    _color_magenta="%F{magenta}"
    _color_cyan="%F{cyan}"
    _color_white="%F{white}"
    _color_brightred="%B%F{red}"
    _color_brightgreen="%B%F{green}"
    _color_brightyellow="%B%F{yellow}"
    _color_brightblue="%B%F{blue}"
    _color_brightmagenta="%B%F{magenta}"
    _color_brightcyan="%B%F{cyan}"
    _color_brightwhite="%B%F{white}"
    _color_reset="%f"
  fi

  # In normal formats and actionformats the following replacements are done:
  # %s - The VCS in use (git, hg, svn, etc.).
  # %b - Information about the current branch.
  # %a - An identifier that describes the action. Only makes sense in actionformats.
  # %i - The current revision number or identifier. For hg the hgrevformat style may be used to customize the output.
  # %c - The string from the stagedstr style if there are staged changes in the repository.
  # %u - The string from the unstagedstr style if there are unstaged changes in the repository.
  # %R - The base directory of the repository.
  # %r - The repository name. If %R is /foo/bar/repoXY, %r is repoXY.
  # %S - A subdirectory within a repository. If $PWD is /foo/bar/repoXY/beer/tasty, %S is beer/tasty.
  #
  # In branchformat these replacements are done:
  # %s - The VCS in use (git, hg, svn, etc.).
  # %b - Information about the current branch.
  # %a - An identifier that describes the action. Only makes sense in actionformats.
  # %i - The current revision number or identifier. For hg the hgrevformat style may be used to customize the output.
  # %c - The string from the stagedstr style if there are staged changes in the repository.
  # %u - The string from the unstagedstr style if there are unstaged changes in the repository.
  # %R - The base directory of the repository.
  # %r - The repository name. If %R is /foo/bar/repoXY, %r is repoXY.
  # %S - A subdirectory within a repository. If $PWD is /foo/bar/repoXY/beer/tasty, %S is beer/tasty.

  local branch_format="${_color_brightyellow}%b${_color_reset} %u%c"
  local action_format="(${_color_green}%a${_color_reset})"
  local unstaged_format="${_color_brightred}●${_color_reset}"
  local staged_format="${_color_brightgreen}●${_color_reset}"

  # Set vcs_info parameters.
  zstyle ':vcs_info:*' enable svn git
  # If enabled, this style causes the %c and %u format escapes to show when the
  # working directory has uncommitted changes
  zstyle ':vcs_info:*:prompt:*' check-for-changes true
  # This string will be used in the %u escape if there are unstaged changes in
  # the repository
  zstyle ':vcs_info:*:prompt:*' unstagedstr "${unstaged_format}"
  # This string will be used in the %c escape if there are staged changes in
  # the repository
  zstyle ':vcs_info:*:prompt:*' stagedstr "${staged_format}"
  # A list of formats, used if there is a special action going on in your
  # current repository; like an interactive rebase or a merge conflict.
  zstyle ':vcs_info:*:prompt:*' actionformats "${branch_format}${action_format}"
  # A list of formats, used when actionformats is not used (which is most of
  # the time).
  zstyle ':vcs_info:*:prompt:*' formats " ${_color_brightwhite}on ${_color_brightcyan}%s${_color_brightwhite}:${branch_format}"
  # These "formats" are exported when we didn’t detect a version control system
  # for the current directory or vcs_info was disabled
  zstyle ':vcs_info:*:prompt:*' nvcsformats   ""

  zstyle ':prezto:module:git:info' verbose 'yes'
  zstyle ':prezto:module:git:info:action' format "${_color_red}! %s"
  zstyle ':prezto:module:git:info:added' format "${_color_brightgreen}✚"
  zstyle ':prezto:module:git:info:ahead' format "${_color_magenta}▲"
  zstyle ':prezto:module:git:info:behind' format "${_color_brightmagenta}▼"
  zstyle ':prezto:module:git:info:branch' format "${_color_brightyellow}%b"
  zstyle ':prezto:module:git:info:deleted' format "${_color_brightred}✖"
  zstyle ':prezto:module:git:info:modified' format "${_color_brightred}✱"
  zstyle ':prezto:module:git:info:position' format "${_color_brightwhite}%p"
  zstyle ':prezto:module:git:info:renamed' format "${_color_red}►"
  zstyle ':prezto:module:git:info:stashed' format "${_color_magenta}s"
  zstyle ':prezto:module:git:info:unmerged' format "${_color_red}═"
  zstyle ':prezto:module:git:info:untracked' format "${_color_brightblack}?"
  # More info on formats at https://github.com/sorin-ionescu/prezto/tree/master/modules/git
  zstyle ':prezto:module:git:info:keys' format 'prompt' " ${_color_brightwhite}on ${_color_brightblue}git${_color_brightwhite}:%b %p%A%B%S%a%d%m%r%U%u"

  # Define prompts.
  PROMPT=' \
%(!.%{$_color_brightred%}%n.%{$_color_brightgreen%}%n)\
%{$_color_brightwhite%} at \
%{$_color_brightmagenta%}%m\
%{$_white%}\
%{$_color_brightwhite%} in \
%{$_color_green%}%(!.%d.%~)\
${git_info[prompt]}\
%1(j.%{$_color_brightwhite%} with %{$_color_green%}%j%{$_color_brightwhite%} jobs.)
%0(?..%{$_color_red%}%?)\
%(!.%{$_color_red%}.%{$_color_cyan%})>%{$_color_reset%}'
  RPROMPT=''
}

prompt_kolter_setup

