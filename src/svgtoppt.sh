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

description="application config file"
source $application_config_file_filepath
exit_code=$?

# echo_breakpoint exit_code "$description" "found" 1 0

if [[ $exit_code -ne 0 ]]; then
  echo_error "Couldn't find $description"
fi

description="application preferences file"
source $application_preferences_file_filepath
exit_code=$?

# echo_breakpoint exit_code "$description" "found" 1 0

if [[ $exit_code -ne 0 ]]; then
  echo_error "Couldn't find $description"
fi

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

  # Check if first parameter ends in .svg
  if [[ "$input_svg" != *"$svg_file_ext" ]]; then
    echo "Input error: SVG file not passed in as the first parameter or using the -i flag"
    exit 2
  fi

  # Remove file extension from ppt_name if present
  if [[ "$ppt_name" == *"$ppt_file_ext" ]]; then
    IFS='.' read -r ppt_name string <<<"$ppt_name"
  fi

  # Check if SVG file exists
  if test -f $PWD/$input_svg; then
    svg_filepath=$PWD/$input_svg
  elif test -f $input_svg; then
    svg_filepath=$input_svg
  else
    echo "Input error: Can't find SVG file $input_svg"
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
    printf "$ppt_name$ppt_file_ext already exists in $output_directory, so creating new file $ppt_name$ppt_name_suffix$ppt_file_ext\n"
  else
    printf "Creating new file: $ppt_filepath\n"
  fi

  if [ "$stop_creations" != true ]; then
    # Copy the template to create/overwrite macro file to be used
    local copy="cp $libre_office_macro_template_filepath $libre_office_macro_filepath"
    eval $copy

    # Write filepath of SVG and PPT to macro for Libre Office to read
    local sed="sed -i '' \"s~SVG_FILEPATH~$svg_filepath~\" $libre_office_macro_filepath"
    eval $sed

    local sed="sed -i '' \"s~PPT_FILEPATH~$ppt_filepath~\" $libre_office_macro_filepath"
    eval $sed
  fi

  if [ "$stop_creations" != true ]; then
    # Launch the template PPT with Libre Office and kick off macro
    libre_office_cmd="/Applications/LibreOffice.app/Contents/MacOS/soffice --invisible --headless $template_ppt_filepath \"vnd.sun.star.script:Standard.$libre_office_macro.Main?language=Basic&location=application\""
    eval $libre_office_cmd

    # Launch the new PPT file if where_to_open is defined
    if [ ! -z $where_to_open ]; then
      open_cmd="open -a $where_to_open $ppt_filepath"
      eval $open_cmd
    fi
  fi
}

# First parameter should be SVG file if no flags are passed
input_svg=$1

# Check for flags overwriting defaults
while getopts "a:f:i:o:p:t:w:dhvx" option; do
  case "${option}" in
    a) application_directory=${OPTARG} ;;
    h) help=true ;;
    f) force_ppt=${OPTARG} ;;
    i) input_svg=${OPTARG} ;;
    o) output_directory=${OPTARG} ;;
    p) ppt_name=${OPTARG} ;;
    t) template_ppt=${OPTARG} ;;
    w) where_to_open=${OPTARG} ;;
    d) debug=true ;;
    v) print_version=true;;
    x) stop_creations=true ;;
  esac
done

if [ "$help" == true ]; then
  echo $bldwht"Usage:$txtrst $application_name [PATH_TO_SVG_FILE]"
  exit
elif [ "$print_version" == true ]; then
  echo "$application_name $version"
  exit
else
  main
fi

if [ "$debug" == true ]; then
  printf $bldcyn"\n~OUTPUT FOR DEBUGGING~\n\n"
  printf "# DEFAULTS\n"
  echo_var application_directory
  echo_var output_directory

  printf "\n# SVG\n"
  echo_var input_svg
  echo_var svg_name_with_ext
  echo_var svg_name
  echo_var svg_filepath

  printf "\n# LIBRE OFFICE\n"
  echo_var stop_creations
  echo_var application_config_file_filepath
  echo_var libre_office_cmd

  printf "\n# PPT\n"
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
