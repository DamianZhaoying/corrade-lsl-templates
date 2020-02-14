///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2016 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
//
// A MOTD module for Corrade Eggdrop.
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
string firstname = "";
string lastname = "";
string group = "";
string data = "";
string jump_state = "";
 
default {
    state_entry() {
        llOwnerSay("[MOTD] Starting module...");
        llSetTimerEvent(10);
    }
    link_message(integer sender, integer num, string message, key id) {
        if(id != "configuration") return;
        llOwnerSay("[MOTD] Got configuration...");
        configuration = message;
        jump_state = "create_database";
        state url;
    }
    timer() {
        llOwnerSay("[MOTD] Requesting configuration...");
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
 
state url {
    state_entry() {
        // DEBUG
        llOwnerSay("[MOTD] Requesting URL...");
        llRequestURL();
    }
    http_request(key id, string method, string body) {
        if(method != URL_REQUEST_GRANTED) return;
        URL = body;
        // DEBUG
        llOwnerSay("[MOTD] Got URL...");
        if(jump_state == "create_database")
            state create_database;
        if(jump_state == "greet")
            state greet;
        if(jump_state == "get")
            state get;
        if(jump_state == "set")
            state set;
        if(jump_state == "listen_group")
            state listen_group;
 
        // DEBUG
        llOwnerSay("[MOTD] Jump table corrupted, please contact creator...");
        llResetScript();
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
 
state create_database {
    state_entry() {
        // DEBUG
        llOwnerSay("[MOTD] Creating database: " + wasKeyValueGet("motd table", configuration));
        llInstantMessage(
            wasKeyValueGet(
                "corrade", 
                configuration
            ), 
            wasKeyValueEncode(
                [
                    "command", "database",
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
                    "SQL", wasURLEscape("CREATE TABLE IF NOT EXISTS \"" + 
                        wasKeyValueGet("motd table", configuration) + 
                        "\" (name text unique collate nocase, data text)"),
                    "callback", wasURLEscape(URL)
                ]
            )
        );
        llSetTimerEvent(60);
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        llReleaseURL(URL);
        if(wasKeyValueGet("command", body) != "database" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("[MOTD] Unable modify database: " + 
                wasURLUnescape(
                    wasKeyValueGet("error", body)
                ) + 
                " " + 
                wasURLUnescape(
                    wasKeyValueGet("data", body)
                )
                
            );
            llResetScript();
        }
        llOwnerSay("[MOTD] Database created!");
        state listen_group;
    }
    timer() {
        llReleaseURL(URL);
        state listen_group;
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
        llOwnerSay("[MOTD] Waiting for group messages and new group members.");
    }
    link_message(integer sender, integer num, string message, key id) {
        // We only care about notifications now.
        if(id != "notification")
            return;
 
        // Get the group.
        group = wasURLUnescape(
            wasKeyValueGet(
                "group",
                message
            )
        );
 
        // Retrieve the membership notification.
        if(wasKeyValueGet("type", message) == "membership" &&
            wasKeyValueGet("action", message) == "joined") {
            firstname = wasURLUnescape(
                wasKeyValueGet(
                    "firstname",
                    message
                )
            );
            lastname = wasURLUnescape(
                wasKeyValueGet(
                    "lastname",
                    message
                )
            );
            jump_state = "greet";
            state url;
        }
 
        // This script only processes group notifications.
        if(wasKeyValueGet("type", message) != "group")
            return;
 
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
            wasKeyValueGet("command", configuration) + "motd")
            return;
 
        // Remove command.
        command = llDeleteSubList(command, 0, 0);
 
        // Dump the rest of the message.
        data = llDumpList2String(command, " ");
 
        // Get the sent message.
        if(data == "") {
            jump_state = "get";
            state url;
        }
 
        jump_state = "set";
        state url;
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
 
state greet {
    state_entry() {
        // DEBUG
        llOwnerSay("[MOTD] Member joined, retrieving MOTD...");
        llInstantMessage(
            wasKeyValueGet(
                "corrade", 
                configuration
            ), 
            wasKeyValueEncode(
                [
                    "command", "database",
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
                    "SQL", wasURLEscape("SELECT data FROM \"" +
                        wasKeyValueGet("motd table", configuration) + 
                        "\" WHERE name=:group"),
                    "data", wasURLEscape(
                        wasListToCSV(
                            [
                                "group",
                                wasURLEscape(group)
                            ]
                        )
                    ),
                    "callback", wasURLEscape(URL)
                ]
            )
        );
        llSetTimerEvent(60);
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        llReleaseURL(URL);
        if(wasKeyValueGet("command", body) != "database" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("[MOTD] Unable retrieve from database: " + 
                wasURLUnescape(
                    wasKeyValueGet("error", body)
                )
            );
            state listen_group;
        }
 
        data = llDumpList2String(
            llDeleteSubList(
                wasCSVToList(
                    wasURLUnescape(
                        wasKeyValueGet("data", body)
                    )
                ),
                0,
                0
            ),
            ""
        );
 
        if(data == "")
            state listen_group;
 
        data = "Hello " + firstname + " " + lastname + "!" + " " + data;
        state tell;
    }
    timer() {
        llReleaseURL(URL);
        state listen_group;
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
 
state get {
    state_entry() {
        // DEBUG
        llOwnerSay("[MOTD] Retrieving from database.");
        llInstantMessage(
            wasKeyValueGet(
                "corrade", 
                configuration
            ), 
            wasKeyValueEncode(
                [
                    "command", "database",
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
                    "SQL", wasURLEscape("SELECT data FROM \"" +
                        wasKeyValueGet("motd table", configuration) + 
                        "\" WHERE name=:group"),
                    "data", wasURLEscape(
                        wasListToCSV(
                            [
                                "group",
                                wasURLEscape(
                                    wasKeyValueGet(
                                        "group", 
                                        configuration
                                    )
                                )
                            ]
                        )
                    ),
                    "callback", wasURLEscape(URL)
                ]
            )
        );
        llSetTimerEvent(60);
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        llReleaseURL(URL);
        if(wasKeyValueGet("command", body) != "database" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("[MOTD] Unable retrieve from database: " + 
                wasURLUnescape(
                    wasKeyValueGet("error", body)
                )
            );
            state listen_group;
        }
 
        data = llDumpList2String(
            llDeleteSubList(
                wasCSVToList(
                    wasURLUnescape(
                        wasKeyValueGet("data", body)
                    )
                ),
                0,
                0
            ),
            ""
        );
 
        if(data == "") {
            data = "Sorry, no MOTD is currently set.";
            state tell;
        }
 
        state tell;
    }
    timer() {
        llReleaseURL(URL);
        state listen_group;
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
 
state set {
    state_entry() {
        // DEBUG
        llOwnerSay("[MOTD] Adding to database.");
        llInstantMessage(
            wasKeyValueGet(
                "corrade", 
                configuration
            ), 
            wasKeyValueEncode(
                [
                    "command", "database",
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
                    "SQL", wasURLEscape("REPLACE INTO \"" +
                        wasKeyValueGet("motd table", configuration) + 
                        "\" (name, data) VALUES (:name, :data)"),
                    "data", wasURLEscape(
                        wasListToCSV(
                            [
                                "name",
                                wasURLEscape(
                                    wasKeyValueGet(
                                        "group", 
                                        configuration
                                    )
                                ),
                                "data",
                                wasURLEscape(data)
                            ]
                        )
                    ),
                    "callback", wasURLEscape(URL)
                ]
            )
        );
        llSetTimerEvent(60);
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        llReleaseURL(URL);
        if(wasKeyValueGet("command", body) != "database" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("[MOTD] Unable modify database: " + 
                wasURLUnescape(
                    wasKeyValueGet("error", body)
                )
            );
            state listen_group;
        }
        data = "Saved";
        state tell;
    }
    timer() {
        llReleaseURL(URL);
        state listen_group;
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
 
state tell {
    state_entry() {
        // DEBUG
        llOwnerSay("[MOTD] Sending to group.");
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
