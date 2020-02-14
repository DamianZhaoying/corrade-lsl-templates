///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2016 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
//
// This script makes Corrade retrieve an item from the sim.
// For more information on Corrade, please see:
//     http://grimore.org/secondlife/scripted_agents/corrade
//
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2011 Wizardry and Steamworks - License: GNU GPLv3    //
///////////////////////////////////////////////////////////////////////////
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
//    Copyright (C) 2015 Wizardry and Steamworks - License: GNU GPLv3    //
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
//    Copyright (C) 2013 Wizardry and Steamworks - License: GNU GPLv3    //
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
//    Copyright (C) 2013 Wizardry and Steamworks - License: GNU GPLv3    //
///////////////////////////////////////////////////////////////////////////
integer wasListCountExclude(list input, list exclude) {
    if(llGetListLength(input) == 0) return 0;
    if(llListFindList(exclude, (list)llList2String(input, 0)) == -1) 
        return 1 + wasListCountExclude(llDeleteSubList(input, 0, 0), exclude);
    return wasListCountExclude(llDeleteSubList(input, 0, 0), exclude);
}
 
///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2013 Wizardry and Steamworks - License: GNU GPLv3    //
///////////////////////////////////////////////////////////////////////////
list wasListMerge(list l, list m, string merge) {
    if(llGetListLength(l) == 0 && llGetListLength(m) == 0) return [];
    string a = llList2String(m, 0);
    if(a != merge) return [ a ] + wasListMerge(l, llDeleteSubList(m, 0, 0), merge);
    return [ llList2String(l, 0) ] + wasListMerge(llDeleteSubList(l, 0, 0), llDeleteSubList(m, 0, 0), merge);
}

// for notecard reading
integer line = 0;
 
// key-value data will be read into this list
list tuples = [];
string configuration = "";

// URL
string callback = "";

// dialog variables
list names = [];
list UUIDs = [];
list local = [];
list menu = [];
integer listenHandle = 0;

// jump table
string autopilot_jump_state = "";

// utility variables
key itemUUID = NULL_KEY;
vector autoPilotTarget = ZERO_VECTOR;

// position of the cliking avatar
key avatarTouch = NULL_KEY;

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
            configuration = wasKeyValueEncode(tuples);
            // GC
            tuples = [];

            autopilot_jump_state = "main";
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

state url {
    state_entry() {
        // DEBUG
        llOwnerSay("Requesting URL...");
        llReleaseURL(callback);
        llRequestURL();
    }
    http_request(key id, string method, string body) {
        if(method != URL_REQUEST_GRANTED) return;
        callback = body;
        // DEBUG
        llOwnerSay("Got URL...");

        state main;
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        llResetScript();
    }
}


state main {
    state_entry() {
        llOwnerSay("Touch to select object...");
    }
    touch_start(integer num) {
        // DEBUG
        llOwnerSay("Getting objects...");

        // store the poition of the cliking avatar
        avatarTouch = llDetectedKey(0);

        llInstantMessage(
            wasKeyValueGet(
                "corrade", 
                configuration
            ), 
            wasKeyValueEncode(
                [
                    "command", "getobjectsdata",
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
                            "range",
                            configuration
                        )
                    ),
                    "data", wasListToCSV(
                        [
                            "Properties.Name",
                            "ID",
                            "Position"
                        ]
                    ),
                    "sift", wasListToCSV(
                        [
                            "take", 30
                        ]
                    ),
                    "callback", wasURLEscape(callback)
                ]
            )
        );

        llSetTimerEvent(60);
    }
    timer() {
        // DEBUG
        llOwnerSay("Timeout retrieving object properties...");
        llResetScript();
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");

        // Only listen to getobjectsdata command.
        if(wasKeyValueGet("command", body) != "getobjectsdata")
            return;

        if(wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Error querying primitives: " + wasKeyValueGet("error", body));
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
            llOwnerSay("No data for scanned primitives. No primitives in range?");
            llResetScript();
        }

        list data = wasCSVToList(dataKey);
        // Copy the names and UUIDs of the primitives.
        names = [];
        UUIDs = [];
        local = [];
        do {
            string k = llList2String(data, 0);
            data = llDeleteSubList(data, 0, 0);
            string v = llList2String(data, 0);
            data = llDeleteSubList(data, 0, 0);

            if(k == "Properties.Name") {
                // Corrade may pass blank names due to SL
                // objects not being yet discovered.
                if(v == "") {
                  names += "Unknown";
                  jump continue;
                }
                names += v;
                jump continue;
            }
            
            if(k == "ID"){
                if(v == "") {
                    UUIDs += NULL_KEY;
                    jump continue;
                }
                UUIDs += v;
                jump continue;
            }
            
            if(k == "Position") {
                if(v == "") {
                    local += ZERO_VECTOR;
                    jump continue;
                }
                local += v;
                jump continue;
            }
@continue;
        } while(llGetListLength(data));

        state pick;
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        llResetScript();
    }
    state_exit() {
        llSetTimerEvent(0);
    }
}

