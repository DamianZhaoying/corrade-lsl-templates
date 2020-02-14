///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2016 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
//
// Help message for Corrade eggdrop.
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

// configuration data
string configuration = "";
// callback URL
string URL = "";
// store message over state.
string data = "";

default {
    state_entry() {
        llOwnerSay("[Help] Starting module...");
        llSetTimerEvent(10);
    }
    link_message(integer sender, integer num, string message, key id) {
        if(id != "configuration") return;
        llOwnerSay("[Help] Got configuration...");
        configuration = message;
        state listen_group;
    }
    timer() {
        llOwnerSay("[Help] Requesting configuration...");
        llMessageLinked(LINK_THIS, 0, "configuration", NULL_KEY);
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if((change & CHANGED_INVENTORY) || 
            (change & CHANGED_REGION_START) || 
            (change & CHANGED_OWNER)) {
            llResetScript();
        }
    }
    state_exit() {
        llSetTimerEvent(0);
    }
}

state listen_group {
    state_entry() {
        // DEBUG
        llOwnerSay("[Help] Waiting for group messages...");
    }
    link_message(integer sender, integer num, string message, key id) {
        // We only care about notifications now.
        if(id != "notification")
            return;
        
        // This script only processes group notifications.
        if(wasKeyValueGet("type", message) != "group")
            return;
            
        string firstname = wasURLUnescape(
            wasKeyValueGet(
                "firstname", 
                message
            )
        );
        
        string agent = (key)wasURLUnescape(
            wasKeyValueGet(
                "agent", 
                message
            )
        );
            
        // Get the sent message.
        data = wasURLUnescape(
            wasKeyValueGet(
                "message", 
                message
            )
        );
        
        // Check if this is an eggdrop command.
        if(llGetSubString(data, 0, 0) != 
            wasKeyValueGet("command", configuration))
            return;
        
        // Check if the command matches the current module.
        list command = llParseString2List(data, [" "], []);
        if(llList2String(command, 0) != 
            wasKeyValueGet("command", configuration) + "help")
            return;
            
        // Remove command.
        command = llDeleteSubList(command, 0, 0);
            
        if(llGetInventoryType(wasKeyValueGet("help card", configuration)) 
            != INVENTORY_NOTECARD) {
            data = "Hmm. I have not notecard to hand out - contact my owner please?";
            state tell;
        }
            
        // Hand out the notecard.
        llGiveInventory(agent, 
            wasKeyValueGet("help card", configuration)
        );
        
        data = "Sent you a help notecard " + firstname + ". Please check your inventory.";

        state tell;
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if((change & CHANGED_INVENTORY) || 
            (change & CHANGED_REGION_START) || 
            (change & CHANGED_OWNER)) {
            llResetScript();
        }
    }
}

state tell {
    state_entry() {
        // DEBUG
        llOwnerSay("[Help] Sending to group.");
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
                    "entity", "group",
                    "message", wasURLEscape(data)
                ]
            )
        );
        state listen_group;
    }
}
