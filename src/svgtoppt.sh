#!/bin/bash

# Uncomment for intense debugging
# before=$(set -o posix; set | sort);

# APPLICATION CONFIG VALUES
application_name=svgtoppt
application_config_file=.$application_name
application_config_file_filepath=~/$application_config_file
application_defaults_file=.$application_name-defaults
application_defaults_file_filepath=~/$application_defaults_file

# HELPFUL STRINGS
svg_file_ext='.svg'
ppt_file_ext='.ppt'
file_uri_prefix='file://'
quote_string='\&quot;'

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
checkmark='✅'
exclamation='❗️'
libre='📄'
octo='🐙'
svg='🖌 '
swirl='🌀'
trash='🗑 '
warn='⚠️ '
x_mark='❌'

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

# Basic commands
brew=$(find_path brew)
cat=$(find_path cat)
cp=$(find_path cp)
curl=$(find_path curl)
mv=$(find_path mv)
sed=$(find_path sed)

main() {
  validate_inputs() {
    # Check if SVG file exists or if it's a directory
    if [ ! -z "$first_parameter" ] && test -f $first_parameter; then
      svg_filepath=$first_parameter
    elif test -f "$input"; then
      svg_filepath="$input"
    elif test -f "$PWD/$input"; then
      svg_filepath="$PWD/$input"
    elif [ ! -z "$first_parameter" ] && [ -d "$first_parameter" ]; then
      svg_directory="$first_parameter"
    elif [ -d "$input" ]; then
      svg_directory="$input"
    elif [ -d "$PWD/$input" ]; then
      svg_directory="$PWD/$input"
    else
      echo_failed "find input file/directory: $input"
      exit 2
    fi

    # Check if SVG extension is present
    if [[ ! -z "$svg_filepath" ]] && [[ "$svg_filepath" != *"$svg_file_ext" ]]; then
      echo_failed "find '$svg_file_ext' at the end of the input file: $bldwht$svg_filepath$txtrst"
      exit 2
    fi

    # If template PPT passed in, check if it exists
    if [ ! -z "$template_ppt" ]; then
      if test -f $PWD/$template_ppt; then
        template_ppt_filepath=$PWD/$template_ppt
      elif test -f $template_ppt; then
        template_ppt_filepath=$template_ppt
      else
        echo_failed "find template PPT file $template_ppt"
        exit 2
      fi
    fi

    # Validate force_ppt for true or false
    if [ "$force_ppt" != true ] && [ "$force_ppt" != false ]; then
      echo_error "Input flag force_ppt (-f) should only be set to true or false"
      exit 2
    fi

    # Validate where_to_open for valid option
    case $where_to_open in
      none) where_to_open= ;;
      keynote) where_to_open=Keynote ;;
      power) where_to_open="Microsoft PowerPoint" ;;
      libre) where_to_open=LibreOffice ;;
      oo) where_to_open=OpenOffice ;;
      *)
        echo_error "Input flag where_to_open (-w) should only be set to: none, keynote, power, libre, oo"
        exit 2
        ;;
    esac

    if [[ ! -z "$svg_filepath" ]]; then
      # Set SVG flag-dependent defaults
      local svg_name_with_ext=${svg_filepath##*/}
      IFS='.' read -r svg_name string <<<"$svg_name_with_ext"

      # Set PPT flag-dependent defaults
      if [ -z "$ppt_name" ]; then
        ppt_name=$svg_name
      fi
      ppt_filepath=$output_directory/$ppt_name$ppt_file_ext
    elif [[ ! -z "$svg_directory" ]]; then
      # echo_var svg_directory

      local first=true
      for i in "$svg_directory"/*
      do
        # echo $i
        if [[ "$i" == *"$svg_file_ext" ]]; then
          if [ "$first" == true ]; then
            first=false
          else
            svg_filepaths="$svg_filepaths, "
          fi

          svg_filepaths="$svg_filepaths$quote_string$file_uri_prefix$i$quote_string"
        # else
        #   echo "Not an SVG: $i"
        fi
      done
    fi

    echo_var svg_filepaths
  }

  # Figures out the name of the PPT file based on $force_ppt and existing PPT files
  determine_ppt_name() {
    if [[ ! -z "$svg_filepath" ]]; then
      local svg_name_with_ext=${svg_filepath##*/}
      IFS='.' read -r svg_name string <<<"$svg_name_with_ext"

      # Set PPT flag-dependent defaults
      if [ -z "$ppt_name" ]; then
        ppt_name=$svg_name
      fi
    elif [[ ! -z "$svg_directory" ]]; then
      local directory_name=${svg_directory##*/}

      # Set PPT flag-dependent defaults
      if [ -z "$ppt_name" ]; then
        ppt_name=$directory_name
      fi
    fi

    ppt_filepath=$output_directory/$ppt_name$ppt_file_ext

    if [ "$force_ppt" != true ] && [ -f "$ppt_filepath" ]; then
      while [ -f "$ppt_filepath" ]; do
        if [ -z "$ppt_name_suffix" ]; then
          ppt_name_suffix=-1
        else
          ppt_name_suffix=$((ppt_name_suffix - 1))
        fi

        ppt_filepath="$output_directory/$ppt_name$ppt_name_suffix$ppt_file_ext"
      done

      if [ "$stop_creations" != true ] && [ "$quiet" != true ]; then
        printf $yellow"$warn Warning: $ppt_name$ppt_file_ext already exists, so creating new file $ppt_name$ppt_name_suffix$ppt_file_ext in directory: $output_directory$txtrst\n"
      fi
    elif [ "$force_ppt" == true ] && [ -f $ppt_filepath ]; then
      if [ "$stop_creations" != true ] && [ "$quiet" != true ]; then
        printf "Overwriting file: $ppt_filepath\n"
      fi
    else
      if [ "$stop_creations" != true ] && [ "$quiet" != true ]; then
        echo "$svg Creating new file: $ppt_filepath"
      fi
    fi
  }

  # Copies the template to create/overwrite macro file to be used
  create_macro_from_template() {
    local description="libre Office macro template"

    local copy_file="$cp \"$libre_office_macro_template_filepath\" \"$libre_office_macro_filepath\""

    if [ "$debug" == true ]; then
      echo_var copy_file
    fi

    # if [ "$stop_creations" != true ]; then
      eval $copy_file
    # fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "copied" 1 0

    if [[ $exit_code -ne 0 ]]; then
      echo_failed "copy $description"
      exit 1
    elif [ "$quiet" != true ]; then
      echo_success "$description copied"
    fi
  }

  # Write filepath of SVG to macro for Libre Office to read
  update_macro_with_svg() {
    local description="Libre Office macro"

    if [ -z "$svg_filepaths" ]; then
      svg_filepaths="$quote_string$svg_filepath$quote_string"
    fi

    local svg_sed="$sed -i '' \"s|SVG_FILEPATHS|$svg_filepaths|\" \"$libre_office_macro_filepath\""
    if [ "$debug" == true ]; then
      echo_var svg_sed
    fi

    if [ "$stop_creations" != true ]; then
      eval $svg_sed
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "updated" 1 0

    if [[ $exit_code -ne 0 ]]; then
      echo_failed "update $description"
      exit 1
    elif [ "$quiet" != true ]; then
      echo_success "$description updated"
    fi
  }

  # Write filepath of PPT to macro for Libre Office to read
  update_macro_with_ppt() {
    local description="Libre Office macro"

    local ppt_sed="$sed -i '' \"s~PPT_FILEPATH~$ppt_filepath~\" \"$libre_office_macro_filepath\""
    if [ "$debug" == true ]; then
      echo_var ppt_sed
    fi

    if [ "$stop_creations" != true ]; then
      eval $ppt_sed
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "updated" 1 0

    if [[ $exit_code -ne 0 ]]; then
      echo_failed "update $description"
      exit 1
    elif [ "$quiet" != true ]; then
      echo_success "$description updated"
    fi
  }

  # Starts the Libre Office macro on the template PPT
  launch_libre_office_macro() {
    local description="Libre Office macro"

    local libre_office_cmd="/Applications/LibreOffice.app/Contents/MacOS/soffice --invisible --headless $template_ppt_filepath \"vnd.sun.star.script:Standard.$libre_office_macro.Main?language=Basic&location=application\""

    if [ "$debug" == true ]; then
      echo_var libre_office_cmd
    fi

    if [ "$stop_creations" != true ]; then
      eval $libre_office_cmd
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "launched" 1 0

    if [[ $exit_code -ne 0 ]]; then
      echo_failed "launch $description"
      exit 1
    elif [ "$quiet" != true ]; then
      echo_success "$description launched"
    fi
  }

  # Opens the new PPT file in an application
  open_ppt() {
    local description="new PPT file"

    local open_cmd="open -a \"$where_to_open\" \"$ppt_filepath\""

    if [ "$debug" == true ]; then
      echo_var open_cmd
    fi

    if [ "$stop_creations" != true ]; then
      eval "$open_cmd"
    fi
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "opened" 1 0

    if [[ $exit_code -ne 0 ]]; then
      echo_failed "open $description"
      exit 1
    elif [ "$quiet" != true ]; then
      echo_success "$description opened"
    fi
  }

  if [ "$debug" == true ]; then
    printf $bldcyn"\n~INPUT FOR DEBUGGING~\n\n"
    printf "# DEFAULTS\n"
    echo_var application_directory
    echo_var output_directory

    printf "\n# SVG\n"
    echo_var input

    printf "\n# PPT\n"
    echo_var ppt_name
    echo_var force_ppt
    echo_var template_ppt
    echo_var where_to_open

    printf "\n~END~\n\n"$txtrst
  fi

  # Remove file extension from ppt_name if present
  if [[ "$ppt_name" == *"$ppt_file_ext" ]]; then
    IFS='.' read -r ppt_name string <<<"$ppt_name"
  fi

  validate_inputs
  determine_ppt_name

  create_macro_from_template
  update_macro_with_svg
  update_macro_with_ppt

  launch_libre_office_macro

  # Launch the new PPT file if where_to_open is defined
  if [ ! -z "$where_to_open" ]; then
    open_ppt
  fi

  if [ "$quiet" != true ]; then
    echo_success "File created"
  fi
}

