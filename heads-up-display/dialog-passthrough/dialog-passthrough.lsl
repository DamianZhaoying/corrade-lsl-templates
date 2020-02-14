///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2016 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
//
// This script is a passthrough or proxy script for dialogs received by
// Corrade. The script binds to Corrade's dialog notification and then any
// dialog received by Corrade gets sent to you. When you press a button on
// the dialog, Corrade will press the button on the dialog it received.
//
// For more information on Corrade, please see:
//     http://grimore.org/secondlife/scripted_agents/corrade
//
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2015 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
string wasKeyValueGet(string k, string data) {
    if(llStringLength(data) == 0) return "";
    if(llStringLength(k) == 0) return "";
    list a = llParseString2List(data, ["&", "="], []);
    integer i = llListFindList(llList2ListStrided(a, 0, -1, 2), [ k ]);
    if(i != -1) return llList2String(a, 2*i+1);
    return "";
}
 
///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2013 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
string wasKeyValueEncode(list data) {
    list k = llList2ListStrided(data, 0, -1, 2);
    list v = llList2ListStrided(llDeleteSubList(data, 0, 0), 0, -1, 2);
    data = [];
    do {
        data += llList2String(k, 0) + "=" + llList2String(v, 0);
        k = llDeleteSubList(k, 0, 0);
        v = llDeleteSubList(v, 0, 0);
    } while(llGetListLength(k) != 0);
    return llDumpList2String(data, "&");
}

///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2015 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
// escapes a string in conformance with RFC1738
string wasURLEscape(string i) {
    string o = "";
    do {
        string c = llGetSubString(i, 0, 0);
        i = llDeleteSubString(i, 0, 0);
        if(c == "") jump continue;
        if(c == " ") {
            o += "+";
            jump continue;
        }
        if(c == "\n") {
            o += "%0D" + llEscapeURL(c);
            jump continue;
        }
        o += llEscapeURL(c);
@continue;
    } while(i != "");
    return o;
}

///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2015 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
list wasCSVToList(string csv) {
    list l = [];
    list s = [];
    string m = "";
    do {
        string a = llGetSubString(csv, 0, 0);
        csv = llDeleteSubString(csv, 0, 0);
        if(a == ",") {
            if(llList2String(s, -1) != "\"") {
                l += m;
                m = "";
                jump continue;
            }
            m += a;
            jump continue;
        }
        if(a == "\"" && llGetSubString(csv, 0, 0) == a) {
            m += a;
            csv = llDeleteSubString(csv, 0, 0);
            jump continue;
        }
        if(a == "\"") {
            if(llList2String(s, -1) != a) {
                s += a;
                jump continue;
            }
            s = llDeleteSubList(s, -1, -1);
            jump continue;
        }
        m += a;
@continue;
    } while(csv != "");
    // postcondition: length(s) = 0
    return l + m;
}

///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2015 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
// unescapes a string in conformance with RFC1738
string wasURLUnescape(string i) {
    return llUnescapeURL(
        llDumpList2String(
            llParseString2List(
                llDumpList2String(
                    llParseString2List(
                        i, 
                        ["+"], 
                        []
                    ), 
                    " "
                ), 
                ["%0D%0A"], 
                []
            ), 
            "\n"
        )
    );
}

// callback URL
string callback = "";
// configuration data
string configuration = "";
// listen handle
integer listenHandle = 0;

// store dialog details
key dialog_item = NULL_KEY;
key dialog_id = NULL_KEY;
integer dialog_channel = 0;
list dialog_buttons = [];
string dialog_message = "";

default {
    state_entry() {
        llSetTimerEvent(1);
    }
    link_message(integer sender, integer num, string message, key id) {
        if(sender != 1 || id != "configuration") return;
        configuration = message;
        state off;
    }
    timer() {
        llMessageLinked(LINK_ROOT, 0, "configuration", NULL_KEY);
    }
    attach(key id) {
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START) || (change & CHANGED_OWNER)) {
            llResetScript();
        }
    }
    state_exit() {
        llSetTimerEvent(0);
    }
}

state off {
    state_entry() {
        llReleaseControls();
        llSetColor(<.5,0,0>, ALL_SIDES);
    }
    touch_end(integer num) {
        state on;
    }
    attach(key id) {
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START) || (change & CHANGED_OWNER)) {
            llResetScript();
        }
    }
}

state on {
    state_entry() {
        llSetColor(<0,.5,0>, ALL_SIDES);
        state url;
    }
    attach(key id) {
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START) || (change & CHANGED_OWNER)) {
            llResetScript();
        }
    }
}

state url {
    state_entry() {
        // DEBUG
        llOwnerSay("Requesting URL...");
        llRequestURL();
    }
    touch_end(integer num) {
        llSetColor(<.5,0,0>, ALL_SIDES);
        llResetScript();
    }
    http_request(key id, string method, string body) {
        if(method != URL_REQUEST_GRANTED) return;
        callback = body;
        // DEBUG
        llOwnerSay("Got URL...");
        state dialog;
    }
    attach(key id) {
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START) || (change & CHANGED_OWNER)) {
            llResetScript();
        }
    }
}

