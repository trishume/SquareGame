////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// 
///  Copyright 2009 Aurora Feint, Inc.
/// 
///  Licensed under the Apache License, Version 2.0 (the "License");
///  you may not use this file except in compliance with the License.
///  You may obtain a copy of the License at
///  
///  	http://www.apache.org/licenses/LICENSE-2.0
///  	
///  Unless required by applicable law or agreed to in writing, software
///  distributed under the License is distributed on an "AS IS" BASIS,
///  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
///  See the License for the specific language governing permissions and
///  limitations under the License.
/// 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#import "OFWebUILoadingView.h"


@implementation OFWebUILoadingView

@synthesize labelView, spinnerView;

- (id)initWithFrame:(CGRect)aFrame {
    if ((self = [super initWithFrame:aFrame])) {
        self.userInteractionEnabled = NO;
        
        self.labelView = [[[UILabel alloc] initWithFrame:self.bounds] autorelease];
        labelView.text = @"\n\n\n  Loading Feint...";
        labelView.font = [UIFont boldSystemFontOfSize:12];
        labelView.numberOfLines = 0;
        labelView.textAlignment = UITextAlignmentCenter;
        labelView.backgroundColor = [UIColor clearColor];
        labelView.textColor = [UIColor grayColor];
        [self addSubview:labelView];
        
        self.spinnerView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
        spinnerView.frame = self.bounds;
        spinnerView.contentMode = UIViewContentModeCenter;
        [spinnerView startAnimating];
        [self addSubview:spinnerView];
    }
    return self;
}

- (void)dealloc {
    self.labelView = nil;
    self.spinnerView = nil;
    [super dealloc];
}


- (void)show {
    [UIView beginAnimations:nil context:nil];
    self.alpha = 1.0;
    [UIView commitAnimations];
}

- (void)hide {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDelegate:self];
    self.alpha = 0.0;
    [UIView commitAnimations];
}

@end
