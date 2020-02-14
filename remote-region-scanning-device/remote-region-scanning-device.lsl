///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2014 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
//
// This is a device meant to scan regions and show metrics for the Corrade
// Second Life / OpenSim bot. You can find more details about the bot
// by following the URL: http://was.fm/secondlife/scripted_agents/corrade
//
// The script works in conjunction with a "configuration" notecard and a 
// "regions" notecard that must both be placed in the same primitive.
// The purpose of this script is to demonstrate scanning with Corrade and 
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
string wasListToCSV(list l) {
    list v = [];
    do {
        string a = llDumpList2String(
            llParseStringKeepNulls(
                llList2String(
                    l, 
                    0
                ), 
                ["\""], 
                []
            ),
            "\"\""
        );
        if(llParseStringKeepNulls(a, [" ", ",", "\n"], []) != (list) a)
            a = "\"" + a + "\"";
        v += a;
        l = llDeleteSubList(l, 0, 0);
    } while(l != []);
    return llDumpList2String(v, ",");
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
    // invariant: length(s) = 0
    return l + m;
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

// for holding the callback URL
string callback = "";

// for notecard reading
integer line = 0;
 
// key-value data will be read into this list
list tuples = [];
// regions will be stored here
list regions = [];
string region = "";

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
            // DEBUG
            llOwnerSay("Read configuration notecard...");
            state read;
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

state read {
    state_entry() {
        if(llGetInventoryType("regions") != INVENTORY_NOTECARD) {
            llOwnerSay("Sorry, could not find a regions inventory notecard.");
            return;
        }
        // DEBUG
        llOwnerSay("Reading regions notecard...");
        line = 0;
        llGetNotecardLine("regions", line);
    }
    dataserver(key id, string data) {
        if(data == EOF) {
            // DEBUG
            llOwnerSay("Read regions notcard...");
            state url;
        }
        if(data == "") jump continue;
        regions += data;
@continue;
        llGetNotecardLine("regions", ++line);
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
        state teleport;
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

state teleport {
    state_entry() {
        // Timeout in one minute.
        llSetTimerEvent(60);
        // Check that Corrade is online.
        llSensorRepeat("", NULL_KEY, AGENT, 0.1, 0.1, 5);
        // Shuffle the regions and grab the next region.
        region = llList2String(regions, 0);
        regions = llDeleteSubList(regions, 0, 0);
        regions += region;
        // DEBUG
        llOwnerSay("Teleporting to: " + region);
        llInstantMessage(
            (key)CORRADE, 
            wasKeyValueEncode(
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
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "teleport" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Failed to teleport to " + region + " due to: " + 
                wasURLUnescape(
                    wasKeyValueGet(
                        "error", 
                        body
                    )
                )
            );
            // Jump to trampoline for re-entry.
            state teleport_trampoline;
        }
        // DEBUG
        llOwnerSay("Teleported successfully to: " + region);
        state stats_trampoline;
    }
    no_sensor() {
        llRequestAgentData((key)CORRADE, DATA_ONLINE);
    }
    dataserver(key id, string data) {
        if(data != "1") {
            // DEBUG
            llOwnerSay("Corrade is not online, sleeping...");
            state detect;
        }
    }
    timer() {
        state teleport_trampoline;
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

state teleport_trampoline {
    state_entry() {
        // DEBUG
        llOwnerSay("Sleeping...");
        llSetTimerEvent(30);
    }
    timer() {
        state teleport;
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

state stats_trampoline {
    state_entry() {
        // DEBUG
        llOwnerSay("Sleeping...");
        llSetTimerEvent(10);
    }
    timer() {
        state stats;
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

state stats {
    state_entry() {
        // Timeout in one minute.
        llSetTimerEvent(60);
        // Check that Corrade is online.
        llSensorRepeat("", NULL_KEY, AGENT, 0.1, 0.1, 5);
        // DEBUG
        llOwnerSay("Fetching region statistics...");
        llInstantMessage(
            (key)CORRADE, 
            wasKeyValueEncode(
                [
                    "command", "getregiondata",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "data", wasListToCSV([
                        // For a full list see: http://was.fm/secondlife/scripted_agents/corrade/application_programming_interface#get_region_data
                        "Stats.LastLag", 
                        "Stats.Agents",
                        "Stats.Dilation",
                        "Stats.FPS",
                        "Stats.ActiveScripts",
                        "Stats.ScriptTime",
                        "Stats.Objects",
                        "Stats.PhysicsFPS",
                        "Stats.ScriptTime"
                    ]),
                    "callback", wasURLEscape(callback) 
                ]
            )
        );
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "getregiondata" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Failed to get stats for " + region + " due to: " + 
                wasURLUnescape(
                    wasKeyValueGet(
                        "error", 
                        body
                    )
                )
            );
            // Jump to trampoline for teleport.
            state teleport_trampoline;
        }
        // DEBUG
        llOwnerSay("Got stats for region: " + region);
        // Get the stats and unescape.
        list stat = wasCSVToList(
            wasURLUnescape(
                wasKeyValueGet(
                    "data", 
                    body
                )
            )
        );
        llSetText("-:[ " + region + " ]:- \n" +
            // Show the stats in the overhead text.
            "Agents: " + llList2String(
                stat, 
                llListFindList(
                    stat, 
                    (list)"Stats.Agents"
                )+1
            ) + "\n" + 
            "LastLag: " + llList2String(
                stat, 
                llListFindList(
                    stat, 
                    (list)"Stats.LastLag"
                )+1
            ) + "\n" + 
            "Time Dilation: " + llList2String(
                stat, 
                llListFindList(
                    stat, 
                    (list)"Stats.Dilation"
                )+1
            ) + "\n" + 
            "FPS: " + llList2String(
                stat, 
                llListFindList(
                    stat, 
                    (list)"Stats.FPS"
                )+1
            ) + "\n" +
            "Physics FPS: " + llList2String(
                stat, 
                llListFindList(
                    stat, 
                    (list)"Stats.PhysicsFPS"
                )+1
            ) + "\n" +
            "Scripts: " + llList2String(
                stat, 
                llListFindList(
                    stat, 
                    (list)"Stats.ActiveScripts"
                )+1
            ) + "\n" +
            "Script Time: " + llList2String(
                stat, 
                llListFindList(
                    stat, 
                    (list)"Stats.ScriptTime"
                )+1
            ) + "\n" +
            "Objects: " + llList2String(
                stat, 
                llListFindList(
                    stat, (list)"Stats.Objects"
                )+1
            ), 
            <1, 0, 0>, 
            1.0
        );
        stat = [];
        state teleport_trampoline;
    }
    no_sensor() {
        llRequestAgentData((key)CORRADE, DATA_ONLINE);
    }
    dataserver(key id, string data) {
        if(data != "1") {
            // DEBUG
            llOwnerSay("Corrade is not online, sleeping...");
            state detect;
        }
    }
    timer() {
        state teleport_trampoline;
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

