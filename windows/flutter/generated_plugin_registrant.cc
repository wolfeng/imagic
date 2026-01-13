//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <audioplayers_windows/audioplayers_windows_plugin.h>
#include <record_windows/record_windows_plugin_c_api.h>
#include <video_player_win/video_player_win_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  AudioplayersWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("AudioplayersWindowsPlugin"));
  RecordWindowsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("RecordWindowsPluginCApi"));
  VideoPlayerWinPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("VideoPlayerWinPluginCApi"));
}
