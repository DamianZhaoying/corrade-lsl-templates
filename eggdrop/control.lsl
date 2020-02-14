///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2016 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
//
// An eggdrop-like group bot using Corrade.
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

// for notecard reading
integer line = 0;
 
// key-value data will be read into this list
list tuples = [];
string configuration = "";
// Corrade's online status.
integer online = FALSE;
integer compatible = FALSE;
string URL = "";

// The notifications to bind to.
list notifications = [ "group", "membership", "login", "MQTT" ];

default {
    state_entry() {
        if(llGetInventoryType("configuration") != INVENTORY_NOTECARD) {
            llOwnerSay("[Control] Sorry, could not find a configuration inventory notecard.");
            return;
        }
        // DEBUG
        llOwnerSay("[Control] Reading configuration file...");
        llGetNotecardLine("configuration", line);
    }
    dataserver(key id, string data) {
        if(data == EOF) {
            // invariant, length(tuples) % 2 == 0
            if(llGetListLength(tuples) % 2 != 0) {
                llOwnerSay("[Control] Error in configuration notecard.");
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
                llOwnerSay("[Control] Error in configuration notecard: corrade");
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
                llOwnerSay("[Control] Error in configuration notecard: group");
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
                llOwnerSay("[Control] Error in configuration notecard: password");
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
                llOwnerSay("[Control] Error in configuration notecard: version");
                return;
            }
            // DEBUG
            llOwnerSay("[Control] Read configuration notecard...");
            configuration = wasKeyValueEncode(tuples);
            // GC
            tuples = [];
            state request_url_notifications;
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

state request_url_notifications {
    state_entry() {
        // DEBUG
        llOwnerSay("[Control] Requesting URL...");
        llRequestURL();
    }
    http_request(key id, string method, string body) {
        if(method != URL_REQUEST_GRANTED) return;
        URL = body;
        // DEBUG
        llOwnerSay("[Control] Got URL...");
        state unbind_notifications;
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

state unbind_notifications {
    state_entry() {
        // DEBUG
        llOwnerSay("[Control] Releasing notifications...");
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
                            "notification tag", 
                            configuration
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
        if(wasKeyValueGet("command", body) != "notify" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("[Control] Unable to release tag: " + 
                wasURLUnescape(
                    wasKeyValueGet("error", body)
                )
            );
            llResetScript();
        }
        state bind_notifications;
    }
    timer() {
        llOwnerSay("[Control] Timeout releasing notifications");
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

state bind_notifications {
    state_entry() {
        // DEBUG
        llOwnerSay("[Control] Binding to notifications...");
        llInstantMessage(
            wasKeyValueGet(
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
                    "action", "add",
                    "type", wasURLEscape(
                        wasListToCSV(
                            notifications
                        )
                    ),
                    "URL", wasURLEscape(URL),
                    "tag", wasURLEscape(
                        wasKeyValueGet(
                            "notification tag", 
                            configuration
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
        if(wasKeyValueGet("command", body) != "notify" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("[Control] Unable to bind notifications: " + 
                wasURLUnescape(
                    wasKeyValueGet("error", body)
                )
            );
            llResetScript();
        }
        state serve_configuration;
    }
    timer() {
        llOwnerSay("[Control] Timeout binding notifications");
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

state serve_configuration {
    state_entry() {
        // DEBUG
        llOwnerSay("[Control] Checking version...");
        llInstantMessage(
            wasKeyValueGet(
                "corrade",
                configuration
            ),
            wasKeyValueEncode(
                [
                    "command", "version",
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
                    "callback", wasURLEscape(URL)
                 ]
            )
        );
        llSetTimerEvent(60);
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        llSetTimerEvent(0);
        if(wasKeyValueGet("command", body) != "version") {
            llMessageLinked(LINK_THIS, 0, body, "notification");
            return;
        }
            
        if(wasKeyValueGet("success", body) != "True") {
            llOwnerSay("[Control] Version check failed...");
            return;
        }
        
        list v = llParseString2List(
            wasKeyValueGet(
                "data",
                body
            ),
            ["."],
            []
        );
        integer receivedVersion = (integer)(llList2String(v, 0) + llList2String(v, 1));
        v = llParseString2List(
            wasKeyValueGet(
                "version",
                configuration
            ),
            ["."],
            []
        );
        integer notecardVersion = (integer)(llList2String(v, 0) + llList2String(v, 1));
        if(receivedVersion < notecardVersion) {
            llOwnerSay("[Control] Version is incompatible! You need a Corrade of at least version: " +
                wasKeyValueGet(
                    "version",
                    configuration
                ) +
                " for this template."
            );
            compatible = FALSE;
            //llReleaseURL(URL);
            return;
        }
        // DEBUG
        llOwnerSay("[Control] Version is compatible!");
        compatible = TRUE;
        //llReleaseURL(URL);
        return;
    }
    link_message(integer sender, integer num, string message, key id) {
        if(message != "configuration") return;
        llMessageLinked(LINK_THIS, 0, configuration, "configuration");
    }
    timer() {
        llOwnerSay("[Control] Timeout checking version...");
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
