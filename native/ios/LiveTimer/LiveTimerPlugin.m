#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

CAP_PLUGIN(LiveTimerPlugin, "LiveTimer",
  CAP_PLUGIN_METHOD(sync, CAPPluginReturnPromise);
  CAP_PLUGIN_METHOD(consumeActions, CAPPluginReturnPromise);
)
