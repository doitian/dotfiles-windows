[xml]$theme = Get-Content $args[0]
$name = Split-Path -LeafBase $args[0]
$dict = $theme.plist.dict

$PuttyColors = @{
  "Colour0" = "Foreground Color"
  "Colour1" = "Bold Color"
  "Colour2" = "Background Color"
  "Colour3" = "Background Color"
  "Colour4" = "Cursor Text Color"
  "Colour5" = "Cursor Color"
  "Colour6" = "Ansi 0 Color"
  "Colour7" = "Ansi 8 Color"
  "Colour8" = "Ansi 1 Color"
  "Colour9" = "Ansi 9 Color"
  "Colour10" = "Ansi 2 Color"
  "Colour11" = "Ansi 10 Color"
  "Colour12" = "Ansi 3 Color"
  "Colour13" = "Ansi 11 Color"
  "Colour14" = "Ansi 4 Color"
  "Colour15" = "Ansi 12 Color"
  "Colour16" = "Ansi 5 Color"
  "Colour17" = "Ansi 13 Color"
  "Colour18" = "Ansi 6 Color"
  "Colour19" = "Ansi 14 Color"
  "Colour20" = "Ansi 15 Color"
  "Colour21" = "Ansi 17 Color"
}

$WindowsTerminalColors = @{
  "background" = "Background Color"
  "foreground" = "Foreground Color"
  "selectionBackground" = "Selection Color"
  "cursorColor" = "Cursor Color"
  "black" = "Ansi 0 Color"
  "red" = "Ansi 1 Color"
  "green" = "Ansi 2 Color"
  "yellow" = "Ansi 3 Color"
  "blue" = "Ansi 4 Color"
  "purple" = "Ansi 5 Color"
  "cyan" = "Ansi 6 Color"
  "white" = "Ansi 15 Color"
  "brightBlack" = "Ansi 8 Color"
  "brightRed" = "Ansi 9 Color"
  "brightGreen" = "Ansi 10 Color"
  "brightYellow" = "Ansi 11 Color"
  "brightBlue" = "Ansi 12 Color"
  "brightPurple" = "Ansi 13 Color"
  "brightCyan" = "Ansi 14 Color"
  "brightWhite" = "Ansi 7 Color"
}

$colors = @{}

$i = 0
foreach ($key in $dict.key) {
  $color = $dict.dict[$i]
  $blue = [Math]::Floor([double]$color.real[1] * 255)
  $green = [Math]::Floor([double]$color.real[2] * 255)
  $red = [Math]::Floor([double]$color.real[3] * 255)

  $colors[$key] = @([int]$red, [int]$green, [int]$blue)

  ++$i
}

echo "==> WindowsTerminal"
echo ('"name": "{0}",' -f $name)
foreach ($item in $WindowsTerminalColors.GetEnumerator()) {
  $red, $green, $blue = $colors[$item.Value]
  echo ('"{0}": "#{1:x2}{2:x2}{3:x2}",' -f $item.Name, $red, $green, $blue)
}

echo ""
echo "==> Putty"
foreach ($item in $PuttyColors.GetEnumerator()) {
  $red, $green, $blue = $colors[$item.Value]
  echo ('"{0}"="{1},{2},{3}"' -f $item.Name, $red, $green, $blue)
}