state dialog {
    state_entry() {
        // DEBUG
        llOwnerSay("Binding to the dialog notification...");
        llInstantMessage(
            (key)wasKeyValueGet(
                "corrade", 
                configuration
            ), 
            wasKeyValueEncode(
                [
                    "command", "notify",
                    "group", wasURLEscape(
                        wasKeyValueGet(
                            "group", 
                            configuration
                        )
                    ),
                    "password", wasURLEscape(
                        wasKeyValueGet(
                            "password", 
                            configuration
                        )
                    ),
                    "action", "set",
                    "type", "dialog",
                    "URL", wasURLEscape(callback),
                    "callback", wasURLEscape(callback)
                ]
            )
        );
        llSetTimerEvent(60);
    }
    touch_end(integer num) {
        llSetColor(<.5,0,0>, ALL_SIDES);
        llResetScript();
    }
    timer() {
        // DEBUG
        llOwnerSay("Timeout binding to the dialog notification...");
        llResetScript();
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "notify" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Failed to bind to the dialog notification..." + wasKeyValueGet("error", body));
            llResetScript();
        }
        // DEBUG
        llOwnerSay("Dialog notification installed...");
        state main;
    }
    attach(key id) {
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START) || (change & CHANGED_OWNER)) {
            llResetScript();
        }
    }
    state_exit() {
        llSetTimerEvent(0);
    }
}

state main {
    state_entry() {
        // DEBUG
        llOwnerSay("Waiting for dialog...");
        llSetTimerEvent(1);
    }
    touch_end(integer num) {
        state uninstall;
    }
    timer() {
        llRequestAgentData(
            (key)wasKeyValueGet(
                "corrade", 
                configuration
        ), DATA_ONLINE);
    }
    dataserver(key id, string data) {
        if(data != "1") llResetScript();
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        
        // get the dialog id
        dialog_id = (key)wasURLUnescape(
            wasKeyValueGet(
                "id", 
                body
            )
        );
                
        // get the dialog message
        dialog_message = wasURLUnescape(
            wasKeyValueGet(
                "message", 
                body
            )
        );
        
        // get the UUID of the object sending the dialog
        dialog_item = (key)wasURLUnescape(
            wasKeyValueGet(
                "item", 
                body
            )
        );
        
        // get the channel that the dialog was sent on
        dialog_channel = (integer)wasURLUnescape(
            wasKeyValueGet(
                "channel", 
                body
            )
        );
        
        // get the buttons that the dialog has
        dialog_buttons = llList2ListStrided(
                llDeleteSubList(
                    wasCSVToList(
                        wasURLUnescape(
                            wasKeyValueGet(
                                "button", 
                                body
                            )
                        )
                    ),
                    0,
                    1
                ),
            0,
            -1,
            2
        );
        
        // DEBUG
        llOwnerSay("Got buttons: " + llDumpList2String(dialog_buttons, "|"));
        listenHandle = llListen(-14, "", llGetOwner(), "");
        llDialog(llGetOwner(), "[CORRADE]: " + dialog_message, dialog_buttons, -14);
    }
    listen(integer channel, string name, key id, string message) {
        llListenRemove(listenHandle);
        integer index = llListFindList(dialog_buttons, (list)message);
        if(index == -1) {
            // DEBUG
            llOwnerSay("Button index not found...");
            return;
        }
        
        llInstantMessage(
            wasKeyValueGet(
                "corrade", 
                configuration
            ), 
            wasKeyValueEncode(
                [
                    "command", "replytoscriptdialog",
                    "group", wasURLEscape(
                        wasKeyValueGet(
                            "group", 
                            configuration
                        )
                    ),
                    "password", wasURLEscape(
                        wasKeyValueGet(
                            "password", 
                            configuration
                        )
                    ),
                    "action", "reply",
                    "dialog", dialog_id,
                    "button", wasURLEscape(message),
                    "index", index
                ]
            )
        );
    }
    attach(key id) {
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START) || (change & CHANGED_OWNER)) {
            llResetScript();
        }
    }
    state_exit() {
        llSetTimerEvent(0);
    }
}

state uninstall {
    state_entry() {
        // DEBUG
        llOwnerSay("Uninstalling dialog notification...");
        llInstantMessage(
            (key)wasKeyValueGet(
                "corrade", 
                configuration
            ), 
            wasKeyValueEncode(
                [
                    "command", "notify",
                    "group", wasURLEscape(
                        wasKeyValueGet(
                            "group", 
                            configuration
                        )
                    ),
                    "password", wasURLEscape(
                        wasKeyValueGet(
                            "password", 
                            configuration
                        )
                    ),
                    "action", "remove",
                    "type", "dialog",
                    "URL", wasURLEscape(callback),
                    "callback", wasURLEscape(callback)
                ]
            )
        );
        llSetTimerEvent(60);
    }
    timer() {
        // DEBUG
        llOwnerSay("Timeout uninstalling the dialog notification...");
        llResetScript();
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "notify" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Failed to uninstall the dialog notification..." + wasKeyValueGet("error", body));
            llResetScript();
        }
        // DEBUG
        llOwnerSay("Dialog notification uninstalled...");
        llResetScript();
    }
    attach(key id) {
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START) || (change & CHANGED_OWNER)) {
            llResetScript();
        }
    }
}
