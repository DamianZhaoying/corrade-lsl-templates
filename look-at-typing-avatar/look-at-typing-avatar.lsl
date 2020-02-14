///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2014 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
//
// This project makes Corrade, the Second Life / OpenSim bot look at the 
// avatars typing in local chat. You can find more details about the bot
// at the URL: http://grimore.org/secondlife/scripted_agents/corrade
//
// The script works in combination with a "configuration" notecard that 
// must be placed in the same primitive as this script. The purpose of this 
// script is to show setting and disposing of viewer effects with Corrade 
// and you are free to use, change, and commercialize it under the terms 
// of the CC BY 2.0 license at: https://creativecommons.org/licenses/by/2.0
//
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2014 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
string wasKeyValueGet(string k, string data) {
    if(llStringLength(data) == 0) return "";
    if(llStringLength(k) == 0) return "";
    list a = llParseString2List(data, ["&", "="], []);
    integer i = llListFindList(a, [ k ]);
    if(i != -1) return llList2String(a, i+1);
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

// corrade data
key CORRADE = NULL_KEY;
string GROUP = "";
string PASSWORD = "";
// the look UUID
key LOOK = NULL_KEY;
// the effect to use
string EFFECT = "look";
key EFFECT_UUID = NULL_KEY;
string EFFECT_TYPE = "";
integer EFFECT_DURATION = 10;

// for holding the callback URL
string callback = "";

// for notecard reading
integer line = 0;
 
// key-value data will be read into this list
list tuples = [];

// the name to look at
string firstName = "";
string lastName = "";

default {
    state_entry() {
        if(llGetInventoryType("configuration") != INVENTORY_NOTECARD) {
            llOwnerSay("Sorry, could not find a configuration inventory notecard.");
            return;
        }
        // DEBUG
        llOwnerSay("Reading configuration file...");
        llGetNotecardLine("configuration", line);
    }
    dataserver(key id, string data) {
        if(data == EOF) {
            // invariant, length(tuples) % 2 == 0
            if(llGetListLength(tuples) % 2 != 0) {
                llOwnerSay("Error in configuration notecard.");
                return;
            }
            CORRADE = llList2Key(
                tuples,
                llListFindList(
                    tuples, 
                    [
                        "corrade"
                    ]
                )
                +1
            );
            if(CORRADE == NULL_KEY) {
                llOwnerSay("Error in configuration notecard: corrade");
                return;
            }
            GROUP = llList2String(
                tuples,
                llListFindList(
                    tuples, 
                    [
                        "group"
                    ]
                )
                +1
            );
            if(GROUP == "") {
                llOwnerSay("Error in configuration notecard: group");
                return;
            }
            PASSWORD = llList2String(
                tuples,
                llListFindList(
                    tuples, 
                    [
                        "password"
                    ]
                )
                +1
            );
            if(PASSWORD == "") {
                llOwnerSay("Error in configuration notecard: password");
                return;
            }
            EFFECT = llToLower(
                llList2String(
                    tuples,
                    llListFindList(
                        tuples, 
                        [
                            "effect"
                        ]
                    )
                    +1
                )
            );
            if(EFFECT != "look" && EFFECT != "point") {
                llOwnerSay("Error in configuration notecard: effect");
                return;
            }
            if(EFFECT == "look") {
                EFFECT_UUID = llList2Key(
                    tuples,
                    llListFindList(
                        tuples, 
                        [
                            "lookUUID"
                        ]
                    )
                    +1
                );
                if(EFFECT_UUID == NULL_KEY) {
                    llOwnerSay("Error in configuration notecard: lookUUID");
                    return;
                }
                EFFECT_TYPE = "Focus";
            }
            if(EFFECT == "point") {
                EFFECT_UUID = llList2Key(
                    tuples,
                    llListFindList(
                        tuples, 
                        [
                            "pointUUID"
                        ]
                    )
                    +1
                );
                if(EFFECT_UUID == NULL_KEY) {
                    llOwnerSay("Error in configuration notecard: pointUUID");
                    return;
                }
                EFFECT_TYPE = "Select";
            }
            EFFECT_DURATION = llList2Integer(
                tuples,
                llListFindList(
                    tuples, 
                    [
                        "duration"
                    ]
                )
                +1
            );
            if(EFFECT_DURATION == 0) {
                llOwnerSay("Error in configuration notecard: duration");
                return;
            }
            // DEBUG
            llOwnerSay("Read configuration notecard...");
            state url;
        }
        if(data == "") jump continue;
        integer i = llSubStringIndex(data, "#");
        if(i != -1) data = llDeleteSubString(data, i, -1);
        list o = llParseString2List(data, ["="], []);
        // get rid of starting and ending quotes
        string k = llDumpList2String(
            llParseString2List(
                llStringTrim(
                    llList2String(
                        o, 
                        0
                    ), 
                STRING_TRIM), 
            ["\""], []
        ), "\"");
        string v = llDumpList2String(
            llParseString2List(
                llStringTrim(
                    llList2String(
                        o, 
                        1
                    ), 
                STRING_TRIM), 
            ["\""], []
        ), "\"");
        if(k == "" || v == "") jump continue;
        tuples += k;
        tuples += v;
@continue;
        llGetNotecardLine("configuration", ++line);
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START)) {
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
    http_request(key id, string method, string body) {
        if(method != URL_REQUEST_GRANTED) return;
        callback = body;
        // DEBUG
        llOwnerSay("Got URL...");
        state detect;
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START)) {
            llResetScript();
        }
    }
}
 
