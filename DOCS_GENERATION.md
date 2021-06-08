# Docs Generation

## Outline
This documents descibes the solution used to generate unified documentation in html format for both Swift and Objective-C sources.
Currently none of the well known docs generators is able to do that as a 'one-click' action.
The solution presented in this document is based on Jazzy capabilities.
Bu using Jazzy's dependency - sourcekitten, a source file is generated separately for Swift and Objective-C.
Then, according to Jazzy [documentation](https://github.com/realm/jazzy/blob/master/README.md), both files are used as a base for `jazzy` command.

## How to use
Ensure that Jazzy is installed.
To generate docs run `generate_docs` Fastlane lane. Example:
```bash
$ bundle exec fastlane generate_docs module_name:"RAnalytics" module_version:"8.0.0"
```
The documentation is generated in `./artifacts/docs` directory.<br>

`generate_docs` lane runs `documentation` action which executes `generate-docs.sh` instead of standard `red-gendoc`.
This setting can be modified by changing `REM_FL_DOCS_GENERATION_COMMAND` variable in `fastlane/.env`.

## Script details
The proposed solution for projects with mixed Objective-C and Swift files in Jazzy documentation doesn't work in our project.
Additional steps are required to make it work:
* To address iOS 8.0 deployment target issue during xcodebuild command:<br>
`The iOS Simulator deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 8.0, but the range of supported deployment target versions is 9.0 to 14.0.99.`<br>
a `post_install` script was added to the Podfile which changes deployment target to iOS 9.0 for pods that had it originally set to 8.0 or lower.
It's necessary because iOS 8 support was dropped in XCode 12.
* The `sourcekitten` command for generating Swift docs needs additional parameters:
  * `--module-name RAnalytics` to point to the SDK's files instead of Tests files
  * `build-for-testing` instead of `build` because there are only Test target types to use in CI project.
  * `-destination 'platform=iOS Simulator,name=iPhone 8'` also needed because of Test target type.<br>
  The final command:
  ```bash
  sourcekitten doc --module-name RAnalytics -- clean build-for-testing -workspace CI.xcworkspace -scheme Tests -destination 'platform=iOS Simulator,name=iPhone 8' > swiftDoc.json
  ```
* For generating Objective-C docs, there's one main issue to be addressed:<br>
`RAnalytics/RAnalyticsDefines.h file not found` error when running sourcekitten command.<br>
Sourcekitten takes umbrealla header and uses its import declarations as relative paths to the rest of headers.
In order to get rid of this error, all Obj-C files are copied to temporary RAnalytics folder to match those relative paths.
With that step, the command from Jazzy documentation can be used as follows:
```bash
sourcekitten doc --objc ./RAnalytics/RAnalytics/RAnalytics.h -- -x objective-c  -isysroot $(xcrun --show-sdk-path --sdk iphonesimulator) -I ./RAnalytics -fmodules > objcDoc.json
```

Now `jazzy` command can be used to generate final documentation.
```bash
$ jazzy --sourcekitten-sourcefile swiftDoc.json,objcDoc.json
```
`.jazzy.yaml` file has been added to provide more information for generation process.<br>
(Because of custom approach we use, some parameters in yaml file might be ignored.)

The last step in the script cleans all temporary files leaving only `docs` directory as a final output.

# README conversion
To convert README from Doxygen to Markdown format the following tool was used:<br>
https://github.com/matusnovak/doxybook2

To generate table of contents:<br>
https://github.com/alexharv074/markdown_toc

Manual fixes:

* Fixed code snippet languages
* Added ⚠️ symbol for each `@attention`
