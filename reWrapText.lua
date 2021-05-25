VERSION = "1.0.0"

-- A Lua based reWrapText/justify plugin for the micro editor

local micro  = import("micro")
local util   = import("micro/util")
local config = import("micro/config")
local buffer = import("micro/buffer")

--[=[
local tmpName = os.time()
local logFile = io.open("/tmp/microLog-"..tmpName, 'w')

function logMsg(msg) 
  logFile:write(msg.."\n")
  logFile:flush()
end
]=]

-- Protect a micro.Log from appending nil values to strings...
--
function mayBeNil(mesg)
  if mesg == nil then mesg = "(nil)" end
  return mesg
end

-- Find a comment marker from the global "reWrapText.commentLineMarkers" 
-- option 
--
function findCommentMarker(possibleCommentMarker)
  if possibleCommentMarker == nil then return nil end
  --
  local commentMarkers = 
    config.GetGlobalOption("reWrapText.commentLineMarkers")
  for aStr in commentMarkers:gmatch("(%S+)") do
    startCommentIndex, endCommentIndex = 
      possibleCommentMarker:find(aStr,1,true)
    if endCommentIndex ~= nil and 
       endCommentIndex == possibleCommentMarker:len() then
      return possibleCommentMarker
    end
  end
  return nil
end

-- Find the block structure for a pre-selected block
--
function findBlockStructure(bp, firstLine, lastLine)
  local indentEnd = 1000
  local blockCommentMarkers = {}
  local indentedCommentEnd = 1000
  --
  local curLine = firstLine
  while curLine <= lastLine do
    local curLineStr = bp.Buf:Line(curLine)
    local startIndex, commentMarker, endIndex =
      curLineStr:match("()(%S+)()")
    if startIndex ~= nil and startIndex < indentEnd then
      indentEnd = startIndex
    end
    if endIndex ~= nil and endIndex < indentedCommentEnd then
      indentedCommentEnd = endIndex
    end
    commentMarker = findCommentMarker(commentMarker)
    if commentMarker ~= nil then
      blockCommentMarkers[commentMarker] = true
    else
      indentedCommentEnd = indentEnd
    end
    curLine = curLine + 1
  end
  local blockCommentMarker = "unknown"
  for key, value in pairs(blockCommentMarkers) do
    if blockCommentMarker == "unknown" then
      blockCommentMarker = key
    elseif blockCommentMarker ~= key then
      blockCommentMarker = nil
      indentedCommentEnd = indentEnd
    end
  end
  if blockCommentMarker == "unknown" then blockCommentMarker = nil end
  return indentEnd - 1,
    blockCommentMarker,
    indentedCommentEnd
end

-- Find the block structure given just a cursor position
--
function findUnselectedCommentedBlock(bp)
  --
  -- Start by determining the indentation and possible comment symbol
  -- of the line on which the cursor is located.
  --
  local firstLine = bp.Cursor.Y
  local curLineStr = bp.Buf:Line(firstLine)
  local startIndex, commentMarker, endIndex = curLineStr:match("()(%S+)()")
  if startIndex    == nil or 
    commentMarker == nil or
    endIndex == nil then
    -- we are on a blank line....
    return nil, nil, nil, nil, nil
  end
  --
  local indentEnd          = startIndex
  local indentedCommentEnd = endIndex
  local blockCommentMarker = findCommentMarker(commentMarker)
  if blockCommentMarker == nil then
    indentedCommentEnd = indentEnd
  end
  --
  -- Now move up to find the first line which has a different 
  -- indentation or comment marker
  --
  firstLine = firstLine - 1
  while 0 < firstLine do
    curLineStr = bp.Buf:Line(firstLine)
    startIndex, commentMarker, endIndex = curLineStr:match("()(%S+)()")
    if blockCommentMarker == nil then
      if startIndex == nil or
        startIndex ~= indentEnd then
        -- we have found a blank line or a line with different indentation
        -- move back one line and break
        firstLine = firstLine + 1
        break
      end
    else
      if startIndex == nil or
        startIndex ~= indentEnd or
        commentMarker ~= blockCommentMarker or
        endIndex == nil or
        endIndex ~= indentedCommentEnd then
        -- we have found a blank line, a line with different indentation
        -- OR a line with a different comment marker
        -- move back one line and break
        firstLine = firstLine + 1
        break
      end
    end
    firstLine = firstLine - 1
  end
  --
  -- Now move down to find the last line which has a different
  -- indentation or comment marker
  --
  local lastLine = bp.Cursor.Y + 1
  while lastLine < bp.Buf:LinesNum() do
    curLineStr = bp.Buf:Line(lastLine)
    startIndex, commentMarker, endIndex = curLineStr:match("()(%S+)()")
    if blockUnselectedCommentMarker == nil then
      if startIndex == nil or
        startIndex ~= indentEnd then
        -- we have found a blank line or a line with different indentation
        -- move back one line and break
        lastLine = lastLine - 1
        break
      end
    else
      if startIndex == nil or
        startIndex ~= indentEnd or
        commentMarker ~= blockCommentMarker or
        endIndex == nil or
        endIndex ~= indentedCommentEnd then
        -- we have found a blank line, a line with different indentation
        -- OR a line with a different comment marker
        -- move back one line and break
        lastLine = lastLine - 1
        break
      end
    end      
    lastLine = lastLine + 1
  end
  --
  return firstLine,
   lastLine,
   indentEnd - 1,
   blockCommentMarker,
   indentedCommentEnd
