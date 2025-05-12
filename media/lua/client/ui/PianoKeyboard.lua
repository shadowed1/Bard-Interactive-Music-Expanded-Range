local OCTAVES_INCLUDED = 7 -- 7 full octaves plus the last C key
local NOTES_IN_SCALE = 7 -- A, B, C, D, E, F, G
local NOTES_INCLUDED = 88 -- 88 keys in total for a full piano

local WHITE_KEY_TEXTURE_WIDTH = 4 * KEY_RATIO
local SPACE_AROUND_WHITE_KEY = 2
local WHITE_KEY_WIDTH = WHITE_KEY_TEXTURE_WIDTH + SPACE_AROUND_WHITE_KEY * 2
local WHITE_KEY_HEIGHT = 27 * KEY_RATIO

local BLACK_KEY_TEXTURE_WIDTH = 3 * KEY_RATIO
local SPACE_AROUND_BLACK_KEY = 0
local BLACK_KEY_WIDTH = BLACK_KEY_TEXTURE_WIDTH + SPACE_AROUND_BLACK_KEY * 2
local BLACK_KEY_HEIGHT = 16 * KEY_RATIO

local WHITE_KEYS = 52
local BLACK_KEYS = 36
local SCALE_WIDTH = WHITE_KEY_WIDTH * NOTES_IN_SCALE

local WIDTH = WHITE_KEY_WIDTH * WHITE_KEYS -- 52 white keys in an 88-key piano
local HEIGHT = WHITE_KEY_HEIGHT + ISCollapsableWindow.TitleBarHeight()

local keyOffsetToNoteName = { 'A', 'B', 'C', 'D', 'E', 'F', 'G' }

-- Updated function to dynamically generate note names across 88 keys
function ScaleOffsetToKeyName(scaleOffset, keyOffset, isSharp)
    local note = keyOffsetToNoteName[(keyOffset % 7) + 1]
    local sharp = isSharp and 's' or ''
    local octave = math.floor(scaleOffset / 7) + (note == "A" or note == "B" and 0 or 1)
    return note .. sharp .. octave
end

-- Updated drawKeys to handle all 88 keys dynamically
function PianoKeyboard:drawKeys()
    local whiteKeyIndex = 0
    for i = 0, 87 do
        local isBlackKey = (i % 12 == 1 or i % 12 == 3 or i % 12 == 6 or i % 12 == 8 or i % 12 == 10)
        if isBlackKey then
            self:drawBlackKey(self.keyPressed[i] ~= nil, whiteKeyIndex * WHITE_KEY_WIDTH - BLACK_KEY_WIDTH / 2)
        else
            self:drawWhiteKey(self.keyPressed[i] ~= nil, whiteKeyIndex * WHITE_KEY_WIDTH)
            whiteKeyIndex = whiteKeyIndex + 1
        end
    end
end

-- Adjust the getKey methods to support all 88 keys
function PianoKeyboard:getKey(x, y)
    return self:getBlackKey(x, y) or self:getWhiteKey(x, y)
end

function PianoKeyboard:getWhiteKey(x, y)
    if y < self:titleBarHeight() or y > HEIGHT or x < 0 or x > WIDTH then
        return nil
    end
    local keyIndex = math.floor(x / WHITE_KEY_WIDTH)
    local noteIndex = keyIndex + 1
    return ScaleOffsetToKeyName(noteIndex, (noteIndex - 1) % 7, false)
end

function PianoKeyboard:getBlackKey(x, y)
    if y < self:titleBarHeight() or y > HEIGHT or x < 0 or x > WIDTH then
        return nil
    end
    local whiteKeyIndex = math.floor(x / WHITE_KEY_WIDTH)
    local i = (x - whiteKeyIndex * WHITE_KEY_WIDTH)
    
    -- Only black keys are in the specified positions
    if (i >= (WHITE_KEY_WIDTH - BLACK_KEY_WIDTH) / 2) and (i <= (WHITE_KEY_WIDTH + BLACK_KEY_WIDTH) / 2) then
        local noteIndex = whiteKeyIndex
        return ScaleOffsetToKeyName(noteIndex, (noteIndex - 1) % 7, true)
    end
end


function PianoKeyboard:pressBlackKey(x, y)
    local keyName = self:getBlackKey(x, y)
    if keyName == nil then
        return false
    end
    self.keyPressed[keyName] = true
    self.currentKeyPressed = keyName
    MusicPlayer.getInstance():playNote(getPlayer():getOnlineID(), self.instrument, keyName, self:isDistorted())
    BardClientSendCommands.sendStartNote(getPlayer():getOnlineID(), self.instrument, keyName, self:isDistorted())
    return true
end

