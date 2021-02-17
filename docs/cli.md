# CLI

## Getting Started

1. Clone this repository: `git clone https://github.com/blakegearin/svg-to-keynote.git`
2. Navigate to the new directory: `cd svg-to-keynote`
3. Don't have Libre Office installed? Run: `bash ./install_libre_office`
4. Run the installation file: `bash ./install_svg_to_keynote.sh`
5. Do you have Libre Office installed?

   - **No:** `bash ./src/install_complete.sh`

   - **Yes:** `bash ./src/install_basic.sh`

## Usage

WIP

## Variables

| Variable Name | Flag | Default Value | Description |
|--|--|--|--|
| `input_svg` | `-i` | none; required input | The SVG wanting to be imported into Keynote |
| `application_directory` | `-a` | `~/svg-to-keynote` | Filepath of directory where the output directory and template PPT live |
| `output_directory` | `-o` | `~/svg-to-keynote/Output` | Filepath of the directory where PPT files are output |
| `template_ppt` | `-t` | `~/svg-to-keynote/template.ppt` | Filepath of the template PPT |
| `ppt_name` | `-p` | the name of the SVG file (e.g. `logo.svg` -> `logo.ppt`) | The name of the PPT file that is output |
| `force_ppt` | `-f` | `false` | For `false`, creates a new, unique PPT file each time a command is run (e.g. x.ppt, x-1.ppt, x-2.ppt)<br><br>For `true`, has the potential to overwrite existing PPT files (e.g. same command run twice overwrites x.ppt ) |
| `where_to_open` | `-w` | `keynote` | Where the PPT file is opened in after it's created<br><br>**Options**<br>Don't open: `none`<br> Apple Keynote: `keynote`<br>Microsoft PowerPoint: `power`<br>Libre Office:`libre`<br>Apache OpenOffice: `oo` |

## Examples of Flag Usage

```bash
# -i is required
svgtokeynote -i logo.svg

svgtokeynote -i logo.svg -a ~/Pictures
svgtokeynote -i logo.svg -o ~/Pictures/Output
svgtokeynote -i logo.svg -t ~/Pictures/template.ppt

# By default the output would be logo.ppt; here we can give it another name
svgtokeynote -i logo.svg -p amazing_logo
# Works with or without .ppt
svgtokeynote -i logo.svg -p amazing_logo.ppt

# This command ran twice creates 2 files: logo.ppt and logo-1.ppt
svgtokeynote -i logo.svg -f false
# This command ran twice creates 1 file (logo.ppt) that gets overwritten once
svgtokeynote -i logo.svg -f true

# Creates the PPT file without opening it
svgtokeynote -i logo.svg -w none
# Creates the PPT file and opens it in Microsoft PowerPoint
svgtokeynote -i logo.svg -w power
```

## Notes

- Feel free to edit `template.ppt` to your liking; it's a 4K (53.33" x 30.00") blank presentation

- DIY Libre Office installation by going to [their homepage](https://www.libreoffice.org/download/download/) **OR** using Homebrew

    ```bash
    # Install Homebrew if you haven't already
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Install Libre Office with Homebrew
    brew install libreoffice
    ```
