#!/bin/bash

set -e

_DJIN_BIN_PATH=/usr/local/bin/djin
_GEM_PATH=$(command -v gem)

function info() {
  >&2 echo "$1"
}

function verify_ruby_installation() {
  print_separator
  info 'Verifying Ruby Instalation...'
  (command_exist ruby) || (info "Missing Ruby installation, read https://www.ruby-lang.org/en/documentation/installation/ for instructions" && exit 1)
  info 'Ok'
  print_separator
}

function maybe_sudo() {
  "$@" || info 'Trying with sudo' && sudo "$@"
}

function uninstall_djin_rbenv {
  local rbenv_path
  local rubies

  rbenv_path=$(rbenv root)
  rubies=$(ls "$rbenv_path/versions")

  for ruby in $rubies; do
    if RBENV_VERSION=$ruby gem_is_installed; then
      print_separator
      echo "Uninstalling djin from Ruby $ruby"
      RBENV_VERSION=$ruby uninstall_djin
      print_separator
    fi
  done
}

function uninstall_djin() {
  info "Uninstalling older djin gems"
  maybe_sudo "$_GEM_PATH" uninstall -ax djin
}
function install_djin() {
  print_separator
  info 'Installing djin 0.11.6...'
  maybe_sudo "$_GEM_PATH" install djin -v 0.11.6
  info 'Ok'
  print_separator
}

function create_symlink() {
  print_separator
  info "Creating a symbolic link in $_DJIN_BIN_PATH"
  local gem_path

  gem_path=$(command -v djin)

  ln -s "$gem_path" $_DJIN_BIN_PATH
  info 'Ok'
  print_separator
}

function command_exist() {
  command -v "$1" &> /dev/null
}

function gem_is_installed() {
  gem list -i djin &> /dev/null
}

function print_separator() {
  echo '---------------------------------------'
}

verify_ruby_installation

# TODO: Warn if djin is installed with a alias
if gem_is_installed; then
  (command_exist rbenv) && uninstall_djin_rbenv
  # TODO: Add rvm uninstaller
  # TODO: Add asdf uninstaller
  uninstall_djin
fi

install_djin

[ ! -f $_DJIN_BIN_PATH ] && create_symlink
