# Set defaults
application_name=svg-to-ppt
application_directory=~/$application_name
output_directory=$application_directory/Output
ppt_template=template.ppt
template_ppt_filepath=$application_directory/$ppt_template
application_config_file_filepath=~/.$application_name
stop_creations=false

# Text options
txtund=$(tput sgr 0 1) # Underline
txtbld=$(tput bold)    # Bold
txtrst=$(tput sgr0)    # Reset
red=$(tput setaf 1)
yellow=$(tput setaf 3)
green=$(tput setaf 2)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)
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

# Emojis

brew="🍺"
checkmark="✅"
dir="📁"
exclamation="❗️"
libre="📄"
svg="🖌 "
swirl="🌀"
warning="⚠️ "
x_mark="❌"

# Helper function
echo_bold() {
  echo -e "\033[1m$1\033[0m"
  tput sgr0
}

echo_success() {
  echo $green"$checkmark $1 successfully$txtrst"
}

echo_already_exists() {
  echo $yellow"$warning Skipping $1 of $2 as it already exists: $bldwht$3$txtrst"
}

echo_already_installed() {
  echo $blue"$swirl Skipping installation of $1 as it's already installed: $2$txtrst"
}

echo_failed() {
  echo $bldred"$x_mark Failed to $1$txtrst"
}

echo_error() {
  echo $bldred"$exclamation Error $1$txtrst"
}

echo_debug() {
  printf $bldcyn"0 for $1, 1 for $2: "$txtrst
}

echo_var() {
  eval 'printf "%s\n" "$1: ${'"$1"'}"'
}

debug() { return "$1"; }

# Main

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

# Creates a directory to keep application files
create_application_directory() {
  if [ -d $application_directory ]; then
    local found=true
  else
    local found=false
  fi

  local breakpoint=false
  if [ "$breakpoint" == true ]; then
    echo_var found
    echo_debug "application directory not found" "found"
    read input
    case $input in
      "0") local found=false ;;
      "1") local found=true ;;
    esac
  fi

  if [ "$found" == true ]; then
    echo_already_exists "creation" "application directory" $application_directory
  else
    echo "$dir Creating directory: $application_directory"
    if [ "$stop_creations" != true ]; then
      mkdir $application_directory
    fi

    if [[ $? -eq 1 ]]; then
      echo_failed "create application directory: $bldwht$application_directory"
      exit 1
    else
      echo_success "Application directory created"
    fi
  fi
}

# Creates a directory where PPT files will be output
create_output_directory() {
  if [ -d $output_directory ]; then
    local found=true
  else
    local found=false
  fi

  local breakpoint=false
  if [ "$breakpoint" == true ]; then
    echo_var found
    echo_debug "output directory not found" "found"
    read input
    case $input in
      "0") local found=false ;;
      "1") local found=true ;;
    esac
  fi

  if [ "$found" == true ]; then
    echo_already_exists "creation" "output directory" $output_directory
  else
    echo "$dir Creating directory: $output_directory"
    mkdir $output_directory

    if [[ $? -eq 1 ]]; then
      echo_failed "create output directory: $bldwht$application_directory"
      exit 1
    else
      echo_success "Output directory created"
    fi
  fi
}

# Fetches a template PPT from GitHub
fetch_template_ppt() {
  local breakpoint=false

  if test -f $template_ppt_filepath; then
    echo_already_exists "fetch" "template PPT" $template_ppt_filepath
  else
    IFS="$ppt_template" read -r template_ppt_directory string <<< "$template_ppt_filepath"

    local wget_location=$(command -v wget)

    if [ -z $wget_location ]; then
      wget_install_cmd="brew install wget"
      echo "Starting wget installation: $(tput sgr 0 1)$wget_install_cmd$txtrst"
      eval $wget_install_cmd

      if [[ $? -eq 1 ]]; then
        echo_error "installing wget with Homebrew"
        exit 1
      else
        echo_success "wget installed"
      fi
    else
      echo_already_installed "wget" $wget_location
    fi

    echo "Pulling down template PPT from GitHub: $template_ppt_filepath"
    /usr/local/bin/wget https://github.com/blakegearin/svg-to-keynote/raw/main/template.ppt -P $template_ppt_directory

    if [[ $? -eq 1 ]]; then
      echo_failed "pull down template.ppt file from GitHub"
      exit 1
    else
      echo "$(tput setaf 2)Template PPT created: $template_ppt_filepath"
    fi
  fi
}