# Fetches the application defaults by version from GitHub
fetch_remote_defaults() {
  local description="application defaults"

  local remote_url="https://raw.githubusercontent.com/SVGtoPPT/svgtoppt/$version/src/svgtoppt-defaults"
  local defaults_curl="$curl -L $remote_url > $application_defaults_file_filepath"

  if [ "$debug" == true ]; then
    echo_var remote_url
    echo_var defaults_curl
  fi

  if [ "$stop_creations" != true ]; then
    eval $defaults_curl
  fi
  local exit_code=$?

  # echo_breakpoint exit_code "$description" "reset" 1 0

  if [[ $exit_code -ne 0 ]]; then
    echo_failed "reset $description"
    exit 1
  fi
}

# Add output_directory and template PPT filepath to defaults file
update_application_defaults_file() {
  local description="application defaults file"

  local add_variables="printf \"output_directory=$output_directory\ntemplate_ppt_filepath=$template_ppt_filepath\n\" | $cat - $current_filepath >temp && $mv \"temp\" \"$current_filepath\""

  if [ "$debug" == true ]; then
    echo_var add_variables
  fi

  if [ "$stop_creations" != true ]; then
    eval $add_variables
  fi
  local exit_code=$?

  # echo_breakpoint exit_code "$description" "update" 1 0

  if [[ $exit_code -ne 0 ]]; then
    echo_failed "update $description"
    exit 1
  elif [ "$quiet" != true ]; then
    echo_success "Defaults reset"
  fi

  exit
}

