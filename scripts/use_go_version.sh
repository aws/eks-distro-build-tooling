function use_go_version() {
  local -r version=$1
  local gobinaryversion=""

  if [[ $version == "1.13"* ]]; then
    gobinaryversion="1.13"
  fi
  if [[ $version == "1.14"* ]]; then
    gobinaryversion="1.14"
  fi
  if [[ $version == "1.15"* ]]; then
    gobinaryversion="1.15"
  fi

  if [[ "$gobinaryversion" == "" ]]; then
    return
  fi

  # This is the path where the specific go binary versions reside in our builder-base image
  local -r gobinarypath=/go/go${gobinaryversion}/bin
  echo "Adding $gobinarypath to PATH"
  # Adding to the beginning of PATH to allow for builds on specific version if it exists
  export PATH=${gobinarypath}:$PATH
}