///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2016 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
//
// A wiki module that can memorize strings and recall them by path.
//
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2014 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
integer wasIsAlNum(string a) {
    if(a == "") return FALSE;
    integer x = llBase64ToInteger("AAAA" + 
        llStringToBase64(llGetSubString(a, 0, 0)));
    return (x >= 65 && x <= 90) || (x >= 97 && x <= 122) ||
        (x >= 48 && x <= 57);
}
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
string path = "";
string data = "";
string action = "";
string statement = "";
string parameters = "";

default {
    state_entry() {
        llOwnerSay("[Wiki] Starting...");
        llSetTimerEvent(10);
    }
    link_message(integer sender, integer num, string message, key id) {
        if(id != "configuration") return;
        llOwnerSay("[Wiki] Got configuration...");
        configuration = message;
        action = "create";
        state url;
    }
    timer() {
        llOwnerSay("[Wiki] Requesting configuration...");
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
        llOwnerSay("[Wiki] Requesting URL...");
        llRequestURL();
    }
    http_request(key id, string method, string body) {
        if(method != URL_REQUEST_GRANTED) return;
        URL = body;
        // DEBUG
        llOwnerSay("[Wiki] Got URL.");
        
        if(action == "create") {
            statement = wasURLEscape("CREATE TABLE IF NOT EXISTS \"" + 
                wasKeyValueGet("wiki table", configuration) + 
                "\" (path text unique collate nocase, data text)");
            state query;
        }
        
        if(action == "get") {
            statement = wasURLEscape("SELECT data FROM \"" +
                wasKeyValueGet("wiki table", configuration) + 
                "\" WHERE path=:path");
            parameters = wasURLEscape(
                wasListToCSV(
                    [
                        "path",
                        wasURLEscape(path)
                    ]
                )
            );
            state query;
        }
        
        if(action == "set") {
            if(data == "") {
                statement = wasURLEscape("DELETE FROM \"" + 
                    wasKeyValueGet("wiki table", configuration) + 
                    "\" WHERE path=:path");
                parameters = wasURLEscape(
                    wasListToCSV(
                        [
                            "path",
                            wasURLEscape(path)
                        ]
                    )
                );
                state query;
            }
            statement = wasURLEscape("REPLACE INTO \"" +
                wasKeyValueGet("wiki table", configuration) + 
                "\" (path, data) VALUES (:path, :data)");
            parameters = wasURLEscape(
                wasListToCSV(
                    [
                        "path",
                        wasURLEscape(path),
                        "data",
                        wasURLEscape(data)
                    ]
                )
            );
            state query;
        }
        
        if(action == "dir") {
            if(path == "/") {
                path = "";
                statement = wasURLEscape(
                    "SELECT DISTINCT SUBSTR(path, 1, LENGTH(path) - LENGTH(LTRIM(SUBSTR(path,2), 'abcdefghijklmnopqrstuvwxyz'))) AS path FROM \"" + 
                    wasKeyValueGet("wiki table", configuration) + 
                    "\" WHERE path LIKE '/%' LIMIT " +
                    wasKeyValueGet("wiki results limit", configuration)
                );
                state query;
            }
            statement = wasURLEscape(
                "SELECT DISTINCT SUBSTR(REPLACE(path, :base, ''),1, LENGTH(REPLACE(path, :base, '')) - LENGTH(LTRIM(REPLACE(path, :base, ''), 'abcdefghijklmnopqrstuvwxyz'))) AS path FROM \"" + 
                wasKeyValueGet("wiki table", configuration) + 
                "\" WHERE path LIKE :path LIMIT " +
                wasKeyValueGet("wiki results limit", configuration)
            );
            parameters = wasURLEscape(
                wasListToCSV(
                    [
                        "path",
                        wasURLEscape(path + "/" + "%"),
                        "base",
                        wasURLEscape("/" + 
                            llDumpList2String(
                                llParseString2List(
                                    path,
                                    ["/"],
                                    []
                                ),
                                "/"
                            ) + 
                            "/"
                        )
                    ]
                )
            );
            state query;
        }
        
        if(action == "find") {
            if(data == "") {
                data = "Command requires two parameters: a path followed by a search term.";
                state tell;
            }
            if(path == "/")
                path = "";            
            statement = wasURLEscape(
                "SELECT DISTINCT path FROM \"" + 
                wasKeyValueGet("wiki table", configuration) + 
                "\" WHERE path LIKE :path AND ( data LIKE :data OR path LIKE :data ) COLLATE NOCASE LIMIT " +
                wasKeyValueGet("wiki search limit", configuration)
            );
            parameters = wasURLEscape(
                wasListToCSV(
                    [
                        "path",
                        wasURLEscape(path + "/" + "%"),
                        "data",
                        wasURLEscape("%" + data + "%")
                    ]
                )
            );
            state query;
        }
        
        // DEBUG
        llOwnerSay("[Wiki] Jump table corrupted, please contact creator...");
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

state listen_group {
    state_entry() {
        // DEBUG
        llOwnerSay("[Wiki] Waiting for group messages...");
    }
    link_message(integer sender, integer num, string message, key id) {
        // We only care about notifications now.
        if(id != "notification")
            return;
        
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
            wasKeyValueGet("command", configuration) + "wiki")
            return;
            
        // Remove command.
        command = llDeleteSubList(command, 0, 0);
        
        // Check for supported sub-commands.
        if(llList2String(command, 0) != "set" && 
            llList2String(command, 0) != "get" &&
            llList2String(command, 0) != "dir" &&
            llList2String(command, 0) != "find") {
            data = "Subcommands are: get, set, dir or find";
            state tell;
        }
        
        // Get the sub-command and store it as a jump state.
        action = llList2String(command, 0);
        
        // Remove sub-command.
        command = llDeleteSubList(command, 0, 0);
        
        // Get the path parts.
        list path_parts = llParseString2List(
            llList2String(command, 0), ["/"], []
        );
        
        // Dump the path and store it over states.
        path = llStringTrim(
            llDumpList2String(
                path_parts, 
                "/"
            ), 
            STRING_TRIM
        );
        
        if(path != "") {
            integer i = llStringLength(path) - 1;
            do {
                string c = llGetSubString(path, i, i);
                if(c != "/" && !wasIsAlNum(c)) {
                    data = "Only alpha-numerics accepted in the path string.";
                    state tell;
                }
            } while(--i > -1);
        }
        
        path = "/" + path;
        
        // Remove path.
        command = llDeleteSubList(command, 0, 0);
        
        // Dump the rest of the message.
        data = llDumpList2String(command, " ");
        
        // Get an URL.
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

state query {
    state_entry() {
        // Check messge length.
        string message = wasKeyValueEncode(
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
                "SQL", statement,
                "data", parameters,
                "callback", wasURLEscape(URL)
            ]
        );
        // GC - none of these are needed anymore.
        statement = "";
        parameters = "";
        if(llStringLength(message) > 1023) {
            data = "Message length exceeded 1023 characters.";
            state tell;
        }
        // DEBUG
        llOwnerSay("[Wiki] Executing action: " + action);
        llInstantMessage(
            wasKeyValueGet(
                "corrade", 
                configuration
            ), 
            message
        );
        // GC
        message = "";
        llSetTimerEvent(60);
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        llReleaseURL(URL);
        if(wasKeyValueGet("command", body) != "database" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("[Wiki] Unable query database: " + 
                wasURLUnescape(
                    wasKeyValueGet("error", body)
                )
            );
            state listen_group;
        }
        
        // Process actions.
        
        if(action == "set") {
            if(data == "") {
                data = "Deleted from " + path;
                state tell;
            }
            data = "Stored into " + path;
            state tell;
        }

        if(action == "find") {
            data = llDumpList2String(
                llList2ListStrided(
                    llDeleteSubList(
                        wasCSVToList(
                            wasURLUnescape(
                                wasKeyValueGet("data", body)
                            )
                        ),
                        0,
                        0
                    ),
                    0,
                    -1,
                    2
                ),
                ","
            );
            if(data == "") {
                data = "Sorry, the term was not found.";
                state tell;
            }
            state tell;
        }

        if(action == "get") {
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
                data = "Sorry, that path contains no data.";
                state tell;
            }
        
            data = path + ": " + data;
            state tell;
        }
        
        if(action == "dir") {
            list paths = llList2ListStrided(
                llDeleteSubList(
                    wasCSVToList(
                        wasURLUnescape(
                            wasKeyValueGet("data", body)
                        )
                    ),
                    0,
                    0
                ),
                0,
                -1,
                2
            );
        
            if(llGetListLength(paths) == 0) {
                data = "Sorry, that path contains no sub-paths.";
                state tell;
            }
        
            // Eliminate path component.
            if(path == "/")
                path = "";
        
            list sibling = [];
            do {
                // Get the path part.
                string part = llList2String(paths, 0);
            
                // Remove the path component.
                string child = llStringTrim(
                    llDumpList2String(
                        llParseString2List(
                            part,
                            [path, "/"], 
                            []
                        ),
                        "/"
                    ),
                    STRING_TRIM
                
                );
            
                integer i = llSubStringIndex(child, "/");
                if(i == -1) {
                    sibling +=  path + "/" + child;
                    jump continue_dir;
                }
                child = path + "/" + llDeleteSubString(child, i, -1) + "/";
                if(llListFindList(sibling, (list)child) == -1)
                    sibling += child;
@continue_dir;
                paths = llDeleteSubList(paths, 0, 0);
            } while(llGetListLength(paths) != 0);
        
            data = llList2CSV(sibling);
            // GC
            sibling = [];
        
            state tell;
        }
        
        // Don't announce creating table.
        if(action == "create")
            state listen_group;
        
        // DEBUG
        llOwnerSay("[Wiki] Jump table corrupted, please contact creator...");
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

state tell {
    state_entry() {
        // DEBUG
        llOwnerSay("[Wiki] Sending to group.");
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
        // GC
        path = "";
        data = "";
        state listen_group;
    }
}
