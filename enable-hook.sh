#!/bin/bash

function printMessage() {
  echo -e "\033[90m$1\033[0m"
}

mix git_hooks.install && printMessage "Hooks enabled!"