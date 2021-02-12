<p align="center">
  <img id="logo" src="logo.svg" class="center" alt="SVG to Keynote logo" title="SVG to Keynote logo" />
</p>

# SVG to Keynote

## About



In 2016, Kyle Ledbetter posted [this how-to article](https://kyleledbetter.medium.com/how-to-import-an-svg-into-powerpoint-or-keynote-8d3d70f347a7) outlining how to import SVG files into Keynote or Powerpoint. As noted by [others](https://medium.com/@chrishoman_15983/i-often-encounter-problems-with-opening-files-created-with-openoffice-and-i-found-libreoffice-a-5a72f652160f), using Libre Office for this process is more stable and has less quirks.

To make this process more viable for people who regularly need SVG files in Keynote, I made this Alfred workflow to automate it. It doesn't necessarily save a lot of time, but it does save energy & sanity.

If you would like native support for vectors in Keynote, I'd recommend [sending Apple feedback](https://www.apple.com/feedback/keynote.html).

## Prerequisites

- [Alfred Powerpack](https://www.alfredapp.com/shop/)
- [Keynote](https://apps.apple.com/us/app/keynote/id409183694) (tested with `10.3.9`)
- [Libre Office](https://www.libreoffice.org/download/download/) (tested with `7.0.4.2`)
  - Workflow contains automated installation 🙂

## Usage

- Download the Alfred workflow file
- Double-click file to open in Alfred > Import
- Launch Alfred (default is `Cmd` + `Space`)
- Do you have Libre Office installed?
  - **No:** Install Libre Office and the directory: `svg install complete`
  - **Yes:** Install only the directory: `svg install dir`
-
