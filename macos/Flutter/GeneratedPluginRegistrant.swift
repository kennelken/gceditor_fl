//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import catcher
import device_info_plus_macos
import menubar
import package_info_plus_macos
import path_provider_macos
import window_size

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  CatcherPlugin.register(with: registry.registrar(forPlugin: "CatcherPlugin"))
  DeviceInfoPlusMacosPlugin.register(with: registry.registrar(forPlugin: "DeviceInfoPlusMacosPlugin"))
  MenubarPlugin.register(with: registry.registrar(forPlugin: "MenubarPlugin"))
  FLTPackageInfoPlusPlugin.register(with: registry.registrar(forPlugin: "FLTPackageInfoPlusPlugin"))
  PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
  WindowSizePlugin.register(with: registry.registrar(forPlugin: "WindowSizePlugin"))
}
