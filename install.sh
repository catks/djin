#!/bin/bash

set -e

_DJIN_BIN_PATH=/usr/local/bin/djin
_GEM_PATH=`command -v gem`

function info() {
  >&2 echo $1
}

function verify_ruby_installation() {
  info 'Verifying Ruby Instalation...'
  command -v ruby 2>&1 /dev/null || (info "Missing Ruby installation, read https://www.ruby-lang.org/en/documentation/installation/ for instructions" && exit 1)
  info 'Ok'
}

function maybe_sudo() {
  $* || info 'Trying with sudo' && sudo $*
}

function uninstall_djin_rbenv {
  local rbenv_path=`rbenv root`

  local rubies=`ls $rbenv_path/versions`

  for ruby in $rubies; do
    if RBENV_VERSION=$ruby gem list -i djin; then
      echo '---------------------------------------'
      echo "Uninstalling djin from Ruby $ruby"
      RBENV_VERSION=$ruby uninstall_djin
    fi
  done
}

function uninstall_djin() {
  info "Uninstalling older djin gems"
  maybe_sudo $_GEM_PATH uninstall -ax djin
}
function install_djin() {
  info 'Installing djin 0.11.4...'
  maybe_sudo $_GEM_PATH install djin -v 0.11.4
  info 'Ok'
}

function create_symlink() {
  info "Creating a symbolic link in $_DJIN_BIN_PATH"
  local gem_path=`which djin`
  ln -s $gem_path $_DJIN_BIN_PATH
  info 'Ok'
}

verify_ruby_installation

if gem list -i djin; then
  uninstall_djin_rbenv
  uninstall_djin
fi

install_djin

#create_symlink
