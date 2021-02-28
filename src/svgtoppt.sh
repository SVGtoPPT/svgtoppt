# Uncomment for intense debugging
# before=$(set -o posix; set | sort);

# APPLICATION CONFIG VALUES
application_name=svgtoppt
application_config_file=.$application_name
application_config_file_filepath=~/$application_config_file
application_preferences_file=.$application_name-preferences
application_preferences_file_filepath=~/$application_preferences_file

# HELPFUL STRINGS
svg_file_ext=.svg
ppt_file_ext=.ppt

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
exclamation="❗️"
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

main() {
  if [ "$debug" == true ]; then
    printf $bldcyn"\n~INPUT FOR DEBUGGING~\n\n"
    printf "# DEFAULTS\n"
    echo_var application_directory
    echo_var output_directory

    printf "\n# SVG\n"
    echo_var input_svg

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

  # Check if SVG file exists
  if test -f $first_parameter && [ ! -z $first_parameter ]; then
    svg_filepath=$first_parameter
  elif test -f $input_svg; then
    svg_filepath=$input_svg
  elif test -f $PWD/$input_svg; then
    svg_filepath=$PWD/$input_svg
  else
    echo_failed "input SVG file: $input_svg"
    exit 2
  fi

  # Check if SVG extension is present
  if [[ "$svg_filepath" != *"$svg_file_ext" ]]; then
    echo_failed "find '$svg_file_ext' at the end of the input file: $bldwht$svg_filepath$txtrst"
    exit 2
  fi

  # If template PPT passed in, check if it exists
  if [ ! -z $template_ppt ]; then
    if test -f $PWD/$template_ppt; then
      template_ppt_filepath=$PWD/$template_ppt
    elif test -f $template_ppt; then
      template_ppt_filepath=$template_ppt
    else
      echo "Input error: Can't find template PPT file $template_ppt"
      exit 2
    fi
  fi

  # Validate force_ppt for true or false
  if [ "$force_ppt" != true ] && [ "$force_ppt" != false ]; then
    echo "Input error: force_ppt flag (-f) should only be set to true or false"
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
      echo "Input error: where_to_open flag (-w) should only be set to: none, keynote, power, libre, oo"
      exit 2
      ;;
  esac

  # Set SVG flag-dependent defaults
  svg_name_with_ext=${input_svg##*/}
  IFS='.' read -r svg_name string <<<"$svg_name_with_ext"

  # Set PPT flag-dependent defaults
  if [ -z $ppt_name ]; then
    ppt_name=$svg_name
  fi
  ppt_filepath=$output_directory/$ppt_name$ppt_file_ext

  if [ "$force_ppt" != true ] && [ -f $ppt_filepath ]; then
    while [ -f $ppt_filepath ]; do
      if [ -z $ppt_name_suffix ]; then
        ppt_name_suffix=-1
      else
        ppt_name_suffix=$((ppt_name_suffix - 1))
      fi

      ppt_filepath=$output_directory/$ppt_name$ppt_name_suffix$ppt_file_ext
    done

    if [ "$stop_creations" != true ]; then
      printf $yellow"$warn Warning: $ppt_name$ppt_file_ext already exists, so creating new file $ppt_name$ppt_name_suffix$ppt_file_ext in directory: $output_directory$txtrst\n"
    fi
  elif [ "$force_ppt" == true ] && [ -f $ppt_filepath ]; then
    if [ "$stop_creations" != true ]; then
      printf "Overwriting file: $ppt_filepath\n"
    fi
  else
    if [ "$stop_creations" != true ]; then
      printf "Creating new file: $ppt_filepath\n"
    fi
  fi

  # Copy the template to create/overwrite macro file to be used
  local copy="cp $libre_office_macro_template_filepath $libre_office_macro_filepath"
  eval $copy

  # Write filepath of SVG and PPT to macro for Libre Office to read
  local svg_sed="sed -i '' \"s~SVG_FILEPATH~$svg_filepath~\" $libre_office_macro_filepath"
  if [ "$debug" == true ]; then
    echo_var svg_sed
  fi

  if [ "$stop_creations" != true ]; then
    eval $svg_sed
  fi

  local ppt_sed="sed -i '' \"s~PPT_FILEPATH~$ppt_filepath~\" $libre_office_macro_filepath"
  if [ "$debug" == true ]; then
    echo_var ppt_sed
  fi

  if [ "$stop_creations" != true ]; then
    eval $ppt_sed
  fi

  # Launch the template PPT with Libre Office and kick off macro
  local libre_office_cmd="/Applications/LibreOffice.app/Contents/MacOS/soffice --invisible --headless $template_ppt_filepath \"vnd.sun.star.script:Standard.$libre_office_macro.Main?language=Basic&location=application\""

  if [ "$debug" == true ]; then
    echo_var libre_office_cmd
  fi

  if [ "$stop_creations" != true ]; then
    eval $libre_office_cmd
  fi

  # Launch the new PPT file if where_to_open is defined
  if [ ! -z $where_to_open ]; then
    local open_cmd="open -a $where_to_open $ppt_filepath"

    if [ "$debug" == true ]; then
      echo_var open_cmd
    fi

    if [ "$stop_creations" != true ]; then
      eval $open_cmd
    fi
  fi

  if [ "$stop_creations" != true ]; then
    echo_success "File created: $ppt_filepath"
  fi
}

reset_preferences() {
  local description="application preferences"

  local remote_url="https://raw.githubusercontent.com/SVGtoPPT/svgtoppt/$version/src/svgtoppt-preferences"
  local preferences_curl="curl -L $remote_url > $application_preferences_file_filepath"

  if [ "$debug" == true ]; then
    echo_var remote_url
    echo_var preferences_curl
  fi

  if [ "$stop_creations" != true ]; then
    eval $preferences_curl
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "reset" 1 0

    if [[ $exit_code -ne 0 ]]; then
      echo_failed "reset $description"
    fi

    # Add output_directory and template PPT filepath to preferences file
    printf "output_directory=$output_directory\ntemplate_ppt_filepath=$template_ppt_filepath" | cat - $current_filepath >temp && mv temp $current_filepath
    local exit_code=$?

    # echo_breakpoint exit_code "$description" "update" 1 0

    if [[ $exit_code -ne 0 ]]; then
      echo_failed "update $description"
    fi
  fi

  echo_success "Preferences reset"
  exit
}

update_preferences() {
  local description="application preferences"

  echo "output_directory=$output_directory
template_ppt_filepath=$template_ppt_filepath
input_svg=$input_svg
ppt_name=$ppt_name
force_ppt=$force_ppt
where_to_open=$where_to_open" >$application_preferences_file_filepath

  local exit_code=$?

  # echo_breakpoint exit_code "$description" "update" 1 0

  if [[ $exit_code -ne 0 ]]; then
    echo_failed "update $description"
  fi

  echo_success "Preferences updated"
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

description="Libre Office"
IFS=' ' read -r brew_path string <<<"$(brew info libreoffice | sed -n '3p')"
libre_office_location=$(whichapp "LibreOffice" || printf $brew_path)

if [ -z "$libre_office_location" ]; then
  echo_failed "find $description; please ensure Libre Office is installed"
  exit 1
fi

description="application config file"
source $application_config_file_filepath
exit_code=$?

# echo_breakpoint exit_code "$description" "found" 1 0

if [[ $exit_code -ne 0 ]]; then
  echo_failed "find $description: $application_config_file_filepath"
  exit 1
fi

description="application preferences file"
source $application_preferences_file_filepath
exit_code=$?

# echo_breakpoint exit_code "$description" "found" 1 0

if [[ $exit_code -ne 0 ]]; then
  echo_failed "find $description"
  exit 1
fi

description="Libre Office macro template"

if test -f "$libre_office_macro_template_filepath"; then
  found=0
else
  found=1
fi

# echo_breakpoint found "$description" "found" 1 0

if [[ $found -ne 0 ]]; then
  echo_failed "find $description: $libre_office_macro_template_filepath"
  exit 1
fi

# First parameter should be SVG file if no flags are passed
first_parameter=$1

# Check for flags overwriting defaults
while getopts "f:i:o:p:t:w:dhsvx" option; do
  case "${option}" in
    f) force_ppt=${OPTARG} ;;
    i) input_svg=${OPTARG} ;;
    o) output_directory=${OPTARG} ;;
    p) ppt_name=${OPTARG} ;;
    t) template_ppt=${OPTARG} ;;
    w) where_to_open=${OPTARG} ;;
    d) debug=true ;;
    h) help=true ;;
    s) save_preferences=true ;;
    v) print_version=true ;;
    x) stop_creations=true ;;
  esac
