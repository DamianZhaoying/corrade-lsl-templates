///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2016 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
//
// This script will make Corrade scan for primitives in the vicinity and
// will then offer a dialog for you to pick which primitive to touch.
//
// For more information on Corrade, please see:
//     http://grimore.org/secondlife/scripted_agents/corrade
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
// http://was.fm/secondlife/wanderer
vector wasCirclePoint(float radius) {
    float x = llPow(-1, 1 + (integer) llFrand(2)) * llFrand(radius*2);
    float y = llPow(-1, 1 + (integer) llFrand(2)) * llFrand(radius*2);
    if(llPow(x,2) + llPow(y,2) <= llPow(radius,2))
        return <x, y, 0>;
    return wasCirclePoint(radius);
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
//    Copyright (C) 2013 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
integer wasMenuIndex = 0;
list wasDialogMenu(list input, list actions, string direction) {
    integer cut = 11-wasListCountExclude(actions, [""]);
    if(direction == ">" &&  (wasMenuIndex+1)*cut+wasMenuIndex+1 < llGetListLength(input)) {
        ++wasMenuIndex;
        jump slice;
    }
    if(direction == "<" && wasMenuIndex-1 >= 0) {
        --wasMenuIndex;
        jump slice;
    }
@slice;
    integer multiple = wasMenuIndex*cut;
    input = llList2List(input, multiple+wasMenuIndex, multiple+cut+wasMenuIndex);
    input = wasListMerge(input, actions, "");
    return input;
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
//    Copyright (C) 2013 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
list wasListMerge(list l, list m, string merge) {
    if(llGetListLength(l) == 0 && llGetListLength(m) == 0) return [];
    string a = llList2String(m, 0);
    if(a != merge) return [ a ] + wasListMerge(l, llDeleteSubList(m, 0, 0), merge);
    return [ llList2String(l, 0) ] + wasListMerge(llDeleteSubList(l, 0, 0), llDeleteSubList(m, 0, 0), merge);
}

// configuration data
string configuration = "";
// callback URL
string callback = "";
// scanned primitives
list names = [];
list UUIDs = [];
// temporary list for button name normalization
list menu = [];
integer select = -1;

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
        state scan;
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

state scan {
    state_entry() {
        // DEBUG
        llOwnerSay("Getting primitives...");
        llInstantMessage(
            wasKeyValueGet(
                "corrade", 
                configuration
            ), 
            wasKeyValueEncode(
                [
                    "command", "getprimitivesdata",
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
                    "entity", "world",
                    "range", wasURLEscape(
                        wasKeyValueGet(
                            "radar",
                            configuration
                        )
                    ),
                    "data", wasListToCSV(
                        [
                            "Properties.Name",
                            "ID"
                        ]
                    ),
                    "sift", wasListToCSV(
                        [
                            "take", 32
                        ]
                    ),
                    "callback", wasURLEscape(callback)
                ]
            )
        );
    }
    touch_end(integer num) {
        llSetColor(<.5,0,0>, ALL_SIDES);
        llResetScript();
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "getprimitivesdata" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Unable to query primitives data: " +
                wasURLUnescape(
                    wasKeyValueGet(
                        "error",
                        body
                    )
                )
            );
            llResetScript();
        }
        string dataKey = wasURLUnescape(
            wasKeyValueGet(
                "data",
                body
            )
        );
        if(dataKey == "") {
            // DEBUG
            llOwnerSay("No data for scanned primitives...");
            llResetScript();
        }
        list data = wasCSVToList(dataKey);
        // Copy the names and UUIDs of the primitives.
        names = [];
        UUIDs = [];
        do {
            string v = llList2String(data, -1);
            data = llDeleteSubList(data, -1, -1);
            string k = llList2String(data, -1);
            data = llDeleteSubList(data, -1, -1);
            if(k == "Properties.Name") {
                names += v;
                jump continue;
            }
            UUIDs += (key)v;
@continue;
        } while(llGetListLength(data));
        state choose;
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

state choose {
    state_entry() {
        // DEBUG
        llOwnerSay("Sending menu...");
        menu = [];
        integer i = 0;
        do {
            menu += llGetSubString(llList2String(names, i), 0, 23);
        } while(++i < llGetListLength(names));
        llListen(-10, "", llGetOwner(), "");
        llDialog(llGetOwner(), "\nPlease choose a primitive for Corrade to sit on from the list below:\n", wasDialogMenu(menu, ["⟵ Back", "", "Next ⟶"], ""), -10);
        llSetTimerEvent(60);
    }
    touch_end(integer num) {
        llSetColor(<.5,0,0>, ALL_SIDES);
        llResetScript();
    }
    listen(integer channel, string name, key id, string message) {
        if(message == "⟵ Back") {
            llDialog(id, "\nPlease choose a primitive for Corrade to sit on from the list below:\n", wasDialogMenu(menu, ["⟵ Back", "", "Next ⟶"], "<"), -10);
            return;
        }
        if(message == "Next ⟶") {
            llDialog(id, "\nPlease choose a primitive for Corrade to sit on from the list below:\n", wasDialogMenu(menu, ["⟵ Back", "", "Next ⟶"], ">"), -10);
            return;
        }
        integer i = llGetListLength(menu) - 1;
        do {
            string v = llList2String(menu, i);
            if(llSubStringIndex(v, message) != -1)
                jump sit;
        } while(--i > -1);
        // GC
        menu = [];
        // DEBUG
        llOwnerSay("Invalid menu item selected...");
        llResetScript();
@sit;
        // GC
        menu = [];
        select = i;
        // Got a menu item so bind to permission notifications and sit.
        state touch_primitive;
        
    }
    timer() {
        // DEBUG
        llOwnerSay("Dialog menu timeout...");
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
    state_exit() {
        llSetTimerEvent(0);
    }
}

state touch_primitive {
    state_entry() {
        // DEBUG
        llOwnerSay("Touching: " + 
            llList2String(names, select)  + 
            " UUID: " + 
            llList2String(UUIDs, select)
        );
        llInstantMessage(
            (key)wasKeyValueGet(
                "corrade", 
                configuration
            ), 
            wasKeyValueEncode(
                [
                    "command", "touch",
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
                    "item", wasURLEscape(
                        llList2String(UUIDs, select)
                    ),
                    "range", wasURLEscape(
                        wasKeyValueGet(
                            "radar",
                            configuration
                        )
                    ),
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
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "touch" ||
            wasKeyValueGet("success", body) != "True") {
                // DEBUG
                llOwnerSay("Failed to touch primitive...");
                llResetScript();
        }
        // DEBUG
        llOwnerSay("Touched...");
        llResetScript();
    }
    timer() {
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
    state_exit() {
        llSetTimerEvent(0);
    }
}
