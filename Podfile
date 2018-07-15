# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

def shared_pods
  # Pods for microjam
  pod 'libpd', :git => 'https://github.com/libpd/libpd', :submodules => true
  pod 'InAppSettingsKit'
  pod 'UIColor_Hex_Swift'
  pod 'NSDate+TimeAgo'
  pod 'DateToolsSwift'
  pod 'DropDown'
  pod 'Avatar'
  pod  'SwiftRandom'
end

target 'microjam' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  shared_pods

  #target 'microjamTests' do
  #  inherit! :search_paths
  #  # Pods for testing
  #end

  target 'microjamUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end
