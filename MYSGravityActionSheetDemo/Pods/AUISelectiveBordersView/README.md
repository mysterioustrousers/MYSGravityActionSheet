# Overview

This is a cocoapod adapted from adam-siton/AUISelectiveBordersView

# Usage

```objective-c

  UILabel* label = [[UILabel alloc] initWithFrame: CGRectMake(0,0, 200, 30)];
  label.selectiveBorderWidth = 1.0f;
  label.selectiveBorderFlags = AUISelectiveBorderTop | AUISelectiveBorderLeft;
  label.selectiveBorderColor = [UIColor redColor];

  //then add the label to another view
```
