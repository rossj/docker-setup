#!/bin/bash -e
# Usage:
#   Build all, caching from current version, and tagging current version: ./build.sh
#   Build one, caching from current version, and tagging current version: ./build.sh image
#   Build one, caching from specified version, and tagging current version: ./build.sh --CACHE_TAG=1.0.0 image

# Load version variables
set -a
source VERSION.env
set +a

TAG="$CURR"
CACHE_TAG="$CURR"
CACHE_FROM=true
PULL=false
extra_args=()

lb () {
  printf '################################################################################\n'
}

handle_option () {
  case "$1" in
    --pull)          PULL=true
                     ;;
    --no-cache-from) CACHE_FROM=false
                     ;;
    --tag=*)         TAG=${1#--tag=}
                     ;;
    --cache-tag=*)   CACHE_TAG=${1#--cache-tag=}
                     ;;
  esac
}

get_cache () {
  if [ "$CACHE_FROM" = true ]; then
    # Default to whatever TAG is set to
    if [ -n "$CACHE_TAG" ]; then
      echo "${1}:${CACHE_TAG}"
    else
      echo "${1}:${TAG}"
    fi
  else
    echo ''
  fi
}

docker_build () {
  local cache="$1"
  shift
  local name="$1"
  shift

  printf '\n'
  lb
  printf "# Building ${name}"
  if [ -n "$cache" ]; then
    printf " cached from ${cache}\n"
  else
    printf " from default cache\n"
  fi
  lb
  docker build --cache-from "$cache" -t "$name" "$@"
  lb
  printf "# Done building ${name}\n"
  lb
}

# Arguments are image, cache
build_image () {
  local name="${1}:${TAG}"
  local cache=$(get_cache "$1")

  case "$1" in
    local/yarn)
      # Always build latest and use local build cache, since not pushed / pulled
      docker_build "" "$1" "${extra_args[@]}" yarn
      ;;
    local/base)
      # This image needs to be named without a tag, since we can't dynamically
      # change the FROM of derived images
      docker_build "$cache" "$1" "${extra_args[@]}" base
      ;;
    local/node-image)
      # Don't send extra_args, because this is FROM a local image, makes no sense to pull first
      docker_build "$cache" "$name" node-image
      ;;
    local/image2)
      build_image local/base

      # Don't send extra_args, because this is FROM a local image, makes no sense to pull first
      docker_build "$cache" "$name" image2
      ;;
    local/image3)
      # Not FROM a local image
      docker_build "$cache" "$name" image3
      ;;
    local/node-image.test)
      # Always use default cache for this -- not pushed / pulled from repo
      docker_build "" "$name" "${extra_args[@]}" -f stanford-ner/Dockerfile.test stanford-ner
      ;;
    *)
      printf "Unknown image to build: ${1}\n"
      exit 1
      ;;
  esac
}

printf "Build: VERSION is $VERSION\n"

# Handle any args before the project name
while true; do
  if [[ $1 == -* ]]; then
    handle_option "$1"
    shift
  else
    break
  fi
done

# Set extra args if pull is set
if [ "$PULL" = true ]; then
  extra_args+=('--pull')
fi

# If there are any args, assume we are building just 1 image
if [ -n "$1" ]; then
  build_image "local/${1}"
else
  # What to build in the "build all" scenario
  declare -a images=(
    'node-image'
    'image2'
    'image3'
  )

  # Loop through the above array
  for i in "${images[@]}"; do
    build_image "local/${i}"
  done
fi
