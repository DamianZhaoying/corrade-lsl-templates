///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2014 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
//
// A greet and invite script made to work in conjunction with the Corrade
// the Second Life / OpenSim bot. You can find more details about the bot
// by following the URL: http://was.fm/secondlife/scripted_agents/corrade
//
// The script works in combination with a "configuration" notecard that
// must be placed in the same primitive as this script. The purpose of this
// script is to demonstrate greeting and inviting avatars using Corrade
// and  you are free to use, change, and commercialize it under the terms
// of the CC BY 2.0 license at: https://creativecommons.org/licenses/by/2.0
//
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2015 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
string wasKeyValueGet(string k, string data) {
    if (llStringLength(data) == 0) return "";
    if (llStringLength(k) == 0) return "";
    list a = llParseString2List(data, ["&", "="], []);
    integer i = llListFindList(llList2ListStrided(a, 0, -1, 2), [ k ]);
    if (i != -1) return llList2String(a, 2 * i + 1);
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
    } while (llGetListLength(k) != 0);
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

// Helper function to extract values from tuples
string getConfigValue(string id) {
    integer i = llListFindList(tuples, (list)id);
    if (i == -1) return "";
    return llList2String(
        tuples,
        i + 1
    );
}

// corrade data
key CORRADE = "";
string GROUP = "";
string PASSWORD = "";

// instance variables
integer channel;
list rem = [];

// for holding the callback URL
string callback = "";

// for notecard reading
integer line = 0;

// key-value data will be read into this list
list tuples = [];

default {
    state_entry() {
        // Set-up commnuication channel.
        channel = (integer)("0x8" + llGetSubString(llGetKey(), 0, 6));
        // Read configuration.
        if (llGetInventoryType("configuration") != INVENTORY_NOTECARD) {
            llOwnerSay("Sorry, could not find a configuration inventory notecard.");
            return;
        }
        // DEBUG
        llOwnerSay("Reading configuration file...");
        llGetNotecardLine("configuration", line);
    }
    dataserver(key id, string data) {
        if (data == EOF) {
            // invariant, length(tuples) % 2 == 0
            if (llGetListLength(tuples) % 2 != 0) {
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
                ) + 1
            );
            if (CORRADE == NULL_KEY) {
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
                ) + 1
            );
            if (GROUP == "") {
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
                ) + 1
            );
            if (PASSWORD == "") {
                llOwnerSay("Error in configuration notecard: password");
                return;
            }
            // DEBUG
            llOwnerSay("Read configuration notecard...");
            state url;
        }
        if (data == "") jump continue;
        integer i = llSubStringIndex(data, "#");
        if (i != -1) data = llDeleteSubString(data, i, -1);
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
        if (k == "" || v == "") jump continue;
        tuples += k;
        tuples += v;
        @continue;
        llGetNotecardLine("configuration", ++line);
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if ((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START)) {
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
        if (method != URL_REQUEST_GRANTED) return;
        callback = body;
        // DEBUG
        llOwnerSay("Got URL...");
        state online;
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if ((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START)) {
            llResetScript();
        }
    }
}

state online {
    state_entry() {
        // DEBUG
        llOwnerSay("Detecting if Corrade is online...");
        llSetTimerEvent(5);
    }
    timer() {
        llRequestAgentData((key)CORRADE, DATA_ONLINE);
    }
    dataserver(key id, string data) {
        if (data != "1") {
            // DEBUG
            llOwnerSay("Corrade is not online, sleeping...");
            llSetTimerEvent(30);
            return;
        }
        state notify;
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if ((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START)) {
            llResetScript();
        }
    }
}

state notify {
    state_entry() {
        // DEBUG
        llOwnerSay("Binding to the membership notification...");
        llInstantMessage(
            (key)CORRADE,
            wasKeyValueEncode(
                [
                    "command", "notify",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "action", "set",
                    "type", llList2CSV(["membership"]),
                    "URL", wasURLEscape(callback),
                    "callback", wasURLEscape(callback)
                ]
                )
        );
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if (wasKeyValueGet("command", body) != "notify" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Failed to bind to the membership notification...");
            state detect;
        }
        // DEBUG
        llOwnerSay("Membership notification installed...");
        state detect;
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if ((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START)) {
            llResetScript();
        }
    }
}

