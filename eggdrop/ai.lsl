///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2016 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
//
// A module using AI-SIML that allows group members to talk to Corrade.
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
//    Copyright (C) 2017 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
list wasSetIntersect(list a, list b) {
    if(llGetListLength(a) == 0) return [];
    string i = llList2String(a, 0);
    a = llDeleteSubList(a, 0, 0);
    if(llListFindList(b, (list)i) == -1)
        return wasSetIntersect(a, b);
    return i + wasSetIntersect(a, b);
}

// configuration data
string configuration = "";
// callback URL
string URL = "";
// store message over state.
string data = "";
string jump_table = "";
string messageHash = "";

default {
    state_entry() {
        llOwnerSay("[AI] Starting...");
        llSetTimerEvent(10);
    }
    link_message(integer sender, integer num, string message, key id) {
        if(id != "configuration") return;
        llOwnerSay("[AI] Got configuration...");
        configuration = message;
        
        // Subscribe to MQTT messages.
        jump_table = "subscribe";
        state url;
    }
    timer() {
        llOwnerSay("[AI] Requesting configuration...");
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
        llOwnerSay("[AI] Requesting URL...");
        llRequestURL();
    }
    http_request(key id, string method, string body) {
        if(method != URL_REQUEST_GRANTED) return;
        URL = body;
        
        // DEBUG
        llOwnerSay("[AI] Got URL...");
        
        if(jump_table == "subscribe")
            state subscribe;
        if(jump_table == "publish")
            state publish;
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

state subscribe {
    state_entry() {
        // DEBUG
        llOwnerSay("[AI] Subscribing to Corrade AI...");
        llInstantMessage(
            wasKeyValueGet(
                "corrade", 
                configuration
            ), 
            wasKeyValueEncode(
                [
                    "command", "MQTT",
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
                    // Subscribe to Corrade AI
                    "action", "subscribe",
                    "id", wasURLEscape(
                        wasKeyValueGet(
                            "ai subscription", 
                            configuration
                        )
                    ),
                    // Corrade AI listening host.
                    "host", wasURLEscape(
                        wasKeyValueGet(
                            "ai host", 
                            configuration
                        )
                    ),
                    // Corrade AI listening port.
                    "port", wasURLEscape(
                        wasKeyValueGet(
                            "ai port", 
                            configuration
                        )
                    ),
                    // Corrade AI credentials.
                    "username", wasURLEscape(
                        wasKeyValueGet(
                            "ai username", 
                            configuration
                        )
                    ),
                    "secret", wasURLEscape(
                        wasKeyValueGet(
                            "ai secret", 
                            configuration
                        )
                    ),
                    // Use the SIML module of Corrade AI.
                    "topic", "SIML",
                    // Send the result of the MQTT command to this URL.
                    "callback", wasURLEscape(URL)
                ]
            )
        );
    }
    
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        llReleaseURL(URL);
        if(wasKeyValueGet("command", body) != "MQTT" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("[AI] Unable to subscribe to MQTT topic: " + 
                wasURLUnescape(
                    wasKeyValueGet("error", body)
                )
            );
            llResetScript();
        }
        
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
        llOwnerSay("[AI] Waiting for group messages...");
    }
    link_message(integer sender, integer num, string message, key id) {
        // We only care about notifications now.
        if(id != "notification")
            return;
        
        // Listen to group message notifications.
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
            wasKeyValueGet("command", configuration) + 
            wasKeyValueGet("nickname", configuration))
            return;
            
        // Remove command.
        command = llDeleteSubList(command, 0, 0);
        
        // Dump the rest of the message.
        data = llDumpList2String(command, " ");

        // Get an URL.
        jump_table = "publish";
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

state publish {
    state_entry() {
        // DEBUG
        llOwnerSay("[AI] Sending to AI for processing...");
        
        messageHash = llSHA1String(data);
        
        llInstantMessage(
            wasKeyValueGet(
                "corrade", 
                configuration
            ), 
            wasKeyValueEncode(
                [
                    "command", "MQTT",
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
                    "action", "publish",
                    // Corrade AI listening host.
                    "host", wasURLEscape(
                        wasKeyValueGet(
                            "ai host", 
                            configuration
                        )
                    ),
                    // Corrade AI listening port.
                    "port", wasURLEscape(
                        wasKeyValueGet(
                            "ai port", 
                            configuration
                        )
                    ),
                    // Corrade AI credentials.
                    "username", wasURLEscape(
                        wasKeyValueGet(
                            "ai username", 
                            configuration
                        )
                    ),
                    "secret", wasURLEscape(
                        wasKeyValueGet(
                            "ai secret", 
                            configuration
                        )
                    ),
                    // Use the SIML module of Corrade AI.
                    "topic", "SIML",
                    "payload", wasURLEscape(
                        wasKeyValueEncode(
                            [
                                // The hash is an identifier that will allow responses from Corrade AI
                                // for various messages to be distinguished. It can be any identifier
                                // but a handy way of generating an identifier is to hash the message.
                                "Hash", messageHash,
                                // Note the double escaping!
                                "Message", wasURLEscape(data)
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
        if(wasKeyValueGet("command", body) != "MQTT" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("[AI] Unable to publish message: " + 
                wasURLUnescape(
                    wasKeyValueGet("data", body)
                )
            );
            state listen_group;
        }
        
        // DEBUG
        llOwnerSay("[AI] Message published successfully...");
    }
    link_message(integer sender, integer num, string message, key id) {
        // We only care about notifications now.
        if(id != "notification")
            return;
        
        // Listen to MQTT messages.
        if(wasKeyValueGet("type", message) != "MQTT")
            return;
            
        // Get the sent message.
        data = wasURLUnescape(
            wasKeyValueGet(
                "payload", 
                message
            )
        );
        
        string hash = wasURLUnescape(
            wasKeyValueGet(
                "Hash", 
                data
            )
        );
        
        string serverMessage = wasURLUnescape(
            wasKeyValueGet(
                "ServerMessage", 
                data
            )
        );
        
        // Skip generated messages that are not for the published message.
        if(hash != messageHash || 
            serverMessage != "True")
            return;
        
        data = wasURLUnescape(
            wasKeyValueGet(
                "Message", 
                data
            )
        );
        
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
        llOwnerSay("[AI] Sending to group.");
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
