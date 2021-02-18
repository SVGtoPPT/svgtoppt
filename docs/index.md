<p align="center">
  <img src="img/svg-to-ppt-logo.svg" class="center" alt="SVG to PPT logo" title="SVG to PPT logo" width="500" height="500"/>
</p>

# Home

A [scalable vector graphic](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) (SVG) is an image format that enables infinite scaling without pixelation, unlike [raster graphic formats](https://en.wikipedia.org/wiki/Raster_graphics) like JPEG and PNG. Apple Keynote and Microsoft PowerPoint don't support SVG files natively, though they have "shapes" that are vectors.

In 2005, David Astling published a [script](http://mcb.berkeley.edu/labs/zusman/dave/svg2key/) that could convert SVG files to Keynote shapes. This application doesn't run on newer versions of macOS (likely due to being 32-bit) and is no longer supported.

In 2016, Kyle Ledbetter posted [this article](https://kyleledbetter.medium.com/how-to-import-an-svg-into-powerpoint-or-keynote-8d3d70f347a7) outlining how to import SVG files into Keynote or Powerpoint by using [PPT files](https://www.lifewire.com/ppt-file-2622187) (Microsoft PowerPoint 97-2003) as a middleman. As noted by [others](https://medium.com/@chrishoman_15983/i-often-encounter-problems-with-opening-files-created-with-openoffice-and-i-found-libreoffice-a-5a72f652160f), I found Libre Office to be more stable with less quirks.

To make the process more viable for people like me who regularly want SVG files in Keynote, I made an [Alfred workflow](https://www.alfredapp.com/workflows/) to automate it. Then I was able to generalize it into a bash script and a [Libre Office macro](https://help.libreoffice.org/latest/en-US/text/shared/01/06130000.html).

If you would like native support for SVG files and other vector formats in Keynote, I recommend [sending Apple feedback](https://www.apple.com/feedback/keynote.html).

## Prerequisites

- [macOS](https://www.apple.com/macos), primarily tested with `10.15.7`
- [Libre Office](https://www.libreoffice.org/download/download/)
    - Primarily tested with `7.0.4.2` and `7.1.0`
    - Automated installation for `7.1.0` included 🙂

## Flavors

<div id="flavors" align="center">
  <span>
    <a href="cli">
      CLI
      <img id="alfred-logo" src="img/iterm2-icon.svg" class="center" alt="iTerm2 icon" title="iTerm2 icon"/>
    </a>
  </span>
  <span>
    <a href="alfred">
      Alfred
      <img id="alfred-logo" src="img/alfred-icon.svg" class="center" alt="Alfred icon" title="Alfred icon"/>
    </a>
  </span>
</div>

## Works With

<div id="works-with" align="center">
  <span>
    <a href="https://apps.apple.com/us/app/keynote/id409183694">
      Apple<br>Keynote
    </a>
    <img id="alfred-logo" src="img/keynote-icon.svg" class="center" alt="Keynote icon" title="Keynote icon"/>
    <span>Primarily tested with <code>10.3.9</code></span>
  </span>
  <span>
    <a href="https://www.microsoft.com/en-us/microsoft-365/powerpoint">
      Microsoft<br>PowerPoint
    </a>
    <img id="alfred-logo" src="img/powerpoint-icon.svg" class="center" alt="Powerpoint icon" title="Powerpoint icon"/>
    <span>Primarily tested with <code>16.46</code></span>
  </span>
  <span>
    <a href="https://www.openoffice.org">
      Apache<br>OpenOffice
    </a>
    <img id="alfred-logo" src="img/open-office-icon.svg" class="center" alt="OpenOffice icon" title="OpenOffice icon"/>
    <span>Primarily tested with <code>4.1.8</code></span>
  </span>
</div>

<style>
  #flavors > span {
    display: inline-block;
    width: 200px;
    margin-bottom: 20px;
  }
  #flavors img {
    width: 200px;
    height: 200px;
    margin: 10px;
  }

  #works-with span {
    display: inline-block;
  }
  #works-with > span {
    width: 150px;
    margin-bottom: 30px;
  }
  #works-with img {
    width: 150px;
    height: 150px;
    margin: 10px;
  }

  @media only screen and (min-width: 768px) {
    #flavors > span {
      margin: 0 50px 0 0;
    }
    #works-with > span {
      margin: 0 50px 0 0;
    }
  }
</style>

## Known Issues

| Issue | Resolution |
|--|--|
| Fonts don't transfer well from SVG to PPT to Keynote | Convert text to curves/outlines/paths when exporting your SVG |
| Gradients displays fine in Libre Office but when opening the PPT file in Keynote it's gone | Recreate the gradient with Keynote's [native gradient fill](https://support.apple.com/en-us/HT210063) or save your content as a PDF file and drag & drop into Keynote to retain your original gradient |
| Background rectangle displays fine in Libre Office but when opening the PPT file in Keynote the rectangle is small | Resize rectangle or use Keynote's [native background color](https://support.apple.com/en-us/HT211077) on your slides |  |  |

## Credits

- Publisher of the conversion process: Kyle Ledbetter ([Twitter](https://twitter.com/kyleledbetter), [Website](https://kyleledbetter.com/))
- Libre Office support: [The Document Foundation](https://www.documentfoundation.org/) and [Libre Office contributors](https://www.libreoffice.org/community/community-map/)
- Website theme: [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/)
- Font in branding: [Morro by Great Scott](https://www.greatscott.se/fonts/morro)
- Alfred developers: [Running with Crayons Ltd](http://runningwithcrayons.net/), founded by [Andrew Pepperrell](https://twitter.com/preppeller) and [Vero Pepperrell](https://twitter.com/vero)
