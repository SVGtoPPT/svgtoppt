# APPLICATION CONFIG VALUES
version=1.0.0-alpha28
application_name=svgtoppt
application_directory=$PWD/$application_name
application_config_file=$application_name
application_config_file_filepath=~/.$application_config_file
application_preferences_file=$application_name-preferences
application_preferences_file_filepath=~/.$application_preferences_file
application_zip_file=$PWD/$application_name.zip

# BASH SCRIPT CONFIG VALUES
bash_script=svgtoppt
bash_script_filepath=/usr/local/bin/$bash_script

# LIBRE OFFICE MACRO CONFIG VALUES
libre_office_macro_template=SVGtoPPT_template.xba
application_support_directory="Application\ Support"
libre_office_macros_filepath=~/Library/$application_support_directory/LibreOffice/4/user/basic/Standard
libre_office_macro_template_filepath=$libre_office_macros_filepath/$libre_office_macro

# APPLICATION DEFAULTS
output_directory=$application_directory/Output
template_ppt=template.ppt
template_ppt_filepath=$application_directory/$template_ppt
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
bldylw=${txtbld}$yellow
bldcyn=${txtbld}$cyan
bldwht=${txtbld}$white

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
beer="🍺"
checkmark="✅"
exclamation="❗️"
file="📁"
libre="📄"
octo="🐙"
svg="🖌 "
swirl="🌀"
trash="🗑 "
warn="⚠️ "
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
  echo $yellow"$warn Warning: ${1^} already exists: $bldwht$2$txtrst"
}

echo_already_installed() {
  echo $blue"$swirl Note: Skipped installation of $1 as it's already installed: $2$txtrst"
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
  echo
  echo_var $var_name

  echo_debug "$2 not $3" "$3"
  local input
  read input

  case $input in
    "0") eval "$var_name"="$4" ;;
    "1") eval "$var_name"="$5" ;;
    "2") exit 1 ;;
  esac
  echo
}

find_path() {
  path=$(
    command -v $1 ||
      command -v /bin/$1 ||
      command -v /usr/bin/$1 ||
      command -v /usr/local/sbin/$1 ||
      command -v /usr/local/bin/$1 ||
      command -v ~/bin/$1
  )
  printf "$path"
}

bash=$(find_path bash)
brew=$(find_path brew)
cat=$(find_path cat)
curl=$(find_path curl)
find=$(find_path find)
mkdir=$(find_path mkdir)
mv=$(find_path mv)
rm=$(find_path rm)
unzip=$(find_path unzip)

