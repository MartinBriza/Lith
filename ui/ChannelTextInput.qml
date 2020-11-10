// Lith
// Copyright (C) 2020 Martin Bříza
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; If not, see <http://www.gnu.org/licenses/>.

import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12

import lith 1.0

TextInput {
    id: inputField
    clip: true
    font.pointSize: settings.baseFontSize
    verticalAlignment: TextField.AlignVCenter
    focus: true
    inputMethodHints: Qt.ImhMultiLine
    renderType: TextInput.NativeRendering

    color: palette.text

    property alias inputFieldAlias: inputField

    onAccepted: {
        if (text.length > 0) {
            lith.selectedBuffer.input(text)
            text = ""
        }
    }

    Connections {
        target: lith
        function onSelectedBufferChanged() {
            inputField.focus = true
        }
    }

    Shortcut {
        sequence: StandardKey.Paste
        onActivated: {
             console.warn("HA")
        }
    }
    property int lastCursorPos: 0
    property int matchedNickIndex: 0
    property variant matchedNicks: []

    function autocomplete() {
        // console.log("BEFORE matchedNicks = ", matchedNicks, "LAST=", lastCursorPos, "NOW=", cursorPosition);

        if(matchedNickIndex > matchedNicks.length-1) {
            matchedNickIndex = 0;
        }

        if(matchedNicks.length > 1) {
            if(lastCursorPos == cursorPosition) {
                inputField.text = inputField.text.substring(0,
                                                            inputField.text.length -
                                                            matchedNicks[matchedNickIndex == 0 ? matchedNicks.length-1 : matchedNickIndex - 1].length
                                                            - 2)
                inputField.text += matchedNicks[matchedNickIndex] + ": "

                matchedNickIndex += 1

                lastCursorPos = cursorPosition
                return;
            }
            else {
                // console.warn("ende.")
                matchedNicks = []
                matchedNickIndex = 0
                lastCursorPos = 0
            }
        }

        // TODO: refactor this, I want cursorPosition tabbing still :)
        var i = inputField.text.lastIndexOf(" ");
        var lastWord
        if (i >= 0)
            lastWord = inputField.text.substring(i+1, inputField.text.length).trim().toLocaleLowerCase();
        else {
            i = 0
            lastWord = inputField.text.trim().toLocaleLowerCase()
        }

        var nicks = lith.selectedBuffer.getVisibleNicks()

        for (var y = 0; y < nicks.length; y++) {
            // console.warn("\"" + lastWord + "\" " + nicks[y])
            if (nicks[y].toLocaleLowerCase().startsWith(lastWord) && lastWord !== "") {
                inputField.text = inputField.text.substring(0, i)
                if (i !== 0) {
                    inputField.text += " "
                }
                inputField.text += nicks[y] + ": "
                matchedNicks.push(nicks[y])
            }
        }

        if (matchedNicks.length == 1) {
            matchedNicks = []; // Reset matchedNicks if there's just one match
        }

        lastCursorPos = cursorPosition
    }

    Shortcut {
        sequences: lith.settings.shortcutSearchBuffer
        onActivated: bufferDrawer.open()
    }
    Shortcut {
        sequences: lith.settings.shortcutNicklist
        onActivated: nickDrawer.open()
    }
    Shortcut {
        sequences: lith.settings.shortcutAutocomplete
        onActivated: autocomplete();
    }
    Shortcut {
        sequences: lith.settings.shortcutSwitchToNextBuffer
        onActivated: lith.selectedBufferIndex += 1
    }
    Shortcut {
        sequences: lith.settings.shortcutSwitchToPreviousBuffer
        onActivated: lith.selectedBufferIndex -= 1
    }
    Shortcut {
        enabled: lith.settings.enableReadlineShortcuts
        sequence: "Ctrl+W"
        onActivated: {
            var str = inputField.text.replace(/\s+$/, '')
            var lastIndex = str.lastIndexOf(" ");
            inputField.text = inputField.text.substring(0, lastIndex + 1);
        }
    }
    Shortcut {
        enabled: lith.settings.enableReadlineShortcuts
        sequence: "Ctrl+D"
        onActivated: {
            var str = inputField.text
            str = str.slice(0, inputField.cursorPosition - 1) + str.slice(inputField.cursorPosition);
            inputField.text = str
        }
    }
    Shortcut {
        enabled: lith.settings.enableReadlineShortcuts
        sequence: "Ctrl+K"
        onActivated: {
            var right = inputField.text.slice(inputField.cursorPosition)
            inputField.text = inputField.text.slice(0, inputField.cursorPosition - 1)
            clipboard.setText(right)
        }
    }
    Shortcut {
        enabled: lith.settings.enableReadlineShortcuts
        sequence: "Ctrl+U"
        onActivated: {
            var left = inputField.text.slice(0, inputField.cursorPosition - 1)
            inputField.text = inputField.text.slice(inputField.cursorPosition)
            clipboard.setText(left)
        }
    }
    Shortcut {
        enabled: lith.settings.enableReadlineShortcuts
        sequence: "Ctrl+Y"
        onActivated: {
            if (clipboard.text.length > 0)
                inputField.text = clipboard.text()
        }
    }
    Shortcut {
        enabled: lith.settings.enableReadlineShortcuts
        sequence: "Ctrl+F"
        onActivated: inputField.cursorPosition++
    }
    Shortcut {
        enabled: lith.settings.enableReadlineShortcuts
        sequence: "Ctrl+B"
        onActivated: inputField.cursorPosition--
    }
    Shortcut {
        enabled: lith.settings.enableReadlineShortcuts
        sequence: "Ctrl+A"
        onActivated: inputField.cursorPosition = 0
    }
    Shortcut {
        enabled: lith.settings.enableReadlineShortcuts
        sequence: "Ctrl+E"
        onActivated: inputField.cursorPosition = inputField.text.length
    }
    Keys.onPressed: {
        if (event.modifiers & Qt.ControlModifier) {
            if (event.key === Qt.Key_V) {
                if (clipboard.hasImage) {
                    uploader.uploadBinary(clipboard.image())
                }
                else {
                    inputField.paste()
                }
                event.accepted = true
            }
        }

        if (event.key === Qt.Key_Up) {
            channelMessageList.contentY += 30
        }
        if (event.key === Qt.Key_Down) {
            if (channelMessageList.contentY > 30)
                channelMessageList.contentY -= 30
            else
                channelMessageList.contentY = 0
        }
        if (event.key === Qt.Key_PageUp) {
            channelMessageList.contentY += channelMessageList.height - 30
        }
        if (event.key === Qt.Key_PageDown) {
            if (channelMessageList.contentY > channelMessageList.height)
                channelMessageList.contentY -= channelMessageList.height - 30
            else
                channelMessageList.contentY = 0
        }
        if (event.key === Qt.Key_End) {
            channelMessageList.contentY = 0
        }
    }
}
