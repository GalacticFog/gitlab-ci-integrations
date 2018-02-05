exit_with_error() {
  echo "[Error] $@"
  exit 1
}

exit_on_error() {
  if [ $? -ne 0 ]; then
    exit_with_error $1
  fi
}

check_for_required_environment_variables() {
  retval=0

  for e in $@; do
    if [ -z "${!e}" ]; then
      echo "Required environment variable \"$e\" not defined."
      retval=1
    fi
  done

  if [ $retval -ne 0 ]; then
    echo "One or more required environment variables not defined, aborting."
    exit 1
  else
    echo "All required environment variables found."
  fi
}

check_for_required_tools() {
  retval=0

  for t in $@; do
    which $t > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        retval=1
        echo "'$t' not found"
    fi
  done

  if [ $retval -ne 0 ]; then
    echo "One or more required tools not defined, aborting."
    exit 1
  else
    echo "All required tools found."
  fi
}
