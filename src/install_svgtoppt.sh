#!/bin/bash

# APPLICATION CONFIG VALUES
version=1.0.2-SNAPSHOT
application_name=svgtoppt
application_directory=$PWD/$application_name
application_config_file=$application_name
application_config_file_filepath=~/.$application_config_file
application_defaults_file=$application_name-defaults
application_defaults_file_filepath=~/.$application_defaults_file
application_zip_file=$PWD/$application_name.zip

# BASH SCRIPT CONFIG VALUES
bash_script=svgtoppt
bash_script_filepath=/usr/local/bin/$bash_script

# LIBRE OFFICE MACRO CONFIG VALUES
libre_office_macro_template=SVGtoPPT_template.xba
application_support_directory="Application Support"
libre_office_macros_filepath=~/Library/$application_support_directory/LibreOffice/4/user/basic/Standard
libre_office_macro_template_filepath=$libre_office_macros_filepath/$libre_office_macro

# Included for nonvolatile debugging
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

capitalize() {
  local input=$1
  echo $(tr a-z A-Z <<< ${input:0:1})${input:1}
}

echo_success() {
  echo $green"$checkmark $(capitalize "$1") successfully$txtrst"
}

echo_already_exists() {
  echo $yellow"$warn Warning: $(capitalize "$1") already exists: $bldwht$2$txtrst"
}

echo_already_installed() {
  echo $blue"$swirl Note: Skipped installation of $1 as it's already installed: $2$txtrst"
}

echo_failed() {
  echo $bldred"$x_mark Failure: Couldn't $1$txtrst"
}

echo_error() {
  echo $bldred"$exclamation Error: $1$txtrst"
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
  read -r input

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

# Basic commands
bash=$(find_path bash)
brew=$(find_path brew)
cat=$(find_path cat)
curl=$(find_path curl)
find=$(find_path find)
mkdir=$(find_path mkdir)
mv=$(find_path mv)
rm=$(find_path rm)
sed=$(find_path sed)
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

    if [ "$quiet" != true ]; then
      echo_already_installed "$description" $brew
    fi
  fi

  # echo_breakpoint found "$description" "found" 0 1

  return $found
}

