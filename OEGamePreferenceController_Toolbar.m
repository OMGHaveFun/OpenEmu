//
//  OEGamePreferenceController_Toolbar.m
//  OpenEmu
//
//  Created by Remy Demarest on 25/02/2009.
//  Copyright 2009 Psycho Inc.. All rights reserved.
//

#import "OEGamePreferenceController_Toolbar.h"
#import "PluginInfo.h"

static NSString *OEToolbarLabelKey        = @"OEToolbarLabelKey";
static NSString *OEToolbarPaletteLabelKey = @"OEToolbarPaletteLabelKey";
static NSString *OEToolbarToolTipKey      = @"OEToolbarToolTipKey";
static NSString *OEToolbarImageKey        = @"OEToolbarImageKey";
static NSString *OEToolbarNibNameKey      = @"OEToolbarNibNameKey";
static NSString *OEPluginViewKey          = @"OEPluginViewKey";

//static NSString *OEPreferenceToolbarIdentifier     = @"OEPreferenceToolbarIdentifier";
static NSString *OEVideoSoundToolbarItemIdentifier = @"OEVideoSoundToolbarItemIdentifier";
static NSString *OEControlsToolbarItemIdentifier   = @"OEControlsToolbarItemIdentifier";
static NSString *OEAdvancedToolbarItemIdentifier   = @"OEAdvancedToolbarItemIdentifier";
static NSString *OEPluginsToolbarItemIdentifier    = @"OEPluginsToolbarItemIdentifier";

@interface OEGamePreferenceController ()
- (NSString *)itemIdentifier;
@end


@implementation OEGamePreferenceController (Toolbar)

