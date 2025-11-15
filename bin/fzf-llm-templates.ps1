# fzf script to select a template from a text file and return its name

# Read all lines from the template file and pipe to fzf
$selected_template = llm templates list | fzf

# Exit if no selection was made
if ([string]::IsNullOrEmpty($selected_template)) {
    Write-Error "No template selected"
    exit 1
}

# Extract the name before colon (with any number of surrounding spaces)
# Split on colon and trim whitespace from the first part
$template_name = ($selected_template -split ":" | Select-Object -First 1).Trim()

# Output the template name
Write-Output $template_name
exit 0
