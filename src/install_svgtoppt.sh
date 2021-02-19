# Set defaults
application_name=svg-to-ppt
application_directory=~/$application_name
output_directory=$application_directory/Output
template_ppt_filepath=$application_directory/template.ppt
libre_office_input_filepath=~/.$application_name

# Credit: https://stackoverflow.com/a/12900116
whichapp() {
  local appNameOrBundleId=$1 isAppName=0 bundleId
  # Determine whether an app *name* or *bundle id* was specified
  [[ $appNameOrBundleId =~ \.[aA][pP][pP]$ || $appNameOrBundleId =~ ^[^.]+$ ]] && isAppName=1
  if (( isAppName )); then # an application NAME was specified
    # Translate to a bundle id first
    bundleId=$(osascript -e "id of application \"$appNameOrBundleId\"" 2>/dev/null) ||
      { echo "false" 1>&2; return 1; }
  else # a bundle id was specified
    bundleId=$appNameOrBundleId
  fi
    # Let AppleScript determine the full bundle path
  fullPath=$(osascript -e "tell application \"Finder\" to POSIX path of (get application file id \"$bundleId\" as alias)" 2>/dev/null ||
    { echo "$FUNCNAME: ERROR: Application with specified bundle ID not found: $bundleId" 1>&2; return 1; })
  printf '%s\n' "$fullPath"
  # Warn about /Volumes/... paths, because applications launched from mounted devices aren't persistently installed
  if [[ $fullPath == /Volumes/* ]]; then
    echo "NOTE: Application is not persistently installed, due to being located on a mounted volume." >&2
  fi
}

# exit_if_one() {
#   if [[ $1 -eq 1 ]]; then
#     echo "Exiting"
#     exit 1
#   fi
# }

>&2 echo "Starting script"

array=($1)

application_directory=${array[0]/\~/$HOME}
output_directory=${array[1]/\~/$HOME}
template_ppt_path=${array[2]/\~/$HOME}

wget_from_github() {
	/usr/local/bin/wget https://github.com/blakegearin/svg-to-keynote/raw/main/template.ppt -P $template_ppt_directory
	if [[ $? -eq 1 ]]; then
		echo -n "Failed to pull down template.ppt file from GitHub"
	else
		echo -n "true"
	fi
}

fetch_template_ppt() {
	if test -f $template_ppt_path; then
    		>&2 echo "Template PPT already exists: $template_ppt_path"
		echo -n "true"
	else
		template_ppt_directory=${template_ppt_path%?????????????}
		>&2 echo "Pulling down template PPT from GitHub: $template_ppt_path"

		# Check if wget is installed
		if [[ $(command -v /usr/local/bin/wget) == "" ]]; then
			>&2 echo "Installing wget"
			brew install wget

			if [[ $? -eq 1 ]]; then
				echo -n "Failed to install weget with Homebrew"
			else
				>&2 echo "Installed wget"
				wget_from_github
			fi
		else
    			>&2 echo "wget already installed"
			wget_from_github
		fi
	fi
}

create_output_directory() {
	if [ -d $output_directory ]; then
    		>&2 echo "Directory already exists: $output_directory"
		fetch_template_ppt
	else
    		>&2 echo "Creating directories: $output_directory"
		mkdir $output_directory

		if [[ $? -eq 1 ]]; then
			echo -n "Failed to create output directory: $application_directory"
		else
			>&2 echo "Output directory created successfully"
			fetch_template_ppt
		fi
	fi
}

install_basic() {
  echo "Starting basic installation"

  if [ -d $application_directory ]; then
    >&2 echo "Directory already exists: $application_directory"
    create_output_directory
  else
      >&2 echo "Creating directories: $application_directory"
    mkdir $application_directory

    if [[ $? -eq 1 ]]; then
      echo -n "Failed to create application directory: $application_directory"
    else
      >&2 echo "Application directory created successfully"
      create_output_directory
    fi
  fi
}

install_homebrew() {
  homebrew_install_cmd='/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  echo "Starting Homebrew installation: $homebrew_install_cmd"

  eval $homebrew_install_cmd

  if [[ $? -ne 0 ]]; then
    echo "Error installing Homebrew"
    exit 1
  else
    echo "Homebrew installed successfully"
  fi
}

install_libre_office() {
  libre_office_install_cmd="brew install --cask libreoffice"
  echo "Starting Libre Office installation: $libre_office_install_cmd"

  eval $libre_office_install_cmd

  if [[ $? -ne 0 ]]; then
    echo "Error installing Libre Office"
    exit 1
  else
    echo "Libre Office installed successfully"
  fi
}

install_complete() {
  # libre_office_location=false
  libre_office_location=$(whichapp "LibreOffice")
  if [[ "$libre_office_location" != false ]]; then
    echo "Found Libre Office already installed: $libre_office_location"
  else
    homebrew_location=$(command -v brew)

    if [ -z $homebrew_location ]; then
      install_homebrew
    else
      echo "Found Homebrew already installed: $homebrew_location"
    fi

    install_libre_office
  fi

  install_basic
}

install_type=$1

case $install_type in
  basic)      install_basic;;
  complete)  install_complete;;
  *)
    echo "Input error: \"$install_type\" is not a valid install type; should only be: basic, complete"
    exit 2
    ;;
esac
