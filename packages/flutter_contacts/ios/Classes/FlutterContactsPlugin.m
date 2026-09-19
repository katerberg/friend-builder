#import "FlutterContactsPlugin.h"

#if __has_include(<flutter_contacts/flutter_contacts-Swift.h>)
#import <flutter_contacts/flutter_contacts-Swift.h>
#else
#import "flutter_contacts-Swift.h"
#endif

@implementation FlutterContactsPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  [SwiftFlutterContactsPlugin registerWithRegistrar:registrar];
}

@end
