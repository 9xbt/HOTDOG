/*

 HOTDOG

 Copyright (c) 2020 Arthur Choung. All rights reserved.

 Email: arthur -at- hotdogpucko.com

 This file is part of HOTDOG.

 HOTDOG is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.

 */

#import "HOTDOG.h"

#define MAX_RECT 640

static void drawStripedBackgroundInBitmap_rect_(id bitmap, Int4 r)
{
    [bitmap setColorIntR:205 g:212 b:222 a:255];
    [bitmap fillRectangleAtX:r.x y:r.y w:r.w h:r.h];
    [bitmap setColorIntR:201 g:206 b:209 a:255];
    for (int i=6; i<r.w; i+=10) {
        [bitmap fillRectangleAtX:r.x+i y:r.y w:4 h:r.h];
    }
}

static char *_letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ#";
static int _numLetters = 27;

static unsigned char *button_top_middle = 
"b\n"
".\n"
".\n"
;

static unsigned char *button_middle_left =
"b...\n"
;
static unsigned char *button_middle_middle =
".\n"
;
static unsigned char *button_middle_right =
"...b\n"
;

static unsigned char *button_bottom_middle =
".\n"
".\n"
"b\n"
;

static unsigned char *button_top_left_squared = 
"bbbb\n"
"b...\n"
"b...\n"
;
static unsigned char *button_top_right_squared = 
"bbbb\n"
"...b\n"
"...b\n"
;

static unsigned char *button_bottom_left_squared =
"b...\n"
"b...\n"
"bbbb\n"
;
static unsigned char *button_bottom_right_squared =
"...b\n"
"...b\n"
"bbbb\n"
;

@implementation Definitions(fmekwlfmksdlfmklsdkfm)
+ (id)ContactListNavigation
{
    id object = [Definitions ContactListInterface];
    if (object) {
        id nav = [Definitions navigationStack];
        [nav pushObject:object];
        return nav;
    }
    return nil;
}
+ (id)ContactListInterface
{
    return [@"ContactListInterface" asInstance];
}
@end

@interface ContactListInterface : IvarObject
{
    time_t _timestamp;
    int _seconds;
    id _array;
    Int4 _rect[MAX_RECT];
    id _buttons;
    char _buttonType[MAX_RECT];
    int _buttonDown;
    int _buttonHover;
    int _scrollY;

    id _bitmap;
    Int4 _r;
    int _cursorY;

    char _letterHeader;
    char _letterHeaderScrolledOff;
    int _letterHeaderY[256];
    int _letterScrollerButton;
}
@end
@implementation ContactListInterface
- (void)handleBackgroundUpdate:(id)event
{
    time_t timestamp = [[@"." fileModificationTimestamp] longValue];
    if (timestamp == _timestamp) {
        _seconds++;
        return;
    }
    [self updateArray];
    _timestamp = timestamp;
    _seconds = 0;
}
- (void)updateArray
{
    id cmd = nsarr();
    [cmd addObject:@"hotdog-contacts-list.py"];
    id output = [[[cmd runCommandAndReturnOutput] asString] split:@"\n"];
    if (output) {
        [self setValue:output forKey:@"array"];
    }
}

