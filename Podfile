inhibit_all_warnings!

target 'ManicEmu' do
  platform :ios, '15.0'
  use_modular_headers!
  pod 'JXBanner', '~> 0.3.6'
  pod 'HXPhotoPicker/Lite', '~> 4.2.5'
  pod 'RealmSwift', '= 10.54.2'
  pod 'UMCommon', '~> 7.5.2'
  pod 'UMAPM', '~> 2.0.3'
  pod 'Fireworks', :git => 'https://github.com/tomkowz/fireworks.git', :branch => 'master'
  pod 'SnapKit', '~> 5.0'
  pod 'SwifterSwift', '~> 7.0'
  pod 'KeychainAccess', '~> 4.2'
  pod 'Permission/Photos', '~> 3.1.2'
  pod 'Permission/Camera', '~> 3.1.2'
  pod 'Permission/Microphone', '~> 3.1.2'
  pod 'NVActivityIndicatorView', '~> 5.2'
  pod 'SideMenu', '~> 6.5'
  pod 'VisualEffectView', '~> 5.0'
  pod 'FluentDarkModeKit', '~> 1.0.4'
  pod "Device", '~> 3.7'
  pod 'SFSafeSymbols', '~> 5.0'
  pod "Haptica", '~> 3.0'
  pod 'MarqueeLabel', '~> 4.5'
  pod 'IQKeyboardManagerSwift', '~> 8.0'
  pod 'Tiercel', '~> 3.0'
  pod 'BetterSegmentedControl', '~> 2.0'
  pod 'Schedule', '~> 2.0'
  pod 'SWCompression/SevenZip', '~> 4.8'
  pod 'LookinServer', :subspecs => ['Swift'], :configurations => ['Debug', 'DevRelease']
  pod 'FLEX', :configurations => ['Debug', 'DevRelease']
  pod 'ShowTouches', :configurations => ['Debug', 'DevRelease']
  pod 'DNSPageView', :git => 'https://github.com/LeeAoshuang/DNSPageView.git', :branch => 'master'
  pod 'CollectionViewPagingLayout', :git => 'https://github.com/LeeAoshuang/CollectionViewPagingLayout.git', :branch => 'master'
  pod 'CloudServiceKit', :git => 'https://github.com/LeeAoshuang/CloudServiceKit.git', :branch => 'main'
  pod 'Closures', :git => 'https://github.com/LeeAoshuang/Closures.git', :branch => 'master'
  pod 'TKSwitcherCollection', :git => 'https://github.com/LeeAoshuang/TKSwitcherCollection.git', :branch => 'master'
  pod "GCDWebServer/WebUploader", :git => 'https://github.com/LeeAoshuang/GCDWebServer.git', :branch => 'master'
  pod 'ProHUD', :git => 'https://github.com/LeeAoshuang/ProHUD.git', :branch => 'main'
  pod 'BlankSlate', :git => 'https://github.com/LeeAoshuang/BlankSlate.git', :branch => 'main'
  pod 'IceCream', :git => 'https://github.com/LeeAoshuang/IceCream.git', :branch => 'master'
  pod 'iCloudSync', :git => 'https://github.com/LeeAoshuang/iCloudSync.git', :branch => 'master'
  pod 'SwipeCellKit', :git => 'https://github.com/LeeAoshuang/SwipeCellKit.git', :branch => 'develop'
  pod 'SSZipArchive', :git => 'https://github.com/LeeAoshuang/ZipArchive.git', :branch => 'main'
  pod 'ZIPFoundation', :git => 'https://github.com/LeeAoshuang/ZIPFoundation.git', :branch => 'development'
  pod 'ManicSupport', :git => 'https://github.com/LeeAoshuang/ManicSupport.git', :branch => 'main'
  pod 'ManicEmuCore', :path => 'ManicEmuCore'
end

post_install do |installer|
    installer.generated_projects.each do |project|
          project.targets.each do |target|
              target.build_configurations.each do |config|
                  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
               end
          end
   end
end