// ============================================================
// NSToolbar Related Methods
// ============================================================
- (void)setupToolbar
{
#define CREATE_RECORD(label, paletteLabel, toolTip, image, nib, ...) \
   [NSDictionary dictionaryWithObjectsAndKeys:                       \
    label,        OEToolbarLabelKey,                                 \
    paletteLabel, OEToolbarPaletteLabelKey,                          \
    toolTip,      OEToolbarToolTipKey,                               \
    image,        OEToolbarImageKey,                                 \
    nib,          OEToolbarNibNameKey, ##__VA_ARGS__, nil]
    
    preferencePanels = [[NSDictionary alloc] initWithObjectsAndKeys:
                        CREATE_RECORD(@"Video & Sound",
                                      @"Video & Sound",
                                      @"Video & Sound Preferences",
                                      [NSImage imageNamed:NSImageNameComputer],
                                      @"VideoAndSoundPreferences"), OEVideoSoundToolbarItemIdentifier,
                        CREATE_RECORD(@"Controls",
                                      @"Controls",
                                      @"Control Preferences",
                                      [NSImage imageNamed:NSImageNamePreferencesGeneral],
                                      @"ControlPreferences",
                                      OEControlsPreferenceKey, OEPluginViewKey), OEControlsToolbarItemIdentifier,
                        CREATE_RECORD(@"Advanced",
                                      @"Advanced",
                                      @"Advanced Preferences",
                                      [NSImage imageNamed:NSImageNameAdvanced],
                                      @"AdvancedPreferences",
                                      OEAdvancedPreferenceKey, OEPluginViewKey), OEAdvancedToolbarItemIdentifier,
                        CREATE_RECORD(@"Plugins",
                                      @"Plugins",
                                      @"Plugin Preferences",
                                      [NSImage imageNamed:NSImageNameEveryone],
                                      @"PluginPreferences"), OEPluginsToolbarItemIdentifier,
                        nil];
#undef CREATE_RECORD
    currentViewIdentifier = OEControlsToolbarItemIdentifier;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)aToolbar
{
    static NSArray *standardItems = nil;
    if(standardItems == nil)
    {
        standardItems = [[NSArray arrayWithObjects:OEVideoSoundToolbarItemIdentifier, OEControlsToolbarItemIdentifier, OEAdvancedToolbarItemIdentifier, OEPluginsToolbarItemIdentifier, nil] retain];
    }
    
    return standardItems;
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)aToolbar
{
    return [self toolbarAllowedItemIdentifiers:aToolbar];	
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)aToolbar
{
    return [self toolbarAllowedItemIdentifiers:aToolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)aToolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
	
    NSDictionary *desc = [preferencePanels objectForKey:itemIdentifier];
    if(desc != nil)
    {
        [toolbarItem setLabel:        [desc objectForKey:OEToolbarLabelKey]];
        [toolbarItem setPaletteLabel: [desc objectForKey:OEToolbarPaletteLabelKey]];
        [toolbarItem setToolTip:      [desc objectForKey:OEToolbarToolTipKey]];
        [toolbarItem setImage:        [desc objectForKey:OEToolbarImageKey]];
        [toolbarItem setTarget:       self];
        [toolbarItem setAction:       @selector(switchView:)];
    }
    else
    {
        toolbarItem = nil;
        /*
        // itemIdent refered to a toolbar item that is not provide or supported by us or cocoa 
        // Returning nil will inform the toolbar this kind of item is not supported 
        toolbarItem = [customIcons objectForKey:itemIdent];
         */
    }
    return toolbarItem;
}

- (NSString *)itemIdentifier
{
    return OEControlsToolbarItemIdentifier;
}

- (NSRect)frameForNewContentViewFrame:(NSRect)viewFrame
{
    NSWindow *window = [self window];
    NSRect newFrameRect = [window frameRectForContentRect:viewFrame];
    NSRect oldFrameRect = [window frame];
    NSSize newSize = newFrameRect.size;
    NSSize oldSize = oldFrameRect.size;
    
    NSRect frame = [window frame];
    frame.size = newSize;
    frame.origin.y -= (newSize.height - oldSize.height);
    return frame;
}

- (void)switchView:(id)sender
{
    // Figure out the new view, the old view, and the new size of the window
	NSViewController *previousController = nil;
        
    previousController = currentViewController;
    if(sender == self) [toolbar setSelectedItemIdentifier:OEControlsToolbarItemIdentifier];
    if(sender != nil) currentViewIdentifier = [sender itemIdentifier];
    currentViewController = [self newViewControllerForIdentifier:currentViewIdentifier];
	
    NSView *view = [currentViewController view];
    
	NSRect newFrame = [self frameForNewContentViewFrame:[[currentViewController view] frame]];
	
	// Using an animation grouping because we may be changing the duration
	[NSAnimationContext beginGrouping];
	
	// With the shift key down, do slow-mo animation
	if ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask)
	    [[NSAnimationContext currentContext] setDuration:5.0];
	
	// Call the animator instead of the view / window directly
	if(previousController) [[[[self window] animator] contentView] replaceSubview:[previousController view] with:view];
	else                   [[[[self window] animator] contentView] addSubview:view];
	
	[[[self window] animator] setFrame:newFrame display:YES];
	[NSAnimationContext endGrouping];
    
    [previousController release];
}

- (void)windowDidResize:(NSNotification *)notification
{
    NSView *view = [currentViewController view];
    NSRect viewFrame = [view frame];
    viewFrame.origin = NSZeroPoint;
    [view setFrame:viewFrame];
}

- (NSViewController *)newViewControllerForIdentifier:(NSString*)identifier
{
    NSDictionary *desc = [preferencePanels objectForKey:identifier];
    
    NSString *pluginViewName = [desc objectForKey:OEPluginViewKey];
    NSViewController *ret = nil;
    
    if(pluginViewName != nil)
    {
        self.availablePluginsPredicate = [NSPredicate predicateWithFormat:@"%@ IN availablePreferenceViewControllers", pluginViewName];
        [pluginDrawer open];
        if(currentPlugin == nil) ret = [[NSViewController alloc] initWithNibName:@"SelectPluginPreferences"
                                                                          bundle:[NSBundle mainBundle]];
        else ret = [currentPlugin newPreferenceViewControllerForKey:pluginViewName];
    }
    else
    {
        [pluginDrawer close];
        NSString *viewNibName = [desc objectForKey:OEToolbarNibNameKey];
        ret = [[NSViewController alloc] initWithNibName:viewNibName bundle:[NSBundle mainBundle]];
    }
    
    [ret loadView];
    
    return ret;
}

@end