# Checks whether an application is installed
# Credit: https://stackoverflow.com/a/12900116
whichapp() {
  local appNameOrBundleId=$1 isAppName=0 bundleId

  # Determine whether an app *name* or *bundle id* was specified
  [[ $appNameOrBundleId =~ \.[aA][pP][pP]$ || $appNameOrBundleId =~ ^[^.]+$ ]] && isAppName=1
  if ((isAppName)); then
    # An application NAME was specified

    # Translate to a bundle id first
    bundleId=$(osascript -e "id of application \"$appNameOrBundleId\"" 2>/dev/null) ||
      {
        return 1
      }
  else # a bundle id was specified
    bundleId=$appNameOrBundleId
  fi

  # Let AppleScript determine the full bundle path
  fullPath=$(osascript -e "tell application \"Finder\" to POSIX path of (get application file id \"$bundleId\" as alias)" 2>/dev/null ||
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

# Checks if Homebrew is installed
# Returns 0 for not found, 1 for found
check_homebrew_installed() {
  local description="Homebrew"

  if [ "$debug" == true ]; then
    echo_var brew
  fi

  if [ -z $brew ]; then
    local found=0
  else
    local found=1

    if [ "$silent" != true ]; then
      echo_already_installed "$description" $homebrew_location
    fi
  fi

  # echo_breakpoint found "$description" "found" 0 1

  return $found
}

# Checks if Libre Office is installed
# Returns 0 for not found, 1 for found
check_libre_office_installed() {
  local description="Libre Office"

  check_homebrew_installed

  if [[ $? -ne 0 ]]; then
    local brew_command="$brew info libreoffice | sed -n '3p'"

    if [ "$debug" == true ]; then
      echo_var brew_command
    fi

    IFS=' ' read -r brew_libre_office_location string <<<$(eval $brew_command)
  else
    $brew_libre_office_location=false
  fi

  libre_office_location=$(whichapp "LibreOffice" || printf $brew_libre_office_location)

  if [ "$debug" == true ]; then
    echo_var libre_office_location
  fi

  if [[ -z "$libre_office_location" ]]; then
    local found=0
  else
    local found=1

    if [ "$silent" != true ]; then
      echo_already_installed "$description" $libre_office_location
    fi
  fi

  # echo_breakpoint found "$description" "found" 0 1

  return $found
}

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

  # Checks if the application directory already exists
  validate_application_directory_missing() {
    local description="application directory"

    check_directory_missing $application_directory "$description"
    exit_code=$?

    # echo_breakpoint exit_code "$description" "found" 0 1

    if [[ $exit_code -eq 1 ]]; then
      if [ "$reinstall" != true ]; then
        echo_already_exists "$description" $application_directory
        printf $bldylw"0 to DELETE & RE-CREATE it$txtrst or "$bldred"1 to EXIT$txtrst: "

        local input
        read input

        case $input in
          "0") echo "$trash Moving forward with delete & re-creation of $description" ;;
          "1") exit 1 ;;
        esac
        echo
      fi

      if [ "$stop_creations" != true ]; then
        local remove_directory="$rm -rf $application_directory"

        if [ "$debug" == true ]; then
          echo_var remove_directory
        fi

        eval $remove_directory

        if [[ $? -ne 0 ]]; then
          echo_error "deleting $description" $application_directory
          exit 1
        fi
      fi
    fi
  }

  # Checks if a file doesn't exist
  # Returns 0 for not found, 1 for found
  check_file_missing() {
    if test -f $1; then
      local found=1
    else
      local found=0
    fi

    # echo_breakpoint found $1 "found" 0 1

    return $found
  }

  # Checks whether the application Bash script already exists
  validate_bash_script_missing() {
    local description="Bash script"

    check_file_missing $bash_script_filepath
    exit_code=$?

    # echo_breakpoint exit_code "$description" "found" 0 1

    if [[ $exit_code -ne 0 ]]; then
      if [ "$reinstall" != true ]; then
        echo_already_exists "$description" $bash_script_filepath
        printf $bldylw"0 to DELETE & RE-CREATE it$txtrst or "$bldred"1 to EXIT$txtrst: "

        local input
        read input
        case $input in
          "0") echo "$trash Moving forward with delete & re-creation of $description" ;;
          "1") exit 1 ;;
        esac
        echo
      fi

      if [ "$stop_creations" != true ]; then
        local remove_directory="$rm $bash_script_filepath"

        if [ "$debug" == true ]; then
          echo_var remove_directory
        fi

        eval $remove_directory

        if [[ $? -ne 0 ]]; then
          echo_error "deleting $description" $bash_script_filepath
          exit 1
        fi
      fi
    fi
  }

  # Checks whether the Libre Office macro template already exists
  validate_libre_office_macro_template_missing() {
    local description="Libre Office macro"

    local description="Libre Office macro"

    check_file_missing $libre_office_macro_template_filepath
    exit_code=$?

    # echo_breakpoint exit_code "$description" "found" 0 1

    if [[ $exit_code -ne 0 ]]; then
      if [ "$reinstall" != true ]; then
        echo_already_exists "$description" $libre_office_macro_template_filepath
        printf $bldylw"0 to DELETE & RE-CREATE it$txtrst or "$bldred"1 to EXIT$txtrst: "

        local input
        read input
        case $input in
          "0") echo "$trash Moving forward with delete & re-creation of $description" ;;
          "1") exit 1 ;;
        esac
        echo
      fi

      if [ "$stop_creations" != true ]; then
        local remove_file="$rm $libre_office_macro_template_filepath"

        if [ "$debug" == true ]; then
          echo_var remove_file
        fi

        eval $remove_file

        if [[ $? -ne 0 ]]; then
          echo_error "deleting $description" $libre_office_macro_template_filepath
          exit 1
        fi
      fi
    fi
  }

  # Fetches the application zip by version from GitHub
  fetch_application_zip() {
    local description="application zip"

    if [ "$silent" != true ]; then
      echo "$octo Fetching $description from GitHub"
    fi

    if [ "$stop_creations" != true ]; then
      remote_url="https://github.com/SVGtoPPT/svgtoppt/archive/$version.zip"

      if [ "$debug" == true ]; then
        echo_var unzip
      fi

      local create_directory="$curl -L $remote_url > \"$application_zip_file\""
      if [ "$debug" == true ]; then
        echo_var create_directory
      fi
      eval $create_directory
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "created" 1 0

    if [[ $exit_code -eq 0 ]]; then
      if [ "$silent" != true ]; then
        echo_success "${description^} created"
      fi
    else
      echo_failed "create $description: $bldwht$application_directory"
      exit 1
    fi
  }

  # Unzips the application zip to create application directory
  unzip_application_zip() {
    local description="application zip"

    if [ "$silent" != true ]; then
      echo "$file Unzipping $description"
    fi

    local unzip_directory="$unzip \"$application_zip_file\""
    if [ "$debug" == true ]; then
      echo_var unzip_directory
    fi

    if [ "$stop_creations" != true ]; then
      eval $unzip_directory
    fi

    # echo_breakpoint exit_code "$description" "unzipped" 1 0

    if [[ $exit_code -eq 0 ]]; then
      if [ "$silent" != true ]; then
        echo_success "${description^} unzipped"
      fi
    else
      echo_failed "unzip $description: $bldwht$application_zip_file"
      exit 1
    fi
  }

  # Removes the application zip file
  remove_application_zip() {
    local description="application zip"

    if [ "$silent" != true ]; then
      echo "$trash Removing $description"
    fi

    local remove_zip="$rm \"$application_zip_file\""
    if [ "$debug" == true ]; then
      echo_var remove_zip
    fi

    if [ "$stop_creations" != true ]; then
      eval $remove_zip
    fi

    # echo_breakpoint exit_code "$description" "removed" 1 0

    if [[ $exit_code -eq 0 ]]; then
      if [ "$silent" != true ]; then
        echo_success "${description^} removed"
      fi
    else
      echo_failed "remove $description"
      exit 1
    fi
  }

  # Moves files from $application_directory/src to $application_directory
  move_src_files() {
    local description="src files"

    if [ "$silent" != true ]; then
      echo "$file Moving $description"
    fi

    local move_files="$mv \"$application_directory/src/*\" \"$application_directory\""
    if [ "$debug" == true ]; then
      echo_var move_files
    fi

    if [ "$stop_creations" != true ]; then
      eval $move_files
    fi

    # echo_breakpoint exit_code "$description" "moved" 1 0

    if [[ $exit_code -eq 0 ]]; then
      if [ "$silent" != true ]; then
        echo_success "${description^} moved"
      fi
    else
      echo_failed "move $description"
      exit 1
    fi
  }

  # Creates an "Output" directory under $application_directory
  create_output_directory() {
    local description="output directory"

    if [ "$silent" != true ]; then
      echo "$file Creating $description"
    fi

    local create_directory="$mkdir $output_directory"
    if [ "$debug" == true ]; then
      echo_var create_directory
    fi

    if [ "$stop_creations" != true ]; then
      eval $create_directory
    fi

    # echo_breakpoint exit_code "$description" "created" 1 0

    if [[ $exit_code -eq 0 ]]; then
      if [ "$silent" != true ]; then
        echo_success "${description^} created"
      fi
    else
      echo_failed "create $description"
      exit 1
    fi
  }

  # Moves the application's Bash script to the appropriate location
  move_bash_script() {
    local description="Bash script"

    if [ "$stop_creations" != true ]; then
      local move="$mv \"$application_directory/$bash_script.sh\" \"$bash_script_filepath\""

      if [ "$debug" == true ]; then
        echo_var move
      fi

      eval $move
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "moved" 1 0

    if [[ $exit_code -eq 0 ]] && [ "$silent" != true ]; then
      echo_success "${description^} moved"
    else
      echo_failed "move $description"
      exit 1
    fi
  }

  # Modifies the access of the application Bash script to run for all users
  update_bash_script_access() {
    local description="access to Bash script"

    if [ "$stop_creations" != true ]; then
      loval modify="chmod +x $bash_script_filepath"

      if [ "$debug" == true ]; then
        echo_var modify
      fi

      eval $modify
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "changed" 1 0

    if [[ $exit_code -eq 0 ]] && [ "$silent" != true ]; then
      echo_success "${description^} updated"
    else
      echo_failed "change $description"
      exit 1
    fi
  }

  # Moves the Libre Office macro template file into Libre Office's file structure
  move_libre_office_macro_template() {
    local description="Libre Office macro"

    if [ "$stop_creations" != true ]; then
      local source="$application_directory/$libre_office_macro_template"
      local target=$libre_office_macro_template_filepath
      local move="$mv \"$source\" \"$target\""

      if [ "$debug" == true ]; then
        echo_var move
      fi

      eval $move
    fi
    exit_code=$?

    # echo_breakpoint exit_code "$description" "moved" 1 0

    if [[ $exit_code -eq 0 ]] && [ "$silent" != true ]; then
      echo_success "${description^} moved"
    else
      echo_error "moving $description"
      exit 1
    fi
  }

  # Add value to the application config file
  update_application_config_file() {
    local description="application config file"

    if [ "$stop_creations" != true ]; then
      local current_filepath="$application_directory/$application_config_file"

      # Add version to config file
      local add_version="echo \"version=$version\" | $cat - $current_filepath >temp && $mv \"temp\" \"$current_filepath\""

      if [ "$debug" == true ]; then
        echo_var add_version
      fi

      eval $add_version
    fi

    exit_code=$?

    # echo_breakpoint exit_code "$description" "updated" 1 0

    if [[ $exit_code -eq 0 ]] && [ "$silent" != true ]; then
      echo_success "${description^} updated"
    else
      echo_error "updating $description"
      exit 1
    fi
  }

  # Moves the application config file into the home directory
  move_application_config_file() {
    local description="application config file"

    if [ "$stop_creations" != true ]; then
      local source="$application_directory/$application_config_file"
      local target=$application_config_file_filepath
      local move="$mv \"$source \"$target\""

      if [ "$debug" == true ]; then
        echo_var move
      fi

      eval $move
    fi
    exit_code=$?

    # echo_breakpoint exit_code "$description" "moved" 1 0

    if [[ $exit_code -eq 0 ]] && [ "$silent" != true ]; then
      echo_success "${description^} moved"
    else
      echo_error "moving $description"
      exit 1
    fi
  }

  # Add values to the application preferences file
  update_application_preferences_file() {
    local description="application preferences file"

    if [ "$stop_creations" != true ]; then
      local current_filepath="$application_directory/$application_preferences_file"

      # Add output_directory and template PPT filepath to preferences file
      local add_preferences="printf \"output_directory=$output_directory\ntemplate_ppt_filepath=$template_ppt_filepath\" | $cat - $current_filepath >temp && $mv \"temp\" \"$current_filepath\""

      if [ "$debug" == true ]; then
        echo_var add_preferences
      fi

      eval $add_preferences
    fi

    exit_code=$?

    # echo_breakpoint exit_code "$description" "updated" 1 0

    if [[ $exit_code -eq 0 ]] && [ "$silent" != true ]; then
      echo_success "${description^} updated"
    else
      echo_error "updating $description"
      exit 1
    fi
  }

  # Moves the application config file into the home directory
  move_application_preferences_file() {
    local description="application preferences file"

    if [ "$stop_creations" != true ]; then
      local source="$application_directory/$application_preferences_file"
      local target=$application_preferences_file_filepath
      local move="$mv \"$source\" \"$target\""

      if [ "$debug" == true ]; then
        echo_var move
      fi

      eval $move
    fi
    exit_code=$?

    # echo_breakpoint exit_code "$description" "moved" 1 0

    if [[ $exit_code -eq 0 ]] && [ "$silent" != true ]; then
      echo_success "${description^} moved"
    else
      echo_error "moving $description"
      exit 1
    fi
  }

  # Removes directories from $application_directory that aren't needed
  remove_extra_directories() {
    local description="extra directories"

    if [ "$silent" != true ]; then
      echo "$trash Removing $description"
    fi

    local remove_directories="$rm -rf \"$application_directory/*/\""
    if [ "$debug" == true ]; then
      echo_var remove_directories
    fi

    if [ "$stop_creations" != true ]; then
      eval $remove_directories
    fi

    # echo_breakpoint exit_code "$description" "removed" 1 0

    if [[ $exit_code -eq 0 ]]; then
      if [ "$silent" != true ]; then
        echo_success "${description^} removed"
      fi
    else
      echo_failed "remove $description"
      exit 1
    fi
  }

  # Removes files from $application_directory that aren't needed
  remove_extra_files() {
    local description="extra files"

    if [ "$silent" != true ]; then
      echo "$trash Removing $description"
    fi

    local remove_files="$find \"$application_directory\" -type f -not -name \"$template_ppt\" -delete"
    if [ "$debug" == true ]; then
      echo_var remove_files
    fi

    if [ "$stop_creations" != true ]; then
      eval $remove_files
    fi

    # echo_breakpoint exit_code "$description" "removed" 1 0

    if [[ $exit_code -eq 0 ]]; then
      if [ "$silent" != true ]; then
        echo_success "${description^} removed"
      fi
    else
      echo_failed "remove $description"
      exit 1
    fi
  }

  # Removes lingering dot files from $application_directory that aren't needed
  remove_dot_files() {
    local description="dot files"

    if [ "$silent" != true ]; then
      echo "$trash Removing $description"
    fi

    local remove_dots="$rm -rf $application_directory/.* 2>/dev/null"
    if [ "$debug" == true ]; then
      echo_var remove_dots
    fi

    if [ "$stop_creations" != true ]; then
      eval $remove_dots
    fi

    # echo_breakpoint exit_code "$description" "removed" 1 0

    if [[ $exit_code -eq 0 ]]; then
      if [ "$silent" != true ]; then
        echo_success "${description^} removed"
      fi
    else
      echo_failed "remove $description"
      exit 1
    fi
  }

  # Start

  if [ "$1" == true ] && [ "$silent" != true ]; then
    echo "$svg Starting basic installation of SVG to PPT"
    echo
  fi

  validate_application_directory_missing
  validate_bash_script_missing
  validate_libre_office_macro_template_missing

  fetch_application_zip
  unzip_application_zip
  remove_application_zip

  move_src_files

  create_output_directory

  move_bash_script
  update_bash_script_access

  move_libre_office_macro_template

  update_application_config_file
  move_application_config_file

  update_application_preferences_file
  move_application_preferences_file

  remove_extra_directories
  remove_extra_files
  remove_dot_files

  if [ "$silent" != true ]; then
    echo
    echo_success $txtbld"SVG to PPT installed"
  fi
)