# Checks if Libre Office is installed
# Returns 0 for not found, 1 for found
check_libre_office_installed() {
  local description="Libre Office"

  libre_office_location=$(whichapp "LibreOffice")

  if [ "$debug" == true ]; then
    echo_var libre_office_location
  fi

  if [[ -z "$libre_office_location" ]]; then
    check_homebrew_installed

    if [[ $? -ne 0 ]]; then
      local brew_command="$brew info libreoffice | $sed -n '3p'"

      if [ "$debug" == true ]; then
        echo_var brew_command
      fi

      IFS=' ' read -r brew_libre_office_location string <<<$(eval $brew_command)

      if [[ $brew_libre_office_location == *"Not"* ]]; then
        brew_libre_office_location=""
      fi
    else
      brew_libre_office_location=""
    fi

    if [ "$debug" == true ]; then
      echo_var brew_libre_office_location
    fi

    if [[ -z "$brew_libre_office_location" ]]; then
      local found=0
    else
      local found=1

      if [ "$quiet" != true ]; then
        echo_already_installed "$description" $brew_libre_office_location
      fi
    fi
  else
    local found=1

    if [ "$quiet" != true ]; then
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
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "found" 0 1

    if [[ $exit_code -eq 1 ]]; then
      if [ "$reinstall" != true ]; then
        echo_already_exists "$description" $application_directory
        echo "Please delete and run install again OR run install with reinstall flag (-r)"
        echo
        exit 1
      fi

      local remove_directory="$rm -rf $application_directory"

      if [ "$debug" == true ]; then
        echo_var remove_directory
      fi

      if [ "$stop_creations" != true ]; then
        eval $remove_directory
      fi
      local exit_code=$?

      # echo_breakpoint exit_code "$description" "removed" 1 0

      if [[ $exit_code -ne 0 ]]; then
        echo_error "Deleting $description failed" $application_directory
        exit 1
      elif [ "$quiet" != true ]; then
        echo_success "Existing $description deleted"
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
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "found" 0 1

    if [[ $exit_code -ne 0 ]]; then
      if [ "$reinstall" != true ]; then
        echo_already_exists "$description" $bash_script_filepath
        echo "Please delete and run install again OR run install with reinstall flag (-r)"
        echo
        exit 1
      fi

      local remove_directory="$rm $bash_script_filepath"

      if [ "$debug" == true ]; then
        echo_var remove_directory
      fi

      if [ "$stop_creations" != true ]; then
        eval $remove_directory
      fi
      local exit_code=$?

      # echo_breakpoint exit_code "$description" "removed" 1 0

      if [[ $exit_code -ne 0 ]]; then
        echo_error "Deleting $description failed" $bash_script_filepath
        exit 1
      elif [ "$quiet" != true ]; then
        echo_success "Existing $description deleted"
      fi
    fi
  }

  # Checks whether the Libre Office macro template already exists
  validate_libre_office_macro_template_missing() {
    local description="Libre Office macro"

    local description="Libre Office macro"

    check_file_missing $libre_office_macro_template_filepath
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "found" 0 1

    if [[ $exit_code -ne 0 ]]; then
      if [ "$reinstall" != true ]; then
        echo_already_exists "$description" $libre_office_macro_template_filepath
        echo "Please delete and run install again OR run install with reinstall flag (-r)"
        echo
        exit 1
      fi

      local remove_file="$rm $libre_office_macro_template_filepath"

      if [ "$debug" == true ]; then
        echo_var remove_file
      fi

      if [ "$stop_creations" != true ]; then
        eval $remove_file
      fi
      local exit_code=$?

      # echo_breakpoint exit_code "$description" "deleted" 1 0

      if [[ $exit_code -ne 0 ]]; then
        echo_error "Deleting $description failed" $libre_office_macro_template_filepath
        exit 1
      elif [ "$quiet" != true ]; then
        echo_success "Existing $description deleted"
      fi
    fi
  }

  # Fetches the application zip by version from GitHub
  fetch_application_zip() {
    local description="application zip"

    if [ "$quiet" != true ]; then
      echo "$octo Fetching $description from GitHub"
    fi

    local remote_url="https://github.com/SVGtoPPT/svgtoppt/archive/$version.zip"

    if [ "$debug" == true ]; then
      echo_var remote_url
    fi

    local fetch_remote="$curl -sL $remote_url > \"$application_zip_file\""
    if [ "$debug" == true ]; then
      echo_var fetch_remote
    fi

    if [ "$stop_creations" != true ]; then
      eval $fetch_remote
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "fetched" 1 0

    if [[ $exit_code -ne 0 ]]; then
      echo_failed "fetch $description: $bldwht$application_directory"
      exit 1
    elif [ "$quiet" != true ]; then
      echo_success "$description fetched"
    fi
  }

  # Unzips the application zip to create application directory
  unzip_application_zip() {
    local description="application zip"

    if [ "$quiet" != true ]; then
      echo "$file Unzipping $description"
    fi

    local unzip_directory="$unzip -q \"$application_zip_file\""
    if [ "$debug" == true ]; then
      echo_var unzip_directory
    fi

    if [ "$stop_creations" != true ]; then
      eval $unzip_directory
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "unzipped" 1 0

    if [[ $exit_code -ne 0 ]]; then
      echo_failed "unzip $description: $bldwht$application_zip_file"
      exit 1
    elif [ "$quiet" != true ]; then
      echo_success "$description unzipped"
    fi
  }

  # Renames the application directory from the default created by unzipping the application zip
  rename_application_directory() {
    local description="application directory"

    if [ "$quiet" != true ]; then
      echo "$file Renaming $description"
    fi

    local rename_dir="$mv \"$PWD/$application_name-$version\" \"$application_directory\""
    if [ "$debug" == true ]; then
      echo_var rename_dir
    fi

    if [ "$stop_creations" != true ]; then
      eval $rename_dir
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "renamed" 1 0

    if [[ $exit_code -ne 0 ]]; then
      echo_failed "rename $description"
      exit 1
    elif [ "$quiet" != true ]; then
      echo_success "$description renamed"
    fi
  }

  # Removes the application zip file
  remove_application_zip() {
    local description="application zip"

    if [ "$quiet" != true ]; then
      echo "$trash Removing $description"
    fi

    local remove_zip="$rm \"$application_zip_file\""
    if [ "$debug" == true ]; then
      echo_var remove_zip
    fi

    if [ "$stop_creations" != true ]; then
      eval $remove_zip
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "removed" 1 0

    if [[ $exit_code -ne 0 ]]; then
      echo_failed "remove $description"
      exit 1
    elif [ "$quiet" != true ]; then
      echo_success "$description removed"
    fi
  }

  # Moves files from $application_directory/src to application directory
  move_src_files() {
    local description="src files"

    if [ "$quiet" != true ]; then
      echo "$file Moving $description"
    fi

    local move_files="$mv $application_directory/src/* $application_directory"
    if [ "$debug" == true ]; then
      echo_var move_files
    fi

    if [ "$stop_creations" != true ]; then
      eval $move_files
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "moved" 1 0

    if [[ $exit_code -ne 0 ]]; then
      echo_failed "move $description"
      exit 1
    elif [ "$quiet" != true ]; then
      echo_success "$description moved"
    fi
  }

  # Removes directories from application directory that aren't needed
  remove_extra_directories() {
    local description="extra directories"

    if [ "$quiet" != true ]; then
      echo "$trash Removing $description"
    fi

    local remove_directories="$rm -rf $application_directory/*/"
    if [ "$debug" == true ]; then
      echo_var remove_directories
    fi

    if [ "$stop_creations" != true ]; then
      eval $remove_directories
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "removed" 1 0

    if [[ $exit_code -ne 0 ]]; then
      echo_failed "remove $description"
      exit 1
    elif [ "$quiet" != true ]; then
      echo_success "$description removed"
    fi
  }

  # Creates an "Output" directory under application directory
  create_output_directory() {
    local description="output directory"

    if [ "$quiet" != true ]; then
      echo "$file Creating $description"
    fi

    local create_directory="$mkdir $output_directory"
    if [ "$debug" == true ]; then
      echo_var create_directory
    fi

    if [ "$stop_creations" != true ]; then
      eval $create_directory
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "created" 1 0

    if [[ $exit_code -ne 0 ]]; then
      echo_failed "create $description"
      exit 1
    elif [ "$quiet" != true ]; then
      echo_success "$description created"
    fi
  }

  # Moves the application's Bash script to the appropriate location
  move_bash_script() {
    local description="Bash script"

    local move_file="$mv \"$application_directory/$bash_script.sh\" \"$bash_script_filepath\""

    if [ "$debug" == true ]; then
      echo_var move_file
    fi

    if [ "$stop_creations" != true ]; then
      eval $move_file
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "moved" 1 0

    if [[ $exit_code -ne 0 ]]; then
      echo_failed "move $description"
      exit 1
    elif [ "$quiet" != true ]; then
      echo_success "$description moved"
    fi
  }

  # Modifies the access of the application Bash script to run for all users
  update_bash_script_access() {
    local description="access to Bash script"

    local modify="chmod +x $bash_script_filepath"

    if [ "$debug" == true ]; then
      echo_var modify
    fi

    if [ "$stop_creations" != true ]; then
      eval $modify
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "changed" 1 0

    if [[ $exit_code -ne 0 ]]; then
      echo_failed "change $description"
      exit 1
    elif [ "$quiet" != true ]; then
      echo_success "$description updated"
    fi
  }

  # Moves the Libre Office macro template file into Libre Office's file structure
  move_libre_office_macro_template() {
    local description="Libre Office macro"

    local source="$application_directory/$libre_office_macro_template"
    local target=$libre_office_macro_template_filepath
    local move_file="$mv \"$source\" \"$target\""

    if [ "$debug" == true ]; then
      echo_var move_file
    fi

    if [ "$stop_creations" != true ]; then
      eval $move_file
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "moved" 1 0

    if [[ $exit_code -ne 0 ]]; then
      echo_error "Moving $description failed"
      exit 1
    elif [ "$quiet" != true ]; then
      echo_success "$description moved"
    fi
  }

  # Add value to the application config file
  update_application_config_file() {
    local description="application config file"

    local current_filepath="$application_directory/$application_config_file"

    # Add version to config file
    local add_version="echo \"version=$version\" | $cat - $current_filepath >temp && $mv \"temp\" \"$current_filepath\""

    if [ "$debug" == true ]; then
      echo_var add_version
    fi

    if [ "$stop_creations" != true ]; then
      eval $add_version
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "updated" 1 0

    if [[ $exit_code -ne 0 ]]; then
      echo_error "Updating $description failed"
      exit 1
    elif [ "$quiet" != true ]; then
      echo_success "$description updated"
    fi
  }

  # Moves the application config file into the home directory
  move_application_config_file() {
    local description="application config file"

    local source="$application_directory/$application_config_file"
    local target=$application_config_file_filepath
    local move="$mv \"$source\" \"$target\""

    if [ "$debug" == true ]; then
      echo_var move
    fi

    if [ "$stop_creations" != true ]; then
      eval $move
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "moved" 1 0

    if [[ $exit_code -ne 0 ]]; then
      echo_error "Moving $description failed"
      exit 1
    elif [ "$quiet" != true ]; then
      echo_success "$description moved"
    fi
  }

  # Add values to the application defaults file
  update_application_defaults_file() {
    local description="application defaults file"

    local current_filepath="$application_directory/$application_defaults_file"

    # Add output_directory and template PPT filepath to defaults file
    local add_defaults="printf \"output_directory=$output_directory\ntemplate_ppt_filepath=$template_ppt_filepath\n\" | $cat - $current_filepath >temp && $mv \"temp\" \"$current_filepath\""

    if [ "$debug" == true ]; then
      echo_var add_defaults
    fi

    if [ "$stop_creations" != true ]; then
      eval $add_defaults
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "updated" 1 0

    if [[ $exit_code -ne 0 ]]; then
      echo_error "Updating $description failed"
      exit 1
    elif [ "$quiet" != true ]; then
      echo_success "$description updated"
    fi
  }

  # Moves the application config file into the home directory
  move_application_defaults_file() {
    local description="application defaults file"

    local source="$application_directory/$application_defaults_file"
    local target=$application_defaults_file_filepath
    local move="$mv \"$source\" \"$target\""

    if [ "$debug" == true ]; then
      echo_var move
    fi

    if [ "$stop_creations" != true ]; then
      eval $move
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "moved" 1 0

    if [[ $exit_code -ne 0 ]]; then
      echo_error "Moving $description failed"
      exit 1
    elif [ "$quiet" != true ]; then
      echo_success "$description moved"
    fi
  }

  # Removes files from $application_directory that aren't needed
  remove_extra_files() {
    local description="extra files"

    if [ "$quiet" != true ]; then
      echo "$trash Removing $description"
    fi

    local remove_files="$find \"$application_directory\" -type f -not -name \"$template_ppt\" -delete"
    if [ "$debug" == true ]; then
      echo_var remove_files
    fi

    if [ "$stop_creations" != true ]; then
      eval $remove_files
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "removed" 1 0

    if [[ $exit_code -ne 0 ]]; then
      echo_failed "remove $description"
      exit 1
    elif [ "$quiet" != true ]; then
      echo_success "$description removed"
    fi
  }

  # Removes lingering dot files from $application_directory that aren't needed
  remove_dot_files() {
    local description="dot files"

    if [ "$quiet" != true ]; then
      echo "$trash Removing $description"
    fi

    local remove_dots="$rm -rf $application_directory/.* 2> /dev/null"
    # echo_breakpoint remove_dots "$description" "removed" 1 0
    if [ "$debug" == true ]; then
      echo_var remove_dots
    fi

    if [ "$stop_creations" != true ]; then
      eval $remove_dots
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "removed" 1 0

    if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 1 ]]; then
      if [ "$quiet" != true ]; then
        echo_success "$description removed"
      fi
    else
      echo_failed "remove $description"
      exit 1
    fi
  }

  # Start

  if [ "$1" == true ] && [ "$quiet" != true ]; then
    echo "$svg Starting basic installation of SVGtoPPT"
    echo
  fi

  validate_application_directory_missing
  validate_bash_script_missing
  validate_libre_office_macro_template_missing

  if [[ "$version" == *"-SNAPSHOT" ]]; then
    version='latest'
  fi

  fetch_application_zip
  unzip_application_zip
  remove_application_zip

  rename_application_directory

  move_src_files
  remove_extra_directories
  create_output_directory

  move_bash_script
  update_bash_script_access

  move_libre_office_macro_template

  update_application_config_file
  move_application_config_file

  update_application_defaults_file
  move_application_defaults_file

  remove_extra_files
  remove_dot_files

  if [ "$quiet" != true ]; then
    echo
    echo_success $txtbld"SVGtoPPT installed"
  fi
)

