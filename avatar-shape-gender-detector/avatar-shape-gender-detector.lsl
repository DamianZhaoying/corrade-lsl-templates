///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2014 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
//
// This is a script that uses the Corrade Second Life / OpenSim bot which 
// is able to detect the gender of avatar shapes. You can find more details 
// about Corrade at: http://grimore.org/secondlife/scripted_agents/corrade
//
// This script works together with a "configuration" notecard that must be 
// placed in the same primitive as this script. The purpose of this script 
// is to demonstrate detecting avatar genders with Corrade and you are free 
// to use, change, and commercialize it provided that you follow the terms 
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

// corrade data
string CORRADE = "";
string GROUP = "";
string PASSWORD = "";
integer INTERVAL = 0;
integer MEMORY = 0;

// for holding the callback URL
string callback = "";

// for notecard reading
integer line = 0;
 
// key-value data will be read into this list
list tuples = [];
// store names and uuids for gender detect
list names = [];
list uuids = [];
// store the keys of detected agents in 
// order to prevent scanning them again
list found = [];
// temporary storage over event handler scope
string name = "";
key uuid = NULL_KEY;

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
            CORRADE = llList2String(
                tuples,
                llListFindList(
                    tuples, 
                    [
                        "corrade"
                    ]
                )
            +1);
            if(CORRADE == "") {
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
            +1);
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
            +1);
            if(PASSWORD == "") {
                llOwnerSay("Error in configuration notecard: password");
                return;
            }
            INTERVAL = llList2Integer(
                tuples,
                llListFindList(
                    tuples, 
                    [
                        "interval"
                    ]
                )
            +1);
            if(INTERVAL == 0) {
                llOwnerSay("Error in configuration notecard: interval");
                return;
            }
            MEMORY = llList2Integer(
                tuples,
                llListFindList(
                    tuples, 
                    [
                        "memory"
                    ]
                )
            +1);
            if(MEMORY == 0) {
                llOwnerSay("Error in configuration notecard: memory");
                return;
            }
            // DEBUG
            llOwnerSay("Read configuration notecard...");
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
        state scan;
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

state scan {
    state_entry() {
        // DEBUG
        llOwnerSay("Scanning agents...");
        list tmp = llGetAgentList(AGENT_LIST_REGION, []);
        do {
            key id = llList2Key(tmp, 0);
            // skip avatars that we have previously detected
            if(llListFindList(found, (list)id) != -1) jump continue;
            uuids += id;
            names += llKey2Name(id);
@continue;
            tmp = llDeleteSubList(tmp, 0, 0);
        } while(llGetListLength(tmp) != 0);
        // recurse over timer, start.
        llSetTimerEvent(1);
    }
    timer() {
        // Pause the timer.
        llSetTimerEvent(0);
        // if the scanning list is empty, switch to detect
        if(llGetListLength(names) == 0) state detect;
        // pop the first name and UUID off the stack
        name = llList2String(names, 0);
        uuid = llList2Key(uuids, 0);
        names = llDeleteSubList(names, 0, 0);
        uuids = llDeleteSubList(uuids, 0, 0);
        // get the full name and send it to Corrade for scanning
        list full = llParseString2List(name, [" "], []);
        llInstantMessage(CORRADE, 
            wasKeyValueEncode(
                [
                    "command", "getavatardata",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "firstname", wasURLEscape(
                        llList2String(
                            full,
                            0
                        )
                    ),
                    "lastname", wasURLEscape(
                        llList2String(
                            full,
                            1
                        )
                    ),
                    "sift", wasURLEscape(
                        wasListToCSV(
                            [
                                "match", wasURLEscape(
                                    ",Index,31,([^,$]+)"
                                )
                            ]
                        )
                    ),
                    "data", "VisualParameters",
                    "callback", wasURLEscape(callback)
                ]
            )
        );
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");

        if(wasURLUnescape(
            wasKeyValueGet("success", body)) != "True")
            return;
            
        // request succeeded, so grab the 
        // sex from the visual parameters
        integer sex = (integer) wasURLUnescape(
            wasKeyValueGet(
                "data",
                body
            )
        );
        
        // at this point we know the following:
        // - the name of the scanned avatar stored in "name"
        // - the UUID of the scanned avatar stored in "uuid"
        // - the gender of the avatar shape:
        //   - if sex is 0, then the avatar has a female shape
        //   - otherwise, the avatar has a male shape 
        if(sex != 0) {
            llSay(0, "The avatar " + name + "(" + (string)uuid + ")" + " has a male shape!");
            jump continue_2;
        }
        llSay(0, "The avatar " + name + "(" + (string)uuid + ")" + " has a female shape!");
        
@continue_2;

        // this keeps the amount of free memory available to the script above a specified treshold
        if (llGetFreeMemory() < MEMORY)
            found = llDeleteSubList(found, 0, 0);
        
        // to prevent scanning the same avatar again, add the uuid to the found list
        found += uuid;
        
        // Resetart the timer.
        llSetTimerEvent(INTERVAL);
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
