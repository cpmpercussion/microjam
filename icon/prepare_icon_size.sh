#!/bin/sh

base=$1

# iPad/iPhone Notifications
convert "$base" -resize '20x20'     -unsharp 1x4 "Icon-20.png"
convert "$base" -resize '40x40'     -unsharp 1x4 "Icon-20@2x.png"
convert "$base" -resize '60x60'     -unsharp 1x4 "Icon-20@3x.png"

# iPad/iPhone Settings
convert "$base" -resize '29x29'     -unsharp 1x4 "Icon-29.png"
convert "$base" -resize '58x58'     -unsharp 1x4 "Icon-29@2x.png"
convert "$base" -resize '87x87'     -unsharp 1x4 "Icon-29@3x.png"

# iPad/iPhone Spotlight
convert "$base" -resize '40x40'     -unsharp 1x4 "Icon-40.png"
convert "$base" -resize '80x80'     -unsharp 1x4 "Icon-40@2x.png"
convert "$base" -resize '120x120'   -unsharp 1x4 "Icon-40@3x.png"

# iPhone App
convert "$base" -resize '60x60'     -unsharp 1x4 "Icon-60.png"
convert "$base" -resize '120x120'   -unsharp 1x4 "Icon-60@2x.png"
convert "$base" -resize '180x180'   -unsharp 1x4 "Icon-60@3x.png"

# iPad App
convert "$base" -resize '76x76'     -unsharp 1x4 "Icon-76.png"
convert "$base" -resize '152x152'   -unsharp 1x4 "Icon-76@2x.png"
convert "$base" -resize '228x228'   -unsharp 1x4 "Icon-76@3x.png"

# iPad Pro App
convert "$base" -resize '167x167'   -unsharp 1x4 "Icon-83-5@2x.png"

# App Store
convert "$base" -resize '1024x1024'  -unsharp 1x4 "AppStore-1024.png"
