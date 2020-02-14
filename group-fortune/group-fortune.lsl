///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2013 - License: CC BY 2.0      //
//  Please see: https://creativecommons.org/licenses/by/2.0 for legal details,  //
//  rights of fair usage, the disclaimer and warranty conditions.        //
///////////////////////////////////////////////////////////////////////////

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

// Temporary storage for notecard lines.
integer f;
string say;

// Corrade data
string CORRADE = "";
string GROUP = "";
string PASSWORD = "";
integer INTERVAL = 21600;

// For notecard reading
integer line = 0;

// Key-value data will be read into this list
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
            // DEBUG
            llOwnerSay("Read configuration file...");
            state fortune;
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

state fortune {
    state_entry() {
        if(llGetInventoryType("Fortunes") == INVENTORY_NOTECARD) jump schedule;
        llSay(DEBUG_CHANNEL, "Fortunes notecard not found.");
        return;
@schedule;
        llGetNumberOfNotecardLines("Fortunes");
    }
    dataserver(key requested, string data) { 
        f=(integer)data;
        llOwnerSay("Ready, sleeping...");
        state quote;
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
 
state quote {
    state_entry() {
        llGetNotecardLine("Fortunes", (integer)llFrand(f));
    }
    timer() {
        state speak;
    }
    dataserver(key requested, string data) {
        say = data;
        llSetTimerEvent(1 + llFrand(INTERVAL));

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

state speak {
    state_entry() {
        llInstantMessage(CORRADE, 
            wasKeyValueEncode(
                [
                    "command", "tell",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "entity", "group",
                    "message", wasURLEscape(say)
                ]
            )
        );
        llSetTimerEvent(1);
    }
    timer() {
        state quote;
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
