///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2018 - License: GNU GPLv3      //
///////////////////////////////////////////////////////////////////////////
//
// A database-based joke module for Corrade Eggdrop.
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
//    Copyright (C) 2013 Wizardry and Steamworks - License: GNU GPLv3    //
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
//    Copyright (C) 2011 Wizardry and Steamworks - License: GNU GPLv3    //
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
//    Copyright (C) 2015 Wizardry and Steamworks - License: GNU GPLv3    //
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
//    Copyright (C) 2015 Wizardry and Steamworks - License: GNU GPLv3    //
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
integer joke_counter = 0;
 
default {
    state_entry() {
        llOwnerSay("[Joke] Starting module...");
        llSetTimerEvent(10);
    }
    link_message(integer sender, integer num, string message, key id) {
        if(id != "configuration") return;
        llOwnerSay("[Joke] Got configuration...");
        configuration = message;
        jump_state = "create_database";
        state url;
    }
    timer() {
        llOwnerSay("[Joke] Requesting configuration...");
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
        llOwnerSay("[Joke] Requesting URL...");
        llRequestURL();
    }
    http_request(key id, string method, string body) {
        if(method != URL_REQUEST_GRANTED) return;
        URL = body;
        // DEBUG
        llOwnerSay("[Joke] Got URL...");
        if(jump_state == "create_database")
            state create_database;
        if(jump_state == "get")
            state get;
        if(jump_state == "add")
            state add;
        if(jump_state == "remove")
            state remove;
        if(jump_state == "count_jokes")
            state count_jokes;
        if(jump_state == "listen_group")
            state listen_group;
 
        // DEBUG
        llOwnerSay("[Joke] Jump table corrupted, please contact creator...");
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
        llOwnerSay("[Joke] Creating database: " + wasKeyValueGet("joke table", configuration));
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
                        wasKeyValueGet("joke table", configuration) + 
                        "\" (data text(1023), name text(35), firstname text(31), lastname text(31), id integer NOT NULL PRIMARY KEY)"),
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
            llOwnerSay("[Joke] Unable modify database: " + 
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
        llOwnerSay("[Joke] Database created!");
        jump_state = "count_jokes";
        state url;
    }
    timer() {
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
    state_exit() {
        llSetTimerEvent(0);
    }
}

state count_jokes {
    state_entry() {
        // DEBUG
        llOwnerSay("[Joke] Counting jokes in database: " + wasKeyValueGet("joke table", configuration));
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
                    "SQL", wasURLEscape("SELECT COUNT(*) AS count FROM \"" + 
                        wasKeyValueGet("joke table", configuration) + "\""),
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
            llOwnerSay("[Joke] Unable modify database: " + 
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
        
        list result = wasCSVToList(
            wasURLUnescape(
                wasKeyValueGet("data", body)
            )
        );
        
        joke_counter = llList2Integer(
            result, 
            llListFindList(result, ["count"]) + 1
        ) + 1;
        
        llOwnerSay("[Joke] There are " + (string)joke_counter + " jokes in the database.");
        state listen_group;
    }
    timer() {
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
    state_exit() {
        llSetTimerEvent(0);
    }
}
 
state listen_group {
    state_entry() {
        // DEBUG
        llOwnerSay("[Joke] Waiting for group messages.");
    }
    link_message(integer sender, integer num, string message, key id) {
        // We only care about notifications now.
        if(id != "notification")
            return;
        
        // This script only processes group notifications.
        if(wasKeyValueGet("type", message) != "group" ||
            (wasKeyValueGet("type", message) == "group" &&
            wasURLUnescape(wasKeyValueGet("group", message)) != 
            wasKeyValueGet("group", configuration)))
            return;
            
        // Get the message sender.
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
            wasKeyValueGet("command", configuration) + "joke")
            return;
            
        // Remove command.
        command = llDeleteSubList(command, 0, 0);
        
        // Remove action.
        string action = llList2String(command, 0);
        // Jump to the "add" state for adding 
        if(action == "add") {
            command = llDeleteSubList(command, 0, 0);
            data = llDumpList2String(command, " ");
            if(data == "") {
                data = "The joke's too short to be funny.";
                state tell;
            }
            jump_state = "add";
            state url;
        }
        
        // Jump to the "remove" state for removing 
        if(action == "remove") {
            command = llDeleteSubList(command, 0, 0);
            data = llDumpList2String(command, " ");
            if((integer)data == 0) {
                data = "Which one though? Please provide a joke id.";
                state tell;
            }
            jump_state = "remove";
            state url;
        }
        
        data = llDumpList2String(command, " ");
        if((integer)data <= 0)
            data = "";
        jump_state = "get";
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
 
state get {
    state_entry() {
        // DEBUG
        llOwnerSay("[Joke] Retrieving from database.");
        if(data == "") {
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
                        "SQL", wasURLEscape("SELECT * FROM \"" +
                            wasKeyValueGet("joke table", configuration) + 
                            "\" WHERE name=:group LIMIT 1 OFFSET :id"),
                        "data", wasURLEscape(
                            wasListToCSV(
                                [
                                    "group",
                                    wasURLEscape(
                                        wasKeyValueGet(
                                            "group", 
                                            configuration
                                        )
                                    ),
                                    "id",
                                    (string)(
                                        (integer)llFrand(
                                            joke_counter
                                        ) + 1
                                    )
                                ]
                            )
                        ),
                        "callback", wasURLEscape(URL)
                    ]
                )
            );
            llSetTimerEvent(60);
            return;
        }
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
                    "SQL", wasURLEscape("SELECT * FROM \"" +
                        wasKeyValueGet("joke table", configuration) + 
                        "\" WHERE name=:group AND id=:id"),
                    "data", wasURLEscape(
                        wasListToCSV(
                            [
                                "group",
                                wasURLEscape(
                                    wasKeyValueGet(
                                        "group", 
                                        configuration
                                    )
                                ),
                                "id",
                                data
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
            llOwnerSay("[Joke] Unable retrieve from database: " + 
                wasURLUnescape(
                    wasKeyValueGet("error", body)
                )
            );
            state listen_group;
        }
        
        list result = wasCSVToList(
            wasURLUnescape(
                wasKeyValueGet("data", body)
            )
        );
        
        if(llGetListLength(result) != 10) {
            data = "No joke found. . .";
            state tell;
        }
        
        data = llList2String(
            result, 
            llListFindList(result, ["data"]) + 1
        );
        
        string firstname = llList2String(
            result, 
            llListFindList(result, ["firstname"]) + 1
        );
        
        string lastname = llList2String(
            result, 
            llListFindList(result, ["lastname"]) + 1
        );
        
        string id = llList2String(
            result, 
            llListFindList(result, ["id"]) + 1
        );
        
        // Build data to be sent.
        data += " " +  "[" + firstname + " " + lastname + "/"  + id + "]";
 
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
 
state add {
    state_entry() {
        // DEBUG
        llOwnerSay("[Joke] Adding to database: " + (string)(joke_counter + 1));
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
                    "SQL", wasURLEscape("INSERT INTO \"" +
                        wasKeyValueGet("joke table", configuration) + 
                        "\" (name, data, firstname, lastname, id) VALUES (:name, :data, :firstname, :lastname, :id)"),
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
                                wasURLEscape(data),
                                "firstname",
                                wasURLEscape(firstname),
                                "lastname",
                                wasURLEscape(lastname),
                                "id",
                                (string)(joke_counter + 1)
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
            llOwnerSay("[Joke] Unable modify database: " + 
                wasURLUnescape(
                    wasKeyValueGet("data", body)
                )
            );
            state listen_group;
        }
        ++joke_counter;
        data = "Joke " + (string)joke_counter + " has been stored.";
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

state remove {
    state_entry() {
        // DEBUG
        llOwnerSay("[Joke] Removing from database.");
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
                    "SQL", wasURLEscape("DELETE FROM \"" +
                        wasKeyValueGet("joke table", configuration) + 
                        "\" WHERE name=:name AND id=:id"),
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
                                "id",
                                data
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
            llOwnerSay("[Joke] Unable modify database: " + 
                wasURLUnescape(
                    wasKeyValueGet("error", body)
                )
            );
            state listen_group;
        }
        --joke_counter;
        data = "Joke " + data + " has been removed.";
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
        llOwnerSay("[Joke] Sending to group.");
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
