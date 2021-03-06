#!/bin/bash 

CD_ARGS=()

source /lib/gentoo/functions.sh

cd_parse_arguments() {

  while (( ${#1} )); do
    case ${1} in
      *-cd-help)
      CD_HELP=1
      ;;
      *-cd-debug)
      CD_DEBUG=1
      ;;
      *-cd-quiet)
      CD_QUIET=1
      ;;
      *-cd-host)
      shift; CD_HOST="${1}"
      ;;
      *-cd-host=*)
      CD_HOST="${1#*=}"
      ;;
      *-cd-target)
      shift; CD_TARGET="${1}"
      ;;
      *-cd-target=*)
      CD_TARGET="${1#*=}"
      ;;
      *-cd-tmp-dir)
      shift; CD_TMP_DIR="${1}"
      ;;
      *-cd-tmp-dir=*)
      CD_TMP_DIR="${1#*=}"
      ;;
      *-cd-host-dir)
      shift; CD_HOST_DIR="${1}"
      ;;
      *-cd-host-dir=*)
      CD_HOST_DIR="${1#*=}"
      ;;
      *-cd-target-dir)
      shift; CD_TARGET_DIR="${1}"
      ;;
      *-cd-target-dir=*)
      CD_TARGET_DIR="${1#*=}"
      ;;
      *-cd-config-dir)
      shift; CD_CONFIG_DIR="${1}"
      ;;
      *-cd-config-dir=*)
      CD_CONFIG_DIR="${1#*=}"
      ;;
      *-cd-prefix-dir)
      shift; CD_PREFIX_DIR="${1}"
      ;;
      *-cd-prefix-dir=*)
      CD_PREFIX_DIR="${1#*=}"
      ;;
      -h|-help|--help)
      einfo "Use --cd-help to get more options"
      ;;
      --)
      while (( ${#@} )); do
        CD_ARGS+=(${1})
        shift
      done
      break
      ;;
      *)
      CD_ARGS+=(${1})
      ;;
    esac
    shift
  done

  if [ -z "${CD_HOST}" ]; then
    CD_HOST=$(gcc -dumpmachine)
  fi

  if [ -z "${CD_TARGET}" ]; then
    eerror "No target specified, use --cd-target"
    CD_HELP=1
  fi

  if [ -z "${CD_HELP}" ]; then
    if [ -z "${CD_DEBUG}" ]; then
      CD_NODEBUG=" "
    fi
    if [ ! -z "${CD_QUIET}" ]; then
      export EINFO_QUIET=1
    fi
    if [ -z "${CD_TMP_DIR}" ]; then
      CD_TMP_DIR="${CD_PREFIX_DIR}/var/tmp"
      #ewarn "No temp dir specified, using: ${CD_TMP_DIR}"
    fi
    if [ -z "${CD_PREFIX_DIR}" ]; then
      CD_PREFIX_DIR=""
      #ewarn "No temp dir specified, using: ${CD_PREFIX_DIR}"
    fi
    if [ -z "${CD_CONFIG_DIR}" ]; then
      CD_CONFIG_DIR="${CD_PREFIX_DIR}/etc/crossdev"
      #ewarn "No config dir specified, using: ${CD_CONFIG_DIR}"
    fi
    if [ -z "${CD_HOST_DIR}" ]; then
      CD_HOST_DIR="/"
      #ewarn "No host dir specified, using: ${CD_HOST_DIR}"
    fi
    if [ "${CD_TARGET}" = "${CD_HOST}" ]; then
      if [ -z "${CD_TARGET_DIR}" ]; then
        CD_TARGET_DIR="/"
        #ewarn "No target dir specified, using: ${CD_TARGET_DIR}"
      fi
    else
      if [ -z "${CD_TARGET_DIR}" ]; then
        CD_TARGET_DIR="${CD_PREFIX_DIR}/usr/${CD_TARGET}"
        #ewarn "No target dir specified, using: ${CD_TARGET_DIR}"
      fi
    fi
  fi

  export CD_HOST CD_TARGET CD_TMP_DIR CD_PREFIX_DIR CD_HOST_DIR CD_TARGET_DIR CD_CONFIG_DIR CD_DEBUG

}

cd_print_usage_header() {
  echo "usage: ${CD_SCRIPT_FILE} ..."
  echo "--cd-help (This help)"
  echo "--cd-debug (Verbose output)"
  echo "--cd-host \"<host triplet>\" (Host triplet) (${CD_HOST-"required"})"
  echo "--cd-target \"<target triplet>\" (Target triplet) (${CD_TARGET-"required"})"
  echo "--cd-prefix-dir \"<prefix dir>\" (Prefix dir) (${CD_PREFIX_DIR:-"<empty>"})"
  echo "--cd-config-dir \"<config dir>\" (Config dir) (${CD_CONFIG_DIR:-"${CD_PREFIX_DIR}/etc/crossdev"})"
  echo "--cd-target-dir \"<target dir>\" (Target dir) (${CD_TARGET_DIR:-"${CD_PREFIX_DIR}/usr/<target>"})"
  echo "--cd-tmp-dir \"<temp dir>\" (Temp dir) (${CD_TMP_DIR:-"${CD_PREFIX_DIR}/var/tmp"})"
}
    
cd_get_package_version_by_atom() {
  local root=${1} format=${2} atom=${3}
  qatom --root "${root:-/}" -F "${format}" $(qlist --root "${root:-/}" -Ive "${atom}" 2> /dev/null) 2> /dev/null
}

cd_get_package_version_by_path() {
  local root=${1} format=${2}
  local path=$(cd_resolve_symlink "${root}" "${3}")
  qatom --root "${root:-/}" -F "${format}" $(qfile --root "${root:-/}" -v "${path}" 2> /dev/null | cut -d' ' -f1) 2> /dev/null
}

cd_portageq() {
  local root=${1}; shift
  local result="$(ROOT="${root%+(/)}" PORTAGE_CONFIGROOT="${root%+(/)}" portageq "${@}" 2> /dev/null)"
  result="${result#${CD_TARGET_DIR%+(/)}}"
  result="${result#${root%+(/)}}"
  echo "${result}"
}

cd_die() {
  local exit_code=$?
  if [ ! -z "${1}" ]; then
    eerror "${BASH_SOURCE[1]}@${BASH_LINENO[0]}: ${1}"
  else
    eend ${exit_code}
  fi
  exit 1
}

cd_resolve_symlink() {
  local result=''
  local root=${1%/} path=${2}
  path="${root}/${path}"
  while [[ -L "${path}" ]]; do
    local target="$(readlink "${path}")"
    case "${target}" in
      /*) path="${root}/${target}" ;;
      *) path="$(dirname "${path}")/${target}" ;;
    esac
  done; 
  if [ -e "${path}" ]; then
    result="$(realpath "${path}")"
  else
    result="${path}"
  fi
  echo ${result#"${root}"}
}

cd_is_mount_of_type() {
  local path=$(readlink -f ${1} 2> /dev/null)
  local type=${2}
  findmnt "${path}" | tail -1 | grep -q "${type}"
}

cd_is_mount() {
  local path=$(readlink -f ${1} 2> /dev/null)
  mountpoint -q "${path}"
}

CD_SCRIPT_FILE=$(basename "$(readlink -e "${BASH_SOURCE[1]}")")
CD_SCRIPT_DIR=$(dirname "$(readlink -e "${BASH_SOURCE[1]}")")

if [ -z "${CD_ORG_PATH}" ]; then
  export CD_ORG_PATH="${PATH}"
fi

export CD_SCRIPT_DIR CD_SCRIPT_FILE
