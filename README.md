<p align="center">
  <img id="logo" src="logo.svg" class="center" alt="SVG to Keynote logo" title="SVG to Keynote logo" />
</p>

# SVG to Keynote

## About

A [scalable vector graphic](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) (SVG) is an image format that enables infinite scaling without pixelation, unlike [raster graphic formats](https://en.wikipedia.org/wiki/Raster_graphics) like JPEG and PNG.

In 2005, David Astling published a [script](http://mcb.berkeley.edu/labs/zusman/dave/svg2key/) that could convert SVG files to Keynote shapes. This application doesn't run on newer versions of macOS and is no longer supported.

In 2016, Kyle Ledbetter posted [this article](https://kyleledbetter.medium.com/how-to-import-an-svg-into-powerpoint-or-keynote-8d3d70f347a7) outlining how to import SVG files into Keynote or Powerpoint. As noted by [others](https://medium.com/@chrishoman_15983/i-often-encounter-problems-with-opening-files-created-with-openoffice-and-i-found-libreoffice-a-5a72f652160f), using Libre Office for this process is more stable and has less quirks.

To make this process more viable for people who regularly need SVG files in Keynote, I made this Alfred workflow to automate it. It doesn't necessarily save a lot of time, but it does save human energy & sanity.

If you would like native support for SVG files and other vector formats in Keynote, I recommend [sending Apple feedback](https://www.apple.com/feedback/keynote.html).

## Prerequisites

- [Alfred Powerpack](https://www.alfredapp.com/shop/)
- [Keynote](https://apps.apple.com/us/app/keynote/id409183694) (tested with `10.3.9`)
- [Libre Office](https://www.libreoffice.org/download/download/) (tested with `7.0.4.2`)
  - Workflow contains automated installation 🙂

## Getting Started

1. If you haven't yet, download & install Alfred with the button on [their homepage](https://www.alfredapp.com/)
2. Download the [Alfred workflow file](https://github.com/blakegearin/svg-to-keynote/raw/main/svgtokeynote.alfredworkflow) for SVG to Keynote
3. Double-click the workflow file to open it in Alfred > Import
4. Launch Alfred (default is `Cmd` + `Space`)
5. Do you have Libre Office installed?

   - **No:** Install Libre Office and the directory: `svg install complete`

   - **Yes:** Install only the directory: `svg install dir`

## Usage

- Launch Alfred then type `svg`, a space, and the name of your SVG file. Select your file from Alfred's search results, then **wait** as the workflow will start opening Libre Office and clicking buttons for you.
