#import "FTFontDescriptor.h"

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>


@interface FTFontDescriptor ()
@end

@implementation FTFontDescriptor

+ (NSArray *)fontFamilies;
{
  NSArray *displayNames = [UIFont familyNames];
  displayNames = [displayNames sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
  NSMutableArray *families = [NSMutableArray arrayWithCapacity:displayNames.count];
  for (NSString *displayName in displayNames) {
    [families addObject:[[FTFontDescriptor alloc] initWithPostscriptName:nil
                                                             displayName:displayName
                                                           familyMembers:nil]];
  }
  return [families copy];
}

@synthesize postscriptName = _postscriptName;
@synthesize familyMembers = _familyMembers;

- (instancetype)initWithPostscriptName:(NSString *)postscriptName
                           displayName:(NSString *)displayName;
{
  if ((self = [self initWithPostscriptName:postscriptName
                               displayName:displayName
                             familyMembers:nil])) {
    _familyMembers = @[self];
  }
  return self;
}

- (instancetype)initWithPostscriptName:(NSString *)postscriptName
                           displayName:(NSString *)displayName
                         familyMembers:(NSArray *)familyMembers;
{
  if ((self = [super init])) {
    _postscriptName = postscriptName;
    _displayName    = displayName;
    _familyMembers  = familyMembers;
  }
  return self;
}

- (NSString *)postscriptName;
{
  if (_postscriptName == nil) {
    NSParameterAssert(self.displayName);
    _postscriptName = [[UIFont fontWithName:self.displayName size:0] fontName];
  }
  return _postscriptName;
}

// TODO check how often this gets called
- (BOOL)hasFamilyMembers;
{
  NSArray *list = nil;
  if (_familyMembers == nil) {
    list = [UIFont fontNamesForFamilyName:self.displayName];
  } else {
    list = _familyMembers;
  }
  return list.count > 1;
}

- (instancetype)descriptorWithPostscriptName:(NSString *)postscriptName;
{
  for (FTFontDescriptor *descriptor in self.familyMembers) {
    if ([descriptor.postscriptName isEqualToString:postscriptName]) {
      return descriptor;
    }
  }
  return nil;
}

// +[UIFont fontNamesForFamilyName:] returns a sort order different from what
// Pages does, but CoreText returns the right order.
- (NSArray *)familyMembers;
{
  if (_familyMembers == nil) {
    NSParameterAssert(self.displayName);

    CTFontDescriptorRef familyDescriptor;
    CTFontCollectionRef family;
    CFArrayRef descriptors;

    NSDictionary *familyName = @{ (NSString *)kCTFontFamilyNameAttribute:self.displayName };
    familyDescriptor = CTFontDescriptorCreateWithAttributes((__bridge CFDictionaryRef)familyName);
    descriptors = CFArrayCreate(NULL, (CFTypeRef *)&familyDescriptor, 1, NULL);
    family = CTFontCollectionCreateWithFontDescriptors(descriptors, NULL);
    CFRelease(descriptors);
    descriptors = CTFontCollectionCreateMatchingFontDescriptors(family);

    CFRelease(family);
    CFRelease(familyDescriptor);

    CFIndex count = CFArrayGetCount(descriptors);
    NSMutableArray *members = [NSMutableArray arrayWithCapacity:count];

    for (CFIndex i = 0; i < count; i++) {
      CTFontDescriptorRef descriptor;
      CTFontRef font;
      NSString *postscriptName, *displayName;

      descriptor = (CTFontDescriptorRef)CFArrayGetValueAtIndex(descriptors, i);
      font = CTFontCreateWithFontDescriptor(descriptor, 0, NULL);
      postscriptName = (__bridge_transfer NSString *)CTFontCopyPostScriptName(font);
      displayName = (__bridge_transfer NSString *)CTFontCopyLocalizedName(font,
                                                                          kCTFontSubFamilyNameKey,
                                                                          NULL);
      CFRelease(font);
      [members addObject:[[FTFontDescriptor alloc] initWithPostscriptName:postscriptName
                                                              displayName:displayName]];
    }

    CFRelease(descriptors);
    _familyMembers = [members copy];
  }
  return _familyMembers;
}

@end
