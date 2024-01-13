#!/bin/bash

# Replace with your actual root directory path
rootDirectory="/data/media/anime"
logFile="ffmpeg_log.txt"

# Set increased values for the 'analyzeduration' and 'probesize' options
analyzeduration_value="10000000" # Adjust as needed
probesize_value="10000000"       # Adjust as needed

# Function to process a show and its seasons
process_show() {
    local showPath="$1"
    echo "Processing show: $(basename "$showPath")"

    # Loop through each season in the show
    for seasonPath in "$showPath"/*; do
        # Check if the season path is a directory
        if [ -d "$seasonPath" ]; then
            process_season "$seasonPath"
        fi
    done
}

# Function to process a season and its episodes
process_season() {
    local seasonPath="$1"
    echo "  Processing season: $(basename "$seasonPath")"

    # Loop through all .mkv files in the season
    for inputFile in "$seasonPath"/*.mkv; do
        # Check if the file is an actual file
        if [ -f "$inputFile" ]; then
            process_episode "$inputFile"
        fi
    done
}

# Function to process an episode and extract subtitles
process_episode() {
    local inputFile="$1"
    echo "    Processing episode: $(basename "$inputFile")"

    # Run mediainfo and capture the relevant information
    mediainfoOutput=$(mediainfo --Output=JSON "$inputFile")

    # Array to store parsed subtitle information
    declare -a subtitleInfoArray

    # Parse all subtitle tracks and store the information in the array
    while IFS= read -r line; do
        streamOrder=$(echo "$line" | jq -r '.StreamOrder' || echo "")
        format=$(echo "$line" | jq -r '.Format' || echo "")
        title=$(echo "$line" | jq -r '.Title' || echo "")
        language=$(echo "$line" | jq -r '.Language' || echo "")

        # Check if the subtitle format is ASS or SSA (you can add more formats if needed)
        if [ "$format" == "ASS" ] || [ "$format" == "SSA" ]; then
            subtitleInfoArray+=("$streamOrder" "$format" "$title" "$language")
        else
            echo "      Skipping subtitle track with format: $format"
        fi
    done <<< "$(echo "$mediainfoOutput" | jq -c '.media.track[] | select(.["@type"] == "Text") | { StreamOrder: .StreamOrder, Format: .Format, Title: .Title, Language: .Language }')"

    # Iterate over the parsed subtitle information array
    for ((i = 0; i < ${#subtitleInfoArray[@]}; i += 4)); do
        streamOrder="${subtitleInfoArray[i]}"
        format="${subtitleInfoArray[i + 1]}"
        title="${subtitleInfoArray[i + 2]}"
        language="${subtitleInfoArray[i + 3]}"

        # Construct the output filename using the subtitle title and language
        outputFileName=$(basename "${inputFile%.*}.$title.$language.ass")

        # Check if the file already exists, and if so, skip to the next subtitle stream
        if [ -e "$seasonPath/$outputFileName" ]; then
            echo "      Skipping existing subtitle file: $outputFileName"
            continue
        fi

        # Debug information
        echo "      Parsed subtitle JSON data: { StreamOrder: $streamOrder, Format: $format, Title: $title, Language: $language }"
        echo "      Running ffmpeg command:"
        echo "      ffmpeg -analyzeduration $analyzeduration_value -probesize $probesize_value -i $inputFile -copyts -map 0:$streamOrder -an -vn -c:s copy $seasonPath/$outputFileName >> $logFile 2>&1"

        # Run ffmpeg command to extract the subtitle and log the output
        ffmpeg -analyzeduration "$analyzeduration_value" -probesize "$probesize_value" -i "$inputFile" -copyts -map 0:"$streamOrder" -an -vn -c:s copy "$seasonPath/$outputFileName" >> "$logFile" 2>&1

        # Check the exit status of the ffmpeg command
        if [ $? -eq 0 ]; then
            echo "      Subtitle extraction successful"
        else
            echo "      Subtitle extraction failed"
        fi
    done

    # Clear the subtitleInfoArray for the next iteration
    subtitleInfoArray=()
}

# Main loop to process shows in the root directory
for showPath in "$rootDirectory"/*; do
    # Check if the show path is a directory
    if [ -d "$showPath" ]; then
        process_show "$showPath"
    fi
done
