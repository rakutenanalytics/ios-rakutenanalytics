#!/bin/bash
set -e

JAZZY=`VISUAL=echo gem open jazzy`
if [ -z "$JAZZY" ]
then
  echo "ERROR: Jazzy binary not found"
  exit 1
fi

output_dir="./documentation"
# This directory is expected by `generate_docs` lane

echo "📄 Installing Pods"
bundle exec pod install --project-directory=./RakutenAnalyticsSDK

echo "📄 Generating docs"
bundle exec jazzy --output $output_dir

echo "📄 Copying images"
cp -r ./doc "$output_dir/doc"

echo "📄 Done"