state detect {
    state_entry() {
        // DEBUG
        llOwnerSay("Scanning...");
        llSensorRepeat("", "", AGENT, (float)getConfigValue("range"), TWO_PI, 1);
        llListen(channel, "", "", "");
        // Poll for Corrade's online status.
        llSetTimerEvent(5);
    }
    timer() {
        llRequestAgentData((key)CORRADE, DATA_ONLINE);
    }
    dataserver(key id, string data) {
        if (data == "1") return;
        // DEBUG
        llOwnerSay("Corrade is not online, sleeping...");
        // Switch to detect loop and wait there for Corrade to come online.
        state online;
    }
    touch_start(integer num) {
        llDialog(
            llDetectedKey(0),
            getConfigValue("welcome"),
            [
                getConfigValue("join"),
                getConfigValue("info"),
                getConfigValue("exit"),
                getConfigValue("mark"),
                getConfigValue("gift"),
                getConfigValue("site"),
                getConfigValue("page")
            ],
            channel
        );
    }
    listen(integer channel, string name, key id, string message) {
        if (message == getConfigValue("exit")) return;
        if (message == getConfigValue("join")) {
            // DEBUG
            llOwnerSay("Inviting: " + name + " to the group.");
            llInstantMessage(CORRADE,
                wasKeyValueEncode(
                    [
                        "command", "invite",
                        "group", wasURLEscape(GROUP),
                        "password", wasURLEscape(PASSWORD),
                        "agent", wasURLEscape(id)
                    ]
                    )
            );
            jump menu;
        }
        if (message == getConfigValue("page")) {
            list a = llParseString2List(getConfigValue("help"), [", ", ","], []);
            if (llGetListLength(a) == 0) {
                llInstantMessage(id, getConfigValue("n/a"));
                jump menu;
            }
            vector p = llGetPos();
            string slurl = "secondlife://" + wasURLEscape(llGetRegionName()) + "/" + 
                (string)((integer)p.x) + "/" + 
                (string)((integer)p.y) + "/" + 
                (string)((integer)p.z);
            do {
                list n = llParseString2List(llList2String(a, 0), [" "], []);
                if (llGetListLength(n) == 2) {
                    llInstantMessage(CORRADE,
                        wasKeyValueEncode(
                            [
                                "command", "tell",
                                "group", wasURLEscape(GROUP),
                                "password", wasURLEscape(PASSWORD),
                                "entity", "avatar",
                                "firstname", wasURLEscape(llList2String(n, 0)),
                                "lastname", wasURLEscape(llList2String(n, 1)),
                                "message", wasURLEscape(
                                    name + 
                                    " is asking for help at: " + 
                                    slurl
                                )
                            ]
                        )
                    );
                }
                a = llDeleteSubList(a, 0, 0);
            } while (llGetListLength(a) != 0);
            llInstantMessage(id, getConfigValue("assist"));
            jump menu;
        }
        if (message == getConfigValue("mark")) {
            if (llGetInventoryNumber(INVENTORY_LANDMARK) == 0) {
                llInstantMessage(id, getConfigValue("n/a"));
                jump menu;
            }
            llGiveInventory(id, llGetInventoryName(INVENTORY_LANDMARK, 0));
            jump menu;
        }
        if (message == getConfigValue("info")) {
            integer i = llGetInventoryNumber(INVENTORY_NOTECARD) - 1;
            do {
                if (llGetInventoryName(INVENTORY_NOTECARD, i) != "configuration") {
                    llGiveInventory(id, llGetInventoryName(INVENTORY_NOTECARD, i));
                    jump menu;
                }
            } while (--i > -1);
            llInstantMessage(id, getConfigValue("n/a"));
            jump menu;
        }
        if (message == getConfigValue("gift")) {
            if (llGetInventoryNumber(INVENTORY_OBJECT) == 0) {
                llInstantMessage(id, getConfigValue("n/a"));
                jump menu;
            }
            llGiveInventory(id, llGetInventoryName(INVENTORY_OBJECT, 0));
            jump menu;
        }
        if (message == getConfigValue("site")) {
            llLoadURL(id, getConfigValue("loadurl"), getConfigValue("website"));
            jump menu;
        }
@menu;
        llDialog(
            id,
            getConfigValue("welcome"),
            [
                getConfigValue("join"),
                getConfigValue("info"),
                getConfigValue("exit"),
                getConfigValue("mark"),
                getConfigValue("gift"),
                getConfigValue("site"),
                getConfigValue("page")
            ],
            channel
        );
    }
    no_sensor() {
        rem = [];
    }
    sensor(integer i) {
        --i;
        do {
            key id = llDetectedKey(i);
            if (id == NULL_KEY) jump continue;
            if (llListFindList(rem, (list)id) != -1) jump continue;
            llDialog(
                id,
                getConfigValue("welcome"),
                [
                    getConfigValue("join"),
                    getConfigValue("info"),
                    getConfigValue("exit"),
                    getConfigValue("mark"),
                    getConfigValue("gift"),
                    getConfigValue("site"),
                    getConfigValue("page")
                ],
                channel
            );
            rem += id;
@continue;
        } while (--i > -1);
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        list a = llParseString2List(getConfigValue("notify"), [", ", ","], []);
        if (llGetListLength(a) == 0) {
            // DEBUG
            llOwnerSay("Could not read list of avatars to notify about group membership...");
            return;
        }
        do {
            list n = llParseString2List(llList2String(a, 0), [" "], []);
            if (llGetListLength(n) == 2) {
                llInstantMessage(CORRADE,
                    wasKeyValueEncode(
                        [
                            "command", "tell",
                            "group", wasURLEscape(GROUP),
                            "password", wasURLEscape(PASSWORD),
                            "entity", "avatar",
                            "firstname", wasURLEscape(llList2String(n, 0)),
                            "lastname", wasURLEscape(llList2String(n, 1)),
                            "message", wasURLEscape(
                                wasURLUnescape(wasKeyValueGet("firstname", body)) + 
                                " " + 
                                wasURLUnescape(wasKeyValueGet("lastname", body)) + 
                                " has " + 
                                wasURLUnescape(wasKeyValueGet("action", body)) + 
                                " the group."
                            )
                        ]
                    )
                );
            }
            a = llDeleteSubList(a, 0, 0);
        } while (llGetListLength(a) != 0);
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if ((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START)) {
            llResetScript();
        }
    }
}