# Installs Homebrew (if needed) and Libre Office, then executes a basic install
install_complete() (
  # Installs Homebrew
  install_homebrew() {
    local description="Homebrew"

    local homebrew_install_cmd="$bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    if [ "$quiet" != true ]; then
      echo "$beer Starting $description installation: $txtund$homebrew_install_cmd$txtrst"
    fi

    if [ "$debug" == true ]; then
      echo_var homebrew_install_cmd
    fi

    if [ "$stop_creations" != true ]; then
      eval $homebrew_install_cmd
    fi
    local exit_code=$?

    # echo_breakpoint homebrew_location "$description" "installed" 0 1

    if [[ $exit_code -ne 0 ]]; then
      echo_error "Installing $description failed"
      exit 1
    elif [ "$quiet" != true ]; then
      echo_success "$description installed"
    fi
  }

  # Installs Libre Office
  install_libre_office() {
    local description="Libre Office"

    local libre_office_install_cmd="$brew install --cask libreoffice"
    if [ "$quiet" != true ]; then
      echo "$libre Starting $description installation: $txtund$libre_office_install_cmd$txtrst"
    fi

    if [ "$debug" == true ]; then
      echo_var libre_office_install_cmd
    fi

    if [ "$stop_creations" != true ]; then
      eval $libre_office_install_cmd
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "installed" 0 1

    if [[ $exit_code -ne 0 ]]; then
      echo_error "Installing $description with Homebrew failed"
      exit 1
    elif [ "$quiet" != true ]; then
      echo_success "$description installed"
    fi
  }

  # Opens Libre Office to generate $libre_office_macros_filepath
  open_libre_office() {
    local description="Libre Office"

    local libre_office_open_cmd="/Applications/LibreOffice.app/Contents/MacOS/soffice --writer &"
    if [ "$quiet" != true ]; then
      echo "$libre Opening $description to generate file structure"$txtrst
    fi

    if [ "$debug" == true ]; then
      echo_var libre_office_open_cmd
    fi

    if [ "$stop_creations" != true ]; then
      eval $libre_office_open_cmd
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "opened" 0 1

    if [[ $exit_code -ne 0 ]]; then
      echo_error "Opening $description"
      exit 1
    elif [ "$quiet" != true ]; then
      echo_success "$description opened"
    fi
  }

  if [ "$quiet" != true ]; then
    echo_bold "$svg Starting complete installation of SVGtoPPT"
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
    open_libre_office
  fi

  if [ "$quiet" != true ]; then
    echo
  fi

  install_basic false
)

# MAIN

install_type=$1

# Check for flags overwriting defaults
while getopts "a:i:dqrx" option; do
  case "${option}" in
    a) application_directory=${OPTARG} ;;
    i) install_type=${OPTARG} ;;
    d) debug=true ;;
    q) quiet=true ;;
    r) reinstall=true ;;
    x) stop_creations=true ;;
  esac
done

# APPLICATION DEFAULTS
output_directory=$application_directory/Output
template_ppt=template.ppt
template_ppt_filepath=$application_directory/$template_ppt

# Valides install_type and routes to install functions
case "$install_type" in
  "basic") install_basic true ;;
  "complete") install_complete ;;
  *)
    echo "Input error: \"$install_type\" is not a valid install type; should only be: basic, complete"
    exit 2
    ;;
esac