state detect {
    state_entry() {
        // DEBUG
        llOwnerSay("Detecting if Corrade is online...");
        llSetTimerEvent(5);
    }
    timer() {
        llRequestAgentData((key)CORRADE, DATA_ONLINE);
    }
    dataserver(key id, string data) {
        if(data != "1") {
            // DEBUG
            llOwnerSay("Corrade is not online, sleeping...");
            llSetTimerEvent(30);
            return;
        }
        state notify;
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START)) {
            llResetScript();
        }
    }
}
 
state notify {
    state_entry() {
        // DEBUG
        llOwnerSay("Binding to the typing notification for local chat...");
        llInstantMessage(
            (key)CORRADE, 
            wasKeyValueEncode(
                [
                    "command", "notify",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "action", "set",
                    "type", "typing",
                    "URL", wasURLEscape(callback),
                    "callback", wasURLEscape(callback)
                ]
            )
        );
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "notify") return;
        if(wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Failed to bind to the typing notification...");
            state sense;
        }
        // DEBUG
        llOwnerSay("Typing notification installed...");
        state sense;
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START)) {
            llResetScript();
        }
    }
}

state sense {
    state_entry() {
        // DEBUG
        llOwnerSay("Waiting for typing messages...");
    }
    timer() {
        llRequestAgentData((key)CORRADE, DATA_ONLINE);
    }
    dataserver(key id, string data) {
        if(data == "1") return;
        // DEBUG
        llOwnerSay("Corrade is not online, sleeping...");
        // Switch to detect loop and wait there for Corrade to come online.
        state detect;
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        firstName = wasURLUnescape(
            wasKeyValueGet(
                "firstname",
                body
            )
        );
        lastName = wasURLUnescape(
            wasKeyValueGet(
                "lastname",
                body
            )
        );
        state delete;
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START)) {
            llResetScript();
        }
    }
}

state delete {
    state_entry() {
        llInstantMessage(
            (key)CORRADE, wasKeyValueEncode(
                [
                    "command", "deleteviewereffect",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "effect", EFFECT,
                    "id", EFFECT_UUID,
                    "callback", wasURLEscape(callback)
                ]
            )
        );
        // alarm 10
        llSetTimerEvent(10);
    }
    timer() {
        state effect;
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        state effect;
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START)) {
            llResetScript();
        }
    }
    state_exit() {
        llSetTimerEvent(0);
    }
}

state effect {
    state_entry() {
        llInstantMessage(
            (key)CORRADE, wasKeyValueEncode(
                [
                    "command", "setviewereffect",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "effect", EFFECT,
                    "offset", ZERO_VECTOR,
                    "firstname", firstName,
                    "lastname", lastName,
                    "type", EFFECT_TYPE,
                    "id", EFFECT_UUID,
                    "callback", wasURLEscape(callback)
                ]
            )
        );
        // alarm 10
        llSetTimerEvent(10);
    }
    timer() {
        state sense;
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) 
            != "setviewereffect") return;
        if(wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Failed to look at...");
            state sense;
        }
        state wait;
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START)) {
            llResetScript();
        }
    }
    state_exit() {
        llSetTimerEvent(0);
    }
}

state wait {
    state_entry() {
        llSetTimerEvent(EFFECT_DURATION);
    }
    timer() {
        llSetTimerEvent(0);
        llInstantMessage(
            (key)CORRADE, wasKeyValueEncode(
                [
                    "command", "deleteviewereffect",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "effect", EFFECT,
                    "id", EFFECT_UUID
                ]
            )
        );
        state sense;
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START)) {
            llResetScript();
        }
    }
    state_exit() {
        llSetTimerEvent(0);
    }
}
