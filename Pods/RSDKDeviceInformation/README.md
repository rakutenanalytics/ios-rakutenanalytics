## Introduction
This Rakuten SDK module allows applications to get pieces of information about
the device they are running on.

@attention For this module to work, keychain access **MUST** be properly
 configured first. Please refer to @ref device-information-keychain-setup "Setting up the keychain"
 for the right way to do so.

If the keychain is locked or the identifier could not otherwise be read, RSDKDeviceInformation::uniqueDeviceIdentifier
returns `nil`. Applications should retry when the application becomes active again.