- (void)drawInBitmap:(id)bitmap rect:(Int4)r
{
    drawStripedBackgroundInBitmap_rect_(bitmap, r);

    [self setValue:nsarr() forKey:@"buttons"];

    _cursorY = -_scrollY + r.y;
    _r = r;

    [self setValue:bitmap forKey:@"bitmap"];

    {
        _letterScrollerButton = [_buttons count];
        [_buttons addObject:@""];
        _buttonType[_letterScrollerButton] = 'l';
        _rect[_letterScrollerButton].x = r.x+r.w-25;
        _rect[_letterScrollerButton].y = r.y;
        _rect[_letterScrollerButton].w = 25;
        _rect[_letterScrollerButton].h = r.h;
    }

    for (int i=0; i<256; i++) {
        _letterHeaderY[i] = 0;
    }

    id arr = _array;
    _letterHeaderScrolledOff = 0;
    for (int i=0; i<[arr count]; i++) {
        if (_cursorY >= r.y + r.h) {
            break;
        }
        if ([_buttons count] >= MAX_RECT) {
            [self panelText:@"MAX_RECT reached"];
            break;
        }

        id elt = [arr nth:i];
        id name = [elt valueForKey:@"name"];
        if (!name) {
            continue;
        }
        char *cstr = [name UTF8String];
        char c = toupper(*cstr);
        if (isdigit(c)) {
            c = '#';
        }
        if (_letterHeader != c) {
            _letterHeader = c;
            _letterHeaderY[c] = _cursorY + _scrollY - r.y;
            int textHeight = [_bitmap bitmapHeightForText:@"X"];
            if (_cursorY < r.y) {
                _letterHeaderScrolledOff = c;
                if (_cursorY + textHeight > r.y) {
                }
            } else {
                if (_letterHeaderScrolledOff) {
                    if (_cursorY < r.y+textHeight) {
                        [self panelLetterTitle:_letterHeaderScrolledOff y:_cursorY-textHeight];
                        [self panelLetterTitle:c y:_cursorY];
                    } else {
                        [self panelLetterTitle:_letterHeaderScrolledOff y:r.y];
                        [self panelLetterTitle:c y:_cursorY];
                    }
                    _letterHeaderScrolledOff = 0;
                } else {
                    [self panelLetterTitle:c y:_cursorY];
                }
            }
            _cursorY += textHeight;
        }
        [self panelButton:elt];
    }
    if (_letterHeaderScrolledOff) {
        [self panelLetterTitle:_letterHeaderScrolledOff y:r.y];
    }

    {
        int val = 0;
        for (int i=0; i<27; i++) {
            char c = _letters[i];
            if (_letterHeaderY[c]) {
                val = _letterHeaderY[c];
            } else {
                _letterHeaderY[c] = val;
            }
        }
    }


    {
        Int4 r1 = _rect[_letterScrollerButton];
        r1.w -= 5;

        int letterHeight = r.h / _numLetters;
        int scrollerOffsetY = (r.h - letterHeight*_numLetters) / 2;
        r1.y += scrollerOffsetY;
        r1.h -= scrollerOffsetY*2;

        if ((_buttonDown == _letterScrollerButton+1) && (_buttonHover == _letterScrollerButton+1)) {
            [bitmap setColor:@"#a0a0a0"];
            [bitmap fillRect:r1];
            [bitmap drawHorizontalLineAtX:r1.x+1 x:r1.x+r1.w-2 y:r1.y-1];
            [bitmap drawHorizontalLineAtX:r1.x+1 x:r1.x+r1.w-2 y:r1.y+r1.h];
        }

        [bitmap setColor:@"#404040"];
        for (int i=0; i<_numLetters; i++) {
            id text = nsfmt(@"%c", _letters[i]);
            int textWidth = [bitmap bitmapWidthForText:text];
            int textHeight = [bitmap bitmapHeightForText:text];
            int letterOffsetX = (r1.w - textWidth) / 2;
            int letterOffsetY = (letterHeight - textHeight) / 2;
            [bitmap drawBitmapText:text x:r1.x+letterOffsetX y:r1.y+letterHeight*i+letterOffsetY];
        }
    }



    [self setValue:nil forKey:@"bitmap"];
}
- (void)scrollToLetterAtY:(int)y
{
    if (!_rect[_letterScrollerButton].h) {
        return;
    }
    int letterHeight = _rect[_letterScrollerButton].h / _numLetters;
    int scrollerOffsetY = (_rect[_letterScrollerButton].h - letterHeight*_numLetters) / 2;

    int index = (y - _rect[_letterScrollerButton].y - scrollerOffsetY) / letterHeight;
    if (index > _numLetters-1) {
        index = _numLetters-1;
    }
NSLog(@"scrollToLetterAtY y %d index %d", y, index);
    char c = _letters[index];
    _scrollY = _letterHeaderY[c];
NSLog(@"scrollTo index %d c %c _scrollY %d", index, c, _scrollY);
}

- (void)panelLetterTitle:(char)c y:(int)y
{
    id text = nsfmt(@"%c", c);
    int textHeight = [_bitmap bitmapHeightForText:text];
    [_bitmap setColor:@"#808080"];
    [_bitmap fillRectangleAtX:_r.x y:y w:_r.w h:textHeight];
    [_bitmap setColor:@"white"];
    [_bitmap drawBitmapText:text x:_r.x+10 y:y];
}

