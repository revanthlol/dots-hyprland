#!/usr/bin/env bash

CONFIG_FILE="$HOME/.config/illogical-impulse/config.json"
JSON_PATH=".screenRecord.savePath"

CUSTOM_PATH=$(jq -r "$JSON_PATH" "$CONFIG_FILE" 2>/dev/null)

RECORDING_DIR=""

if [[ -n "$CUSTOM_PATH" && "$CUSTOM_PATH" != "null" ]]; then
    RECORDING_DIR="$CUSTOM_PATH"
else
    RECORDING_DIR="$HOME/Videos" # Use default path
fi

getdate() {
    date '+%Y-%m-%d_%H.%M.%S'
}
getaudiooutput() {
    pactl list sources | grep 'Name' | grep 'monitor' | cut -d ' ' -f2 | head -n1
}
getactivemonitor() {
    hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name'
}
slurp_to_gsr_region() {
    awk -F '[, x]' '{ printf "%sx%s+%s+%s", $3, $4, $1, $2 }' <<< "$1"
}
recorder_is_running() {
    pgrep -f '(^|/)gpu-screen-recorder( |$)' >/dev/null
}
stop_recorder() {
    pkill -INT -f '(^|/)gpu-screen-recorder( |$)'
}

mkdir -p "$RECORDING_DIR"
cd "$RECORDING_DIR" || exit

# parse --region <value> without modifying $@ so other flags like --fullscreen still work
ARGS=("$@")
MANUAL_REGION=""
SOUND_FLAG=0
FULLSCREEN_FLAG=0
for ((i=0;i<${#ARGS[@]};i++)); do
    if [[ "${ARGS[i]}" == "--region" ]]; then
        if (( i+1 < ${#ARGS[@]} )); then
            MANUAL_REGION="${ARGS[i+1]}"
        else
            notify-send "Recording cancelled" "No region specified for --region" -a 'Recorder' & disown
            exit 1
        fi
    elif [[ "${ARGS[i]}" == "--sound" ]]; then
        SOUND_FLAG=1
    elif [[ "${ARGS[i]}" == "--fullscreen" ]]; then
        FULLSCREEN_FLAG=1
    fi
done

if recorder_is_running; then
    notify-send "Recording Stopped" "Stopped" -a 'Recorder' &
    stop_recorder &
else
    filename='./recording_'"$(getdate)"'.mp4'
    args=(-c mp4 -f 60 -q very_high -tune quality -cursor yes -o "$filename")
    if [[ $SOUND_FLAG -eq 1 ]]; then
        args+=(-a "$(getaudiooutput)")
    fi

    if [[ $FULLSCREEN_FLAG -eq 1 ]]; then
        notify-send "Starting recording" "$filename" -a 'Recorder' & disown
        gpu-screen-recorder -w "$(getactivemonitor)" "${args[@]}"
    else
        # If a manual region was provided via --region, use it; otherwise run slurp as before.
        if [[ -n "$MANUAL_REGION" ]]; then
            region="$MANUAL_REGION"
        else
            if ! region="$(slurp 2>&1)"; then
                notify-send "Recording cancelled" "Selection was cancelled" -a 'Recorder' & disown
                exit 1
            fi
        fi

        notify-send "Starting recording" "$filename" -a 'Recorder' & disown
        gpu-screen-recorder -w region -region "$(slurp_to_gsr_region "$region")" "${args[@]}"
    fi
fi
