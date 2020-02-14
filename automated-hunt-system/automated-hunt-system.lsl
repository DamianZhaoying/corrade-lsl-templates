///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2014 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
//
// This is an automated hunt system template that illustrates various 
// Corrade commands. You can find out more about the Corrade bot by 
// following the URL: http://was.fm/secondlife/scripted_agents/corrade
//
// This script requires the following Corrade permissions:
//   - movement
//   - notifications
//   - interact
//   - inventory
//   - economy
// It also requires the following Corrade notifications:
//   - permission
//
// The template uses the "[WaS-K] Coin Bag" hunt item and Corrade must have 
// the "[WaS-K] Coin Bag" object in its inventory. Other hunt objects are 
// possible by setting "item" in the "configuration" notecard but the item
// must be sent to Corrade such that it is in the bot's inventory.
// 
// The "configuration" notecard inside the primitive must be changed to
// reflect your settings.
//
// In case of panic, please see the full instructions on the project page:
// http://grimore.org/secondlife/scripted_agents/corrade/projects/in_world/automated_hunt_system
// or ask for help in the [Wizardry and Steamworks]:Support group or contact
// Kira Komarov in-world directly.
//
// This script works together with a "configuration" notecard that must be 
// placed in the same primitive as this script. The purpose of this script 
// to demonstrate an automated hunt system using Corrade and you are free
// to use, change, and commercialize it under the CC BY 2.0  license at: 
// https://creativecommons.org/licenses/by/2.0
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
        if(llParseStringKeepNulls(
            a,
            [" ", ",", "\n", "\""], []
                ) !=
                    (list) a
                        ) a = "\"" + a + "\"";
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
    // postcondition: length(s) = 0
    return l + m;
}
 
 
// corrade data
string CORRADE = "";
string GROUP = "";
string PASSWORD = "";
// holds the name of the item to rez
string ITEM = "";
 
// for holding the callback URL
string callback = "";
 
// for notecard reading
integer line = 0;
 
// key-value data will be read into this list
list tuples = [];
 
// holds the location of hunt items
list POI = [];
list poi = [];
 
default {
    state_entry() {
        llSetText("", <1, 1, 1>, 1.0);
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
                +1
            );
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
            ITEM = llList2String(
                tuples,
                llListFindList(
                    tuples, 
                    [
                        "item"
                    ]
                )
                +1
            );
            if(ITEM == "") {
                llOwnerSay("Error in configuration notecard: item");
                return;
            }
 
            // BEGIN POI
            integer i = llGetListLength(tuples)-1;
            do {
                string n = llList2String(tuples, i);
                if(llSubStringIndex(n, "POI_") != -1) {
                    list l = llParseString2List(n, ["_"], []);
                    if(llList2String(l, 0) == "POI") {
                        integer x = llList2Integer(
                                l, 
                                1
                        )-1;
                        // extend the polygon to the number of points
                        while(llGetListLength(POI) < x)
                            POI += "";
                        // and insert the point at the location
                        POI = llListReplaceList(
                            POI, 
                            (list)(
                                (vector)(
                                "<" + llList2CSV(
                                    llParseString2List(
                                        llList2String(
                                            tuples, 
                                            llListFindList(
                                                tuples, 
                                                (list)n
                                            )
                                            +1
                                        ), 
                                        ["<", ",", ">"], 
                                        []
                                    )
                                ) + ">")
                            ), 
                            x,
                            x
                        );
                    }
                }
            } while(--i>-1);
            // now clean up any empty slots
            i = llGetListLength(POI)-1;
            do {
                if(llList2String(POI, i) == "")
                    POI = llDeleteSubList(POI, i, i);
            } while(--i > -1);
            // END POI
 
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
        llSetTimerEvent(1);
    }
    timer() {
        llRequestAgentData((key)CORRADE, DATA_ONLINE);
    }
    dataserver(key id, string data) {
        if(data != "1") {
            // DEBUG
            llOwnerSay("Corrade is not online, sleeping...");
            llSetTimerEvent(5);
            return;
        }
        state permission;
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
 
state permission {
    state_entry() {
        // DEBUG
        llOwnerSay("Binding to the permission notification...");
        llInstantMessage(CORRADE, 
            wasKeyValueEncode(
                [
                    "command", "notify",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "action", "set",
                    "type", "permission",
                    "URL", wasURLEscape(callback),
                    "callback", wasURLEscape(callback)
                ]
            )
        );
        llSetTimerEvent(60);
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "notify" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Failed to bind to the permission notification: " + 
                wasURLUnescape(
                    wasKeyValueGet(
                        "error", 
                        body
                    )
                )
            );
            return;
        }
        // DEBUG
        llOwnerSay("Permission notification installed...");
        state menu;
    }
    timer() {
        // alarm hit, permission notification not installed
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
    state_exit() {
        llSetTimerEvent(0);
    }
}
 
