#!/bin/sh

set -eu
set -o pipefail

create_keys() {
  mkdir -p ./.ssh
  ssh-keygen -t rsa -b 4096 -f ./.ssh/key
}

terraform_apply() {
  local public_key
  public_key="$(cat ./.ssh/key.pub)"
  terraform init
  terraform apply -var "public_key=${public_key}"
}

run_up() {
  create_keys
  terraform_apply
}

terraform_destroy() {
  local public_key
  public_key="$(cat ./.ssh/key.pub)"
  terraform destroy -var "public_key=${public_key}"
}

rm_keys() {
  rm -rf ./.ssh
}

run_down() {
  terraform_destroy
  rm_keys
}

run_connect() {
  ssh -i ./.ssh/key ubuntu@$(terraform output ip_address)
}

usage() {
  local prog="$0"
  cat <<EOF
usage: ${prog} up
       ${prog} connect
       ${prog} down
       ${prog} help
EOF
}

main() {
  if [[ "$#" != "1" ]]; then
    echo "Err: Must specify a command" >&2
    usage
    exit 1
  fi

  case "$1" in
    up) run_up ;;
    down) run_down ;;
    connect) run_connect ;;
    help|-h|--help) usage ;;
    *)
      echo "Err: Unknown command $1" >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"

