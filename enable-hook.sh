#!/bin/bash

function printMessage() {
  echo -e "\033[90m$1\033[0m"
}

git config core.hooksPath .github/hooks && printMessage "Hooks enabled!"