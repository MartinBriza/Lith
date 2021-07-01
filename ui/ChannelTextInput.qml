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

TextField {
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
            if (lith.selectedBuffer.input(text)) {
                text = ""
            }
        }
    }

    Connections {
        target: lith
        function onSelectedBufferChanged() {
            inputField.focus = true
        }
    }

    property int lastCursorPos: 0
    property int matchedNickIndex: 0
    property variant matchedNicks: []

    function pasteText(pasted) {
        var left = text.slice(0, selectionStart)
        //var mid = text.slice(selectionStart, selectionEnd)
        var right = text.slice(selectionEnd)
        text = left + pasted + right
        cursorPosition = left.length + pasted.length
    }

    function autocomplete() {
        console.log("BEFORE matchedNicks = ", matchedNicks, "LAST=", lastCursorPos, "NOW=", cursorPosition);

        if(matchedNickIndex > matchedNicks.length-1) {
            matchedNickIndex = 0;
        }

        if(matchedNicks.length > 1) {
            if(lastCursorPos == cursorPosition) {
                /*inputField.text = inputField.text.substring(0,
                                                            (inputField.text.length) -
                                                            (matchedNicks[matchedNickIndex == 0 ? matchedNicks.length-1 : matchedNickIndex - 1].length) -
                                                            (inputField.text.endsWith(": ") ? 2 : 1)
                                                            )*/

                var prevNick = matchedNicks[matchedNickIndex == 0 ? matchedNicks.length - 1 : matchedNickIndex - 1];
                console.log("prevNick =", prevNick);
                var tmp_msg_str_before_nick = inputField.text.substring(0, cursorPosition - prevNick.length);
                console.log("0, ", cursorPosition - prevNick.length);
                var tmp_msg_str_after_nick = inputField.text.substring(cursorPosition, inputField.text.length);

                //console.log("Bla = ", bla);

                /*inputField.text = inputField.text.substring(0,
                                                            (inputField.text.length) -
                                                            (matchedNicks[matchedNickIndex == 0 ? matchedNicks.length-1 : matchedNickIndex - 1].length) -
                                                            (inputField.text.endsWith(": ") ? 2 : 1)
                                                            )*/
                inputField.text = ""
                inputField.text += tmp_msg_str_before_nick
                inputField.text += matchedNicks[matchedNickIndex] + " "
                inputField.text += tmp_msg_str_after_nick

                // This needs to be on a seperate line as we are working based of the current cursor position AFTER adding the nickname, ugh
                //inputField.text += cursorPosition - matchedNicks[matchedNickIndex].length === 0 ? ": " : " "

                matchedNickIndex += 1

                cursorPosition = cursorPosition - matchedNicks[matchedNickIndex]
                lastCursorPos = cursorPosition
                return;
            }
            else {
                console.warn("ende.")
                matchedNicks = []
                matchedNickIndex = 0
                lastCursorPos = 0
            }
        }

        var i = -1; // This is the starting position if the message is empty

        // Like indexOf, but let's go backwards from the current curpos
        for(var x = cursorPosition - 1; x >= 0; x--) // TODO: ACcurate????
        {
            if(inputField.text.charAt(x) == " ")
            {
                i = x;
                break;
            }
        }

        //var i = inputField.text.indexOf(" ", cursorPosition);
        var lastWord
        if (i >= 0) {
            //lastWord = inputField.text.substring(i+1, inputField.text.length).trim().toLocaleLowerCase();
            lastWord = inputField.text.substring(i+1, cursorPosition).trim().toLocaleLowerCase();

            console.log("lastWord = ", lastWord);
        }
        else {
            i = 0
            lastWord = inputField.text.trim().toLocaleLowerCase()
        }

        var nicks = lith.selectedBuffer.getVisibleNicks()

        for (var y = 0; y < nicks.length; y++) {
            // console.warn("\"" + lastWord + "\" " + nicks[y])
            if (nicks[y].toLocaleLowerCase().startsWith(lastWord) && lastWord !== "") {
                if(matchedNicks.length < 1) // We only want to add the first nick to the message for now
                {
                    var tmp_orig = inputField.text.substring(0, i)
                    var tmp_to_add = ""; // Since we have sometimes have ": " and " ", let's store it seperately for the cursorPosition hack

                    if (i !== 0) {
                        tmp_to_add += " "
                        tmp_to_add += nicks[y] + " "
                    }
                    else {
                        //tmp_to_add += nicks[y] + ": "
                        // TODO: JUST FOR TESTING, REMOVE ME
                        tmp_to_add += " "
                        tmp_to_add += nicks[y] + " "
                    }

                    // Add the text before the tabbed "lastWord", then add the nickname and finally add the text that was there after the tabbed "lastWord"
                    inputField.text = tmp_orig + tmp_to_add + inputField.text.substring(i + lastWord.length + 1, inputField.text.length)

                    // Hack back the cursorPosition since we used inputField.text = which messed it up to the end
                    cursorPosition = i + tmp_to_add.length
                }

                matchedNicks.push(nicks[y]) // But add all of them to the list to be used when Tab is used again
            }
        }

        if (matchedNicks.length == 1) {
            matchedNicks = []; // Reset matchedNicks if there's just one match
        }
        else
        {
            matchedNickIndex += 1; // We need to add + 1 to the index, since we already matched the first one (0) here ^
        }

        lastCursorPos = cursorPosition
    }

    Connections {
        target: uploader
        onSuccess: {
            if (inputField.length !== 0 && !inputField.text.endsWith(" "))
                inputField.pasteText(" ")
            inputField.pasteText(url + " ")
        }
        onError: {
            console.warn("IMAGE UPLOAD ERROR")
            console.warn(message)
            lith.errorString = message
        }
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
        sequences: lith.settings.shortcutSwitchToBuffer1
        onActivated: lith.switchToBufferNumber(1)
    }
    Shortcut {
        sequences: lith.settings.shortcutSwitchToBuffer2
        onActivated: lith.switchToBufferNumber(2)
    }
    Shortcut {
        sequences: lith.settings.shortcutSwitchToBuffer3
        onActivated: lith.switchToBufferNumber(3)
    }
    Shortcut {
        sequences: lith.settings.shortcutSwitchToBuffer4
        onActivated: lith.switchToBufferNumber(4)
    }
    Shortcut {
        sequences: lith.settings.shortcutSwitchToBuffer5
        onActivated: lith.switchToBufferNumber(5)
    }
    Shortcut {
        sequences: lith.settings.shortcutSwitchToBuffer6
        onActivated: lith.switchToBufferNumber(6)
    }
    Shortcut {
        sequences: lith.settings.shortcutSwitchToBuffer7
        onActivated: lith.switchToBufferNumber(7)
    }
    Shortcut {
        sequences: lith.settings.shortcutSwitchToBuffer8
        onActivated: lith.switchToBufferNumber(8)
    }
    Shortcut {
        sequences: lith.settings.shortcutSwitchToBuffer9
        onActivated: lith.switchToBufferNumber(9)
    }
    Shortcut {
        sequences: lith.settings.shortcutSwitchToBuffer10
        onActivated: lith.switchToBufferNumber(10)
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
            clipboardProxy.setText(right)
        }
    }
    Shortcut {
        enabled: lith.settings.enableReadlineShortcuts
        sequence: "Ctrl+U"
        onActivated: {
            var left = inputField.text.slice(0, inputField.cursorPosition - 1)
            inputField.text = inputField.text.slice(inputField.cursorPosition)
            clipboardProxy.setText(left)
        }
    }
    Shortcut {
        enabled: lith.settings.enableReadlineShortcuts
        sequence: "Ctrl+Y"
        onActivated: {
            if (clipboardProxy.text.length > 0)
                inputField.text = clipboardProxy.text()
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
        if (event.matches(StandardKey.Paste)) {
            if (clipboardProxy.hasImage()) {
                uploader.uploadBinary(clipboardProxy.image())
            }
            else {
                pasteText(clipboardProxy.text())
            }
            event.accepted = true
        }

        if (event.key === Qt.Key_Up) {
            channelMessageList.contentY += 30
        }
        if (event.key === Qt.Key_Down) {
            if (channelMessageList.contentY > 35)
                channelMessageList.contentY -= 30
            else
                channelMessageList.positionViewAtBeginning()
        }
        if (event.key === Qt.Key_PageUp) {
            channelMessageList.contentY += channelMessageList.height - 30
        }
        if (event.key === Qt.Key_PageDown) {
            if (channelMessageList.contentY > channelMessageList.height - 35)
                channelMessageList.contentY -= channelMessageList.height - 30
            else
                channelMessageList.positionViewAtBeginning()
        }
        if (event.key === Qt.Key_End) {
            channelMessageList.contentY = 0
        }
    }
}
