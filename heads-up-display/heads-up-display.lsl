///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2016 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
//
// A template HUD script for Corrade that reads a configuration notecard
// and then feeds that configuration to various other components of the HUD
// that request the configuration. Additionally, this HUD is programmed to
// "fold" and "unfold" depending on whether Corrade is online or not. For 
// more information on the Corrade scripted agent please see the URL:
// http://grimore.org/secondlife/scripted_agents/corrade
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

// for notecard reading
integer line = 0;
 
// key-value data will be read into this list
list tuples = [];
// Corrade's online status.
integer online = FALSE;
integer open = FALSE;
string URL = "";

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
            key CORRADE = llList2Key(
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
            string GROUP = llList2String(
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
            string PASSWORD = llList2String(
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
            string VERSION = llList2String(
                tuples,
                llListFindList(
                    tuples, 
                    [
                        "version"
                    ]
                )
            +1);
            if(VERSION == "") {
                llOwnerSay("Error in configuration notecard: version");
                return;
            }
            // DEBUG
            llOwnerSay("Read configuration notecard...");
            state configuration;
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
    attach(key id) {
        llResetScript();
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

state configuration {
    state_entry() {
        // DEBUG
        llOwnerSay("Configuration ready...");
        llMessageLinked(LINK_SET, 0, "retract", NULL_KEY);
        llSetTimerEvent(1);
    }
    timer() {
        llRequestAgentData(
            (key)wasKeyValueGet(
                "corrade", 
                wasKeyValueEncode(tuples)
            ),
            DATA_ONLINE
        );
        llSetTimerEvent(5);
    }
    dataserver(key id, string data) {
        if(data != "1") {
            if(online == TRUE) {
                // DEBUG
                llOwnerSay("Corrade is not online, shutting down...");
                llMessageLinked(LINK_SET, 0, "retract", NULL_KEY);
                online = FALSE;
            }
            return;
        }
        online = TRUE;
    }
    touch_start(integer total_number) {
        if(!open && online) {
            // DEBUG
            llOwnerSay("Getting URL...");
            llRequestURL();
            return;
        }
        llMessageLinked(LINK_SET, 0, "retract", NULL_KEY);
        open = FALSE;
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        llReleaseURL(URL);
        string configuration = wasKeyValueEncode(tuples);
        if(method == URL_REQUEST_GRANTED) {
            llOwnerSay("Checking version...");
           
            URL = body;
            llInstantMessage(
                wasKeyValueGet(
                    "corrade",
                    configuration
                ),
                wasKeyValueEncode(
                    [
                        "command", "version",
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
                        "callback", wasURLEscape(URL)
                     ]
                )
            );
            return;
        }
        if(wasKeyValueGet("command", body) != "version" ||
            wasKeyValueGet("success", body) != "True") {
            llOwnerSay("Version check failed...");
            return;
        }
        list corradeVersion = llParseString2List(
            wasKeyValueGet(
                "data",
                body
            ),
            ["."],
            []
        );
        //integer receivedVersion = (integer)(llList2String(v, 0) + llList2String(v, 1));
        list notecardVersion = llParseString2List(
            wasKeyValueGet(
                "version",
                configuration
            ),
            ["."],
            []
        );
        //llOwnerSay((string)receivedVersion);
        //integer notecardVersion = (integer)(llList2String(v, 0) + llList2String(v, 1));
        if(llList2Integer(corradeVersion, 0) >= llList2Integer(notecardVersion, 0) || llList2Integer(corradeVersion, 1) >= llList2Integer(notecardVersion, 1)) {
            llOwnerSay("Version is compatible. Deploying HUD...");
            llMessageLinked(LINK_SET, 0, "deploy", NULL_KEY);
            open = TRUE;
            return;
        }
        llOwnerSay("HUD version is incompatible! You need a Corrade of at least version: " +
            wasKeyValueGet(
                "version",
                configuration
            ) +
            " for this HUD."
        );
        llMessageLinked(LINK_SET, 0, "retract", NULL_KEY);
        open = FALSE;
        return;
    }
    link_message(integer sender, integer num, string message, key id) {
        if(message != "configuration") return;
        llMessageLinked(sender, 0, wasKeyValueEncode(tuples), "configuration");
    }
    attach(key id) {
        llResetScript();
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
