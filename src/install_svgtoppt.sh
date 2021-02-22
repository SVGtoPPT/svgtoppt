# APPLICATION DEFAULTS
application_name=svg-to-ppt
application_directory=~/$application_name
output_directory=$application_directory/Output
template_ppt=template.ppt
template_ppt_filepath=$application_directory/$template_ppt
bash_script=svgtoppt
bash_script_filepath=/usr/local/bin/$bash_script
application_config_file_filepath=~/.$application_name
stop_creations=false

# TEXT FORMATS
txtund=$(tput sgr 0 1) # Underline
txtbld=$(tput bold)    # Bold
txtrst=$(tput sgr0)    # Reset

# TEXT COLORS
red=$(tput setaf 1)
yellow=$(tput setaf 3)
green=$(tput setaf 2)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)

# TEXT COMBINATIONS
bldred=${txtbld}$red
bldblu=${txtbld}$blue
bldwht=${txtbld}$white
bldcyn=${txtbld}$cyan

print_text_options() {
  echo -e "$(tput bold) reg  bld  und   tput-command-colors$(tput sgr0)"

  for i in $(seq 1 7); do
    echo " $(tput setaf $i)Text$(tput sgr0) $(tput bold)$(tput setaf $i)Text$(tput sgr0) $(tput sgr 0 1)$(tput setaf $i)Text$(tput sgr0)  \$(tput setaf $i)"
  done

  echo ' Bold            $(tput bold)'
  echo ' Underline       $(tput sgr 0 1)'
  printf ' Reset           $(tput sgr0)\n\n'
}
# print_text_options

# EMOJIS
brew="🍺"
checkmark="✅"
dir="📁"
exclamation="❗️"
libre="📄"
octo="🐙"
svg="🖌 "
swirl="🌀"
warning="⚠️ "
x_mark="❌"

# HELPER FUNCTIONS
echo_bold() {
  echo -e "\033[1m$1\033[0m"
  tput sgr0
}

echo_success() {
  echo $green"$checkmark $1 successfully$txtrst"
}

echo_already_exists() {
  echo $yellow"$warning Warning: Skipped $1 of $2 as it already exists: $bldwht$3$txtrst"
}

echo_already_installed() {
  echo $blue"$swirl Warning: Skipped installation of $1 as it's already installed: $2$txtrst"
}

echo_failed() {
  echo $bldred"$x_mark Failure: Couldn't $1$txtrst"
}

echo_error() {
  echo $bldred"$exclamation Error $1$txtrst"
}

echo_debug() {
  printf $bldcyn"0 for $1, 1 for $2, or 2 to exit: "$txtrst
}

echo_var() {
  eval 'printf $bldcyn"Variable:$txtrst "%s"\n" "$1=\"${'"$1"'}\""'
}

echo_breakpoint() {
  var_name=$1
  echo_var $var_name

  echo_debug "$2 not $3" "$3"
  local input
  read input

  case $input in
    "0") eval "$var_name"="$4" ;;
    "1") eval "$var_name"="$5" ;;
    "2") exit 1 ;;
  esac
}

output_code() { return "$1"; }

