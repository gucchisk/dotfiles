# Custom fish_right_prompt to display on the first line when using newline cursor
# This overrides bobthefish's default fish_right_prompt

function fish_right_prompt -d 'Display right prompt on first line with newline cursor'
    # Import bobthefish's helper functions and settings
    set -l __bobthefish_left_arrow_glyph \uE0B3
    if [ "$theme_powerline_fonts" = "no" -a "$theme_nerd_fonts" != "yes" ]
        set __bobthefish_left_arrow_glyph '<'
    end

    # When using newline cursor, we want to display the right prompt on the previous line
    if [ "$theme_newline_cursor" = "yes" ] || [ "$theme_newline_cursor" = "clean" ]
        # Save cursor position and move up one line
        echo -en "\e7\e[1A"

        # Build the right prompt content
        set -l right_prompt_content ""

        # Add command duration if available
        if [ "$theme_display_cmd_duration" != "no" ] && [ -n "$CMD_DURATION" ] && [ "$CMD_DURATION" -ge 100 ]
            if [ "$CMD_DURATION" -lt 5000 ]
                set right_prompt_content "$CMD_DURATION"ms
            else if [ "$CMD_DURATION" -lt 60000 ]
                set right_prompt_content (math -s1 "$CMD_DURATION/1000")s
            else if [ "$CMD_DURATION" -lt 3600000 ]
                set right_prompt_content (math -s1 "$CMD_DURATION/60000")m
            else
                set right_prompt_content (math -s2 "$CMD_DURATION/3600000")h
            end

            if [ "$theme_display_date" != "no" ]
                set right_prompt_content "$right_prompt_content $__bobthefish_left_arrow_glyph"
            end
        end

        # Add timestamp
        if [ "$theme_display_date" != "no" ]
            set -q theme_date_format; or set -l theme_date_format "+%c"
            set -l timestamp (date $theme_date_format)
            set right_prompt_content "$right_prompt_content $timestamp"
        end

        # Move cursor to the right position
        set -l prompt_width (string length -- (echo -n $right_prompt_content | string replace -ra '\e\[[0-9;]*m' ''))
        set -l term_width (tput cols)
        set -l move_right (math $term_width - $prompt_width)

        echo -en "\e["$move_right"G"

        # Print the right prompt
        set_color $fish_color_autosuggestion
        echo -n $right_prompt_content
        set_color normal

        # Restore cursor position
        echo -en "\e8"
    else
        # Standard right prompt for non-newline mode
        set_color $fish_color_autosuggestion

        # Command duration
        if [ "$theme_display_cmd_duration" != "no" ] && [ -n "$CMD_DURATION" ] && [ "$CMD_DURATION" -ge 100 ]
            if [ "$CMD_DURATION" -lt 5000 ]
                echo -ns $CMD_DURATION 'ms'
            else if [ "$CMD_DURATION" -lt 60000 ]
                echo -ns (math -s1 "$CMD_DURATION/1000") 's'
            else if [ "$CMD_DURATION" -lt 3600000 ]
                echo -ns (math -s1 "$CMD_DURATION/60000") 'm'
            else
                echo -ns (math -s2 "$CMD_DURATION/3600000") 'h'
            end

            [ "$theme_display_date" = "no" ]; or echo -ns ' ' $__bobthefish_left_arrow_glyph
        end

        # Timestamp
        if [ "$theme_display_date" != "no" ]
            set -q theme_date_format; or set -l theme_date_format "+%c"
            echo -n ' '
            date $theme_date_format
        end

        set_color normal
    end
end
