//
//  ViewController.m
//  Tracklet
//
//  Copyright (c) 2014 io.nakamura. All rights reserved.
//

#import "ViewController.h"
#import "LocationManager.h"
#import "DataManager.h"
#import "NetworkManager.h"

#import "MBProgressHUD.h"

static NSString *const updatingLocationsKeyPath = @"updatingLocations";
static NSString *const monitoringVisitsKeyPath = @"monitoringVisits";

static NSString *const updateLocationsToggleCellId = @"updateLocationsToggleCell";
static NSString *const updateLocationsTextLabel = @"Updating Locations";

static NSString *const monitorVisitsToggleCellId = @"updateVisitsToggleCell";
static NSString *const monitorVisitsTextLabel = @"Updating Visits";

static NSString *const locationsToUploadCellId = @"locationsToUploadCell";
static NSString *const locationsToUploadTextLabel = @"%lu Locations to upload";

static NSString *const visitsToUploadCellId = @"visitsToUploadCell";
static NSString *const visitsToUploadTextLabel = @"%lu Visits to upload";

static NSString *const clearUploadedLocationsCellId = @"clearUploadedLocationsCell";
static NSString *const clearUploadedLocationsTextLabel = @"%lu Locations uploaded";

static NSString *const clearUploadedVisitsCellId = @"clearUploadedVisitsCell";
static NSString *const clearUploadedVisitsTextLabel = @"%lu Visits uploaded";

@interface ViewController () <LocationManagerDelegate>

@property (weak, nonatomic) DataManager *dm;
@property (weak, nonatomic) LocationManager *lm;

@property (strong, nonatomic) IBOutlet UISwitch *updatingLocationsSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *monitoringVisitsSwitch;

@property (strong, nonatomic) IBOutlet UILabel *locationsToUploadLabel;
@property (strong, nonatomic) IBOutlet UILabel *locationsUploadedLabel;
@property (strong, nonatomic) IBOutlet UILabel *visitsToUploadLabel;
@property (strong, nonatomic) IBOutlet UILabel *visitsUploadedLabel;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.dm = [DataManager sharedManager];
    self.lm = [LocationManager sharedManager];
    self.lm.delegate = self;
    
    // [self setUpdatingLocationsSwitchState];
    // [self setMonitoringVisitsSwitchState];
    // [self updateLocationsToUploadCount];
    // [self updateLocationsUploadedCount];
    // [self updateVisitsToUploadCount];
    // [self updateVisitsUploadedCount];
    
    // [self.lm addObserver:self forKeyPath:updatingLocationsKeyPath options:NSKeyValueObservingOptionNew context:nil];
    // [self.lm addObserver:self forKeyPath:monitoringVisitsKeyPath options:NSKeyValueObservingOptionNew context:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)updatingLocationsSwitchWasSwitched:(id)sender {
    if (self.updatingLocationsSwitch.on) {
        [self.lm startUpdatingLocation];
    } else {
        [self.lm stopUpdatingLocation];
    }
}

- (IBAction)monitoringVisitsSwitchWasSwitched:(id)sender {
    if (self.monitoringVisitsSwitch.on) {
        [self.lm startMonitoringVisits];
    } else {
        [self.lm stopMonitoringVisits];
    }
}

#pragma mark - State

- (void)setUpdatingLocationsSwitchState {
    [self.updatingLocationsSwitch setOn:self.lm.updatingLocations animated:YES];
}

- (void)setMonitoringVisitsSwitchState {
    [self.monitoringVisitsSwitch setOn:self.lm.monitoringVisits animated:YES];
}

- (void)updateLocationsToUploadCount {
    unsigned long c = (unsigned long)[self.dm locationsToUploadCount];
    self.locationsToUploadLabel.text = [NSString stringWithFormat:locationsToUploadTextLabel, c];
}

- (void)updateLocationsUploadedCount {
    self.locationsUploadedLabel.text = [NSString stringWithFormat:clearUploadedLocationsTextLabel,
                                        [self.dm locationsUploadedCount]];
}

- (void)updateVisitsToUploadCount {
    unsigned long c = (unsigned long)[self.dm visitsToUploadCount];
    self.visitsToUploadLabel.text = [NSString stringWithFormat:visitsToUploadTextLabel, c];
}

- (void)updateVisitsUploadedCount {
    self.visitsUploadedLabel.text = [NSString stringWithFormat:clearUploadedVisitsTextLabel,
                                     [self.dm visitsUploadedCount]];
}

#pragma mark - Observe

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    LocationManager *lm = [LocationManager sharedManager];
    if (lm == object) {
        if (keyPath == updatingLocationsKeyPath) {
            [self setUpdatingLocationsSwitchState];
        } else if (keyPath == monitoringVisitsKeyPath) {
            [self setMonitoringVisitsSwitchState];
        }
    }
}

#pragma mark - LocationManagerDelegate

- (void)locationManager:(LocationManager *)locationManager didSaveLocations:(NSArray *)locations {
    [self updateLocationsToUploadCount];
}

