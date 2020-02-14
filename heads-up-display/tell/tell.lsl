///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2016 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
//
// This script is able to send messages to avatars, groups or talk in local
// using Corrade.
//
// For more information on Corrade, please see:
//     http://grimore.org/secondlife/scripted_agents/corrade
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

// callback URL
string callback = "";
// configuration data
string configuration = "";
// listen handle
integer listenHandle = 0;
string firstname = "";
string lastname = "";
list names = [];
list UUIDs = [];
// temporary list for button name normalization
list menu = [];
integer select = -1;
string entity = "";

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
        llReleaseControls();
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
}

state choose {
    state_entry() {
        // DEBUG
        llOwnerSay("Tell...");
        llSetTimerEvent(1);
        listenHandle = llListen(-24, "", llGetOwner(), "");
        llDialog(
            llGetOwner(), 
            "[CORRADE] Select avatar, local or group:", 
            [
                "avatar",
                "local",
                "group"
            ],
            -24
        );
    }
    touch_end(integer num) {
        llResetScript();
    }
    listen(integer channel, string name, key id, string message) {
        llListenRemove(listenHandle);
        
        entity = message;
        
        if(message == "local") state tell;
        if(message == "avatar") state select_avatar;
        if(message == "group") state get_groups;
        
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

state get_groups {
    state_entry() {
        // DEBUG
        llOwnerSay("Getting groups...");
        llSetTimerEvent(1);
        llInstantMessage(
            wasKeyValueGet(
                "corrade", 
                configuration
            ), 
            wasKeyValueEncode(
                [
                    "command", "getcurrentgroups",
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
                    "sift", wasListToCSV(
                        [
                            "take", 16
                        ]
                    ),
                    "callback", wasURLEscape(callback)
                ]
            )
        );
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "getcurrentgroups" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Too many groups or unable to groups...");
            llResetScript();
        }
        list data = wasCSVToList(
            wasURLUnescape(
                wasKeyValueGet(
                    "data",
                    body
                )
            )
        );
        // Copy the names and UUIDs of the groups for the menu.
        names = [];
        UUIDs = [];
        do {
            UUIDs += llList2String(data, -1);
            data = llDeleteSubList(data, -1, -1);
            names += llList2String(data, -1);
            data = llDeleteSubList(data, -1, -1);
        } while(llGetListLength(data));       
        state select_group;
    }
    timer() {
        llRequestAgentData(
            (key)wasKeyValueGet(
                "corrade", 
                configuration
        ), DATA_ONLINE);
    }
    dataserver(key id, string data) {
        if(data != "1") llResetScript();
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

state select_group {
    state_entry() {
        // DEBUG
        llOwnerSay("Sending menu...");
        menu = [];
        integer i = 0;
        do {
            menu += llGetSubString(llList2String(names, i), 0, 23);
        } while(++i < llGetListLength(names));
        llListen(-10, "", llGetOwner(), "");
        llDialog(llGetOwner(), "\nPlease choose a group for Corrade to talk in from the list below:\n", wasDialogMenu(menu, ["⟵ Back", "", "Next ⟶"], ""), -10);
        llSetTimerEvent(60);
    }
    touch_end(integer num) {
        llSetColor(<.5,0,0>, ALL_SIDES);
        llResetScript();
    }
    listen(integer channel, string name, key id, string message) {
        if(message == "⟵ Back") {
            llDialog(id, "\nPlease choose a group for Corrade to talk in from the list below:\n", wasDialogMenu(menu, ["⟵ Back", "", "Next ⟶"], "<"), -10);
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
        
        state tell;
        
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

state select_avatar {
    state_entry() {
        // DEBUG
        llOwnerSay("Select avatar...");
        llSetTimerEvent(1);
        listenHandle = llListen(-24, "", llGetOwner(), "");
        llTextBox(llGetOwner(), "[CORRADE] Enter the avatar name:", -24);
    }
    touch_end(integer num) {
        llResetScript();
    }
    listen(integer channel, string name, key id, string message) {
        llListenRemove(listenHandle);
        list name = llParseString2List(message, [" "], [""]);
        if(llGetListLength(name) != 2) {
            llOwnerSay("Invalid avatar name...");
            state tell;
        }
        firstname = llList2String(name, 0);
        lastname = llList2String(name, 1);
        state tell;
    }
    timer() {
        llRequestAgentData(
            (key)wasKeyValueGet(
                "corrade", 
                configuration
        ), DATA_ONLINE);
    }
    dataserver(key id, string data) {
        if(data != "1") llResetScript();
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

state tell {
    state_entry() {
        // DEBUG
        llOwnerSay("Tell...");
        llSetTimerEvent(1);
        listenHandle = llListen(-24, "", llGetOwner(), "");
        llTextBox(llGetOwner(), "[CORRADE] Enter the message:", -24);
    }
    touch_end(integer num) {
        llResetScript();
    }
    timer() {
        llRequestAgentData(
            (key)wasKeyValueGet(
                "corrade", 
                configuration
        ), DATA_ONLINE);
    }
    dataserver(key id, string data) {
        if(data != "1") llResetScript();
    }
    listen(integer channel, string name, key id, string message) {
        llListenRemove(listenHandle);
        llInstantMessage(
            wasKeyValueGet(
                "corrade", 
                configuration
            ), 
            wasKeyValueEncode(
                [
                    "command", "tell",
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
                    "entity", entity,
                    "type", "normal",
                    "target", wasURLEscape(
                        llList2String(UUIDs, select)
                    ),
                    "firstname", wasURLEscape(firstname),
                    "lastname", wasURLEscape(lastname),
                    "message", wasURLEscape(message),
                    "callback", wasURLEscape(callback)
                ]
            )
        );
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "tell" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Failed to say message: " + wasKeyValueGet("error", body));
        }
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
