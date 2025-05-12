local TABasePlayMusicFrom = ISBaseTimedAction:derive('TABasePlayMusicFrom');

local MusicNotes = require 'MusicNotes'
local MusicPlayer = require 'MusicPlayer'
local BardClientSendCommands = require 'BardClientSendCommands'
local KeybindManager = require 'KeybindManager'
local PianoKeyboard = require 'ui/PianoKeyboard'

function TABasePlayMusicFrom:new(character, instrument, hasDistortion)
    local o = ISBaseTimedAction:new(character)
    setmetatable(o, self)
    self.__index = self
    o.instrument = instrument
    o.hasDistortion = hasDistortion
    o.stopOnWalk = true
    o.stopOnRun = true
    o.stopOnAim = true
    o.maxTime = -1
    o.handItem = nil
    o.isPlaying = false
    o.eventAdded = false
    o.keyboard = nil
    return o
end

function TABasePlayMusicFrom:onKeyPressed(key)
    if not self.isPlaying then
        return
    end
    for octave = 2, 5 do
        for _, noteName in pairs(MusicNotes) do
            local fullNote = noteName .. octave
            if key == getCore():getKey('BardNote' .. fullNote) then
                local playerId = getPlayer():getOnlineID()
                BardClientSendCommands.sendStartNote(playerId, self.instrument, fullNote, self.keyboard:isDistorted())
                MusicPlayer.getInstance():playNote(playerId, self.instrument, fullNote, self.keyboard:isDistorted())
                self.keyboard:markPressedKey(fullNote)
            end
        end
    end
end

function TABasePlayMusicFrom:onKeyReleased(key)
    if not self.isPlaying then
        return
    end
    for octave = 2, 5 do
        for _, noteName in pairs(MusicNotes) do
            local fullNote = noteName .. octave
            if key == getCore():getKey("BardNote" .. fullNote) then
                local playerId = getPlayer():getOnlineID()
                BardClientSendCommands.sendStopNote(playerId, fullNote)
                MusicPlayer.getInstance():stopNote(playerId, fullNote)
                self.keyboard:markReleasedKey(fullNote)
            end
        end
    end
end

function TABasePlayMusicFrom:isValid()
    return true
end

local KeyToNote = {
    ['`'] = 'A0',  
    ['1'] = 'As0',
    ['2'] = 'B0',
    ['3'] = 'C1',
    ['4'] = 'Cs1',
    ['5'] = 'D1',
    ['6'] = 'Ds1',
    ['7'] = 'E1',
    ['8'] = 'F1',
    ['9'] = 'Fs1',
    ['0'] = 'G1',
    ['-'] = 'Gs1',
    ['='] = 'A1',

    ['Q'] = 'As1',
    ['W'] = 'B1',
    ['E'] = 'C2',
    ['R'] = 'Cs2',
    ['T'] = 'D2',
    ['Y'] = 'Ds2',
    ['U'] = 'E2',
    ['I'] = 'F2',
    ['O'] = 'Fs2',
    ['P'] = 'G2',
    ['['] = 'Gs2',
    [']'] = 'A2',

    ['A'] = 'As2',
    ['S'] = 'B2',
    ['D'] = 'C3',
    ['F'] = 'Cs3',
    ['G'] = 'D3',
    ['H'] = 'Ds3',
    ['J'] = 'E3',
    ['K'] = 'F3',
    ['L'] = 'Fs3',
    [';'] = 'G3',
    ['\''] = 'Gs3',

    ['Z'] = 'A3',
    ['X'] = 'As3',
    ['C'] = 'B3',
    ['V'] = 'C4',
    ['B'] = 'Cs4',
    ['N'] = 'D4',
    ['M'] = 'Ds4',
    [','] = 'E4',
    ['.'] = 'F4',
    ['/'] = 'Fs4',

    ['~'] = 'G4',
    ['!'] = 'Gs4',
    ['@'] = 'A4',
    ['#'] = 'As4',
    ['$'] = 'B4',
    ['%'] = 'C5',
    ['^'] = 'Cs5',
    ['&'] = 'D5',
    ['*'] = 'Ds5',
    ['('] = 'E5',
    [')'] = 'F5',
    ['_'] = 'Fs5',
    ['+'] = 'G5',

    ['Q'] = 'Gs5',
    ['W'] = 'A5',
    ['E'] = 'As5',
    ['R'] = 'B5',
    ['T'] = 'C6',
    ['Y'] = 'Cs6',
    ['U'] = 'D6',
    ['I'] = 'Ds6',
    ['O'] = 'E6',
    ['P'] = 'F6',
    ['{'] = 'Fs6',
    ['}'] = 'G6',

    ['A'] = 'Gs6',
    ['S'] = 'A6',
    ['D'] = 'As6',
    ['F'] = 'B6',
    ['G'] = 'C7',
    ['H'] = 'Cs7',
    ['J'] = 'D7',
    ['K'] = 'Ds7',
    ['L'] = 'E7',
    [':'] = 'F7',
    ['"'] = 'Fs7',

    ['Z'] = 'G7',
    ['X'] = 'Gs7',
    ['C'] = 'A7',
    ['V'] = 'As7',
    ['B'] = 'B7',
    ['N'] = 'C8'
}


function TABasePlayMusicFrom:start()
    if not self.eventAdded then
        -- no mistake here, the KeyPressed event is named OnKeyStartPressed
        -- and the KeyReleased event is named OnKeyPressed, blame PZ
        self.onKeyPressedLambda = function(key)
            self:onKeyPressed(key)
        end
        self.onKeyReleasedLambda = function(key)
            self:onKeyReleased(key)
        end
        Events.OnKeyStartPressed.Add(self.onKeyPressedLambda)
        Events.OnKeyPressed.Add(self.onKeyReleasedLambda)
        self.eventAdded = true
    end
    for key, _ in pairs(KeyToNote) do
        KeybindManager.getInstance():disableKey(key, 'bard')
    end
    self.isPlaying = true
    self.keyboard = PianoKeyboard:new(self.instrument, self.hasDistortion)
end

function TABasePlayMusicFrom:terminateAction()
    Events.OnKeyStartPressed.Remove(self.onKeyPressedLambda)
    Events.OnKeyPressed.Remove(self.onKeyReleasedLambda)
    KeybindManager.getInstance():restoreKeys()
    self.keyboard:close()
    self.isPlaying = false
    MusicPlayer.getInstance():stopPlayer(function(note)
        BardClientSendCommands.sendStopNote(self.character:getOnlineID(), note)
    end)
end

function TABasePlayMusicFrom:stop()
    self:terminateAction()
    ISBaseTimedAction.stop(self)
end

function TABasePlayMusicFrom:update()
    if self.keyboard.closing then
        self:forceStop()
    end
end

-- I don't think this can be called as the action has no time limit
-- stop should be the last function called before the object ends
function TABasePlayMusicFrom:perform()
    self:terminateAction()
    ISBaseTimedAction.perform(self)
end

KeybindManager.getInstance():addCategory('[Bard]')
for key, note in pairs(KeyToNote) do
    KeybindManager.getInstance():addBinding(key, 'BardNote' .. note, 'bard')
end

return TABasePlayMusicFrom