# Installs Homebrew (if needed) and Libre Office, then executes a basic install
install_complete() (
  # Installs Homebrew
  install_homebrew() {
    local description="Homebrew"

    local homebrew_install_cmd="$bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    if [ "$silent" != true ]; then
      echo "$beer Starting $description installation: $txtund$homebrew_install_cmd$txtrst"
    fi

    if [ "$debug" == true ]; then
      echo_var homebrew_install_cmd
    fi

    if [ "$stop_creations" != true ]; then
      eval $homebrew_install_cmd
    fi
    local exit_code=$?

    # echo_breakpoint homebrew_location "$description" "install" 0 1

    if [[ $exit_code -ne 0 ]]; then
      echo_error "installing $description"
      exit 1
    elif [ "$silent" != true ]; then
      echo_success "$description installed"
    fi
  }

  # Installs Libre Office
  install_libre_office() {
    local description="Libre Office"

    local libre_office_install_cmd="$brew install --cask libreoffice"
    if [ "$silent" != true ]; then
      echo "$libre Starting $description installation: $txtund$libre_office_install_cmd$txtrst"
    fi

    if [ "$debug" == true ]; then
      echo_var libre_office_install_cmd
    fi

    if [ "$stop_creations" != true ]; then
      eval $libre_office_install_cmd
    fi
    local exit_code=$?

    # echo_breakpoint homebrew_location "$description" "install" 0 1

    if [[ $exit_code -ne 0 ]]; then
      echo_error "installing $description with Homebrew"
      exit 1
    elif [ "$silent" != true ]; then
      echo_success "$description installed"
    fi
  }

  if [ "$silent" != true ]; then
    echo_bold "$svg Starting complete installation of SVG to PPT"
    echo
  fi

  check_libre_office_installed

  if [[ $? -eq 0 ]]; then
    check_homebrew_installed

    if [[ $? -eq 0 ]]; then
      install_homebrew
    fi

    if [ "$debug" == true ]; then
      echo_var brew
    fi

    install_libre_office
  fi

  echo
  install_basic false
)

# MAIN

install_type=$1

# Check for flags overwriting defaults
while getopts "a:i:drsx" option; do
  case "${option}" in
    a) application_directory=${OPTARG} ;;
    i) install_type=${OPTARG} ;;
    r) reinstall=true ;;
    s) silent=true ;;
    d) debug=true ;;
    x) stop_creations=true ;;
  esac
done

# Valides install_type and routes to install functions
case "$install_type" in
  "basic") install_basic true ;;
  "complete") install_complete ;;
  *)
    echo "Input error: \"$install_type\" is not a valid install type; should only be: basic, complete"
    exit 2
    ;;
esac