function PianoKeyboard:pressWhiteKey(x, y)
    local keyName = self:getWhiteKey(x, y)
    if keyName == nil then
        return false
    end
    self.keyPressed[keyName] = true
    self.currentKeyPressed = keyName
    MusicPlayer.getInstance():playNote(getPlayer():getOnlineID(), self.instrument, keyName, self:isDistorted())
    BardClientSendCommands.sendStartNote(getPlayer():getOnlineID(), self.instrument, keyName, self:isDistorted())
    return true
end

function PianoKeyboard:onMouseDown(x, y)
    if not self:pressKeyWithMouse(x, y) then
        -- copied from ISCollapsableWindow.lua onMouseDown()
        -- calling the function was not working
        if not self:getIsVisible() then
            return
        end
        self.downX = x
        self.downY = y
        self.moving = true
        self:bringToTop()
    end
end

function PianoKeyboard:releaseKeyWithMouse()
    self.keyPressed[self.currentKeyPressed] = nil
    if self.currentKeyPressed ~= nil then
        MusicPlayer.getInstance():stopNote(getPlayer():getOnlineID(), self.currentKeyPressed)
        BardClientSendCommands.sendStopNote(getPlayer():getOnlineID(), self.currentKeyPressed)
    end
    self.currentKeyPressed = nil
end

function PianoKeyboard:onMouseUp(x, y)
    if self.currentKeyPressed ~= nil then
        self:releaseKeyWithMouse()
    end

    -- copied from ISCollapsableWindow.lua onMouseUp()
    -- calling the function was not working
    if not self:getIsVisible() then
        return
    end
    self.moving = false
    if ISMouseDrag.tabPanel then
        ISMouseDrag.tabPanel:onMouseUp(x, y)
    end
    ISMouseDrag.dragView = nil
end

function PianoKeyboard:onMouseUpOutside(x, y)
    if self.currentKeyPressed ~= nil then
        self:releaseKeyWithMouse()
    end

    -- copied from ISCollapsableWindow.lua onMouseUpOutside()
    -- calling the function was not working
    if not self:getIsVisible() then
        return
    end

    self.moving = false
    ISMouseDrag.dragView = nil
end

function PianoKeyboard:onMouseMove(x, y)
    if self.currentKeyPressed ~= nil then
        local keyOvered = self:getKey(self:getMouseX(), self:getMouseY())
        if keyOvered ~= self.currentKeyPressed then
            self:releaseKeyWithMouse()
            if keyOvered ~= nil then
                self:pressKeyWithMouse(self:getMouseX(), self:getMouseY())
            end
        end
    end

    -- copied from ISCollapsableWindow.lua onMouseMove()
    -- calling the function was not working
    self.mouseOver = true;

    if self.moving then
        self:setX(self.x + x);
        self:setY(self.y + y);
        self:bringToTop();
        --ISMouseDrag.dragView = self;
    end
    if not isMouseButtonDown(0) and not isMouseButtonDown(1) and not isMouseButtonDown(2) then
        self:uncollapse();
    end
end

function PianoKeyboard:onMouseMoveOutside(dx, dy)
    if self.currentKeyPressed ~= nil then
        self:releaseKeyWithMouse()
    end

    -- copied from ISCollapsableWindow.lua onMouseMoveOutside()
    -- calling the function was not working
    self.mouseOver = false;

    if self.moving then
        self:setX(self.x + dx);
        self:setY(self.y + dy);
        self:bringToTop();
    end

    if not self.pin and (self:getMouseX() < 0 or self:getMouseY() < 0 or self:getMouseX() > self:getWidth() or self:getMouseY() > self:getHeight()) then
        self.collapseCounter = self.collapseCounter + 1;

        local bDo = true;

        if self.collapseCounter > 20 and not self.isCollapsed and bDo then
            self.isCollapsed = true;
            self:setMaxDrawHeight(self:titleBarHeight());
        end
    end
end

function PianoKeyboard:markPressedKey(keyName)
    self.keyPressed[keyName] = true
end

function PianoKeyboard:markReleasedKey(keyName)
    self.keyPressed[keyName] = nil
    if keyName == self.currentKeyPressed then
        self.currentKeyPressed = nil
    end
end

function PianoKeyboard:onShowNotesButton(button)
    self.isShowingNotes = not self.isShowingNotes
    self.showNotesButton:setImage(
        self.isShowingNotes and self.showNotesOnImage or self.showNotesOffImage)
end

function PianoKeyboard:onShowKeybindsButton(button)
    self.isShowingKeybinds = not self.isShowingKeybinds
    self.showKeybindsButton:setImage(
        self.isShowingKeybinds and self.showKeybindsOnImage or self.showKeybindsOffImage)
end

function PianoKeyboard:onDistortionButton(button)
    self:setDistortion(not self.distorted)
end

function PianoKeyboard:setDistortion(isDistorted)
    self.distorted = isDistorted
    self.distortionButton:setImage(
        isDistorted and self.distortionButtonOnImage or self.distortionButtonOffImage)
end

function PianoKeyboard:isDistorted()
    return self.distorted
end

return PianoKeyboard