- (void)locationManager:(LocationManager *)locationManager didSaveVisit:(CLVisit *)visit {
    [self updateVisitsToUploadCount];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger r = 0;
    switch (section) {
        case 0:
            r = 4;
            break;
        case 1:
            r = 2;
            break;
            
    }
    return r;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    cell = [self updateLocationsToggleCell];
                    break;
                    
                case 1:
                    cell = [self monitorVisitsToggleCell];
                    break;
                    
                case 2:
                    cell = [self locationsToUploadCell];
                    break;
                    
                case 3:
                    cell = [self visitsToUploadCell];
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                    cell = [self clearUploadedLocationsCell];
                    break;
                    
                case 1:
                    cell = [self clearUploadedVisitsCell];
                    break;
            }
            break;
    }
    return cell;
}

#pragma mark - Cells

- (UITableViewCell *)getCellForId:(NSString *)cellIdentifier creation:(UITableViewCell *(^)(UITableViewCell *cell))creation
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.textLabel.font = [UIFont fontWithName:cell.textLabel.font.fontName size:12.0];
        if (creation) {
            cell = creation(cell);
        }
    }
    return cell;
}

- (UITableViewCell *)updateLocationsToggleCell {
    return [self getCellForId:updateLocationsToggleCellId creation:^UITableViewCell *(UITableViewCell *c) {
        c.textLabel.text = updateLocationsTextLabel;
        c.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.updatingLocationsSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        [self.updatingLocationsSwitch addTarget:self action:@selector(updatingLocationsSwitchWasSwitched:) forControlEvents:UIControlEventValueChanged];
        [self setUpdatingLocationsSwitchState];
        c.accessoryView = self.updatingLocationsSwitch;
        
        return c;
    }];
}

- (UITableViewCell *)monitorVisitsToggleCell {
    return [self getCellForId:monitorVisitsToggleCellId creation:^UITableViewCell *(UITableViewCell *c) {
        c.textLabel.text = monitorVisitsTextLabel;
        c.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.monitoringVisitsSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        [self.monitoringVisitsSwitch addTarget:self action:@selector(monitoringVisitsSwitchWasSwitched:) forControlEvents:UIControlEventValueChanged];
        [self setMonitoringVisitsSwitchState];
        c.accessoryView = self.monitoringVisitsSwitch;
        
        return c;
    }];
}

- (UITableViewCell *)locationsToUploadCell {
    return [self getCellForId:locationsToUploadCellId creation:^UITableViewCell *(UITableViewCell *c) {
        self.locationsToUploadLabel = c.textLabel;
        [self updateLocationsToUploadCount];
        return c;
    }];
}

- (UITableViewCell *)visitsToUploadCell {
    return [self getCellForId:visitsToUploadCellId creation:^UITableViewCell *(UITableViewCell *c) {
        self.visitsToUploadLabel = c.textLabel;
        [self updateVisitsToUploadCount];
        return c;
    }];
}

- (UITableViewCell *)clearUploadedLocationsCell {
    return [self getCellForId:clearUploadedLocationsCellId creation:^UITableViewCell *(UITableViewCell *c) {
        self.locationsUploadedLabel = c.textLabel;
        [self updateLocationsUploadedCount];
        return c;
    }];
}

- (UITableViewCell *)clearUploadedVisitsCell {
    return [self getCellForId:clearUploadedVisitsCellId creation:^UITableViewCell *(UITableViewCell *c) {
        self.visitsUploadedLabel = c.textLabel;
        [self updateVisitsUploadedCount];
        return c;
    }];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 2:
                    [self uploadLocationsToUpload];
                    break;
                    
                case 3:
                    [self uploadVisitsToUpload];
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                    [self clearUploadedLocations];
                    break;
                    
                case 1:
                    [self clearUploadedVisits];
                    break;
            }
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -

- (void)uploadLocationsToUpload {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *locations = [self.dm locationsToUpload];
        if ([locations count] > 0) {
            [[NetworkManager sharedManager] uploadLocations:locations completion:^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateLocationsToUploadCount];
                    [self updateLocationsUploadedCount];
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
        }
        
    });
}

- (void)uploadVisitsToUpload {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *visits = [self.dm visitsToUpload];
        if ([visits count] > 0) {
            [[NetworkManager sharedManager] uploadVisits:visits completion:^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateVisitsToUploadCount];
                    [self updateVisitsUploadedCount];
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
        }
    });
}

#pragma mark -

- (void)clearUploadedLocations {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Deleting Locations"
                                                                message:@"Delete all uploaded locations?"
                                                         preferredStyle:UIAlertControllerStyleAlert];
    [ac addAction:[UIAlertAction actionWithTitle:@"Delete"
                                           style:UIAlertActionStyleDestructive
                                         handler:^(UIAlertAction *action) { [self _clearUploadedLocations]; }]];
    [ac addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:ac animated:YES completion:nil];
}

- (void)_clearUploadedLocations {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.dm deleteUploadedLocations:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateLocationsUploadedCount];
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
        }];
    });
}

- (void)clearUploadedVisits {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Deleting Visits"
                                                                message:@"Delete all uploaded visits?"
                                                         preferredStyle:UIAlertControllerStyleAlert];
    [ac addAction:[UIAlertAction actionWithTitle:@"Delete"
                                           style:UIAlertActionStyleDestructive
                                         handler:^(UIAlertAction *action) { [self _clearUploadedVisits]; }]];
    [ac addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:ac animated:YES completion:nil];
}

- (void)_clearUploadedVisits {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.dm deleteUploadedVisits:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateVisitsUploadedCount];
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
        }];
    });
}

@end
