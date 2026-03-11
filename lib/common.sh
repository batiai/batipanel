#!/usr/bin/env bash
# batipanel common - module loader
# Sources all modules in dependency order. This is the single entry point
# for all scripts that need batipanel functions.

set -euo pipefail

BATIPANEL_HOME="${BATIPANEL_HOME:-$HOME/.batipanel}"
_BATIPANEL_LIB="$BATIPANEL_HOME/lib"

# shellcheck source=lib/core.sh
source "$_BATIPANEL_LIB/core.sh"
# shellcheck source=lib/validate.sh
source "$_BATIPANEL_LIB/validate.sh"
# shellcheck source=lib/layout.sh
source "$_BATIPANEL_LIB/layout.sh"
# shellcheck source=lib/session.sh
source "$_BATIPANEL_LIB/session.sh"
# shellcheck source=lib/project.sh
source "$_BATIPANEL_LIB/project.sh"
# shellcheck source=lib/doctor.sh
source "$_BATIPANEL_LIB/doctor.sh"
# shellcheck source=lib/wizard.sh
source "$_BATIPANEL_LIB/wizard.sh"
# shellcheck source=lib/server-docker.sh
source "$_BATIPANEL_LIB/server-docker.sh"
# shellcheck source=lib/server.sh
source "$_BATIPANEL_LIB/server.sh"
# shellcheck source=lib/server-init.sh
source "$_BATIPANEL_LIB/server-init.sh"
# shellcheck source=lib/themes.sh
source "$_BATIPANEL_LIB/themes.sh"