# Overwrite the application defaults file based on current variables
update_defaults_from_input() {
  local description="application defaults"

  echo "output_directory=$output_directory
template_ppt_filepath=$template_ppt_filepath
input=$input
ppt_name=$ppt_name
force_ppt=$force_ppt
where_to_open=$where_to_open" >$application_defaults_file_filepath

  local exit_code=$?

  # echo_breakpoint exit_code "$description" "update" 1 0

  if [[ $exit_code -ne 0 ]]; then
    echo_failed "update $description"
  fi

  echo_success "Defaults updated"
}

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

validate_libre_office_installed() {
  local description="Libre Office"

  local brew_command="$brew info libreoffice"
  IFS=' ' read -r brew_path string <<<"$($brew_command | sed -n '3p')"
  libre_office_location=$(whichapp "LibreOffice" || printf $brew_path)

  if [ -z "$libre_office_location" ]; then
    echo_failed "find $description; please ensure Libre Office is installed"
    exit 1
  fi
}

validate_application_config_file_exists() {
  local description="application config file"

  source $application_config_file_filepath
  exit_code=$?

  # echo_breakpoint exit_code "$description" "found" 1 0

  if [[ $exit_code -ne 0 ]]; then
    echo_failed "find $description: $application_config_file_filepath"
    exit 1
  fi
}

validate_application_defaults_file_exists() {
  local description="application defaults file"

  source $application_defaults_file_filepath
  exit_code=$?

  # echo_breakpoint exit_code "$description" "found" 1 0

  if [[ $exit_code -ne 0 ]]; then
    echo_failed "find $description"
    exit 1
  fi
}

validate_libre_office_macro_template_exists() {
  local description="Libre Office macro template"

  if test -f "$libre_office_macro_template_filepath"; then
    local found=0
  else
    local found=1
  fi
  # echo_breakpoint found "$description" "found" 1 0

  if [[ $found -ne 0 ]]; then
    echo_failed "find $description: $libre_office_macro_template_filepath"
    exit 1
  fi
}

validate_libre_office_installed
validate_application_config_file_exists
validate_application_defaults_file_exists
validate_libre_office_macro_template_exists

source $application_config_file_filepath
source $application_defaults_file_filepath

# First parameter should be SVG file if no flags are passed
first_parameter=$1

if [ "$first_parameter" == "check_install" ]; then
  exit 0
elif [ "$first_parameter" == "reset_def" ]; then
  fetch_remote_defaults
  update_application_defaults_file
  exit 0
