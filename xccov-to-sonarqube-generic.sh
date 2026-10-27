#!/usr/bin/env bash
set -euo pipefail

# Convert xccov output to SonarQube Generic Coverage format.
# Based on SonarSource's official script, with path normalization for SonarCloud.
# See: https://docs.sonarsource.com/sonarqube-cloud/analyzing-source-code/test-coverage/generic-test-data

function convert_xccov_to_xml {
  awk '
    BEGIN {
      current_file = ""
      pending_path = ""
      in_branch_block = 0
    }

    function xml_escape(value) {
      gsub(/&/, "\\&amp;", value)
      gsub(/</, "\\&lt;", value)
      gsub(/>/, "\\&gt;", value)
      gsub(/"/, "\\&quot;", value)
      return value
    }

    function close_current_file() {
      if (current_file != "") {
        print "  </file>"
        current_file = ""
      }
    }

    function open_pending_file() {
      if (pending_path != "") {
        close_current_file()
        print "  <file path=\"" pending_path "\">"
        current_file = pending_path
        pending_path = ""
      }
    }

    function emit_line(line_num, covered) {
      if (line_num !~ /^[0-9]+$/) {
        return
      }
      open_pending_file()
      if (current_file == "") {
        return
      }
      printf "    <lineToCover lineNumber=\"%s\" covered=\"%s\"/>\n", line_num, covered
    }

    # File path line (ends with colon, not a line-number entry)
    /:$/ && !/^ *[0-9]+:/ {
      close_current_file()
      pending_path = xml_escape(substr($0, 1, length($0) - 1))
      in_branch_block = 0
      next
    }

    # Branch block opener: "  NN: X ["
    /^ *[0-9]+: [0-9]+ \[$/ {
      line_num = $1
      sub(/:$/, "", line_num)
      current_line = line_num
      current_exec = $2 + 0
      in_branch_block = 1
      next
    }

    # Branch tuple: "(column, count1, count2)"
    /^\([0-9]+, [0-9]+, [0-9]+\)$/ {
      next
    }

    # Branch block closing: "]"
    /^\]$/ {
      if (in_branch_block) {
        covered = (current_exec > 0) ? "true" : "false"
        emit_line(current_line, covered)
        in_branch_block = 0
      }
      next
    }

    # Uncovered line: "  NN: 0"
    /^ *[0-9]+: 0$/ {
      line_num = $1
      sub(/:$/, "", line_num)
      emit_line(line_num, "false")
      next
    }

    # Covered line without branch info: "  NN: X" where X > 0
    /^ *[0-9]+: [1-9][0-9]*$/ {
      line_num = $1
      sub(/:$/, "", line_num)
      emit_line(line_num, "true")
      next
    }

    # Empty line - end of file section (ignore blank lines before first line)
    /^$/ {
      if (in_branch_block) {
        next
      }
      if (current_file != "") {
        close_current_file()
      }
      next
    }

    END {
      close_current_file()
    }
  '
}

function filter_coverage_input {
  # Include project sources xccov sees under Sources/, but drop build artifacts
  # and third-party dependencies. SonarCloud applies coverage only to sonar.sources.
  #
  # On CI, xccov often reports paths under DerivedData that still point at this
  # repo's Sources/ tree — check Sources/ before excluding DerivedData-only paths.
  awk '
    BEGIN { skip_file = 0 }
    /:$/ && !/^ *[0-9]+:/ {
      file_path = $0
      if (file_path ~ /SourcePackages\// ||
          file_path ~ /Pods\// ||
          file_path ~ /ViewInspector\// ||
          file_path ~ /RAnalyticsBroadcast\//) {
        skip_file = 1
      } else if (file_path ~ /Sources\//) {
        skip_file = 0
      } else if (file_path ~ /DerivedData\//) {
        skip_file = 1
      } else {
        skip_file = 1
      }
    }
    !skip_file { print }
  '
}

function print_xccov_path_diagnostics {
  local xcresult="$1"

  echo "DEBUG: xcodebuild/xcode-select version:" >&2
  xcodebuild -version 2>&1 | sed 's/^/  /' >&2 || true

  echo "DEBUG: total distinct file paths in xcresult:" >&2
  xcrun xccov view --archive "$xcresult" 2>/dev/null \
    | awk '/:$/ && !/^ *[0-9]+:/ { sub(/:$/, "", $0); print }' \
    | sort -u | wc -l | sed 's/^/  /' >&2 || true

  echo "DEBUG: sample xccov file paths:" >&2
  xcrun xccov view --archive "$xcresult" 2>/dev/null \
    | awk '/:$/ && !/^ *[0-9]+:/ { sub(/:$/, "", $0); print "  " $0 }' \
    | head -30 >&2 || true

  echo "DEBUG: paths containing Sources/:" >&2
  xcrun xccov view --archive "$xcresult" 2>/dev/null \
    | awk '/:$/ && !/^ *[0-9]+:/ && /Sources\// { sub(/:$/, "", $0); print "  " $0 }' \
    | head -15 >&2 || true
}

function normalize_coverage_paths {
  local project_root="${PROJECT_ROOT:-${BITRISE_SOURCE_DIR:-}}"

  if [[ -n "$project_root" ]]; then
    sed -E \
        -e 's|<file path="/[^"]*/Sources/|<file path="Sources/|' \
        -e 's|<file path="Sources/Sources/|<file path="Sources/|' \
        -e "s|<file path=\"${project_root}/|<file path=\"|g"
  else
    sed -E \
        -e 's|<file path="/[^"]*/Sources/|<file path="Sources/|' \
        -e 's|<file path="Sources/Sources/|<file path="Sources/|'
  fi
}

function validate_coverage_xml {
  local xml_file="$1"

  if command -v xmllint >/dev/null 2>&1; then
    if ! xmllint --noout "$xml_file" 2>/dev/null; then
      echo "ERROR: Generated coverage XML is not well-formed." >&2
      return 1
    fi
  fi

  if grep -qE '^  <lineToCover ' "$xml_file"; then
    echo "ERROR: Generated coverage XML has lineToCover elements outside file tags." >&2
    return 1
  fi

  if ! grep -q '<lineToCover ' "$xml_file"; then
    echo "ERROR: Generated coverage XML has files but no lineToCover entries." >&2
    return 1
  fi

  return 0
}

function xccov_to_generic {
  local xcresult="$1"

  # Sonar generic coverage example uses this root element only (no XML prolog).
  echo '<coverage version="1">'
  xcrun xccov view --archive "$xcresult" | filter_coverage_input | convert_xccov_to_xml | normalize_coverage_paths
  echo '</coverage>'
}

function find_profdata {
  local derived_data="${DERIVED_DATA_PATH:-$HOME/Library/Developer/Xcode/DerivedData}"
  find "$derived_data" -path '*/Build/ProfileData/*/Coverage.profdata' -print0 2>/dev/null \
    | xargs -0 ls -t 2>/dev/null | head -1
}

# xccov intermittently drops statically linked SPM targets (Sources/) from the
# xcresult, while the raw profdata still has them. Read it with llvm-cov instead.
function llvm_cov_to_generic {
  local profdata="$1"
  local products_dir="${profdata%/ProfileData/*}/Products"
  local objects=()
  local bundle

  while IFS= read -r -d '' bundle; do
    objects+=("-object" "$bundle/$(basename "$bundle" .xctest)")
  done < <(find "$products_dir" -name '*.xctest' -type d -print0)

  [[ ${#objects[@]} -gt 0 ]] || return 1

  echo '<coverage version="1">'
  xcrun llvm-cov export -format=lcov -instr-profile "$profdata" "${objects[@]:1}" \
    | awk '
      /^SF:/ {
        path = substr($0, 4)
        keep = (path ~ /\/Sources\// && path !~ /SourcePackages\/|Pods\/|ViewInspector\/|RAnalyticsBroadcast\/|DerivedData\//)
        if (keep) print "  <file path=\"" path "\">"
        next
      }
      /^DA:/ && keep {
        split(substr($0, 4), da, ",")
        printf "    <lineToCover lineNumber=\"%s\" covered=\"%s\"/>\n", da[1], (da[2] > 0) ? "true" : "false"
        next
      }
      /^end_of_record/ {
        if (keep) print "  </file>"
        keep = 0
      }
    ' | normalize_coverage_paths
  echo '</coverage>'
}

function is_xcode_version_supported() {
  local major=${1:-0} minor=${2:-0}
  if (( (major >= 14) || (major == 13 && minor >= 3) )); then
    return 0
  fi
  return 1
}

command -v xcrun >/dev/null 2>&1 || { echo >&2 "xcrun is required but not installed."; exit 1; }
command -v xcodebuild >/dev/null 2>&1 || { echo >&2 "xcodebuild is required but not installed."; exit 1; }

if ! xcode_version="$(xcodebuild -version | sed -n '1s/^Xcode \([0-9.]*\)$/\1/p')"; then
  echo 'Failed to get Xcode version' 1>&2
  exit 1
elif ! is_xcode_version_supported ${xcode_version//./ }; then
  echo "Xcode version '$xcode_version' not supported, version 13.3 or above is required" 1>&2
  exit 1
fi

if [[ $# -ne 1 ]]; then
  echo "Invalid number of arguments. Expecting 1 path matching '*.xcresult'" 1>&2
  exit 1
fi

xcresult="$1"
if [[ ! -d "$xcresult" ]]; then
  echo "Path not found: $xcresult" 1>&2
  exit 1
elif [[ $xcresult != *".xcresult"* ]]; then
  echo "Expecting input to match '*.xcresult', got: $xcresult" 1>&2
  exit 1
fi

coverage_xml="$(mktemp)"
trap 'rm -f "$coverage_xml"' EXIT

xccov_to_generic "$xcresult" > "$coverage_xml" || true

file_count="$(grep -c '<file path=' "$coverage_xml" || true)"

if [[ "$file_count" -eq 0 ]] && profdata="$(find_profdata)" && [[ -n "$profdata" ]]; then
  echo "WARNING: xccov reported no Sources/ files; falling back to llvm-cov on $profdata" >&2
  llvm_cov_to_generic "$profdata" > "$coverage_xml" || true
  file_count="$(grep -c '<file path=' "$coverage_xml" || true)"
fi

line_count="$(grep -c '<lineToCover ' "$coverage_xml" || true)"

echo "Coverage report: $file_count files, $line_count lines" >&2

if [[ "$file_count" -eq 0 ]]; then
  echo "ERROR: No coverage files matched Sources/. Check that tests ran with code coverage enabled." >&2
  echo "  xcresult: $xcresult" >&2
  print_xccov_path_diagnostics "$xcresult"
  echo "  Tip: run 'xcrun xccov view --archive \"$xcresult\" | head -50' to inspect raw paths." >&2
  exit 1
fi

if ! validate_coverage_xml "$coverage_xml"; then
  echo "  Tip: run 'xcrun xccov view --archive \"$xcresult\" | head -100' to inspect raw paths." >&2
  exit 1
fi

cat "$coverage_xml"
