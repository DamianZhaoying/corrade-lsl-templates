///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2014 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
//
// This project makes Corrade, the Second Life / OpenSim bot track all the
// visitors on a region and record information to the group database. More
// information on the Corrade Second Life / OpenSim scripted agent can be 
// found at the URL: http://grimore.org/secondlife/scripted_agents/corrade
//
// The script works in combination with a "configuration" notecard that 
// must be placed in the same primitive as this script. The purpose of this 
// script is to illustrate the Corrade built-in group database features 
// and you are free to use, change, and commercialize it under the terms 
// of the CC BY 2.0 license at: https://creativecommons.org/licenses/by/2.0
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
key CORRADE = NULL_KEY;
string GROUP = "";
string PASSWORD = "";

// for holding the callback URL
string callback = "";

// for notecard reading
integer line = 0;
 
// key-value data will be read into this list
list tuples = [];


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
            CORRADE = llList2Key(
                tuples,
                llListFindList(
                    tuples, 
                    [
                        "corrade"
                    ]
                )
                +1
            );
            if(CORRADE == NULL_KEY) {
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
            // DEBUG
            llOwnerSay("Read configuration notecard...");
            tuples = [];
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
        llSetTimerEvent(5);
    }
    timer() {
        llRequestAgentData((key)CORRADE, DATA_ONLINE);
    }
    dataserver(key id, string data) {
        if(data != "1") {
            // DEBUG
            llOwnerSay("Corrade is not online, sleeping...");
            llSetTimerEvent(30);
            return;
        }
        state initialize;
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
 
state initialize {
    state_entry() {
        // DEBUG
        llOwnerSay("Creating the database if it does not exist...");
        llInstantMessage(
            (key)CORRADE, 
            wasKeyValueEncode(
                [
                    "command", "database",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "SQL", wasURLEscape(
                        "CREATE TABLE IF NOT EXISTS visitors (
                            'firstname' TEXT NOT NULL, 
                            'lastname' TEXT NOT NULL, 
                            'lastseen' TEXT NOT NULL, 
                            'time' INTEGER NOT NULL, 
                            'memory' INTEGER NOT NULL, 
                            PRIMARY KEY ('firstname', 'lastname')
                        )"
                    ),
                    "callback", wasURLEscape(callback)
                ]
            )
        );
        // alarm 60
        llSetTimerEvent(60);
    }
    timer() {
        // DEBUG
        llOwnerSay("Timeout creating table...");
        llResetScript();
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "database") return;
        if(wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Failed to create the table: " + 
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
        llOwnerSay("Table created...");
        state show;
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

state show {
    state_entry() {
        // DEBUG
        llOwnerSay("Updating display with the number of recorded visitors...");
        llInstantMessage(
            (key)CORRADE, 
            wasKeyValueEncode(
                [
                    "command", "database",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "SQL", wasURLEscape(
                        "SELECT 
                            COUNT(*) AS 'Visits', 
                            AVG(time) AS 'Time', 
                            AVG(memory) AS 'Memory' 
                        FROM visitors"
                    ),
                    "callback", wasURLEscape(callback)
                ]
            )
        );
        // alarm 60
        llSetTimerEvent(60);
    }
    timer() {
        // DEBUG
        llOwnerSay("Timeout reading rows from visitors table...");
        llResetScript();
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "database") return;
        if(wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Failed to enumerate visitors: " + 
                wasURLUnescape(
                    wasKeyValueGet(
                        "error", 
                        body
                    )
                )
            );
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
        integer visits = llList2Integer(
            data, 
            llListFindList(
                data, 
                (list)"Visits"
            ) + 1
        );
        integer time = llList2Integer(
            data, 
            llListFindList(
                data, 
                (list)"Time"
            ) + 1
        );
        integer memory = llList2Integer(
            data, 
            llListFindList(
                data, 
                (list)"Memory"
            ) + 1
        );
        llMessageLinked(LINK_ROOT, 204000, "V:" + (string)visits, "0");
        llMessageLinked(LINK_ROOT, 204000, "T:" + (string)time + "m", "1");
        llMessageLinked(LINK_ROOT, 204000, "M:" + (string)memory + "k", "2");
        state scan;
    }
    link_message(integer sender_num, integer num, string str, key id) {
        if(str == "reset")
            state reset;
        if(str == "display") {
            line = 0;
            state display;
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
    state_exit() {
        llSetTimerEvent(0);
    }
}

state scan {
    state_entry() {
        // DEBUG
        llOwnerSay("Scanning for visitors...");
        // Scan for visitors every 60 seconds.
        llSetTimerEvent(60);
    }
    timer() {
        // Check if Corrade is online.
        llRequestAgentData((key)CORRADE, DATA_ONLINE);
        // Get agents
        list as = llGetAgentList(AGENT_LIST_REGION, []);
        do {
            key a = llList2Key(as, 0);
            as = llDeleteSubList(as, 0, 0);
            list name = llParseString2List(llKey2Name(a), [" "], []);
            if(llGetListLength(name) != 2) return;
            string fn = llList2String(name, 0);
            string ln = llList2String(name, 1);
            // The command sent to Corrade responsible for adding a visitor
            // or updating the data for the visitor in case the visitor is
            // already entered into the visitors table. This is performed
            // with an INSER OR REPLACE sqlite command given the first name
            // and the last name of the avatar are unique primary keys.
            llInstantMessage(
                (key)CORRADE,
                wasKeyValueEncode(
                    [
                        "command", "database",
                        "group", wasURLEscape(GROUP),
                        "password", wasURLEscape(PASSWORD),
                        "SQL", wasURLEscape(
                            "INSERT OR REPLACE INTO visitors (
                                firstname, 
                                lastname, 
                                lastseen, 
                                time, 
                                memory
                            ) VALUES(
                                '" + fn + "', '" +  ln + "', '" + llGetTimestamp() + "', 
                                COALESCE(
                                    (
                                        SELECT time FROM visitors WHERE 
                                            firstname='" + fn + "' AND lastname='" + ln + "'
                                    ) + 1
                                    , 
                                    1
                                ), " + 
                                (string)(
                                    (integer)(
                                        llList2Float(
                                            llGetObjectDetails(
                                                a,
                                                [OBJECT_SCRIPT_MEMORY]
                                            ),
                                            0
                                        )
                                        /
                                        1024 /*in kib, to mib 1048576*/
                                    )

                                ) + 
                            ")"
                        )
                    ]
                )
            );
        } while(llGetListLength(as));
        state show;
    }
    link_message(integer sender_num, integer num, string str, key id) {
        if(str == "reset")
            state reset;
        if(str == "display") {
            line = 0;
            state display;
        }
    }
    dataserver(key id, string data) {
        if(data == "1") return;
        // DEBUG
        llOwnerSay("Corrade is not online, sleeping...");
        // Switch to detect loop and wait there for Corrade to come online.
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
    state_exit() {
        llSetTimerEvent(0);
    }
}

state display_trampoline {
    state_entry() {
        ++line;
        state display;
    }
    link_message(integer sender_num, integer num, string str, key id) {
        if(str == "reset")
            state reset;
    }
}

state display {
    state_entry() {
        llInstantMessage(
            (key)CORRADE, 
            wasKeyValueEncode(
                [
                    "command", "database",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "SQL", wasURLEscape(
                        "SELECT * FROM visitors
                            ORDER BY lastseen DESC 
                            LIMIT 1 
                            OFFSET " + (string)line
                    ),
                    "callback", wasURLEscape(callback)
                ]
            )
        );
        // alarm 60
        llSetTimerEvent(60);
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "database") return;
        if(wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Failed to query the table: " + 
                wasURLUnescape(
                    wasKeyValueGet(
                        "error", 
                        body
                    )
                )
            );
            return;
        }
        // Grab the data key if it exists.
        string dataKey = wasURLUnescape(
            wasKeyValueGet(
                "data",
                body
            )
        );
        
        // We got no more rows, so switch back to scanning.
        if(dataKey == "")
            state scan;
               
        list data = wasCSVToList(dataKey);
            
        string firstname = llList2String(
            data, 
            llListFindList(
                data, 
                (list)"firstname"
            ) + 1
        );
        string lastname = llList2String(
            data, 
            llListFindList(
                data, 
                (list)"lastname"
            ) + 1
        );
        string lastseen = llList2String(
            data, 
            llListFindList(
                data, 
                (list)"lastseen"
            ) + 1
        );

        llOwnerSay(firstname + " " + lastname + " @ " + lastseen);
        state display_trampoline;
    }
    link_message(integer sender_num, integer num, string str, key id) {
        if(str == "reset")
            state reset;
    }
    timer() {
        // DEBUG
        llOwnerSay("Timeout reading rows from visitors table...");
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

state reset {
    state_entry() {
        // DEBUG
        llOwnerSay("Resetting all visitors...");
        llInstantMessage(
            (key)CORRADE,
            wasKeyValueEncode(
                [
                    "command", "database",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "SQL", "DROP TABLE visitors",
                    "callback", wasURLEscape(callback)
                ]
            )
        );
        // alarm 60
        llSetTimerEvent(60);
    }
    timer() {
        // DEBUG
        llOwnerSay("Timeout deleting database...");
        llResetScript();
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "database") return;
        if(wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Failed to drop the visitors table: " + 
                wasURLUnescape(
                    wasKeyValueGet(
                        "error", 
                        body
                    )
                )
            );
            llResetScript();
        }
        // DEBUG
        llOwnerSay("Table dropped...");
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
