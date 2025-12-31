# bobthefish theme configuration

# Enable newline cursor (two-line prompt)
set -g theme_newline_cursor yes

# Optional: Customize the prompt character on the new line
# set -g theme_newline_prompt '$ '
set -g theme_newline_prompt \uE0B0' '
set -g theme_show_exit_status yes
set -g theme_display_go 'verbose'
set -g theme_display_k8s_context yes
set -g theme_display_k8s_namespace yes
