///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2014 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
//
// This is an automatic teleporter, sitter and animator for the Corrade
// Second Life / OpenSim bot. You can find more details about the bot
// by following the URL: http://was.fm/secondlife/scripted_agents/corrade
//
// The sit script works together with a "configuration" notecard and an
// animation that must both be placed in the same primitive as this script. 
// The purpose of this script is to demonstrate sitting with Corrade and 
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
//    Copyright (C) 2013 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
integer wasListCountExclude(list input, list exclude) {
    if(llGetListLength(input) == 0) return 0;
    if(llListFindList(exclude, (list)llList2String(input, 0)) == -1) 
        return 1 + wasListCountExclude(llDeleteSubList(input, 0, 0), exclude);
    return wasListCountExclude(llDeleteSubList(input, 0, 0), exclude);
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
string CORRADE = "";
string GROUP = "";
string PASSWORD = "";
string PUNISHMENT = "";
list SPLIT = [];
list ANNOUNCE = [];

// for holding the callback URL
string callback = "";

// for notecard reading
integer line = 0;
 
// key-value data will be read into this list
list tuples = [];
// blacklisted words will be here
list badwords = [];

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
            if(PASSWORD == "") {
                llOwnerSay("Error in configuration notecard: password");
                return;
            }
            PUNISHMENT = llList2String(
                tuples,
                llListFindList(
                    tuples, 
                    [
                        "punishment"
                    ]
                )
            +1);
            if(PUNISHMENT == "") {
                llOwnerSay("Error in configuration notecard: punishment");
                return;
            }
            string split = llList2String(
                tuples,
                llListFindList(
                    tuples, 
                        [
                            "split"
                        ]
                    )
                +1
            );
            do {
                SPLIT += llGetSubString(split, 0, 0);
                split = llDeleteSubString(split, 0, 0);
            } while(llStringLength(split) != 0);
            if(SPLIT == []) {
                llOwnerSay("Error in configuration notecard: split");
                return;
            }
            ANNOUNCE = llCSV2List(
                llList2String(
                    tuples,
                    llListFindList(
                        tuples, 
                            [
                                "announce"
                            ]
                        )
                    +1
                )
            );
            if(ANNOUNCE == []) {
                llOwnerSay("Error in configuration notecard: announce");
                return;
            }
            // DEBUG
            llOwnerSay("Read configuration notecard...");
            state words;
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

state words {
    state_entry() {
        if(llGetInventoryType("badwords") != INVENTORY_NOTECARD) {
            llOwnerSay("Sorry, could not find a blacklist inventory notecard.");
            return;
        }
        // DEBUG
        llOwnerSay("Reading badwords notecard...");
        line = 0;
        llGetNotecardLine("badwords", line);
    }
    dataserver(key id, string data) {
        if(data == EOF) {
            // DEBUG
            llOwnerSay("Read badwords notcard...");
            state url;
        }
        if(data == "") jump continue;
        badwords += data;
@continue;
        llGetNotecardLine("badwords", ++line);
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
        llOwnerSay("Binding to the group chat notification...");
        llInstantMessage(
            (key)CORRADE, 
            wasKeyValueEncode(
                [
                    "command", "notify",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "action", "set",
                    "type", "group",
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
            llOwnerSay("Failed to bind to the group chat notification...");
            state detect;
        }
        // DEBUG
        llOwnerSay("Permission notification installed...");
        state main;
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

state main {
    state_entry() {
        // DEBUG
        llOwnerSay("Waiting for badwords...");
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        
        // split the input
        list input = llParseString2List(
            wasURLUnescape(
                wasKeyValueGet(
                    "message", 
                    body
                )
            ), 
        SPLIT, []);
        
        // now find badwords
        string badword = "";
        do {
            badword = llList2String(input, 0);
            if(llListFindList(badwords, (list)badword) != -1) jump punish;
            input = llDeleteSubList(input, 0, 0);
        } while(llGetListLength(input) != 0);
        return;
        
@punish;

        string firstname = wasURLUnescape(wasKeyValueGet("firstname", body));
        string lastname = wasURLUnescape(wasKeyValueGet("lastname", body));
        
        if(PUNISHMENT == "eject") {
            llOwnerSay("Ejecting: " + firstname + " " + lastname);
            llInstantMessage((key)CORRADE, 
                wasKeyValueEncode(
                    [
                        "command", "eject",
                        "group", wasURLEscape(GROUP),
                        "password", wasURLEscape(PASSWORD),
                        "firstname", wasURLEscape(firstname),
                        "lastname", wasURLEscape(lastname)
                    ]
                )
            );
            jump announce;
        }
        
        llOwnerSay("Muting: " + firstname + " " + lastname);
        llInstantMessage((key)CORRADE, 
            wasKeyValueEncode(
                [
                    "command", "moderate",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "firstname", wasURLEscape(firstname),
                    "lastname", wasURLEscape(lastname),
                    "type", "text",
                    "silence", "true"
                ]
            )
        );
        
@announce;

        // Go through the list of avatars to announce and 
        // tell them who has been ajected and for what word
        integer i = llGetListLength(ANNOUNCE)-1;
        do {
            string full = llList2String(ANNOUNCE, i);
            list name = llParseString2List(full, [" "], []); 
            llInstantMessage((key)CORRADE, 
                wasKeyValueEncode(
                    [
                        "command", "tell",
                        "group", wasURLEscape(GROUP),
                        "password", wasURLEscape(PASSWORD),
                        "entity", "avatar",
                        "firstname", wasURLEscape(llList2String(name, 0)),
                        "lastname", wasURLEscape(llList2String(name, 1)),
                        "message", wasURLEscape(
                            "The avatar " + 
                            firstname + 
                            " " + 
                            lastname + 
                            " was ejecteded from: " + 
                            GROUP + " for saying: \"" + 
                            badword + "\"."
                        )
                    ]
                )
            );
        } while(--i>-1);
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
