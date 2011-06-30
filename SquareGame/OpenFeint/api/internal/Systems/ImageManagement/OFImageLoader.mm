//  Copyright 2009-2010 Aurora Feint, Inc.
// 
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  	http://www.apache.org/licenses/LICENSE-2.0
//  	
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "OFImageLoader.h"
#import "OFImageCache.h"
#import "OpenFeint+Private.h"

@implementation OFImageLoader

static NSMutableSet * gAdditionalResourceBundles;

+ (UIImage*)loadImage:(NSString*)imageName
{
	UIImage* image = [[OFImageCache sharedInstance] fetch:imageName];
	if (!image)
	{
		NSString* imagePath = [[OpenFeint getResourceBundle] pathForResource:imageName ofType:nil];	
		image = [UIImage imageWithContentsOfFile:imagePath];
	
		if (!image && gAdditionalResourceBundles)
		{
			NSBundle * thisBundle;
			NSEnumerator *enumerator = [gAdditionalResourceBundles objectEnumerator];
			while (image == nil && (thisBundle = [enumerator nextObject]))
			{
				NSString* imagePath = [thisBundle pathForResource:imageName ofType:nil];
				if (imagePath)
				{
					image = [UIImage imageWithContentsOfFile:imagePath];
				}
			}
		}
		
		// Fallback to main bundle
		if (!image)
		{
		    imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:nil];
		    image = [UIImage imageWithContentsOfFile:imagePath];
		}
		
		if (image)
		{
			[[OFImageCache sharedInstance] store:image withIdentifier:imageName];
		}
	}
	
	return image;
}

+ (void)registerResourceBundle:(NSBundle*)bundle
{
	if (gAdditionalResourceBundles == nil)
	{
		gAdditionalResourceBundles = [[NSMutableSet alloc] initWithCapacity:10];
	}
	[gAdditionalResourceBundles addObject:bundle];
}

@end