elif [[ $first_parameter = --* ]]; then
  while [ $# -gt 0 ]; do
    case "$1" in
      --debug) debug=true ;;
      --help) help=true ;;
      --save_def) save_def=true ;;
      --quiet) quiet=true ;;
      --version) print_version=true ;;
      --stop_creations) stop_creations=true ;;
      --force_ppt=*) force_ppt="${1#*=}" ;;
      --input=*) input="${1#*=}" ;;
      --output_directory=*) output_directory=${OPTARG} ;;
      --ppt_name=*) ppt_name=${OPTARG} ;;
      --template_ppt=*) template_ppt=${OPTARG} ;;
      --where_to_open=*) where_to_open=${OPTARG} ;;
    esac
    shift
  done
elif [[ $first_parameter = -* ]]; then
  # Check for flags overwriting defaults
  while getopts "f:i:o:p:t:w:dhqsvx" option; do
    case "${option}" in
      f) force_ppt=${OPTARG} ;;
      i) input=${OPTARG} ;;
      o) output_directory=${OPTARG} ;;
      p) ppt_name=${OPTARG} ;;
      t) template_ppt=${OPTARG} ;;
      w) where_to_open=${OPTARG} ;;
      d) debug=true ;;
      h) help=true ;;
      q) quiet=true ;;
      s) save_def=true ;;
      v) print_version=true ;;
      x) stop_creations=true ;;
    esac
  done
fi

if [ "$help" == true ]; then
  echo $bldwht"Standard Usage:$txtrst $application_name [PATH_TO_SVG_FILE]"
  echo $bldwht"Custom Usage:$txtrst $application_name [FLAGS]"
  echo
  bldwhtund=$txtund$bldwht
  echo $bldwhtund"Flags$txtrst                  "$bldwhtund"Name$txtrst              "$bldwhtund"Description"$txtrst
  echo "-q --quiet             quiet             Quiet mode to prevent output"
  echo "-i --input             input             Filepath of the SVG file or directory to be converted"
  echo "-t --template_ppt      template_ppt      Filepath of the template PPT"
  echo "-o --output_directory  output_directory  Filepath of the directory where PPT files are output"
  echo "-p --ppt_name          ppt_name          The name of the PPT file that is output"
  echo "-f --force_ppt         force_ppt         Force use the ppt_name (introduces risk of overwriting a PPT file)"
  echo "-w --where_to_open     where_to_open     Where the PPT file is opened in after it's created"
  echo "-s --save_def          save_def          Save the other flags on the current request as your defaults"
  echo
  echo $bldwht"Examples:$txtrst"
  echo "  svgtoppt -i ~/Desktop/logo.svg -t ~/Documents/blake_template.ppt -o ~/Desktop -p amazing_logo -f true -w none -q"
  echo "  svgtoppt --input=~/Desktop/logo.svg \\"
  echo "           --template_ppt=~/Documents/blake_template.ppt \\"
  echo "           --output_directory=~/Desktop \\"
  echo "           --ppt_name=amazing_logo \\"
  echo "           --force_ppt=true \\"
  echo "           --where_to_open=none \\"
  echo "           --quiet"
  echo
  echo $bldwht"Get Help:$txtrst $application_name -h"
  echo "          $application_name --help"
  echo $bldwht"View Version:$txtrst $application_name -v"
  echo "              $application_name --version"
  echo
  echo $bldwht"More documentation:$txtrst https://svgtoppt.com/cli"
  echo $bldwht"Source:$txtrst https://github.com/SVGtoPPT/svgtoppt"
  echo $bldwht"Support:$txtrst https://svgtoppt.com/support"
  exit
elif [ "$print_version" == true ]; then
  if [ -z $version ]; then
    echo_error "Version of svgtoppt not found; ensure application config file exists: $bldwht$application_config_file_filepath"
    exit 1
  fi

  echo "$application_name $version"
  exit
else
  if [ "$save_def" == true ]; then
    update_defaults_from_input
  fi

  main
fi

if [ "$debug" == true ]; then
  printf $bldcyn"\n~OUTPUT FOR DEBUGGING~\n\n"$txtrst

  printf $bldcyn"\n# INPUT\n"$txtrst
  echo_var input
  echo_var svg_name_with_ext
  echo_var svg_name
  echo_var svg_filepath

  printf $bldcyn"\n# LIBRE OFFICE\n"$txtrst
  echo_var stop_creations
  echo_var application_config_file_filepath

  printf $bldcyn"\n# OUTPUT\n"$txtrst
  echo_var output_directory
  echo_var template_ppt_filepath
  echo_var ppt_name
  echo_var ppt_name_suffix
  echo_var ppt_filepath
  echo_var force_ppt
  echo_var where_to_open

  # Uncomment for intense debugging
  # comm -13 <(printf %s "$before") <(set -o posix; set | sort | uniq)

  printf "\n~END~\n\n"$txtrst
fi
