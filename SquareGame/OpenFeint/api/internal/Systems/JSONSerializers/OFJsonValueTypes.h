//  Copyright 2010 Aurora Feint, Inc.
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

#pragma once

@interface OFJsonValueType : NSObject
{
	SEL selector;
}
+ (id)valueWithSelector:(SEL)valueSetter;
- (void)setValue:(id)value onObject:(id)target;
@end

@interface OFJsonObjectValue : OFJsonValueType
{
	Class objectKlass;
}
@property (nonatomic, assign) Class objectKlass;
+ (id)valueWithKnownClass:(Class)klass selector:(SEL)valueSetter;
@end

@interface OFJsonIntegerValue : OFJsonValueType
@end

@interface OFJsonInt64Value : OFJsonValueType
@end

@interface OFJsonDoubleValue : OFJsonValueType
@end

@interface OFJsonBoolValue : OFJsonValueType
@end

@interface OFJsonDateValue : OFJsonValueType
@end

@interface OFJsonUrlValue : OFJsonValueType
@end
