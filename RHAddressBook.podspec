Pod::Spec.new do |s|

  s.name         = "RHAddressBook"
  s.version      = "1.0.5"
  s.summary      = "A Cocoa / Objective-C library for interfacing with the iOS AddressBook that also adds geocoding support."

  s.homepage     = "https://github.com/LeonKeijzer/RHAddressBook"

  s.license      = 'MIT (example)'
  s.license      = { :type => 'Modified BSD', :file => 'LICENSE' }

  s.author       = { "leonk" => "l.keijzer@foize.com" }
  s.platform     = :ios

  s.source       = { :git => "https://github.com/LeonKeijzer/RHAddressBook.git", :tag => "1.0.5" }
  s.source_files = 'RHAddressBook/*.{h,m}'
  s.requires_arc = false
  s.subspec 'no-arc' do |sna|
    sna.requires_arc = false
    sna.source_files = non_arc_files
  end

  s.frameworks  = 'AddressBook', 'AddressBookUI', 'CoreLocation'

end
