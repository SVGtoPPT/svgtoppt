# Uncomment for intense debugging
# before=$(set -o posix; set | sort);

# Application defaults
application_name=svg-to-ppt
application_directory=~/$application_name
output_directory=$application_directory/Output
template_ppt_filepath=$application_directory/template.ppt
libre_office_input_filepath=~/.$application_name
force_ppt=false
where_to_open=keynote

# Helpful strings
svg_file_ext=.svg
ppt_file_ext=.ppt
file_uri_prefix=file://

# First parameter should be SVG file if no flags are passed
input_svg=$1

# Check for flags overwriting defaults
while getopts "a:f:h:i:o:p:t:w:dx" option; do
  case "${option}" in
    a) application_directory=${OPTARG} ;;

    f) force_ppt=${OPTARG} ;;
    i) input_svg=${OPTARG} ;;
    o) output_directory=${OPTARG} ;;
    p) ppt_name=${OPTARG} ;;
    t) template_ppt=${OPTARG} ;;
    w) where_to_open=${OPTARG} ;;
    d) debug=true ;;
    x) stop_creations=true ;;
  esac
done

echo_var() {
  eval 'printf "%s\n" "$1: ${'"$1"'}"'
}

if [ "$debug" == true ]; then
  printf "\n~INPUT FOR DEBUGGING~\n\n"
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

  printf "\n~END~\n\n"
fi

# Check if first parameter ends in .svg
if [[ "$input_svg" != *"$svg_file_ext" ]]; then
  echo "Input error: SVG file not passed in as the first parameter or using the -i flag"
  exit 2
fi

# Remove file extension from ppt_name if present
if [[ "$ppt_name" == *"$ppt_file_ext" ]]; then
  IFS='.' read -r ppt_name string <<< "$ppt_name"
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
IFS='.' read -r svg_name string <<< "$svg_name_with_ext"

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

# Write filepath of SVG and PPT to input file for Libre Office to read
printf "$file_uri_prefix$svg_filepath\n$file_uri_prefix$ppt_filepath\n" > $libre_office_input_filepath

if [ "$stop_creations" != true ]; then
  if [ ! -z $where_to_open ]; then
    open_cmd="open -a $where_to_open $ppt_filepath"
    eval $open_cmd
  fi

  # Launch the template PPT with Libre Office and kick off macro
  libre_office_cmd="/Applications/LibreOffice.app/Contents/MacOS/soffice --invisible --headless $template_ppt_filepath \"vnd.sun.star.script:Standard.SVGtoPPT.Main?language=Basic&location=application\""
  eval $libre_office_cmd
fi

# Launch the new PPT file if where_to_open is defined
if [ ! -z $where_to_open ]; then
  open_cmd="open -a $where_to_open $ppt_filepath"
  # eval $open_cmd
fi

if [ "$debug" == true ]; then
  printf "\n~OUTPUT FOR DEBUGGING~\n\n"
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
  echo_var libre_office_input_filepath
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

  printf "\n~END~\n\n"
fi
