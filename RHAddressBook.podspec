Pod::Spec.new do |s|
  s.name         = 'RHAddressBook'
  s.version      = '1.0.5'
  s.summary      = 'A Cocoa / Objective-C library for interfacing with the iOS AddressBook that also adds geocoding support.'
  s.author = {
    'Richard Heard' => 'http://twitter.com/heardwt',
	'Leon Keijzer' => 'nightfox500@gmail.com'
  }
  s.source = {
    :git => 'https://github.com/LeonKeijzer/RHAddressBook'
  }
  s.source_files = 'Source/*.{h,m}'
end
