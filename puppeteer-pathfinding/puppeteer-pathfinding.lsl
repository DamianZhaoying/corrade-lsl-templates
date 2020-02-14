///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2014 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
//
// This is a puppeteer script for the Corrade Second Life / OpenSim bot
// that, given a set of local coordinates, will make the bot traverse a 
// path while also minding collisions with object. You can find more 
// details about the Corrade bot and how to get it to work on your machine
// by following the URL: http://grimore.org/secondlife/scripted_agents/corrade
//
// This script works together with a "configuration" notecard that must 
// be placed in the same primitive as this script. The purpose of this 
// script is to demonstrate how Corrade can be made to walk on a path and 
// you are free to use, change, and commercialize it under the CC BY 2.0 
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

// corrade data
key CORRADE = NULL_KEY;
string GROUP = "";
string PASSWORD = "";
list PATH = [];
float PAUSE = 0;
integer RANDOMIZE = FALSE;

// for holding the callback URL
string callback = "";

// for notecard reading
integer line = 0;
 
// key-value data will be read into this list
list tuples = [];
// stores COrrade's current position
vector origin = ZERO_VECTOR;

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
            +1);
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
            +1);
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
            +1);
            if(PASSWORD == "") {
                llOwnerSay("Error in configuration notecard: password");
                return;
            }
            PATH = llCSV2List(
                llList2String(
                    tuples,
                    llListFindList(
                        tuples, 
                        [
                            "path"
                        ]
                    )
                +1)
            );
            if(PATH == []) {
                llOwnerSay("Error in configuration notecard: points");
                return;
            }
            PAUSE = llList2Float(
                tuples,
                llListFindList(
                    tuples, 
                    [
                        "pause"
                    ]
                )
            +1);
            if(PAUSE == 0) {
                llOwnerSay("Error in configuration notecard: pause");
                return;
            }
            string boolean = llList2String(
                tuples,
                llListFindList(
                    tuples, 
                    [
                        "randomize"
                    ]
                )
            +1);
            if(llToLower(boolean) == "true") RANDOMIZE = TRUE;
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
        llOwnerSay("Binding to the collision notification...");
        llInstantMessage(
            (key)CORRADE, 
            wasKeyValueEncode(
                [
                    "command", "notify",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "action", "set",
                    "type", "collision",
                    "URL", wasURLEscape(callback),
                    "callback", wasURLEscape(callback)
                ]
            )
        );
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "notify" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Failed to bind to the collisioin notification...");
            state detect;
        }
        // DEBUG
        llOwnerSay("Collision notification installed...");
        state pause;
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

state pause { 
    state_entry() {
        //DEBUG
        llOwnerSay("Pausing...");
        // Check whether Corrade is still online first.
        llRequestAgentData((key)CORRADE, DATA_ONLINE);
    }
    dataserver(key id, string data) {
        if(data != "1") {
            // DEBUG
            llOwnerSay("Corrade is not online, sleeping...");
            llSetTimerEvent(30);
            return;
        }
        // Corrade is online, so schedule the next walk.
        if(RANDOMIZE) {
            // The minimal trigger time for a timer event is ~0.045s
            // This ensures we do not end up stuck in the pause state.
            llSetTimerEvent(0.045 + llFrand(PAUSE - 0.045));
            return;
        }
        llSetTimerEvent(PAUSE);
    }
    timer() {
        llSetTimerEvent(0);
        state find;
    }
}

state find {
    state_entry() {
        // We now query Corrade for its current position.
        llInstantMessage(CORRADE, 
            wasKeyValueEncode(
                [
                    "command", "getselfdata",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "data", "SimPosition",
                    "callback", wasURLEscape(callback)
                ]
            )
        );
        // alarm 60 for Corrade not responding
        llSetTimerEvent(60);
    }
    timer() {
        llSetTimerEvent(0);
        // DEBUG
        llOwnerSay("Corrade not responding to data query...");
        state pause;
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        list data = wasCSVToList(
            wasKeyValueGet(
                "data", 
                wasURLUnescape(body)
            )
        );
        origin= (vector)llList2String(
            data, 
            llListFindList(
                data, 
                (list)"SimPosition"
            )+1
        );
        state walk;
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

state walk {
    state_entry() {
        // DEBUG
        llOwnerSay("Walking...");
        
        // extract next destination and permute the set
        vector next = (vector)llList2String(PATH, 0);
        PATH = llDeleteSubList(PATH, 0, 0);
        PATH += next;
        
        llInstantMessage(CORRADE, 
            wasKeyValueEncode(
                [
                    "command", "autopilot",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "position", next,
                    "action", "start"
                ]
            )
        );
        // We now determine the waiting time for Corrade to reach
        // its next destination by extracting time as a function
        // of the distance it has to walk and the speed of travel:
        // t = s / v
        // This, of course, is prone to error since the distance
        // is calculated on the shortest direct path. Nevertheless,
        // it is a pretty good appoximation for terrain that is 
        // mostly flat and without too many curvatures.
        // NB. 3.20 m/s is the walking speed of an avatar.
        llSetTimerEvent(llVecDist(origin, next)/3.20);
    }
    http_request(key id, string method, string body) {
        // since we have bound to the collision notification, 
        // this region of code deals with Corrade colliding 
        // with in-world assets; in which case, we stop 
        // moving to not seem awkward
        
        // DEBUG
        llOwnerSay("Collided...");
        
        llHTTPResponse(id, 200, "OK");
        
        llInstantMessage(CORRADE, 
            wasKeyValueEncode(
                [
                    "command", "autopilot",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "action", "stop"
                ]
            )
        );
        // We did not reach our destination since we collided with 
        // something on our path, so switch directly to waiting and 
        // attempt to reach the next destination on our path.
        state pause;
    }
    timer() {
        // We most likely reached our destination, so switch to pause.
        llSetTimerEvent(0);
        state pause;
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

