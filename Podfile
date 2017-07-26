# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

def shared_pods
  # Pods for microjam
  pod 'libpd', :git => 'https://github.com/libpd/libpd', :submodules => true
  pod 'UIColor_Hex_Swift'
end

target 'microjam' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  shared_pods
  pod 'InAppSettingsKit'
  pod 'UIColor_Hex_Swift'
  pod 'NSDate+TimeAgo'
  pod 'DateToolsSwift'
  pod 'DropDown'

  target 'microjamTests' do
    inherit! :search_paths
    shared_pods
    # Pods for testing
  end

  target 'microjamUITests' do
    inherit! :search_paths
    shared_pods
    # Pods for testing
  end

end