state pick {
    state_entry() {
        // DEBUG
        llOwnerSay("Sending menu...");

        // trim the button labels down to 23 characters
        menu = [];
        integer i = 0;
        do {
            menu += llGetSubString(llList2String(names, i), 0, 23);
        } while(++i < llGetListLength(names));

        // listen and send the dialog
        integer comChannel = ((integer)("0x"+llGetSubString((string)avatarTouch,-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF;
        listenHandle = llListen(comChannel, "", avatarTouch, "");
        llDialog(avatarTouch, "\nPlease choose a primitive for Corrade to sit on from the list below:\n", wasDialogMenu(menu, ["⟵ Back", "", "Next ⟶"], ""), comChannel);
        llSetTimerEvent(60);
    }
    listen(integer channel, string name, key id, string message) {
        if(message == "⟵ Back") {
            llDialog(id, "\nPlease choose a primitive for Corrade to sit on from the list below:\n", wasDialogMenu(menu, ["⟵ Back", "", "Next ⟶"], "<"), channel);
            return;
        }
        if(message == "Next ⟶") {
            llDialog(id, "\nPlease choose a primitive for Corrade to sit on from the list below:\n", wasDialogMenu(menu, ["⟵ Back", "", "Next ⟶"], ">"), channel);
            return;
        }
        integer i = llGetListLength(menu) - 1;
        do {
            string v = llList2String(menu, i);
            if(llSubStringIndex(v, message) != -1)
                jump selection;
        } while(--i > -1);
        // GC
        menu = [];

        // DEBUG
        llOwnerSay("Invalid menu item selected...");
        llResetScript();
@selection;

        // DEBUG
        llOwnerSay("Selected: " + llList2String(names, i) + "...");

        // Get the key of the object.
        itemUUID = (key)llList2String(UUIDs, i);
        
        // Get the target.
        autoPilotTarget = (vector)llList2String(local, i);

        // GC
        menu = [];
        names = [];
        UUIDs = [];
        local = [];
        
        // Got a menu item so bind to permission notifications and sit.
        state bind;
    }
    timer() {
        // DEBUG
        llOwnerSay("Dialog menu timeout...");
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        llResetScript();
    }
    state_exit() {
        llSetTimerEvent(0);
    }
}


state bind {
    state_entry() {
        // DEBUG
        llOwnerSay("Binding notifications...");

        llInstantMessage(
            (key)wasKeyValueGet(
                "corrade", 
                configuration
            ),
            wasKeyValueEncode(
                [
                    "command", "notify",
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
                    "action", "set",
                    "type", wasListToCSV(
                        [
                            "inventory",
                            "location"
                        ]
                    ),
                    "tag", wasURLEscape(
                        wasKeyValueGet(
                            "tag", 
                            configuration
                        )
                    ),
                    "URL", wasURLEscape(callback),
                    "callback", wasURLEscape(callback)
                ]
            )
        );
        llSetTimerEvent(60);
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");

        if(wasKeyValueGet("command", body) != "notify")
            return;

        if(wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Failed to bind notifications...");
            llResetScript();
        }

        // DEBUG
        llOwnerSay("Notifications installed, fetching...");
        
        autopilot_jump_state = "take";
        state autopilot;
    }
    timer() {
        // DEBUG
        llOwnerSay("Timeout binding notifications...");
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        llResetScript();
    }
    state_exit() {
        llSetTimerEvent(0);
    }
}

state autopilot {
    state_entry() {
        // DEBUG
        llOwnerSay("Walking...");
        
        llInstantMessage(
            (key)wasKeyValueGet(
                "corrade", 
                configuration
            ),
            wasKeyValueEncode(
            [
                "command", "autopilot",
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
                    "position", autoPilotTarget + wasCirclePoint(1.1),
                    "action", "start"
                ]
            )
        );
        
        llSetTimerEvent(60);
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        
        // Wait for the location notification.
        if(wasKeyValueGet("type", body) != "location")
            return;
            
        // Compute the position beteen the bot and the target.
        vector position = (vector)wasURLUnescape(
            wasKeyValueGet(
                "position",
                body
            )
        );
        
        // Detect when Corrade is near.
        if(llVecDist(position, autoPilotTarget) > 
            (float)wasURLEscape(wasKeyValueGet("scan", configuration)))
            return;
               
        // DEBUG
        llOwnerSay("Corrade has arrived...");
        
        // Jump table!
        if(autopilot_jump_state == "drop")
            state drop;
        
        if(autopilot_jump_state == "take")
            state take;
        
        // DEBUG
        llOwnerSay("Jump table corrupt, please contact vendor...");
    }
    timer() {
        // DEBUG
        llOwnerSay("Timeout fetching object...");
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        llResetScript();
    }
    state_exit() {
        llSetTimerEvent(0);
    }
}

state take {
    state_entry() {
        // DEBUG
        llOwnerSay("Taking to inventory...");
        
        llInstantMessage(
            (key)wasKeyValueGet(
                "corrade", 
                configuration
            ),
            wasKeyValueEncode(
            [
                "command", "derez",
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
                    "item", itemUUID,
                    "type", "AgentInventoryTake",
                    "range", "5"
                ]
            )
        );
        
        llSetTimerEvent(60);
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        
        // wait for inventory notification.
        if(wasKeyValueGet("type", body) != "inventory")
            return;

        // item taken to inventory implies the create action
        if(wasKeyValueGet("action", body) != "created")
            return;
            
        itemUUID = (key) wasURLUnescape(
            wasKeyValueGet(
                "inventory", 
                body
            )
        );
        
        // DEBUG
        llOwnerSay("Retrieved object as inventory UUID: " + (string)itemUUID);

        state wear;
    }
    timer() {
        // DEBUG
        llOwnerSay("Timeout taking object to inventory...");
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        llResetScript();
    }
    state_exit() {
        llSetTimerEvent(0);
    }
}

state wear {
    state_entry() {
        // DEBUG
        llOwnerSay("Wearing...");
        
        llInstantMessage(
            (key)wasKeyValueGet(
                "corrade", 
                configuration
            ),
            wasKeyValueEncode(
            [
                "command", "attach",
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
                    "attachments", wasListToCSV(
                        [
                            wasURLEscape(
                                wasKeyValueGet(
                                    "attachPoint", 
                                configuration
                                )
                            ), itemUUID
                        ]
                    ),
                    "callback", wasURLEscape(callback)
                ]
            )
        );
        
        llSetTimerEvent(60);
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        
        if(wasKeyValueGet("command", body) != "attach")
            return;
            
        if(wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Unable to attach item: " + wasKeyValueGet("error", body));
            llResetScript();
        }
        
        // DEBUG
        llOwnerSay("Item attached, returning...");
        
        // set the new target to the position of the avatar
        autoPilotTarget = (vector)llList2String(
            llGetObjectDetails(
                avatarTouch, 
                [
                    OBJECT_POS
                ]
            ), 
            0
        );
        autopilot_jump_state = "drop";
        state autopilot;
    }
    timer() {
        // DEBUG
        llOwnerSay("Timeout taking object to inventory...");
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        llResetScript();
    }
    state_exit() {
        llSetTimerEvent(0);
    }
}

state drop {
    state_entry() {
        // DEBUG
        llOwnerSay("Dropping...");
        
        llInstantMessage(
            (key)wasKeyValueGet(
                "corrade", 
                configuration
            ),
            wasKeyValueEncode(
            [
                "command", "dropobject",
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
                    "type", "UUID",
                    "item", wasURLEscape(itemUUID),
                    "callback", wasURLEscape(callback)
                ]
            )
        );
        
        llSetTimerEvent(60);
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        
        if(wasKeyValueGet("command", body) != "dropobject")
            return;
        
        if(wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Could not drop object: " + wasURLUnescape(body));
            llResetScript();
        }
        
        // DEBUG
        llOwnerSay("Item dropped...");
        
        state unbind;
    }
    timer() {
        // DEBUG
        llOwnerSay("Timeout dropping object...");
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        llResetScript();
    }
    state_exit() {
        llSetTimerEvent(0);
    }
}

state unbind {
    state_entry() {
        // DEBUG
        llOwnerSay("Unbinding notifications...");

        llInstantMessage(
            (key)wasKeyValueGet(
                "corrade", 
                configuration
            ),
            wasKeyValueEncode(
                [
                    "command", "notify",
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
                    "action", "remove",
                    "tag", wasURLEscape(
                        wasKeyValueGet(
                            "tag", 
                            configuration
                        )
                    ),
                    "URL", wasURLEscape(callback),
                    "callback", wasURLEscape(callback)
                ]
            )
        );

        llSetTimerEvent(60);
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");

        if(wasKeyValueGet("command", body) != "notify")
            return;

        if(wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Failed to unbind notifications...");
            llResetScript();
        }

        // DEBUG
        llOwnerSay("Notifications uninstalled...");
        
        llResetScript();
    }
    timer() {
        // DEBUG
        llOwnerSay("Timeout binding notifications...");
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        llResetScript();
    }
    state_exit() {
        llSetTimerEvent(0);
    }
}