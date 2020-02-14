///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2013 - License: CC BY 2.0      //
//  Please see: https://creativecommons.org/licenses/by/2.0 for legal details,  //
//  rights of fair usage, the disclaimer and warranty conditions.        //
///////////////////////////////////////////////////////////////////////////

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

// corrade data
string CORRADE = "";
list GROUPS = [];
list PASSWORDS = [];
// holds the original count for notice to send
integer notices = 0;
// subject and message for notices
string SUBJECT = "";
string MESSAGE = "";

// holds the current group and password
string group = "";
string password = "";

// store URL
string URL = "";

// for notecard reading
integer line = 0;

// key-value data will be read into this list
list tuples = [];
 
default {
    state_entry() {
        if(llGetInventoryType("configuration") != INVENTORY_NOTECARD) {
            llOwnerSay("Sorry, could not find an inventory notecard.");
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
                +1
            );
            if(CORRADE == "") {
                llOwnerSay("Error in configuration notecard: corrade");
                return;
            }
            
            SUBJECT = llList2String(
                tuples,
                llListFindList(
                    tuples,
                        [
                            "subject"
                        ]
                    )
                +1
            );
            if(SUBJECT == "") {
                llOwnerSay("Error in configuration notecard: subject");
                return;
            }
            
            MESSAGE = llList2String(
                tuples,
                llListFindList(
                    tuples,
                        [
                            "message"
                        ]
                    )
                +1
            );
            if(MESSAGE == "") {
                llOwnerSay("Error in configuration notecard: message");
                return;
            }

            // Retrieve groups.
            integer i = llGetListLength(tuples)-1;
            do {
                string n = llList2String(tuples, i);
                if(llSubStringIndex(n, "group_") == -1) jump skip_group;
                list l = llParseString2List(n, ["_"], []);
                if(llList2String(l, 0) != "group") jump skip_group;
                GROUPS += llList2String(tuples, i + 1);
@skip_group;
            } while(--i>-1);
            
            // Retrieve passwords.
            i = llGetListLength(tuples)-1;
            do {
                string n = llList2String(tuples, i);
                if(llSubStringIndex(n, "password_") == -1) jump skip_password;
                list l = llParseString2List(n, ["_"], []);
                if(llList2String(l, 0) != "password") jump skip_password;
                PASSWORDS += llList2String(tuples, i + 1);
@skip_password;
            } while(--i>-1);
            
            notices = llGetListLength(GROUPS);
            if(notices != llGetListLength(PASSWORDS)) {
                llOwnerSay("Error in configuration notecard: groups and passwords");
                return;
            }
            
            // GC
            tuples = [];
            
            // DEBUG
            llOwnerSay("Read configuration file...");
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
        llRequestURL();
    }
    http_request(key id, string method, string body) {
        if(method != URL_REQUEST_GRANTED) {
          llOwnerSay("I cannot get any more URLs");
          return;
        }
        URL = body;
        state ready;
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

state ready {
    state_entry() {
        llSetText("Touch to start sending notices...", <0, 1, 0>, 1.0);
    }
    touch_start(integer num) {
        state send_trampoline;
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "");
        llOwnerSay(wasURLUnescape(body));
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

state send_trampoline {
    state_entry() {
        llSetText(
            "Notices [" + (string)llGetListLength(GROUPS) + "/" + (string)notices + "]", 
            <1, 1, 0>, 
            1.0
        );
        llSetTimerEvent(1);
    }
    timer() {
        state send;
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

state send {
    state_entry() {
        
        // re-entry / recursion 
        if(llGetListLength(GROUPS) == 0 || 
            llGetListLength(PASSWORDS) == 0) state done;
        
        group = llList2String(GROUPS, 0);
        GROUPS = llDeleteSubList(GROUPS, 0, 0);
        
        password = llList2String(PASSWORDS, 0);
        PASSWORDS = llDeleteSubList(PASSWORDS, 0, 0);
        
        llInstantMessage(CORRADE, 
            wasKeyValueEncode(
                [
                    "command", "notice",
                    "group", wasURLEscape(group),
                    "password", wasURLEscape(password),
                    "subject", wasURLEscape(SUBJECT),
                    "message", wasURLEscape(MESSAGE),
                    "callback", wasURLEscape(URL)
                ]
            )
        );
        
        llSetTimerEvent(60);
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "");
        if(wasKeyValueGet("success", body) != "True") {
            llSetText(
                "Could not send notice to group: " + 
                group + 
                "\n" + 
                "Error: " + 
                wasURLUnescape(
                    wasKeyValueGet(
                        "error", 
                        body
                    )
                ), 
                <1, 0, 0>, 
                1.0
            );
        }
        state send_trampoline;
    }
    timer() {
        llSetText(
            "Timeout waiting for response from Corrade...", 
            <1, 0, 0>, 
            1.0
        );
        state send_trampoline;
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

state done {
    state_entry() {
        llSetText(
            "Notices sent! Touch for restart...",
            <0, 1, 0>,
            1.0
        );
    }
    touch_start(integer num) {
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
