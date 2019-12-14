https://developer.apple.com/library/archive/documentation/General/Conceptual/AppleTV_PG/index.html

https://www.bignerdranch.com/blog/10-tips-for-mastering-the-focus-engine-on-tvos/

Apple tv Design Guideline:-  
https://developer.apple.com/design/human-interface-guidelines/tvos/visual-design/layout/


Design Note:-  
- Top, bottom space = 60 pixel
- Left, Right space = 90 pixel
- selected item ni size Moti rakhvi
- Design black loading screens
- Provide images with a scale factor of @1x and @2x for all your app’s artwork
- Apple TV sizes 3840 x 2160, 1920 x 1080(maximum use), 1280 x 720, 640 x 480
- App Icon For App(layered icons) Size:- 400 x 240 and 800 x 480
- App Icon For App Store(layered icons background layer without transparent) Size:- 1280 x 768
- Top Shelf Image(for app) Size :- 1920x720 and 3840x1440
- Top Shelf Image Wide(for App Store) Size :- 2320x720 and 4640x1440

Note:-  
- when application is loading entertain to mask loading time
- carefull on selected, focus, highlighted style.
- Maximum Avoid input from user
- when user press on menu button close app or viewcontroller. (Do not display back button)


Remote what can do:-  
- Swipe up/down/left/right (For simulator:- command + arrow move)
- Tap up/down/left/right
- long press on touch surface
- menu button to back (For simulator:- esc)


Programing use full Note:-  

1)Control use for focus  
- UIButton  
- UIControl  
- UISegmentedControl  
- UITabBar  
- UITextField  
- UISearchBar (although UISearchBar itself isn’t focusable, its internal text field is)  

2)Get current focus control from screen:-  
- UIScreen.mainScreen().focusedView // possibly nil  

3)Prevent or manage cell can focus or not:-  
```
collectionView(_:shouldUpdateFocusInContext:)  
tableView(_:shouldUpdateFocusInContext:)  
```

4)Adjust Image when focused use adjustsImageWhenAncestorFocused property  

5)perform animation when get or lost focus   
```
use "didUpdateFocusInContext" method and get next and previous focus view  
```

6)force update focus :-  
```
item.setNeedsFocusUpdate()  
item.updateFocusIfNeeded()  
```


# Userfull method :-
```
//Change focus of view (for new version)
- (NSArray<id<UIFocusEnvironment>> *)preferredFocusEnvironments {
    return @[self.view1, self.view2, self.view3];
}

//When firsttime load set bydefault first row focus
- (NSIndexPath *)indexPathForPreferredFocusedViewInTableView:(UITableView *)tableView {
    return [NSIndexPath indexPathForRow:0 inSection:0];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldUpdateFocusInContext:(UICollectionViewFocusUpdateContext *)context {
	//for prevent focus
}

- (void)tableView:(UITableView *)tableView didUpdateFocusInContext:(UITableViewFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
	//animate you view when focus got to lost
	//for next view use context.nextFocusedView
	//for previous view use context.previouslyFocusedView
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
	//animate you view when focus got to lost
}
```
