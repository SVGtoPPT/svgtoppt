# SVG to PPT with Alfred

## Prerequisites

- [Alfred Powerpack](https://www.alfredapp.com/shop/)
  - Current prices: £29 for single license / £49 for mega supporter (free lifetime upgrades)
  - Primarily tested with `4.3.1`

## Getting Started

1. If you haven't yet, download & install Alfred with the button on [their homepage](https://www.alfredapp.com/)
2. Download the [Alfred workflow file](https://github.com/blakegearin/svg-to-keynote/raw/main/svg-to-keynote.alfredworkflow) (`svg-to-keynote.alfredworkflow`) for SVG to Keynote

### Install

1. Double-click the workflow file  to open it in Alfred, then select Import
2. Launch Alfred (default is `Cmd` + `Space`)
3. Do you have Libre Office installed?

   - **No:** Install Libre Office and the basics: `svg install complete`

   - **Yes:** Install just the application basics: `svg install basics`

#### Usage

1. Launch Alfred (default is `Cmd` + `Space`)
2. Type `svg`, a space, and the name of your SVG file
3. Select your file from Alfred's search results
4. Workflow will work in the background and open Keynote when finished
5. Select all vectors `Ctrl` + `A`
6. Copy (`Ctrl` + `C`) and paste (`Ctrl` + `V`) shapes to other Keynote presentations

## Notes

- Edit the workflow environment variables if you'd like

    | Variable Name         | Default Value                 | Description                                           |
    | --------------------- | ----------------------------- | ----------------------------------------------------- |
    | application_directory | ~/svg-to-keynote              | Default location of output directory and template PPT |
    | output_directory      | ~/svg-to-keynote/Output       | Where the resultant PPT files are saved               |
    | template_ppt_path     | ~/svg-to-keynote/template.ppt | File path to the template PPT                         |

- DIY Libre Office installation by going to [their homepage](https://www.libreoffice.org/download/download/) **OR** using Homebrew

    ```bash
    # Install Homebrew if you haven't already
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Install Libre Office with Homebrew
    brew install libreoffice
    ```

- Feel free to edit `template.ppt` to your liking; it's a 4K (53.33" x 30.00") blank presentation