# Creates directories and files necessary for the application to run
install_basic() (
  # Checks if a directory exists
  # Returns 0 for not found, 1 for found
  check_directory_missing() {
    if [ -d $1 ]; then
      local found=1
    else
      local found=0
    fi

    # echo_breakpoint found "$2" "found" 0 1

    return $found
  }

  # Creates a directory
  create_directory() {
    echo "$dir Creating directory: $1"
    if [ "$stop_creations" != true ]; then
      mkdir $1
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$2" "created" false true

    if [[ $? -eq 1 ]]; then
      echo_failed "create $2: $bldwht$1"
      exit 1
    else
      echo_success "${2^} created"
    fi
  }

  # Checks if wget is installed
  # Returns 0 for not found, 1 for found
  check_wget_installed() {
    local wget_location=$(command -v wget)

    # echo_breakpoint wget_location "wget" "found" "" 1

    if [ -z $wget_location ]; then
      return 0
    else
      echo_already_installed "wget" $wget_location
      return 1
    fi
  }

  # Installs wget
  install_wget() {
    local wget_install_cmd="brew install wget"
    echo "Starting wget installation: $(tput sgr 0 1)$wget_install_cmd$txtrst"

    if [ "$stop_creations" != true ]; then
      eval $wget_install_cmd
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "wget" "install" false true

    if [[ $exit_code -eq 0 ]]; then
      echo_error "installing wget with Homebrew"
      exit 1
    else
      echo_success "wget installed"
    fi
  }

  # Checks if a file exists
  # Returns 0 for not found, 1 for found
  check_file_missing() {
    if test -f $1; then
      local found=1
    else
      local found=0
    fi

    # echo_breakpoint found "$2" "found" 0 1

    return $found
  }

  # Fetches a remote file
  fetch_remote_file() {
    echo "$octo Pulling down $2 from GitHub to directory: $1"

    file_parent_directory=${1%/*}
    if [ "$stop_creations" != true ]; then
      /usr/local/bin/wget -P $file_parent_directory $3
    fi
    local exit_code=$?

    # echo_breakpoint exit_code $2 "fetched" 1 0

    if [[ $exit_code -eq 1 ]]; then
      echo_failed "pull down $2 file from GitHub"
      exit 1
    else
      echo_success "${2^} created: $1"
    fi
  }

  # Creates the application configuration file
  create_application_config_file() {
    if [ "$stop_creations" != true ]; then
      touch $application_config_file_filepath
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "application config file" "created" 0 1

    if [[ $exit_code -eq 1 ]]; then
      echo_error "creating application config file"
      exit 1
    else
      echo_success "Application config file created"
    fi
  }

  if [ "$1" == true ]; then
    echo "$svg Starting basic installation of SVG to PPT"
    echo
  fi

  local description="application directory"
  check_directory_missing $application_directory "$description"
  if [[ $? -eq 0 ]]; then
    create_directory $application_directory "$description"
  else
    echo_already_exists "creation" "$description" $application_directory
  fi

  local description="output directory"
  check_directory_missing $output_directory "$description"
  if [[ $? -eq 0 ]]; then
    create_directory $output_directory "$description"
  else
    echo_already_exists "creation" "$description" $output_directory
  fi

  local description="template PPT"
  check_file_missing $template_ppt_filepath "$description"
  if [[ $? -eq 0 ]]; then
    local output_filepath=$template_ppt_filepath
    local remote_url=https://github.com/SVGtoPPT/svg-to-ppt/raw/main/src/template.ppt
    fetch_remote_file $output_filepath "$description" $remote_url
  else
    echo_already_exists "fetch" "$description" $template_ppt_filepath
  fi

  local description="Bash script file"
  check_file_missing $bash_script_filepath "$description"
  if [[ $? -eq 0 ]]; then
    local output_filepath=$bash_script_filepath
    local remote_url=https://raw.githubusercontent.com/SVGtoPPT/svg-to-ppt/main/src/svgtoppt.sh
    fetch_remote_file $output_filepath "$description" $remote_url
    mv "$bash_script_filepath.sh" $bash_script_filepath
    chmod +x $bash_script_filepath
  else
    echo_already_exists "fetch" "$description" $bash_script_filepath
  fi

  check_file_missing $application_config_file_filepath "application config file"
  if [[ $? -eq 0 ]]; then
    create_application_config_file
  else
    echo_already_exists "creation" "application config file" $application_config_file_filepath
  fi

  echo
  echo_success $txtbld"SVG to PPT installed"
)

# Installs Homebrew (if needed) and Libre Office, then executes a basic install
install_complete() (
  # Checks whether an application is installed
  # Credit: https://stackoverflow.com/a/12900116
  whichapp() {
    local appNameOrBundleId=$1 isAppName=0 bundleId
    # Determine whether an app *name* or *bundle id* was specified
    [[ $appNameOrBundleId =~ \.[aA][pP][pP]$ || $appNameOrBundleId =~ ^[^.]+$ ]] && isAppName=1
    if ((isAppName)); then # an application NAME was specified
      # Translate to a bundle id first
      bundleId=$(osascript -e "id of application \"$appNameOrBundleId\"" 2> /dev/null) ||
        {
          return 1
        }
    else # a bundle id was specified
      bundleId=$appNameOrBundleId
    fi
    # Let AppleScript determine the full bundle path
    fullPath=$(osascript -e "tell application \"Finder\" to POSIX path of (get application file id \"$bundleId\" as alias)" 2> /dev/null ||
      {
        echo "$FUNCNAME: ERROR: Application with specified bundle ID not found: $bundleId" 1>&2
        return 1
      })
    printf '%s\n' "$fullPath"
    # Warn about /Volumes/... paths, because applications launched from mounted devices aren't persistently installed
    if [[ $fullPath == /Volumes/* ]]; then
      echo "NOTE: Application is not persistently installed, due to being located on a mounted volume." >&2
    fi
  }

  # Checks if Libre Office is installed
  # Returns 0 for not found, 1 for found
  check_libre_office_installed() {
    local description="Libre Office"
    libre_office_location=$(whichapp "LibreOffice")

    # echo_breakpoint libre_office_location $description "found" "" true

    if [[ -z "$libre_office_location" ]]; then
      return 0
    else
      echo_already_installed $description $libre_office_location
      return 1
    fi
  }

  # Checks if Homebrew is installed
  # Returns 0 for not found, 1 for found
  check_homebrew_installed() {
    local description="Homebrew"
    local homebrew_location=$(command -v brew)

    # echo_breakpoint homebrew_location $description "found" "" true

    if [ -z $homebrew_location ]; then
      return 0
    else
      echo_already_installed $description $homebrew_location
      return 1
    fi
  }

  # Installs Homebrew
  install_homebrew() {
    local description="Homebrew"
    local homebrew_install_cmd='/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    echo "$brew Starting $description installation: $txtund$homebrew_install_cmd$txtrst"

    if [ "$stop_creations" != true ]; then
      eval $homebrew_install_cmd
    fi
    local exit_code=$?

    # echo_breakpoint homebrew_location $description "install" 0 1

    if [[ $exit_code -ne 0 ]]; then
      echo_error "installing $description"
      exit 1
    else
      echo_success "$description installed"
    fi
  }

  # Installs Libre Office
  install_libre_office() {
    local description="Libre Office"
    local libre_office_install_cmd="brew install --cask libreoffice"
    echo "$libre Starting $description installation: $txtund$libre_office_install_cmd$txtrst"

    if [ "$stop_creations" != true ]; then
      eval $libre_office_install_cmd
    fi
    local exit_code=$?

    # echo_breakpoint homebrew_location $description "install" 0 1

    if [[ $exit_code -ne 0 ]]; then
      echo_error "installing $description with Homebrew"
      exit 1
    else
      echo_success "$description installed"
    fi
  }

  echo_bold "$svg Starting complete installation of SVG to PPT"
  echo

  check_libre_office_installed

  if [[ $? -eq 0 ]]; then
    check_homebrew_installed

    if [[ $? -eq 0 ]]; then
      install_homebrew
    fi

    install_libre_office
  fi

  echo
  install_basic false
)

# MAIN

install_type=$1

# Check for flags overwriting defaults
while getopts "a:f:i:o:p:t:w:dx" option; do
  case "${option}" in
    a) application_directory=${OPTARG} ;;
    f) force_ppt=${OPTARG} ;;
    i) install_type=${OPTARG} ;;
    o) output_directory=${OPTARG} ;;
    p) ppt_name=${OPTARG} ;;
    t) template_ppt=${OPTARG} ;;
    w) where_to_open=${OPTARG} ;;
    d) debug=true ;;
    x) stop_creations=true ;;
  esac
done

# Valides install_type and routes to install functions
case $install_type in
  basic) install_basic true ;;
  complete) install_complete ;;
  *)
    echo "Input error: \"$install_type\" is not a valid install type; should only be: basic, complete"
    exit 2
    ;;
esac
