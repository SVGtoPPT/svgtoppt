<p align="center">
  <img id="logo" src="logo.svg" class="center" alt="SVG to Keynote logo" title="SVG to Keynote logo" />
</p>

# SVG to Keynote

## About

A [scalable vector graphic](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) (SVG) is an image format that enables infinite scaling without pixelation, unlike [raster graphic formats](https://en.wikipedia.org/wiki/Raster_graphics) like JPEG and PNG.

In 2005, David Astling published a [script](http://mcb.berkeley.edu/labs/zusman/dave/svg2key/) that could convert SVG files to Keynote shapes. This application doesn't run on newer versions of macOS and is no longer supported.

In 2016, Kyle Ledbetter posted [this article](https://kyleledbetter.medium.com/how-to-import-an-svg-into-powerpoint-or-keynote-8d3d70f347a7) outlining how to import SVG files into Keynote or Powerpoint by using [PPT files](https://www.lifewire.com/ppt-file-2622187) (Microsoft PowerPoint 97-2003) as a middleman. As noted by [others](https://medium.com/@chrishoman_15983/i-often-encounter-problems-with-opening-files-created-with-openoffice-and-i-found-libreoffice-a-5a72f652160f), using Libre Office to accomplish this more stable and has less quirks.

To make this process more viable for people who regularly need SVG files in Keynote, I made this [Alfred workflow](https://www.alfredapp.com/workflows/) to automate it. It doesn't necessarily save a lot of time, but it does save human energy & sanity.

If you would like native support for SVG files and other vector formats in Keynote, I recommend [sending Apple feedback](https://www.apple.com/feedback/keynote.html).

## Prerequisites

- [Alfred Powerpack](https://www.alfredapp.com/shop/)
- [Keynote](https://apps.apple.com/us/app/keynote/id409183694) (tested with `10.3.9`)
- [Libre Office](https://www.libreoffice.org/download/download/) (tested with `7.0.4.2`)
  - Workflow contains automated installation 🙂

## Getting Started

1. If you haven't yet, download & install Alfred with the button on [their homepage](https://www.alfredapp.com/)
2. Download the [Alfred workflow file](https://github.com/blakegearin/svg-to-keynote/raw/main/svg-to-keynote.alfredworkflow) (`svgtokeynote.alfredworkflow`) for SVG to Keynote

## Install

### Automated

1. Double-click the workflow file  to open it in Alfred, then select Import
2. Launch Alfred (default is `Cmd` + `Space`)
3. Do you have Libre Office installed?

   - **No:** Install Libre Office and the basics: `svg install complete`

   - **Yes:** Install just the basics: `svg install basic`

### Manual/Custom

1. Double-click the workflow file to open it in Alfred
2. Edit the workflow environment variables if you'd like, then select Import

    | Variable Name     | Default Value                 | Description                             |
    | ----------------- | ----------------------------- | --------------------------------------- |
    | output_directory  | ~/svg-to-keynote/Output       | Where the resultant PPT files are saved |
    | template_ppt_path | ~/svg-to-keynote/template.ppt | File path to the template PPT           |

3. If you haven't yet, install your preferred version of Libre Office from [their homepage](https://www.libreoffice.org/download/download/) **OR** using Homebrew

    ```bash
    # Install Homebrew if you haven't already
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Install Libre Office with Homebrew
    brew install libreoffice@7.0.4
    brew install libreoffice@7.1.0
    ```

4. Retrieve the blank PPT file from GitHub and move it to align with `template_ppt_path` as necessary:

    ```bash
    # Install wget if you haven't already
    brew install wget

    # Pull down template
    wget https://github.com/blakegearin/svg-to-keynote/raw/main/template.ppt
    ```

5. Feel free to open `template.ppt` and edit it to your liking; it's a 4K (53.33" x 30.00") blank presentation

## Usage

1. Launch Alfred (default is `Cmd` + `Space`)
2. Type `svg`, a space, and the name of your SVG file
3. Select your file from Alfred's search results
4. **Wait** as the workflow will start opening Libre Office and clicking buttons for you; do **NOT** click away as the workflow will get interrupted and not work
5. When Keynote opens the workflow is finished
6. Select all vectors `Ctrl` + `A`
7. Copy (`Ctrl` + `C`) and paste (`Ctrl` + `V`) shapes to other Keynote presentations

## Notes

### Known Issues

| Issue                                                                                                              | Resolution                                                                                                                   |
| ------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------- |
| Background rectangle displays fine in Libre Office but when opening the PPT file in Keynote the rectangle is small | Resize rectangle or use Keynote's [native background color](https://support.apple.com/en-us/HT211077) feature on your slides |
| Fonts don't transfer well from SVG to PPT to Keynote                                                               | Convert text to curves/outlines/paths when exporting your SVG                                                                |

### Credits

- Publisher of this process: Kyle Ledbetter ([Twitter](https://twitter.com/kyleledbetter), [Website](https://kyleledbetter.com/))
- PPT support: [The Document Foundation](https://www.documentfoundation.org/) and [Libre Office contributors](https://www.libreoffice.org/community/community-map/)
- Alfred development: [Running with Crayons Ltd](http://runningwithcrayons.net/), founded by [Andrew Pepperrell](https://twitter.com/preppeller) and [Vero Pepperrell](https://twitter.com/vero)
- Font in logo: [Morro by Great Scott](https://www.greatscott.se/fonts/morro)
