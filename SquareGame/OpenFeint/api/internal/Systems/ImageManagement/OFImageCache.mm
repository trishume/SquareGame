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

#import "OFImageCache.h"


namespace
{
	static OFImageCache* sInstance = nil;
	static NSInteger const kCacheInitialSize = 50;
	static NSInteger const kCacheCapacityBytes = 2000000;
}

@implementation OFImageCache

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		mCache = [[NSMutableDictionary dictionaryWithCapacity:kCacheInitialSize] retain];
		mKeys = [[NSMutableArray arrayWithCapacity:kCacheInitialSize] retain];
		mTotalBytes = 0;

		[[NSNotificationCenter defaultCenter] 
			addObserver:self
			selector:@selector(purge)
			name:UIApplicationDidReceiveMemoryWarningNotification
			object:nil];

	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];

	OFSafeRelease(mCache);
	OFSafeRelease(mKeys);
	[super dealloc];
}

+ (void)initializeCache
{
	OFAssert(!sInstance, "Already initialized");
	sInstance = [OFImageCache new];
}

+ (void)shutdownCache
{
	OFSafeRelease(sInstance);
}

+ (OFImageCache*)sharedInstance
{
	OFAssert(sInstance, "Not initialized");
	return sInstance;
}

//Helper function
- (int)roughImageSizeInBytes:(UIImage*)image
{
	CGImageRef cgImage = image.CGImage;
	int sizeBytes = CGImageGetBytesPerRow(cgImage) * CGImageGetHeight(cgImage);
	return sizeBytes;
}

- (UIImage*)fetch:(NSString*)identifier
{
	UIImage * image = [mCache objectForKey:identifier];
	if (image)
	{
		[mKeys removeObject:identifier];
		[mKeys addObject:identifier];
	}
	return image;
}

- (void)store:(UIImage*)image withIdentifier:(NSString*)identifier
{
	UIImage * existingImage = [mCache objectForKey:identifier];
	if (existingImage)
	{
		// We are replacing an already cached item.
		mTotalBytes -= [self roughImageSizeInBytes:existingImage];
		[mKeys removeObject:identifier];
	}

	[mCache setObject:image forKey:identifier];
	[mKeys addObject:identifier];
	mTotalBytes += [self roughImageSizeInBytes:image];
	
	// If the cache is too big, remove items from the end,
	// which are the least recently used ones.
	while (mTotalBytes > kCacheCapacityBytes)
	{
		NSString * leastRecentlyUsedKey = [mKeys objectAtIndex:0];
		UIImage * imageToRemove = [mCache objectForKey:leastRecentlyUsedKey];
		OFAssert(imageToRemove, @"");
		mTotalBytes -= [self roughImageSizeInBytes:imageToRemove];
		[mCache removeObjectForKey:leastRecentlyUsedKey];
		[mKeys removeObjectAtIndex:0];
	}
}

- (void)purgeUnreferenced
{
	UIImage* image = nil;
	unsigned int i = 0;
	while (i < [mKeys count])
	{
		NSString * key = [mKeys objectAtIndex:i];
		image = [mCache objectForKey:key];
		if ([image retainCount] == 1)
		{
			mTotalBytes -= [self roughImageSizeInBytes:image];
			[mCache removeObjectForKey:key];
			[mKeys removeObjectAtIndex:i];
		}
		else
		{
			i++;
		}
	}
}

- (void)purge
{
	[mCache removeAllObjects];
	[mKeys removeAllObjects];
	mTotalBytes = 0;
}

@end
