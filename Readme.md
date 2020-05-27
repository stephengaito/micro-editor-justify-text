# A Justify text for the Micro Text Editor

The reWrapText plugin for the [micro 
editor](https://github.com/zyedidia/micro) provides a number of block 
based functions: 

1. reWrapping text in a selected block
2. reWrapping text in the block in which the cursor is located
3. commenting text in a selected block
4. commenting text in the block in which the cursor is located
5. selecting a block

If no block is pre-selected then the reWrap, comment and select block 
functions will pre-select the current block with the same indentation 
*and* (single line) comment marker. 

The default settings (which can be configured in your settings.json file) 
are: 

1. reWrapText.commentLineMarkers (default: "// # -- ; >")
2. reWrapText.textWidth          (default: 75)

The reWrapText.commentLineMarkers setting determines which possible 
(leading words) are actually to be interpreded as comment markers. 

The reWrapText.textWidth controls how wide a given reWrapped line should 
be (including any leading indentation).

For each buffer there is a local setting "lastBlockCommentMarker" which 
will be used if the current block is *not* commented. 

The default key-bindings are:

1. "Alt-[" reWrapText.selectCommentedBlock
2. "Alt-]" reWrapText.commentBlock
3. "Alt-j" reWrapText.reWrapText

## Installation

To install the reWrapText plugin, make a copy of this directroy to your 
local plugins directory. On a linux machine that would be located in the 
directory: 

    ~/.config/micro/plug

When installed you should have (at a minimum) the following files:

    ~/.config/micro/plug/reWrapText/reWrapText.lua
    ~/.config/micro/plug/reWrapText/help/reWrapText.lua

On a Linux machine you can use the bash script:

    ./bin/install

in this directory to install reWrapText for your use.
