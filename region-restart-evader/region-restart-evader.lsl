///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2016 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
//
// This project makes Corrade, the Second Life / OpenSim bot evade region 
// restarts by teleporting to other regions. More details about  Corrade 
// can be found at the URL: 
// 
//     http://grimore.org/secondlife/scripted_agents/corrade
//
// The script works in combination with a "configuration" notecard that 
// must be placed in the same primitive as this script. The purpose of this 
// script is to illustrate how region restarts can be evaded with Corrade 
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

// hold all the escape regions
list REGIONS = [];
// the home region name
string HOME_REGION = "";
vector HOME_POSITION = ZERO_VECTOR;
// holds the restat delay dynamically
integer RESTART_DELAY = 0;

// for holding the callback URL
string callback = "";

// for notecard reading
integer line = 0;
 
// key-value data will be read into this list
list tuples = [];

// jump label
string setjmp = "";

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
            REGIONS = wasCSVToList(
                llList2String(
                    tuples,
                    llListFindList(
                        tuples, 
                        [
                            "regions"
                        ]
                    )
                    +1
                )
            );
            if(REGIONS == []) {
                llOwnerSay("Error in configuration notecard: regions");
                return;
            }
            HOME_REGION = llList2String(
                tuples,
                llListFindList(
                    tuples, 
                    [
                        "home"
                    ]
                )
                +1
            );
            if(HOME_REGION == "") {
                llOwnerSay("Error in configuration notecard: home");
                return;
            }
            HOME_POSITION = (vector)llList2String(
                tuples,
                llListFindList(
                    tuples, 
                    [
                        "position"
                    ]
                )
                +1
            );
            if(HOME_POSITION == ZERO_VECTOR) {
                llOwnerSay("Error in configuration notecard: position");
                return;
            }
            // DEBUG
            llOwnerSay("Read configuration notecard...");
            
            // The notecard has been read, so get and URL and switch into detect.
            setjmp = "detect";
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
        
        // Jump table
        if(setjmp == "detect") state detect;
        if(setjmp == "recall") state recall;
        
        // Here be HALT.
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if((change & CHANGED_INVENTORY)) {
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
        llOwnerSay("Binding to the alert notification...");
        llInstantMessage(
            (key)CORRADE, 
            wasKeyValueEncode(
                [
                    "command", "notify",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "action", "set",
                    "type", "alert",
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
            llOwnerSay("Failed to bind to the alert notification...");
            state sense;
        }
        // DEBUG
        llOwnerSay("Alert notification installed...");
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
        llOwnerSay("Waiting for alert messages for region restarts...");
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
        // Get the number of minutes after which the region will go down.
        RESTART_DELAY = llList2Integer(
            llParseString2List(
                wasURLUnescape(
                    wasKeyValueGet(
                        "message",
                        body
                    )
                ), 
                [
                    " will restart in ", 
                    " minutes."
                ],
                []
            ),
            1
        );
        
        if(RESTART_DELAY == 0) return;

        // DEBUG
        llOwnerSay("Attempting to evade region restart...");

        // Evade!
        state evade;
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

state evade_trampoline {
    state_entry() {
        state evade;
    }
}

state evade {
    state_entry() {
        // DEBUG
        llOwnerSay("Teleporting Corrade out of the region...");
        // Alarm 60
        llSetTimerEvent(60);
        // Shuffle regions.
        string region = llList2String(REGIONS, 0);
        REGIONS = llDeleteSubList(REGIONS, 0, 0);
        REGIONS += region;
        llInstantMessage(
            (key)CORRADE, wasKeyValueEncode(
                [
                    "command", "teleport",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "entity", "region",
                    "region", wasURLEscape(region),
                    "callback", wasURLEscape(callback)
                ]
            )
        );
    }
    timer() {
        state evade_trampoline;
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        // This message was most likely not for us.
        if(wasKeyValueGet("command", body) 
            != "teleport") return;
        if(wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Failed teleport, retrying...");
            state evade_trampoline;
        }
        
        // DEBUG
        llOwnerSay("Corrade evaded region restart...");
        
        state confront;
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

/*
 * This state is suspended for the duration of the simulator downtime.
 * Effects: 
 *   - callback URL is lost
 *   - timer is resumed
 *   - CHANGED_REGION_RESTART raised
 */
state confront {
    state_entry() {
        // Marty! The future is in the past. 
        //     The past is in the future! - Doc Brown, Back To The Future
        //
        // Schedule an event after the scheduled restart delay 
        // sent to the region plus some convenience offset (60s).
        //
        // Even if the region is not back up after the restart
        // delay and the convenience offset, the script will not
        // be running anyway since the sim will be offline and 
        // will be suspended.
        //
        // Instead, when the region is back up, the timer will
        // resume and the script will eventually raise the event.
        llSetTimerEvent(RESTART_DELAY * 60 + 60);
    }
    timer() {
        // Ok, either the region has restarted or the event was raised.
        //
        // Refresh the URL and then recall.
        setjmp = "recall";
        state url;
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if(change & CHANGED_INVENTORY) {
            llResetScript();
        }
    }
    state_exit() {
        llSetTimerEvent(0);
    }
}

state recall_trampoline {
    state_entry() {
        state recall;
    }
}

state recall {
    state_entry() {
        // DEBUG
        llOwnerSay("Teleporting Corrade back to the home region...");
        // Alarm 60
        llSetTimerEvent(60);
        llInstantMessage(
            (key)CORRADE, wasKeyValueEncode(
                [
                    "command", "teleport",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "entity", "region",
                    "region", wasURLEscape(HOME_REGION),
                    "position", wasURLEscape((string)HOME_POSITION),
                    "callback", wasURLEscape(callback)
                ]
            )
        );
    }
    timer() {
        state recall_trampoline;
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        // This message was most likely not for us.
        if(wasKeyValueGet("command", body) 
            != "teleport") return;
        if(wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Failed teleport, retrying...");
            state recall_trampoline;
        }
        
        // DEBUG
        llOwnerSay("Corrade teleported to home region...");
        
        // We are back to the home region now.
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
    state_exit() {
        llSetTimerEvent(0);
    }
}
