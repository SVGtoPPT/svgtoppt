# before=$(set -o posix; set | sort);

input_svg=$1

# Set defaults
application_directory=~/svg-to-keynote
output_directory=~/svg-to-keynote/Output
template_ppt_filepath=~/svg-to-keynote/template.ppt
libre_office_input_filepath=$application_directory/.input
force_ppt=false
keynote_open=true

# Helpful strings
svg_file_ext=.svg
ppt_file_ext=.ppt
file_uri_prefix=file://

# Check for flags overwriting defaults
while getopts a:f:i:k:o:p:t: option
do
  case "${option}"
  in
    a) application_directory=${OPTARG};;
    f) force_ppt=${OPTARG};;
    i) input_svg=${OPTARG};;
    k) keynote_open=${OPTARG};;
    o) output_directory=${OPTARG};;
    p) ppt_name=${OPTARG};;
    t) input_template_ppt=${OPTARG};;
  esac
done

# Check if first parameter ends in .svg
if [[ "$input_svg" != *"$svg_file_ext" ]]; then
  echo "Input error: SVG file not passed in as the first parameter or using the -i flag"
  exit 2
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
if [ ! -z $input_template_ppt ]; then
  if test -f $PWD/$input_template_ppt; then
    template_ppt_filepath=$PWD/$input_template_ppt
  elif test -f $input_template_ppt; then
    template_ppt_filepath=$input_template_ppt
  else
    echo "Input error: Can't find template PPT file $input_template_ppt"
    exit 2
  fi
fi

# Ensure force_ppt has true or false value
if [ "$force_ppt" != true ] && [ "$force_ppt" != false ]; then
  echo "Input error: Force PPT flag (-f) should only be set to true or false"
  exit 2
fi

# Set flag-dependent defaults
## SVG-related
svg_name_with_ext=${input_svg##*/}
IFS='.' read -r svg_name string <<< "$svg_name_with_ext"

## PPT-related
if [ -z $ppt_name ]; then
  ppt_name=$svg_name
fi
ppt_filepath=$output_directory/$ppt_name$ppt_file_ext

if [ "$force_ppt" != true ] && [ -f $ppt_filepath ]; then
  while [ -f $ppt_filepath ]
  do
    if [ -z $ppt_name_suffix ]; then
      ppt_name_suffix=-1
    else
      ppt_name_suffix=$((ppt_name_suffix-1))
    fi

    ppt_filepath=$output_directory/$ppt_name$ppt_name_suffix$ppt_file_ext
  done
  printf "$ppt_name$ppt_file_ext already exists in $output_directory, so creating $ppt_name$ppt_name_suffix$ppt_file_ext\n"
else
  printf "Going with $ppt_filepath\n\n"
fi

# Write filepath of SVG and PPT to input file for Libre Office to read
printf "$file_uri_prefix$svg_filepath\n$file_uri_prefix$ppt_filepath\n" > $libre_office_input_filepath

# Launch the template PPT with Libre Office and kick off macro
/Applications/LibreOffice.app/Contents/MacOS/soffice --invisible --headless $template_ppt_filepath "vnd.sun.star.script:Standard.SVGtoKeynote.Main?language=Basic&location=application"

# Launch the new PPT file with Keynote
open -a Keynote $ppt_filepath



printf "# DEFAULTS\n"
c=(
  application_directory
  output_directory
  libre_office_input_filepath
)
for i in "${c[@]}"; do echo "$i : ${!i}"; done

printf "\n# SVG\n"
c=(
  input_svg
  svg_name_with_ext
  svg_name
  svg_filepath
)
for i in "${c[@]}"; do echo "$i : ${!i}"; done

printf "\n# PPT/KEYNOTE\n"
c=(
  template_ppt_filepath
  ppt_name
  ppt_name_suffix
  ppt_filepath
  force_ppt
  keynote_open
)
for i in "${c[@]}"; do echo "$i : ${!i}"; done

# comm -13 <(printf %s "$before") <(set -o posix; set | sort | uniq)