state menu {
    state_entry() {
        llSetText("Touch me for menu!", <0, 1, 0>, 1.0);
    }
    touch_start(integer num) {
        if(llDetectedKey(0) != llGetOwner()) return;
        integer comChannel = (integer)("0x8" + llGetSubString(llGetKey(), 0, 6));
        llListen(comChannel, "", llGetOwner(), "");
        llDialog(llGetOwner(), "The menu will allow you to cast and dispel the hunt items.", [ "Cast", "Dispel" ], comChannel);
    }
    listen(integer channel, string name, key id, string message) {
        /* Copy the POI list to recurse over. */
        poi = POI;
        /* Process the dialog messages. */
        if(message == "Cast") state rez;
        if(message == "Dispel") state derez;
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
 * In order to rez all the items we permute the "poi" list by recursing over states.
 * The "rez_trampoline" provides a trampoline for the "rez" state re-entry. 
 */
state rez_trampoline {
    state_entry() {
        llSetTimerEvent(1);
    }
    timer() {
        state rez;
    }
    state_exit() {
        llSetTimerEvent(0);
    }
}
 
/* 
 * Rez the hunt item from inventory, grant debit permission and trampoline for the
 * next item in the POI list.
 */
state rez {
    state_entry() {
        // If we have rezzed all the objects, then stop rezzing.
        if(llGetListLength(poi) == 0) state menu;
        llSetText("Hunt items left to set-up: " + 
            (string)
                llGetListLength(
                    poi
            ),
            <0, 1, 1>,
            1.0
        );
        // Permute POIs
        string head = llList2String(poi, 0);
        poi = llDeleteSubList(poi, 0, 0);
 
        // DEBUG
        llOwnerSay("Rezzing @ " + head);
 
        llInstantMessage(CORRADE, 
            wasKeyValueEncode(
                [
                    "command", "rez",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "position", wasURLEscape(head),
                    "item", wasURLEscape(ITEM),
                    "callback", wasURLEscape(callback)
                ]
            )
        );
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        // Get the result of rezzing the object.
        if(wasKeyValueGet("command", body) == "rez") {
            if(wasKeyValueGet("success", body) != "True") {
                // DEBUG
                llOwnerSay("Failed to rez the object: " + 
                    wasURLUnescape(
                        wasKeyValueGet(
                            "error", 
                            body
                        )
                    )
                );
                return;
            }
            llOwnerSay("Item rezzed...");
            return;
        }
        // Grant debit permissions to the rezzed object.
        if(wasKeyValueGet("type", body) == "permission" &&
            wasKeyValueGet("permissions", body) == "Debit") {
                llInstantMessage(CORRADE, 
                    wasKeyValueEncode(
                        [
                            "command", "replytoscriptpermissionrequest",
                            "group", wasURLEscape(GROUP),
                            "password", wasURLEscape(PASSWORD),
                            "task", wasKeyValueGet("task", body),
                            "item", wasKeyValueGet("item", body),
                            "region", wasKeyValueGet("region", body),
                            "action", "reply",
                            "permissions", "Debit",
                            "callback", wasURLEscape(callback)
                        ]
                    )
                );
                // DEBUG
                llOwnerSay("Replying to permission request...");
                return;
        }
        // Get the result of granting script permissions.
        if(wasKeyValueGet("command", body) == "replytoscriptpermissionrequest") {
            if(wasKeyValueGet("success", body) != "True") {
                // DEBUG
                llOwnerSay("Failed to grant permissions to the object: " + 
                    wasURLUnescape(
                        wasKeyValueGet(
                            "error", 
                            body
                        )
                    )
                );
                return;
            }
            llOwnerSay("Permissions granted...");
            // Go for the next item in the POI list.
            state rez_trampoline;
        }
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
 
/*
 * In order to de-rez the hunt items we first teleport Corrade in the vicinity 
 * of the POI and then issue a "derez" command to Corrade.
 * Symmetrically to "rez", the "derez_trampoline" state provides a trampoline 
 * for the "derez" state re-entry.
 */
state derez_trampoline {
    state_entry() {
        llSetTimerEvent(1);
    }
    timer() {
        state derez;
    }
    state_exit() {
        llSetTimerEvent(0);
    }
}
 
state derez {
    state_entry() {
        // If we have derezzed all the objects, then stop rezzing.
        if(llGetListLength(poi) == 0) state menu;
        llSetText("Hunt items left to remove: " + 
            (string)
                llGetListLength(
                    poi
            ),
            <0, 1, 1>,
            1.0
        );
        // Permute POIs
        string head = llList2String(poi, 0);
        poi = llDeleteSubList(poi, 0, 0);
        // DEBUG
        llOwnerSay("Teleporting to: " + (string)head);
        llInstantMessage((key)CORRADE, 
            wasKeyValueEncode(
                [
                    "command", "teleport",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "region", wasURLEscape(llGetRegionName()),
                    "position", wasURLEscape(head),
                    "entity", "region",
                    "fly", "True",
                    "callback", wasURLEscape(callback)
                ]
            )
        );
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        // Get the result of teleporting to the POI.
        if(wasKeyValueGet("command", body) == "teleport") {
            // If the teleport did not succeed and the error was not that the destination
            // was too close, then print the error and stop; otherwise, continue.
            if(wasKeyValueGet("success", body) != "True" && 
                wasKeyValueGet("status", body) != "37559") {
                // DEBUG
                llOwnerSay("Failed to teleport: " + 
                    wasURLUnescape(
                        wasKeyValueGet(
                            "error", 
                            body
                        )
                    )
                );
                return;
            }
            // DEBUG
            llOwnerSay("Teleport succeeded...");
            // If the teleport succeeded, request to derez the item.
            llInstantMessage((key)CORRADE, 
                wasKeyValueEncode(
                    [
                        "command", "derez",
                        "group", wasURLEscape(GROUP),
                        "password", wasURLEscape(PASSWORD),
                        "item", wasURLEscape(ITEM),
                        "range", 5,
                        "callback", wasURLEscape(callback)
                    ]
                )
            );
            return;
        }
        // Get the result of the derez request.
        if(wasKeyValueGet("command", body) == "derez") {
            // If removing the item because the item was not found, then it was 
            // probably consumed during the hunt so carry on to the next destination.
            if(wasKeyValueGet("success", body) != "True" &&
                wasKeyValueGet("status", body) != "22693") {
                // DEBUG
                llOwnerSay("Failed to derez: " + 
                    wasURLUnescape(
                        wasKeyValueGet(
                            "error", 
                            body
                        )
                    )
                );
                return;
            }
            // DEBUG
            llOwnerSay("Derez succeeded...");
            state derez_trampoline;
        }
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