done

if [ "$help" == true ]; then
  echo $bldwht"Usage:$txtrst $application_name [PATH_TO_SVG_FILE]"
  exit
elif [ "$print_version" == true ]; then
  echo "$application_name $version"
  exit
elif [ "$first_parameter" == "reset_pref" ]; then
  reset_preferences
elif [ "$first_parameter" == "check_install" ]; then
  exit 0
else
  if [ "$save_preferences" == true ]; then
    update_preferences
  fi

  main
fi

if [ "$debug" == true ]; then
  printf $bldcyn"\n~OUTPUT FOR DEBUGGING~\n\n"$txtrst

  printf $bldcyn"\n# INPUT\n"$txtrst
  echo_var input_svg
  echo_var svg_name_with_ext
  echo_var svg_name
  echo_var svg_filepath

  printf $bldcyn"\n# LIBRE OFFICE\n"$txtrst
  echo_var stop_creations
  echo_var application_config_file_filepath
  echo_var libre_office_cmd

  printf $bldcyn"\n# OUTPUT\n"$txtrst
  echo_var output_directory
  echo_var template_ppt_filepath
  echo_var ppt_name
  echo_var ppt_name_suffix
  echo_var ppt_filepath
  echo_var force_ppt
  echo_var where_to_open
  echo_var open_cmd

  # Uncomment for intense debugging
  # comm -13 <(printf %s "$before") <(set -o posix; set | sort | uniq)

  printf "\n~END~\n\n"$txtrst
fi
