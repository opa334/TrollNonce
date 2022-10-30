#import "TNRootViewController.h"
#import "TSUtil.h"

NSString* getHelperPath(void)
{
	return [NSBundle.mainBundle.bundleURL.path stringByAppendingPathComponent:@"noncehelper"];
}

@implementation TNRootViewController

- (void)loadView
{
	[super loadView];
}

- (void)startActivity:(NSString*)activity
{
	if(_activityController) return;

	_activityController = [UIAlertController alertControllerWithTitle:activity message:@"" preferredStyle:UIAlertControllerStyleAlert];
	UIActivityIndicatorView* activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(5,5,50,50)];
	activityIndicator.hidesWhenStopped = YES;
	activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleMedium;
	[activityIndicator startAnimating];
	[_activityController.view addSubview:activityIndicator];

	[self presentViewController:_activityController animated:YES completion:nil];
}

- (void)stopActivityWithCompletion:(void (^)(void))completion
{
	if(!_activityController) return;

	[_activityController dismissViewControllerAnimated:YES completion:^
	{
		_activityController = nil;
		if(completion)
		{
			completion();
		}
	}];
}

- (NSMutableArray*)specifiers
{
	if(!_specifiers)
	{
		_specifiers = [NSMutableArray new];

		PSSpecifier* groupSpecifier = [PSSpecifier emptyGroupSpecifier];
		[groupSpecifier setProperty:[NSString stringWithFormat:@"TrollNonce %@\n\n© 2022 Lars Fröder (opa334)\n\nCredits:\n@jaakerblom: multicast_bytecopy exploit\n@0x7ff: dimentio", [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"]] forKey:@"footerText"];

		[_specifiers addObject:groupSpecifier];

		PSSpecifier* readNonceSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Nonce"
											target:self
											set:nil
											get:@selector(getNonceInfoString)
											detail:nil
											cell:PSTitleValueCell
											edit:nil];
		readNonceSpecifier.identifier = @"readnonce";
		[readNonceSpecifier setProperty:@YES forKey:@"enabled"];

		[_specifiers addObject:readNonceSpecifier];

		PSSpecifier* setNonceSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Set Nonce"
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSButtonCell
												edit:nil];
		setNonceSpecifier.identifier = @"setnonce";
		[setNonceSpecifier setProperty:@YES forKey:@"enabled"];
		setNonceSpecifier.buttonAction = @selector(setNoncePressed);
		[_specifiers addObject:setNonceSpecifier];
	}
	
	[(UINavigationItem *)self.navigationItem setTitle:@"TrollNonce"];
	return _specifiers;
}

- (NSString*)getNonceInfoString
{
	NSString* output;
	spawnRoot(getHelperPath(), @[@"get-nonce"], &output, nil);

	NSLog(@"output: %@", output);

	NSCharacterSet *separator = [NSCharacterSet newlineCharacterSet];
	NSArray* lines = [output componentsSeparatedByCharactersInSet:separator];

	return lines.firstObject;
}

- (void)setNoncePressed
{
	UIAlertController* setNonceAlert = [UIAlertController alertControllerWithTitle:@"Set Nonce" message:@"Select a nonce to set, supports 15.0 - 15.1.1, A10 and up.\nNote: Setting a nonce is only possible once per boot." preferredStyle:UIAlertControllerStyleAlert];

	[setNonceAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
		textField.placeholder = @"0x1111111111111111";
	}];

	UIAlertAction* setAction = [UIAlertAction actionWithTitle:@"Set" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
	{
		UITextField* nonceField = setNonceAlert.textFields[0];
		NSString* nonceStr = nonceField.text;

		if(!nonceStr || nonceStr.length == 0)
		{
			nonceStr = @"0x1111111111111111";
		}

		if(nonceStr.length > 2 && [nonceStr hasPrefix:@"0x"])
		{
			[self startActivity:@"Setting Nonce..."];
			dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
				int setRet = spawnRoot(getHelperPath(), @[@"set-nonce", nonceStr], nil, nil);
				dispatch_async(dispatch_get_main_queue(), ^(void){
					[self stopActivityWithCompletion:^
					{
						[self reloadSpecifiers];

						if(setRet == 0)
						{
							UIAlertController* successAlert = [UIAlertController alertControllerWithTitle:@"Success" message:@"Setting the nonce should have succeeded, the TrollHelper app may display \"Error\" or an invalid value in the nonce field until a reboot, this is a quirk of dimentio and normal. If you want to be sure that setting the nonce has succeeded, reboot your device and check the 'Nonce' field afterwards."  preferredStyle:UIAlertControllerStyleAlert];
							UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDefault handler:nil];
							[successAlert addAction:closeAction];

							[self presentViewController:successAlert animated:YES completion:nil];
						}
					}];
				});
			});
		}
	}];
	[setNonceAlert addAction:setAction];

	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
	[setNonceAlert addAction:cancelAction];

	[self presentViewController:setNonceAlert animated:YES completion:nil];
}

@end
