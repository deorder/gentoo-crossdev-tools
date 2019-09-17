#!/bin/bash 

CD_ARGS=()

source /etc/init.d/functions.sh

cd_is_mount() {
  path=$(readlink -f $1)
  grep -q "$path" /proc/mounts
}

cd_parse_arguments() {

  while (( ${#1} )); do
    case ${1} in
      --cd-help)
      CD_HELP=1
      ;;
      --cd-target)
      shift; CD_TARGET="${1}"
      ;;
      --cd-target=*)
      CD_TARGET="${1#*=}"
      ;;
      --cd-target-dir)
      shift; CD_TARGET_DIR="${1}"
      ;;
      --cd-target-dir=*)
      CD_TARGET_DIR="${1#*=}"
      ;;
      --cd-config-dir)
      shift; CD_CONFIG_DIR="${1}"
      ;;
      --cd-config-dir=*)
      CD_CONFIG_DIR="${1#*=}"
      ;;
      -h|--help)
      einfo "Use --cd-help to get more options"
      ;;
      *)
      CD_ARGS+=(${1})
      ;;
    esac
    shift
  done

  if [[ -z "${CD_TARGET}" ]]; then
    eerror "No target specified, use --cd-target"
    CD_HELP=1
  fi

  if [[ -z "${CD_HELP}" ]]; then
    if [[ -z "${CD_TARGET_DIR}" ]]; then
      CD_TARGET_DIR="/usr/${CD_TARGET}"
      #ewarn "No target dir specified, using: ${CD_TARGET_DIR}"
    fi

    if [[ -z "${CD_CONFIG_DIR}" ]]; then
      CD_CONFIG_DIR="/etc/crossdev"
      #ewarn "No config dir specified, using: ${CD_CONFIG_DIR}"
    fi
  fi

  export CD_TARGET CD_TARGET_DIR CD_CONFIG_DIR

}

cd_print_usage_header() {
  echo "usage: ${CD_SCRIPT_FILE} ..."
  echo "--cd-help (This help)"
  echo "--cd-target \"<target triplet>\" (required)"
  echo "--cd-target-dir \"<target dir>\" (${CD_TARGET_DIR:-"/usr/<target>"})"
  echo "--cd-config-dir \"<config dir>\" (${CD_CONFIG_DIR:-"/etc/crossdev"})"
}

cd_die() {
  ERROR=$?; eend ${ERROR};
  if [[ ! -z "${CD_DEBUG}" ]]; then
    eerror "Error in ${BASH_SOURCE[1]} at ${BASH_LINENO[0]}"
  fi
  exit 1
}

export CD_SCRIPT_DIR CD_SCRIPT_FILE
