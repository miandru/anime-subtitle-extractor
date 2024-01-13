#!/bin/bash

# Replace with your actual root directory path
rootDirectory="/data/media/anime"
processedShowsFile="processed_shows.txt"
logFile="ffmpeg_log.txt"
maxProcesses=4  # Number of files to process concurrently

# Set increased values for the 'analyzeduration' and 'probesize' options
analyzeduration_value="10000000" # Adjust as needed
probesize_value="10000000"       # Adjust as needed
# Function to process a show and its seasons
forceProcessing="false"

# Check for the --force option
while [[ $# -gt 0 ]]; do
    case "$1" in
        --force)
            forceProcessing="true"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

process_show() {
    local showPath="$1"
    local showName=$(basename "$showPath")

    # Check if the show has been processed before
    if [ "$forceProcessing" != "true" ] && grep -Fq "$showName" "$processedShowsFile"; then
        echo "Show $showName already processed. Skipping."
        return
    fi

    echo "Processing show: $showName"

    # Loop through each season in the show
    for seasonPath in "$showPath"/*; do
        # Check if the season path is a directory
        if [ -d "$seasonPath" ]; then
            process_season "$seasonPath"
        fi
    done

    # Mark the show as processed
    echo "$showName" >> "$processedShowsFile"
}

# Function to process a season and its episodes
process_season() {
    local seasonPath="$1"
    echo "  Processing season: $(basename "$seasonPath")"

    # Array to store episode files
    episodeFiles=()

    # Loop through all .mkv files in the season and store them in the array
    for inputFile in "$seasonPath"/*.mkv; do
        # Check if the file is an actual file
        if [ -f "$inputFile" ]; then
            episodeFiles+=("$inputFile")
        fi
    done

    # Process episodes concurrently
    process_episodes_concurrently "${episodeFiles[@]}"
}
# Function to process episodes concurrently
process_episodes_concurrently() {
    local episodes=("$@")
    local episodeCount=${#episodes[@]}
    local processCount=0
    local pidArray=()

    for ((i = 0; i < episodeCount; i++)); do
        process_episode "${episodes[i]}" &
        pidArray+=($!)

        # Limit the number of concurrent processes
        processCount=$((processCount + 1))
        if [ "$processCount" -eq "$maxProcesses" ] || [ "$i" -eq "$((episodeCount - 1))" ]; then
            wait "${pidArray[@]}"
            processCount=0
            pidArray=()
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
            # Always add the subtitle information to the array
            subtitleInfoArray+=("$streamOrder" "$format" "$title" "$language")
        else
            echo -e "      \e[93mSkipping subtitle track with format: $format\e[0m"  # Yellow color
        fi
    done <<< "$(echo "$mediainfoOutput" | jq -c '.media.track[] | select(.["@type"] == "Text") | { StreamOrder: .StreamOrder, Format: .Format, Title: .Title, Language: .Language }')"

    # Iterate over the parsed subtitle information array
    for ((i = 0; i < ${#subtitleInfoArray[@]}; i += 4)); do
        streamOrder="${subtitleInfoArray[i]}"
        format="${subtitleInfoArray[i + 1]}"
        title="${subtitleInfoArray[i + 2]}"
        language="${subtitleInfoArray[i + 3]}"

        # Sanitize the title by replacing '/' with underscores
        sanitizedTitle=$(echo "$title" | sed 's/\//_/g')

        # Construct the output filename using the sanitized subtitle title and language
        outputFileName=""
        if [ "$title" != "null" ]; then
            outputFileName=$(basename "${inputFile%.*}.$sanitizedTitle.$language.ass")
        else
            outputFileName=$(basename "${inputFile%.*}.$language.ass")
        fi

        # Check if the file already exists, and if so, skip to the next subtitle stream
        if [ -e "$seasonPath/$outputFileName" ]; then
            echo -e "      \e[93mSkipping existing subtitle file: $outputFileName\e[0m"  # Yellow color
            continue
        fi

        # Debug information
        echo -e "      Episode: \e[96m$(basename "$inputFile")\e[0m"  # Cyan color
        echo -e "      Parsed subtitle JSON data: { StreamOrder: $streamOrder, Format: $format, Title: $title, Language: $language }"
        echo -e "      Constructed output filename: \e[92m$outputFileName\e[0m"  # Green color
        echo -e "      Running ffmpeg command:"
        echo -e "      ffmpeg -analyzeduration $analyzeduration_value -probesize $probesize_value -i $inputFile -copyts -map 0:$streamOrder -an -vn -c:s copy $seasonPath/$outputFileName >> $logFile 2>&1"

        # Run ffmpeg command to extract the subtitle and log the output
        ffmpeg -analyzeduration "$analyzeduration_value" -probesize "$probesize_value" -i "$inputFile" -copyts -map 0:"$streamOrder" -an -vn -c:s copy -threads 12 "$seasonPath/$outputFileName" >> "$logFile" 2>&1

        # Check the exit status of the ffmpeg command
        if [ $? -eq 0 ]; then
            echo -e "      \e[92mSubtitle extraction successful\e[0m"  # Green color
        else
            echo -e "      \e[91mSubtitle extraction failed\e[0m"  # Red color
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
# Remove duplicate entries from processed_shows.txt
awk '!seen[$0]++' "$processedShowsFile" > "$processedShowsFile.tmp" && mv "$processedShowsFile.tmp" "$processedShowsFile"