- (void)panelButton:(id)line
{
    id text = [line valueForKey:@"name"];
    if (!text) {
        text = @"(no name)";
    }
    id fittedText = [_bitmap fitBitmapString:text width:_r.w-40];
    _cursorY -= 1;
    unsigned char *top_left = button_top_left_squared;
    unsigned char *top_middle = button_top_middle;
    unsigned char *top_right = button_top_right_squared;
    unsigned char *bottom_left = button_bottom_left_squared;
    unsigned char *bottom_middle = button_bottom_middle;
    unsigned char *bottom_right = button_bottom_right_squared;


    int buttonIndex = [_buttons count];
    [_buttons addObject:line];
    _buttonType[buttonIndex] = 'b';

    int textWidth = [_bitmap bitmapWidthForText:fittedText];
    int textHeight = [_bitmap bitmapHeightForText:fittedText];
    if (textHeight <= 0) {
        textHeight = [_bitmap bitmapHeightForText:@"X"];
    }

    Int4 r1;
    r1.x = _r.x;
    r1.y = _cursorY;
    r1.w = _r.w;
    r1.h = textHeight + 10;
    r1.x += (_r.w - r1.w) / 2;
    _rect[buttonIndex] = r1;
    
    char *palette = "b #000000\n. #ffffff\n";
    id textColor = @"#000000";

    if (_buttonType[buttonIndex] == 'b') {
        if ((_buttonDown-1 == buttonIndex) && (_buttonDown == _buttonHover)) {
            palette = "b #000000\n. #0000ff\n";
            textColor = @"#ffffff";
        } else if (!_buttonDown && (_buttonHover-1 == buttonIndex)) {
            palette = "b #000000\n. #000000\n";
            textColor = @"#ffffff";
        }
    }

    [Definitions drawInBitmap:_bitmap left:top_left middle:top_middle right:top_right x:r1.x y:r1.y w:r1.w palette:palette];
    for (int buttonY=r1.y+3; buttonY<r1.y+r1.h-3; buttonY++) {
        [Definitions drawInBitmap:_bitmap left:button_middle_left middle:button_middle_middle right:button_middle_right x:r1.x y:buttonY w:r1.w palette:palette];
    }
    [Definitions drawInBitmap:_bitmap left:bottom_left middle:bottom_middle right:bottom_right x:r1.x y:r1.y+r1.h-3 w:r1.w palette:palette];
    [_bitmap setColor:textColor];
    [_bitmap drawBitmapText:fittedText x:r1.x+10 y:r1.y+5];

    _cursorY += r1.h;
}

- (void)handleMouseDown:(id)event
{
    int x = [event intValueForKey:@"mouseX"];
    int y = [event intValueForKey:@"mouseY"];

    for (int i=0; i<[_buttons count]; i++) {
        if ([Definitions isX:x y:y insideRect:_rect[i]]) {
            _buttonDown = i+1;
            if (i == _letterScrollerButton) {
                [self scrollToLetterAtY:y];
            }
            return;
        }
    }
    _buttonDown = 0;
}
- (void)handleMouseMoved:(id)event
{
    int x = [event intValueForKey:@"mouseX"];
    int y = [event intValueForKey:@"mouseY"];
    for (int i=0; i<[_buttons count]; i++) {
        if ([Definitions isX:x y:y insideRect:_rect[i]]) {
            _buttonHover = i+1;
            if (i == _letterScrollerButton) {
                if (_buttonDown == _letterScrollerButton+1) {
                    [self scrollToLetterAtY:y];
                }
            }
            return;
        }
    }
    _buttonHover = 0;
}

- (void)handleMouseUp:(id)event
{
    if (_buttonDown == 0) {
        return;
    }
    if (_buttonDown == _buttonHover) {
        id line = [_buttons nth:_buttonDown-1];
        id path = [line valueForKey:@"path"];
        if (path) {
            id obj = [Definitions ContactDetailInterface:path];
            [obj pushToNavigationStack];
        }
    }
    _buttonDown = 0;
}
- (void)handleScrollWheel:(id)event
{
    int deltaY = [event intValueForKey:@"deltaY"];
    if (deltaY > 0) {
        _scrollY--;
    } else {
        _scrollY++;
    }
}
@end

