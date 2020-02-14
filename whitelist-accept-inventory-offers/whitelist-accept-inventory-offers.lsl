///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2014 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
// All inventory offers made to Corrade can be processed for rejection   //
// approval by scripts. Corrade by default accepts inventory offers from //
// masters defined in Corrade.ini - however, it would be useful to write //
// an example script that takes a list of avatars and automatically      //
// accepts all the items. More information on the Corrade scripted agent //
// can be found at: http://was.fm/secondlife/scripted_agents/corrade     //
//
// The script works in combination with a "configuration" notecard that  //
// must be placed in the same primitive as this script. The purpose of   //
// this script is to demonstrate accepting inventory offers with the     //
// Corrade scripted agent and  you are free to use, and commercialize it //
// under the terms of the CC BY 2.0 license which can be found at:       // 
// https://creativecommons.org/licenses/by/2.0                                  //
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

// corrade data and configuration parameters
key CORRADE = NULL_KEY;
string GROUP = "";
string PASSWORD = "";
list WHITELIST = [];

// for holding the callback URL
string callback = "";

// for notecard reading
integer line = 0;
 
// key-value data will be read into this list
list tuples = [];

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
            WHITELIST = wasCSVToList(
                llToUpper(
                    llList2String(
                        tuples,
                        llListFindList(
                            tuples, 
                            [
                                "whitelist"
                            ]
                        )
                        +1
                    )
                )
            );
            if(WHITELIST == []) {
                llOwnerSay("Error in configuration notecard: whitelist");
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
        llOwnerSay("Binding to the inventory notification...");
        llInstantMessage(
            (key)CORRADE, 
            wasKeyValueEncode(
                [
                    "command", "notify",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "action", "set",
                    "type", "inventory",
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
            llOwnerSay("Failed to bind to the inventory notification: " + 
                wasURLUnescape(
                    wasKeyValueGet(
                        "error", 
                        body
                    )
                )
            );
            state detect;
        }
        // DEBUG
        llOwnerSay("Inventory notification installed...");
        state accept;
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

state accept {
    state_entry() {
        // DEBUG
        llOwnerSay("Waiting for inventory offers...");
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
        
        string direction = wasURLUnescape(
            wasKeyValueGet(
                "direction", 
                body
            )
        );
        
        // Only care about offers being sent to Corrade.
        if(direction != "offer") return;
        
        // Search the whitelist for the full name in case
        // an agent is sending the inventory item.
        string firstname = llToUpper(
            wasURLUnescape(
                wasKeyValueGet(
                    "firstname", 
                    body
                )
            )
        );
        string lastname = llToUpper(
            wasURLUnescape(
                wasKeyValueGet(
                    "lastname", 
                    body
                )
            )
        );
        
        if(firstname != "" && 
            lastname != "" && 
            llListFindList(WHITELIST, (list)(firstname + " " + lastname)) != -1)
                jump accept;
        
        // Search the whitelist for the UUID of the owner 
        // of the object offering the item in case an object 
        // is offering the inventory item
        string agent = llToUpper(
            wasURLUnescape(
                wasKeyValueGet(
                    "agent",
                    body
                )
            )
        );
        
        // Also search by UUID in case one was provided
        if(agent != NULL_KEY && 
            llListFindList(WHITELIST, (list) agent) != -1)
                jump accept;
            
        // No matches so return.
        return;
        
@accept;

        key session = (key)wasURLUnescape(
            wasKeyValueGet(
                "session", 
                body
            )
        );
        
        // Oops, this should not happen!
        if(session == NULL_KEY) return;

        // Accept the inventory item.
        llInstantMessage(CORRADE, 
            wasKeyValueEncode(
                [

                    "command", "replytoinventoryoffer",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "action", "accept", // or decline
                    // can be retrieved from the inventory notification
                    "session", (string)session
                    // "callback", wasURLEscape(URL) // we do not care
                ]
            )
        );
        
        // DEBUG
        string item = wasURLUnescape(
            wasKeyValueGet(
                "item", 
                body
            )
        );
        string asset = wasURLUnescape(
            wasKeyValueGet(
                "asset", 
                body
            )
        );
        llOwnerSay("Accepted: " + asset + " " + item);
        
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
