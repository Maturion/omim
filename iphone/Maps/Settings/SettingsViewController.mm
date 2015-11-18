#import "LinkCell.h"
#import "MapsAppDelegate.h"
#import "MapViewController.h"
#import "MWMMapViewControlsManager.h"
#import "MWMTextToSpeech.h"
#import "SelectableCell.h"
#import "SettingsViewController.h"
#import "Statistics.h"
#import "SwitchCell.h"
#import "WebViewController.h"

#include "Framework.h"

#include "platform/settings.hpp"
#include "platform/platform.hpp"
#include "platform/preferred_languages.hpp"

extern char const * kStatisticsEnabledSettingsKey;
extern NSString * const kTTSStatusWasChangedNotification = @"TTFStatusWasChangedFromSettingsNotification";

typedef NS_ENUM(NSUInteger, Section)
{
  SectionMetrics,
  SectionZoomButtons,
  SectionRouting,
  SectionCalibration,
  SectionStatistics,
  SectionCount // Must be the latest value!
};

@interface SettingsViewController () <SwitchCellDelegate>

@end

@implementation SettingsViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.title = L(@"settings");
  self.tableView.backgroundView = nil;
  self.tableView.backgroundColor = [UIColor applicationBackgroundColor];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return SectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if (section == SectionMetrics || section == SectionRouting)
    return 2;
  else
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell * cell = nil;
  if (indexPath.section == SectionMetrics)
  {
    cell = [tableView dequeueReusableCellWithIdentifier:[SelectableCell className]];
    Settings::Units units = Settings::Metric;
    (void)Settings::Get("Units", units);
    BOOL selected = units == unitsForIndex(indexPath.row);

    SelectableCell * customCell = (SelectableCell *)cell;
    customCell.accessoryType = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    customCell.titleLabel.text = indexPath.row == 0 ? L(@"kilometres") : L(@"miles");
  }
  else if (indexPath.section == SectionStatistics)
  {
    cell = [tableView dequeueReusableCellWithIdentifier:[SwitchCell className]];
    SwitchCell * customCell = (SwitchCell *)cell;
    bool on = [Statistics isStatisticsEnabledByDefault];
    (void)Settings::Get(kStatisticsEnabledSettingsKey, on);
    customCell.switchButton.on = on;
    customCell.titleLabel.text = L(@"allow_statistics");
    customCell.delegate = self;
  }
  else if (indexPath.section == SectionZoomButtons)
  {
    cell = [tableView dequeueReusableCellWithIdentifier:[SwitchCell className]];
    SwitchCell * customCell = (SwitchCell *)cell;
    bool on = true;
    (void)Settings::Get("ZoomButtonsEnabled", on);
    customCell.switchButton.on = on;
    customCell.titleLabel.text = L(@"pref_zoom_title");
    customCell.delegate = self;
  }
  else if (indexPath.section == SectionCalibration)
  {
    cell = [tableView dequeueReusableCellWithIdentifier:[SwitchCell className]];
    SwitchCell * customCell = (SwitchCell *)cell;
    bool on = false;
    (void)Settings::Get("CompassCalibrationEnabled", on);
    customCell.switchButton.on = on;
    customCell.titleLabel.text = L(@"pref_calibration_title");
    customCell.delegate = self;
  }
  else if (indexPath.section == SectionRouting)
  {
    if (indexPath.row == 0)
    {
      cell = [tableView dequeueReusableCellWithIdentifier:[SwitchCell className]];
      SwitchCell * customCell = (SwitchCell *)cell;
      customCell.switchButton.on = [[MWMTextToSpeech tts] isNeedToEnable];
      customCell.titleLabel.text = L(@"pref_tts_enable_title");
      customCell.delegate = self;
    }
    else
    {
      cell = [tableView dequeueReusableCellWithIdentifier:[LinkCell className]];
      LinkCell * customCell = (LinkCell *)cell;
      customCell.titleLabel.text = L(@"pref_tts_language_title");
    }
  }
  return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
  if (section == SectionStatistics)
    return L(@"allow_statistics_hint");
  else if (section == SectionZoomButtons)
    return L(@"pref_zoom_summary");
  return nil;
}

- (void)switchCell:(SwitchCell *)cell didChangeValue:(BOOL)value
{
  NSIndexPath * indexPath = [self.tableView indexPathForCell:cell];
  if (indexPath.section == SectionStatistics)
  {
    Statistics * stat = [Statistics instance];
    [stat logEvent:kStatSettings
        withParameters:
            @{kStatAction : kStatToggleStatistics, kStatValue : (value ? kStatOn : kStatOff)}];
    if (value)
      [stat enableOnNextAppLaunch];
    else
      [stat disableOnNextAppLaunch];
  }
  else if (indexPath.section == SectionZoomButtons)
  {
    [[Statistics instance] logEvent:kStatSettings
                     withParameters:@{
                       kStatAction : kStatToggleZoomButtonsVisibility,
                       kStatValue : (value ? kStatVisible : kStatHidden)
                     }];
    Settings::Set("ZoomButtonsEnabled", (bool)value);
    [MapsAppDelegate theApp].mapViewController.controlsManager.zoomHidden = !value;
  }
  else if (indexPath.section == SectionCalibration)
  {
    [[Statistics instance] logEvent:kStatSettings
                     withParameters:@{
                       kStatAction : kStatToggleCompassCalibration,
                       kStatValue : (value ? kStatOn : kStatOff)
                     }];
    Settings::Set("CompassCalibrationEnabled", (bool)value);
  }
  else if (indexPath.section == SectionRouting)
  {
    [[MWMTextToSpeech tts] setNeedToEnable:value];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTTSStatusWasChangedNotification
                                                        object:nil
                                                      userInfo:@{@"on" : @(value)}];
  }
}

Settings::Units unitsForIndex(NSInteger index)
{
  return index == 0 ? Settings::Metric : Settings::Foot;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section == SectionMetrics)
  {
    Settings::Units units = unitsForIndex(indexPath.row);
    [[Statistics instance]
              logEvent:kStatSettings
        withParameters:@{
          kStatAction : kStatChangeMeasureUnits,
          kStatValue : (units == Settings::Units::Metric ? kStatKilometers : kStatMiles)
        }];
    Settings::Set("Units", units);
    [tableView reloadSections:[NSIndexSet indexSetWithIndex:SectionMetrics] withRowAnimation:UITableViewRowAnimationFade];
    [[MapsAppDelegate theApp].mapViewController setupMeasurementSystem];
  }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  if (section == SectionMetrics)
    return L(@"measurement_units");
  else if (section == SectionRouting)
    return L(@"prefs_group_route");
  else
    return nil;
}

@end
