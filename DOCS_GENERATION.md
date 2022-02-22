# Docs Generation

## Description
The documentation generation uses [Jazzy](https://github.com/realm/jazzy) as main documentation engine. The current solution does not include any Objective-C sources. The process starts with `generate_docs` lane which runs `generate-docs.sh` script (defined in `REM_FL_DOCS_GENERATION_COMMAND` var in `fastlane/.env` file). The shell script sets up the project in `RakutenAnalyticsSDK` folder and then runs `jazzy` command. Finally, the generated documentation is moved to `artifacts/docs/<module_name>-<version>` directory.

## Setup
Run `bundle install`
Ensure that parameters in `.jazzy.yaml` are up-to-date.

## How to use
To generate docs run `generate_docs` Fastlane lane. Example:
```bash
$ bundle exec fastlane generate_docs module_name:"RAnalytics" module_version:"8.0.0"
```
`module_name` and `module_version` parameters are used only to create the output directory. (e.g. `./artifacts/docs/RAnalytics-8.0`). The most important parameters are set in `.jazzy.yaml` file.
