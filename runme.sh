#!/bin/bash

if [ "$1" = "--prepare-env" ]; then
  DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
  mkdir -p ~/Scripts

  echo "Copying the script to $HOME/Scripts"
  cp -rf $DIR/runme.sh  ~/Scripts/jetbrains-reset.sh
  chmod +x ~/Scripts/jetbrains-reset.sh

  echo
  echo "Copying com.jetbrains.reset.plist to $HOME/Library/LaunchAgents"
  cp -rf $DIR/com.jetbrains.reset.plist ~/Library/LaunchAgents

  echo
  echo "Loading job into launchctl"
  launchctl load ~/Library/LaunchAgents/com.jetbrains.reset.plist

  echo
  echo "That's it, enjoy ;)"
  exit 0
fi

if [ "$1" = "--launch-agent" ]; then
  PROCESS=(idea webstorm datagrip phpstorm clion pycharm goland rubymine rider)
  COMMAND_PRE=("${PROCESS[@]/#/MacOS/}")

  # Kill all Intellij applications
  PIDS=$(ps aux | egrep $(IFS=$'|'; echo "${COMMAND_PRE[*]}") | awk '{print $2}')
  if [ ! -z "$PIDS" ]; then
    kill -9 $PIDS 2>/dev/null || true
  fi
fi

# Reset Intellij evaluation
for product in IntelliJIdea WebStorm DataGrip PhpStorm CLion PyCharm GoLand RubyMine Rider; do

  # Check if directory exists before running
  product_dir="$HOME/Library/Application\ Support/JetBrains/$product*"
  if ! compgen -G "$product_dir" > /dev/null; then
    # echo "Skipping $product - directory not found"
    continue
  fi

  # This will expand the wildcard to actual path
  product_dir=$(echo $product_dir)

  echo "Resetting trial period for $product"

  echo "removing evaluation key..."
  # Check if eval directory exists and remove key files
  rm -rf "$product_dir"/evel/*.key

  echo "removing all evlsprt properties in options.xml..."
  # Check if other.xml exists before attempting to modify it
  other_xml_path="$product_dir/options/other.xml"
  if [ -f "$other_xml_path" ]; then
    sed -i '' '/evlsprt/d' "$other_xml_path"
  fi

  echo
done

echo "removing additional plist files..."
rm -f ~/Library/Preferences/com.apple.java.util.prefs.plist
rm -f ~/Library/Preferences/com.jetbrains.*.plist
rm -f ~/Library/Preferences/jetbrains.*.*.plist

for f in ~/Library/Preferences/jetbrains.*.plist; do
    if [[ -f $f ]]; then
        fn=${f##*/}; key=${fn%.plist}
        echo delete $key from pref and file $f
        defaults delete "${fn%.plist}" 2>/dev/null && rm "$f"
    fi
done


echo
echo "That's it, enjoy ;)"

# Flush preference cache
if [ "$1" = "--launch-agent" ]; then
  killall cfprefsd
  echo "Evaluation was reset at $(date)" >> ~/Scripts/logs
fi
