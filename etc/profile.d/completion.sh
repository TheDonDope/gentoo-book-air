# enable bash completion if available
if [ -f /etc/bash_completion ]; then
  source /etc/bash_completion
fi

# Gentoo Portage completions
if [ -f /usr/share/portage/bashrc ]; then
  source /usr/share/portage/bashrc
fi
