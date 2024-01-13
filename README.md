# Anime Subtitle Extractor for ASS/SSA formats

## Overview

The Anime Subtitle Extractor is a bash script designed to automate the extraction of subtitles from anime episodes in Matroska (.mkv) format. The script utilizes [ffmpeg](https://ffmpeg.org/) and [mediainfo](https://mediaarea.net/en/MediaInfo) to process anime episodes, identify subtitle tracks, and extract ASS or SSA format subtitles.

## Features

- Recursive processing of a specified root directory containing anime shows and seasons.
- Extraction of ASS or SSA format subtitles from Matroska (.mkv) files.
- Progress messages for each show, season, and episode being processed.

## Requirements

- [ffmpeg](https://ffmpeg.org/): A powerful multimedia processing tool.
- [mediainfo](https://mediaarea.net/en/MediaInfo): A convenient unified display of the most relevant technical and tag data for video and audio files.

## Usage

1. Clone the repository:

   ```bash
   git clone https://github.com/miandru/anime-subtitle-extractor.git
   ```

2. Change into the repository directory:

   ```bash
   cd anime-subtitle-extractor
   ```

3. Make the script executable:

   ```bash
   chmod +x anime_subtitle_extractor.sh
   ```

4. Edit the script to set the correct values for `rootDirectory`, `analyzeduration_value`, `probesize_value`, and other parameters according to your setup.
   This is the expected folder structure `/data/media/anime/season/episode.mkv`


6. Run the script:

   ```bash
   ./anime_subtitle_extractor.sh
   ```

   The script will process each anime show, season, and episode within the specified root directory, extracting subtitles from Matroska files.

## Configuration

- `rootDirectory`: The root directory containing anime shows and seasons.
- `analyzeduration_value`: Set the value for the 'analyzeduration' option in ffmpeg (adjust as needed).
- `probesize_value`: Set the value for the 'probesize' option in ffmpeg (adjust as needed).
- `logFile`: The log file where ffmpeg commands and their outputs will be logged.

## Notes

- Make sure to have the required dependencies (ffmpeg and mediainfo) installed on your system.

- The script assumes a directory structure where shows contain seasons, and each season contains episodes.

- Currently, the script is configured to extract subtitles in ASS or SSA format. You can customize the script to support additional subtitle formats if needed.

Feel free to contribute to the project or report any issues [here](https://github.com/yourusername/anime-subtitle-extractor/issues). Happy anime subtitle extracting!
