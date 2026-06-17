Pod::Spec.new do |s|
  s.name         = "FlexCheckout"
  s.version      = "1.4.0"
  s.summary      = "Flex Checkout SDK for iOS"
  s.description  = "Split rent payments with Flex. Drop-in UI components and checkout flow for iOS apps."
  s.homepage     = "https://github.com/flexapp/flex-checkout-ios"
  s.license      = { type: "Proprietary", text: "Copyright © 2026 Flexible Finance, Inc. All rights reserved." }
  s.author       = "Flex"

  s.platform     = :ios, "12.0"
  s.swift_version = "5.9"

  s.source = { git: "https://github.com/flexapp/flex-checkout-ios.git", tag: s.version }

  s.vendored_frameworks = "FlexCheckout.xcframework"
end