# Creates a config file
create_application_config_file() {
  local breakpoint=false

  if test -f $application_config_file_filepath; then
    echo_already_exists "creation" "application config file" $application_config_file_filepath
  else
    touch $application_config_file_filepath

    if [[ $? -eq 1 ]]; then
      echo_error "creating application config file"
      exit 1
    else
      echo_success "Application config file created"
    fi
  fi
}

install_basic() {
  if [ "$1" == true ]; then
    echo "$svg Starting basic installation of SVG to PPT"
  fi

  create_application_directory
  create_output_directory
  fetch_template_ppt
  create_application_config_file

  echo
  echo_success $txtbld"SVG to PPT installed"
}

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
  libre_office_location=$(whichapp "LibreOffice")

  local breakpoint=false
  if [ "$breakpoint" == true ]; then
    echo_var libre_office_location
    echo_debug "Libre Office not found" "found"
    read input
    case $input in
      "0") libre_office_location= ;;
      "1") libre_office_location=true ;;
    esac
  fi

  if [[ -z "$libre_office_location" ]]; then
    return 0
  else
    echo_already_installed "Libre Office" $libre_office_location
    return 1
  fi
}

# Checks if Homebrew is installed
# Returns 0 for not found, 1 for found
check_homebrew_installed() {
  local homebrew_location=$(command -v brew)

  local breakpoint=false
  if [ "$breakpoint" == true ]; then
    echo_var homebrew_location
    echo_debug "Homebrew not found" "found"
    read input
    case $input in
      "0") homebrew_location= ;;
      "1") homebrew_location=true ;;
    esac
  fi

  if [ -z $homebrew_location ]; then
    return 0
  else
    echo_already_installed "Homebrew" $homebrew_location
    return 1
  fi
}

# Installs Homebrew and checks for success
install_homebrew() {
  local breakpoint=false

  homebrew_install_cmd='/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  echo "$brew Starting Homebrew installation: $txtund$homebrew_install_cmd$txtrst"

  if [ "$stop_creations" != true ]; then
    eval $homebrew_install_cmd
  fi
  local exit_code=$?

  local breakpoint=false
  if [ "$breakpoint" == true ]; then
    echo_var exit_code
    echo_debug "Homebrew install succeeded" "failed"
    read input
    case $input in
      "0") exit_code=0 ;;
      "1") exit_code=1 ;;
    esac
  fi

  if [[ $exit_code -ne 0 ]]; then
    echo_error "installing Homebrew"
    exit 1
  else
    echo_success "Homebrew installed"
  fi
}

# Installs Libre Office and checks for success
install_libre_office() {
  libre_office_install_cmd="brew install --cask libreoffice"
  echo "$libre Starting Libre Office installation: $txtund$libre_office_install_cmd$txtrst"

  if [ "$stop_creations" != true ]; then
    eval $libre_office_install_cmd
  fi
  local exit_code=$?

  local breakpoint=true
  if [ "$breakpoint" == true ]; then
    echo_var exit_code
    echo_debug "Homebrew install succeeded" "failed"
    read input
    case $input in
      "0") exit_code=0 ;;
      "1") exit_code=1 ;;
    esac
  fi


  if [[ $exit_code -ne 0 ]]; then
    echo_error "installing Libre Office with Homebrew"
    exit 1
  else
    echo_success "Libre Office installed"
  fi
}

# Installs Libre Office and then a basic install
install_complete() {
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
}

# Valides install_type and routes to install functions
case $install_type in
  basic) install_basic true ;;
  complete) install_complete ;;
  *)
    echo "Input error: \"$install_type\" is not a valid install type; should only be: basic, complete"
    exit 2
    ;;
esac
