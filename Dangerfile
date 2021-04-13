# Warn when there is a big PR
warn("Big PR") if git.lines_of_code > 1000

# Delete any existing coverage files due to
# https://github.com/fastlane-community/danger-xcov/issues/33
system('rm -rf artifacts/unit-tests/coverage')
xcov.report(
  workspace: 'CI.xcworkspace',
  scheme: 'Tests',
  output_directory: 'artifacts/unit-tests/coverage',
  json_report: true,
  include_targets: 'RAnalytics.framework',
  include_test_targets: false,
  minimum_coverage_percentage: 80.0,
  skip_slack: true
)