end

-- The acutal reWrapText.selectCommentBlock method
--
function selectCommentedBlock(bp, arg)
  --
  -- If the user has made a selection... just make it a full block...
  --
  if bp.Cursor:HasSelection() then
    bp.Cursor:SetSelectionStart(buffer.Loc(0, bp.Cursor.CurSelection[1].Y))
    lastLineStr = bp.Buf:Line(bp.Cursor.CurSelection[2].Y)
    bp.Cursor:SetSelectionEnd(
      buffer.Loc(#lastLineStr, bp.Cursor.CurSelection[2].Y)
    )
    return
  end 
  --
  local firstLine, lastLine, indentEnd, blockCommentMarker, indentedCommentEnd =
    findUnselectedCommentedBlock(bp)
  if firstLine == nil or lastLine == nil then return end
  bp.Cursor:SetSelectionStart(buffer.Loc(0, firstLine))
  lastLineStr = bp.Buf:Line(lastLine)
  bp.Cursor:SetSelectionEnd(
    buffer.Loc(#lastLineStr, lastLine)
  )
end

-- Determine block structure for either a pre-selected block or a block 
-- with just cursor. This function is used by both the 
-- reWrapText.commentBlock and reWrapText.reWrapText. 
--
function determineBlockStructure(bp)
  local firstLine, lastLine, indentEnd, blockCommentMarker, indentedCommentEnd
  if bp.Cursor:HasSelection() then
    firstLine = bp.Cursor.CurSelection[1].Y
    lastLine  = bp.Cursor.CurSelection[2].Y
    if bp.Cursor.CurSelection[2].X == 0 and firstLine < lastLine then
      lastLine = lastLine -1
     end
    indentEnd, blockCommentMarker, indentedCommentEnd =
      findBlockStructure(bp, firstLine, lastLine)
  else
    firstLine, lastLine, indentEnd, blockCommentMarker, indentedCommentEnd =
      findUnselectedCommentedBlock(bp)
  end
  if firstLine ~= nil and firstLine < 1 then firstLine = 0 end
  if lastLine ~= nil and lastLine < 1 then lastLine = 0 end
  if lastLine ~= nil and bp.Buf:LinesNum() <= lastLine then
    lastLine = bp.Buf:LinesNum() - 1
   end
  return firstLine,
    lastLine,
    indentEnd,
    blockCommentMarker,
    indentedCommentEnd
end

-- Determine the block comment marker using any possibly previously saved 
-- "lastBlockCommentMarkers", or the buffer's "commenttype" settings.
--
function determineBlockCommentMarker(bp, blockCommentMarker)
  if blockCommentMarker == nil then
    -- we have not determined a unique blockCommentMarker
    -- do we have a previous comment marker?
    -- if so ... we should use it
    blockCommentMarker = bp.Buf.Settings["lastBlockCommentMarker"]
    if blockCommentMarker == nil then
      -- we have no previous block comment marker so use commentype
      blockCommentMarker = bp.Buf.Settings["commenttype"]
      if blockCommentMarker ~= nil then
        blockCommentMarker = blockCommentMarker:match("(%S+)")
      end
      if blockCommentMarker == nil then
        blockCommentMarker = "#"
      end
    end
  end
  -- store the current comment marker for possible later use
  bp.Buf.Settings["lastBlockCommentMarker"] = blockCommentMarker
  return blockCommentMarker
end

-- The reWrapText.commentBlock function
--
function commentBlock(bp, arg)
  local firstLine, lastLine, indentEnd, blockCommentMarker, indentedCommentEnd =
    determineBlockStructure(bp)
  --
  if firstLine == nil or lastLine == nil then return end
  --
  -- determine what the comment marker should be...
  --
  blockCommentMarker = determineBlockCommentMarker(bp, blockCommentMarker)
  --
  local commentMarker = ""
  if indentEnd + 1 == indentedCommentEnd then
    -- we have an uncommented block... so add comment marker
    commentMarker = blockCommentMarker.." "
  else
    commentMarker = ""
    indentedCommentEnd = indentedCommentEnd + 1
  end
  --
  -- now comment/uncomment the block
  --
  local curLine = firstLine
  while curLine <= lastLine do
    local curLineStr = bp.Buf:Line(curLine)
    local indentStr  = curLineStr:sub(1, indentEnd)
    local restOfStr  = curLineStr:sub(indentedCommentEnd)
    bp.Buf:Replace(
      buffer.Loc(0, curLine),
      buffer.Loc(#curLineStr, curLine),
      indentStr .. commentMarker .. restOfStr
    )
    curLine = curLine + 1
  end
  bp.Cursor:SetSelectionStart(buffer.Loc(0, firstLine))
  lastLineStr = bp.Buf:Line(lastLine)
  bp.Cursor:SetSelectionEnd(
    buffer.Loc(#lastLineStr, lastLine)
  )
end

-- Append a value (string) to a table for later concatenating
--
local function appendValue(aTable, aValue)
  aTable[#aTable+1] = aValue
end

-- ReWrap the text provided as a collection of words
-- returns a table of the re-wrapped lines of text
--
local function reWrapWords(someLines, textWidth, indentStr)
  --
  -- Split a collection of strings into component "words"
  -- by splitting on white space
  -- inspired by http://lua-users.org/wiki/SplitJoin
  -- Example: splitOnWhiteSpace("this is\ta\ntest ")
  --
  local someWords = {}
  for i, aString in ipairs(someLines) do
    aString:gsub("(%S+)", function(c) appendValue(someWords, c) end)
  end
  --
  -- now re-wrap the text
  --
  local newText = {}
  local indentLen = indentStr:len()
  appendValue(newText, indentStr)
  local lineLength = indentLen
  for i, aWord in ipairs(someWords) do
    if textWidth < (lineLength + aWord:len() + 1) then
      appendValue(newText, "\n")
      appendValue(newText, indentStr)
      appendValue(newText, aWord)
      appendValue(newText, " ")
      lineLength = indentLen + aWord:len() + 1
    else
      appendValue(newText, aWord)
      appendValue(newText, " ")
      lineLength = lineLength + aWord:len() + 1
    end
  end
  return table.concat(newText)
end

-- The reWrapText.reWrapText function
--
function reWrapText(bp, args)
  local firstLine, lastLine, indentEnd, blockCommentMarker, indentedCommentEnd =
    determineBlockStructure(bp)
  if firstLine == nil then
    bp.Cursor:UpN(-1)
    return
  end
  local someLines = {}
  local curLine = firstLine
  while curLine <= lastLine do
    local curLineStr = bp.Buf:Line(curLine)
    local restOfStr  = curLineStr:sub(indentedCommentEnd)
    appendValue(someLines, restOfStr)
    curLine = curLine + 1
  end
  --
  -- determine the text width
  --
  local textWidth = bp.Buf.Settings["textWidth"]
  if textWidth == nil then
    textWidth = config.GetGlobalOption("reWrapText.textWidth")
  end
  if textWidth == nil then
    textWidth = 75
  end
  --
  local lastLineStr = bp.Buf:Line(lastLine)
  if blockCommentMarker == nil then
    indentedCommentEnd = indentedCommentEnd - 1
  end
  local indentStr = lastLineStr:sub(1,indentedCommentEnd)
  local newText = reWrapWords(someLines, textWidth, indentStr)
  --
  -- Now replace the text
  --
  bp.Buf:Replace(
    buffer.Loc(0, firstLine),
    buffer.Loc(#lastLineStr, lastLine),
    newText
  )
  bp.Cursor:UpN(-1)
end

-- Initialize the reWrapText plugin
--
function init()
  --
  config.RegisterCommonOption("reWrapText", "textWidth", 75)
  config.RegisterCommonOption("reWrapText", "commentLineMarkers",
    "// # -- ; >")
  --
  config.MakeCommand("selectCommentedBlock", selectCommentedBlock,
    config.NoComplete)
  config.MakeCommand("commentBlock", commentBlock,
    config.NoComplete)
  config.MakeCommand("reWrapText", reWrapText, config.NoComplete)
  --
  config.TryBindKey("Alt-[", "lua:reWrapText.selectCommentedBlock", true)
  config.TryBindKey("Alt-]", "lua:reWrapText.commentBlock", true)
  config.TryBindKey("Alt-j", "lua:reWrapText.reWrapText", true)
  --
  config.AddRuntimeFile("reWrapText", config.RTHelp, "help/reWrapText.md")
end
