# ReWrapText plugin

The reWrapText plugin provides a number of block based functions:

1. reWrapping text in a selected block
2. reWrapping text in the block in which the cursor is located
3. commenting text in a selected block
4. commenting text in the block in which the cursor is located
5. selecting a block

If no block is pre-selected then the reWrap, comment and select block 
functions will pre-select the current block with the same indentation 
*and* (single line) comment marker. 

The default settings are:

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
