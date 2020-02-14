///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2014 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
//
// This is an automatic grid follower for the Corrade Second Life / OpenSim 
// bot. You can find more details about the bot by following the URL: 
// http://was.fm/secondlife/scripted_agents/corrade
//
// The follower script works together with a "configuration" notecard and 
// that must be placed in the same primitive as this script. 
// You are free to use, change, and commercialize it under the CC BY 2.0 
// license at: https://creativecommons.org/licenses/by/2.0
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
//    Copyright (C) 2011 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
vector wasCirclePoint(float radius) {
    float x = llPow(-1, 1 + (integer) llFrand(2)) * llFrand(radius*2);
    float y = llPow(-1, 1 + (integer) llFrand(2)) * llFrand(radius*2);
    if(llPow(x,2) + llPow(y,2) <= llPow(radius,2))
        return <x, y, 0>;
    return wasCirclePoint(radius);
}

///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2014 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
integer wasIsAvatarInSensorRange(key avatar) {
    return llListFindList(
        llGetAgentList(
            AGENT_LIST_REGION, 
            []
        ), 
        (list)((key)avatar)
    ) != -1 && 
        llVecDist(
            llGetPos(), 
            llList2Vector(
                llGetObjectDetails(
                    avatar, 
                    [OBJECT_POS]
                ), 
            0
        )
    ) <= 96;
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

// corrade data
string CORRADE = "";
string GROUP = "";
string PASSWORD = "";
string RANGE = "";

// for holding the callback URL
string callback = "";

// for notecard reading
integer line = 0;
 
// key-value data will be read into this list
list tuples = [];
 
default {
    state_entry() {
        // set color for button
        llSetColor(<1,1,0>, ALL_SIDES);
        if(llGetInventoryType("configuration") != INVENTORY_NOTECARD) {
            llOwnerSay("Sorry, could not find an inventory notecard.");
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
            CORRADE = llList2String(
                          tuples,
                          llListFindList(
                              tuples, 
                              [
                                  "corrade"
                              ]
                          )
                      +1);
            if(CORRADE == "") {
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
                      +1);
            if(GROUP == "") {
                llOwnerSay("Error in configuration notecard: password");
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
                      +1);
            if(GROUP == "") {
                llOwnerSay("Error in configuration notecard: group");
                return;
            }
            RANGE = llList2String(
                          tuples,
                          llListFindList(
                              tuples, 
                              [
                                  "range"
                              ]
                          )
                      +1);
            if(RANGE == "") {
                llOwnerSay("Error in configuration notecard: range");
                return;
            }
            // DEBUG
            llOwnerSay("Read configuration file...");
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
        state off;
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

state off {
    state_entry() {
        // set color for button
        llSetColor(<1,0,0>, ALL_SIDES);
    }
    touch_start(integer num) {
        state on;
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
 
state on {
    state_entry() {
        // set color for button
        llSetColor(<0,1,0>, ALL_SIDES);
        // if Corrade is in-range then just follow
        if(wasIsAvatarInSensorRange(CORRADE)) state follow;
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
        llSensorRepeat("", (key)CORRADE, AGENT, (integer)RANGE, TWO_PI, 5);
    }
    no_sensor() {
        // DEBUG
        llOwnerSay("Teleporting Corrade...");
        llInstantMessage((key)CORRADE, 
            wasKeyValueEncode(
                [
                    "command", "teleport",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "entity", "region",
                    "region", wasURLEscape(llGetRegionName()),
                    "position", llGetPos() + wasCirclePoint((integer)RANGE),
                    "callback", callback
                ]
            )
        );
    }
    sensor(integer num) {
        llSetTimerEvent(0);
        state follow;
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "teleport" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Teleport failed...");
            return;
        }
        llSetTimerEvent(0);
        state follow;
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
 
state follow {
    state_entry() {
        // DEBUG
        llOwnerSay("In follow state...");
        // check every second whether Corrade is online
        llRequestAgentData(CORRADE, DATA_ONLINE);
    }
    touch_start(integer num) {
        state off;
    }
    dataserver(key id, string data) {
        // if Corrade is not online
        if(data != "1") state on;
        // Corrade is online, so attempt to dectect
        llSensorRepeat("", CORRADE, AGENT, (integer)RANGE, TWO_PI, 1);
    }
    no_sensor() {
        // check if Corrade is in range, and if not, start detecting
        if(!wasIsAvatarInSensorRange(CORRADE)) state on;
        // Corrade is in sensor range, so execute move.
        llInstantMessage(CORRADE, 
            wasKeyValueEncode(
                [
                    "command", "autopilot",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    // move in a radius around the current primitive.
                    "position", llGetPos() + wasCirclePoint((integer)RANGE),
                    "action", "start"
                ]
            )
        );
        llSensorRepeat("", CORRADE, AGENT, (integer)RANGE, TWO_PI, 1);
        llRequestAgentData(CORRADE, DATA_ONLINE);
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