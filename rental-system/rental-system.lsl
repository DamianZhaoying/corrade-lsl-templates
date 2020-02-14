///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2015 - License: CC BY 2.0      //
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
string wasKeyValueGet(string k, string data) {
    if(llStringLength(data) == 0) return "";
    if(llStringLength(k) == 0) return "";
    list a = llParseString2List(data, ["&", "="], []);
    integer i = llListFindList(llList2ListStrided(a, 0, -1, 2), [ k ]);
    if(i != -1) return llList2String(a, 2*i+1);
    return "";
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
//    Copyright (C) 2013 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
integer wasDateTimeToStamp(
    integer year,
    integer month,
    integer day,
    integer hour,
    integer minute,
    integer second
    ) {
    month -= 2;
    if (month <= 0) {
        month += 12;
        --year;
    }
    return 
    (
        (((year / 4 - year / 100 + year / 400 + (367 * month) / 12 + day) +
                year * 365 - 719499
            ) * 24 + hour
        ) * 60 + minute
    ) * 60 + second;
}

///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2014 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
float wasFmod(float a, float p) {
    if(p == 0) return (float)"nan";
    return a - ((integer)(a/p) * p);
}

///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2014 Wizardry and Steamworks - License: CC BY 2.0    //
//     Original: Clive Page, Leicester University, UK.   1995-MAY-2      //
///////////////////////////////////////////////////////////////////////////
list wasUnixTimeToDateTime(integer seconds) {
    integer mjday = (integer)(seconds/86400 + 40587);
    integer dateYear = 1858 + (integer)( (mjday + 321.51) / 365.25);
    float day = (integer)( wasFmod(mjday + 262.25, 365.25) ) + 0.5;
    integer dateMonth = 1 + (integer)(wasFmod(day / 30.6 + 2.0, 12.0) );
    integer dateDay = 1 + (integer)(wasFmod(day,30.6));
    float nsecs = wasFmod(seconds, 86400);
    integer dateSeconds = (integer)wasFmod(nsecs, 60);
    nsecs = nsecs / 60;
    integer dateMinutes = (integer)wasFmod(nsecs, 60);
    integer dateHour = (integer)(nsecs / 60);
    return [ dateYear, 
        dateMonth, dateDay, dateHour, dateMinutes, dateSeconds ];
}

// for changing states
string nextstate = "";

// notecard reading
integer line = 0;
list tuples = [];

// corrade data
key CORRADE = NULL_KEY;
string GROUP = "";
string PASSWORD = "";
// the owner of the rental system
// the dude or dudette that gets paid
key OWNER = NULL_KEY;
// the price of the rent
integer PRICE = 0;
// the time for the rent in seconds
integer RENT = 0;
string URL = "";
// the role to invite rentants to
string ROLE = "";

default {
    state_entry() {
        if(llGetInventoryType("configuration") != INVENTORY_NOTECARD) {
            llSetText("Sorry, could not find an inventory notecard.", <1, 0, 0>, 1.0);
            return;
        }
        llSetText("Reading configuration notecard...", <1, 1, 0>, 1.0);
        llGetNotecardLine("configuration", line);
    }
    dataserver(key id, string data) {
        if(data == EOF) {
            // invariant, length(tuples) % 2 == 0
            if(llGetListLength(tuples) % 2 != 0) {
                llSetText("Error in configuration notecard.", <1, 0, 0>, 1.0);
                return;
            }
            CORRADE = (key)llList2String(
                          tuples,
                          llListFindList(
                              tuples, 
                              [
                                  "corrade"
                              ]
                          )
                      +1);
            if(CORRADE == NULL_KEY) {
                llSetText("Error in configuration notecard: corrade", <1, 0, 0>, 1.0);
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
                llSetText("Error in configuration notecard: group", <1, 0, 0>, 1.0);
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
                llSetText("Error in configuration notecard: password", <1, 0, 0>, 1.0);
                return;
            }
            OWNER = (key)llList2String(
                          tuples,
                          llListFindList(
                              tuples, 
                              [
                                  "owner"
                              ]
                          )
                      +1);
            if(OWNER == NULL_KEY) {
                llSetText("Error in configuration notecard: owner", <1, 0, 0>, 1.0);
                return;
            }
            PRICE = (integer)llList2String(
                          tuples,
                          llListFindList(
                              tuples, 
                              [
                                  "price"
                              ]
                          )
                      +1);
            if(PRICE == 0) {
                llSetText("Error in configuration notecard: price", <1, 0, 0>, 1.0);
                return;
            }
            RENT = (integer)llList2String(
                          tuples,
                          llListFindList(
                              tuples, 
                              [
                                  "rent"
                              ]
                          )
                      +1);
            if(RENT == 0) {
                llSetText("Error in configuration notecard: rent", <1, 0, 0>, 1.0);
                return;
            }
            ROLE = llList2String(
                tuples,
                llListFindList(
                    tuples, 
                    [
                        "role"
                    ]
                )
                +1
            );
            if(ROLE == "") {
                llSetText("Error in configuration notecard: role", <1, 0, 0>, 1.0);
                return;
            }
            
            llSetText("Read configuration notecard.", <0, 1, 0>, 1.0);
            
            // if data is set switch to rented state
            if(llGetObjectDesc() != "") state rented;
            // otherwise switch to the payment state
            state payment;
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
        if(change & CHANGED_INVENTORY) {
            llResetScript();
        }
    }
}

state trampoline {
    state_entry() {
        llSetTimerEvent(5);
    }
    timer() {
        llSetTimerEvent(0);
        // State jump table
        if(nextstate == "url") state url;
        if(nextstate == "getmembers") state getmembers;
        if(nextstate == "getrolemembers") state getrolemembers;
        if(nextstate == "addtorole") state addtorole;
        if(nextstate == "invite") state invite;
        if(nextstate == "rented") state rented;
        if(nextstate == "demote") state demote;
        // automata in invalid state
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if(change & CHANGED_INVENTORY) {
            llResetScript();
        }
    }
}

state payment {
    state_entry() {
        llSetPayPrice(PRICE, [PRICE]);
        llSetClickAction(CLICK_ACTION_PAY);
        llSetText("☀ Touch me to rent this place! ☀", <0, 1, 0>, 1.0);
    }
    money(key id, integer amount) {
        // Get the current time stamp.
        list stamp = llList2List(
            llParseString2List(
                llGetTimestamp(),
                ["-",":","T", "."],[""]
            ),
            0, 5
        );
        // convert to seconds and add the rent
        integer delta = wasDateTimeToStamp(
            llList2Integer(stamp, 0),
            llList2Integer(stamp, 1),
            llList2Integer(stamp, 2),
            llList2Integer(stamp, 3),
            llList2Integer(stamp, 4),
            llList2Integer(stamp, 5)
        ) + 
        // the amount of time is the amount paid
        // times the rent time divided by the price
        amount * (integer)(
            (float)RENT / 
            (float)PRICE
        );
        // convert back to a timestamp
        stamp = wasUnixTimeToDateTime(delta);
        // and set the renter and the eviction date
        llSetObjectDesc(
            wasKeyValueEncode(
                [
                    "rentantUUID", id,
                    "rentantName", llKey2Name(id),
                    "expiresDate", llList2String(stamp, 0) +
                        "-" + llList2String(stamp, 1) + 
                        "-" + llList2String(stamp, 2) + 
                        "T" + llList2String(stamp, 3) +
                        ":" + llList2String(stamp, 4) +
                        ":" + llList2String(stamp, 5)
                ]
            )
        );
        nextstate = "getmembers";
        state url;
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if(change & CHANGED_INVENTORY) {
            llResetScript();
        }
    }
}

state url {
    state_entry() {
        // release any previous URL
        llReleaseURL(URL);
        // request a new URL
        llRequestURL();
    }
    http_request(key id, string method, string body) {
        if(method != URL_REQUEST_GRANTED) {
            llSetText("☀ Unable to get an URL! ☀", <1, 0, 0>, 1.0);
            nextstate = "url";
            state trampoline;
        }
        URL = body;
        // state URL jump table
        if(nextstate == "getmembers") state getmembers;
        if(nextstate == "demote") state demote;
        // automata in invalid state
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if(change & CHANGED_INVENTORY) {
            llResetScript();
        }
    }
}

state getmembers {
    state_entry() {
        llSetText("☀ Getting group members... ☀", <1, 1, 0>, 1.0);
        llInstantMessage(CORRADE,
            wasKeyValueEncode(
                [
                    "command", "getmembers",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    // we just care if the agent is in the group
                    // so we use Corrade's sifting ability in order
                    // to reduce the script memory usage
                    "sift", wasURLEscape(
                        "(" +
                            wasKeyValueGet(
                                "rentantUUID",
                                llGetObjectDesc()
                            ) +
                        ")*"
                    ),
                    "callback", wasURLEscape(URL)
                ]
            )
        );
        llSetTimerEvent(60);
    }
    http_request(key id, string method, string body) {
        if(wasKeyValueGet("success", body) != "True") {
            llSetText("☀ Could not get group members! ☀", <1, 0, 0>, 1.0);
            nextstate = "getmembers";
            state trampoline;
        }
        // check that the payer is part of the role
        integer i = 
            llListFindList(
                wasCSVToList(
                    wasURLUnescape(
                        wasKeyValueGet(
                            "data", 
                            body
                        )
                    )
                ), 
                (list)wasKeyValueGet(
                    "rentantUUID", 
                    llGetObjectDesc()
                )
            );
        llSetTimerEvent(0);
        // if they are in the group then check roles.
        if(i != -1) state getrolemembers;
        // otherwise invite them to the group role.
        state invite;
    }
    timer() {
        llSetTimerEvent(0);
        nextstate = "getmembers";
        state trampoline;
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if(change & CHANGED_INVENTORY) {
            llResetScript();
        }
    }    
}

state getrolemembers {
    state_entry() {
        llSetText("☀ Getting role members... ☀", <1, 1, 0>, 1.0);
        llInstantMessage(CORRADE,
            wasKeyValueEncode(
                [
                    "command", "getrolemembers",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "role", wasURLEscape(ROLE),
                    // we just care if the agent is in the renter role
                    // so we use Corrade's sifting ability in order
                    // to reduce the script memory usage
                    "sift", wasURLEscape(
                        "(" +
                            wasKeyValueGet(
                                "rentantUUID",
                                llGetObjectDesc()
                            ) +
                        ")*"
                    ),
                    "callback", wasURLEscape(URL)
                ]
            )
        );
        llSetTimerEvent(60);
    }
    http_request(key id, string method, string body) {
        if(wasKeyValueGet("success", body) != "True") {
            llSetText("☀ Could not get role members! ☀", <1, 0, 0>, 1.0);
            nextstate = "getrolemembers";
            state trampoline;
        }
        // check that the payer is part of the role
        integer i = 
            llListFindList(
                wasCSVToList(
                    wasURLUnescape(
                        wasKeyValueGet(
                            "data", 
                            body
                        )
                    )
                ), 
                (list)wasKeyValueGet(
                    "rentantUUID", 
                    llGetObjectDesc()
                )
            );
        llSetTimerEvent(0);
        // if they are in the role then skip inviting them.
        if(i != -1) state rented;
        // otherwise add them to the land role.
        state addtorole;
    }
    timer() {
        llSetTimerEvent(0);
        nextstate = "getrolemembers";
        state trampoline;
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if(change & CHANGED_INVENTORY) {
            llResetScript();
        }
    }
}

state addtorole {
    state_entry() {
        llSetText("☀ Adding to role... ☀", <1, 1, 0>, 1.0);
        llInstantMessage(CORRADE,
            wasKeyValueEncode(
                [
                    "command", "addtorole",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "agent", wasURLEscape(
                        wasKeyValueGet(
                            "rentantUUID",
                            llGetObjectDesc()
                        )
                    ),
                    "role", wasURLEscape(ROLE),
                    "callback", wasURLEscape(URL)
                ]
            )
        );
        llSetTimerEvent(60);
    }
    http_request(key id, string method, string body) {
        if(wasKeyValueGet("success", body) != "True") {
            llSetText("☀ Could not add to role! ☀", <1, 0, 0>, 1.0);
            nextstate = "addtorole";
            state trampoline;
        }
        // otherwise invite them to the group role.
        state rented;
    }
    timer() {
        llSetTimerEvent(0);
        nextstate = "addtorole";
        state trampoline;
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if(change & CHANGED_INVENTORY) {
            llResetScript();
        }
    }
}

state invite {
    state_entry() {
        llSetText("☀ Please accept the group invite! ☀", <1, 1, 0>, 1.0);
        // invite the agent to the land group
        llInstantMessage(CORRADE,
            wasKeyValueEncode(
                [
                    "command", "invite",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "agent", wasURLEscape(
                        wasKeyValueGet(
                            "rentantUUID", 
                            llGetObjectDesc()
                        )
                    ),
                    "role", wasURLEscape(ROLE),
                    "callback", wasURLEscape(URL)
                ]
            )
        );
        // handle any Corrade timeouts
        llSetTimerEvent(60);
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        // Checks if the invite was sent successfully or if that fails but the 
        // agent is already in the group (status 15345) then continue.
        // Otherwise, jump to the trampoline and send the invite again.
        // Status codes:
        // http://grimore.org/secondlife/scripted_agents/corrade/status_codes/progressive
        if(wasKeyValueGet("success", body) != "True" && 
            wasKeyValueGet("status", body) != "15345") {
            llSetText("☀ Group invite could not be sent! ☀", <1, 0, 0>, 1.0);
            nextstate = "invite";
            state trampoline;
        }
        llSetText("☀ Group invitation sent! ☀", <1, 1, 0>, 1.0);
        llSetTimerEvent(0);
        state rented;
    }
    timer() {
        llSetTimerEvent(0);
        nextstate = "invite";
        state trampoline;
    }
}

state rented {
    state_entry() {
        // Get the expiration date
        list expires = llList2List(
            llParseString2List(
                wasKeyValueGet(
                    "expiresDate", 
                    llGetObjectDesc()
                ),
                ["-",":","T", "."],[""]
            ),
            0, 5
        );
        // Get the current date
        list stamp = llList2List(
            llParseString2List(
                llGetTimestamp(),
                ["-",":","T", "."],[""]
            ),
            0, 5
        );
        
        integer delta = wasDateTimeToStamp(
            llList2Integer(expires, 0),
            llList2Integer(expires, 1),
            llList2Integer(expires, 2),
            llList2Integer(expires, 3),
            llList2Integer(expires, 4),
            llList2Integer(expires, 5)
        ) - wasDateTimeToStamp(
            llList2Integer(stamp, 0),
            llList2Integer(stamp, 1),
            llList2Integer(stamp, 2),
            llList2Integer(stamp, 3),
            llList2Integer(stamp, 4),
            llList2Integer(stamp, 5)
        );
        
        // the rent has expired, now evict the rentant
        if(delta <= 0) {
            llSetTimerEvent(0);
            nextstate = "demote";
            state url;
        }
        
        // otherwise, update the remaining time
        list remaining = wasUnixTimeToDateTime(delta);
        remaining = llListReplaceList(remaining, [ llList2Integer(remaining, 0)-1970 ], 0, 0);
        remaining = llListReplaceList(remaining, [ llList2Integer(remaining, 1)-1 ], 1, 1);
        remaining = llListReplaceList(remaining, [ llList2Integer(remaining, 2)-1 ], 2, 2);
        
        llSetText(
            "☀ Private property! ☀" 
            + "\n" +
            "Rented by: " + 
                wasKeyValueGet(
                    "rentantName", 
                    llGetObjectDesc()
                ) 
            + "\n" + 
            "Expires on: " + 
                wasKeyValueGet(
                    "expiresDate", 
                    llGetObjectDesc()
                ) 
            + "\n" + 
            "Remaining: " + 
                llList2String(remaining, 0) + "-" + 
                llList2String(remaining, 1) + "-" +
                llList2String(remaining, 2) + " " +
                llList2String(remaining, 3) + ":" + 
                llList2String(remaining, 4)
            + "\n" +
            "Touch to extend rent.", 
            <0, 1, 1>, 
            1.0
        );
        llSetPayPrice(PRICE, [PRICE]);
        llSetClickAction(CLICK_ACTION_PAY);
        // set the countdown every minute
        llSetTimerEvent(60);
    }
    money(key id, integer amount) {
        // Get the expiration date
        list stamp = llList2List(
            llParseString2List(
                wasKeyValueGet(
                    "expiresDate", 
                    llGetObjectDesc()
                ),
                ["-",":","T", "."],[""]
            ),
            0, 5
        );
        // convert to seconds and add the extended rent
        integer delta = wasDateTimeToStamp(
            llList2Integer(stamp, 0),
            llList2Integer(stamp, 1),
            llList2Integer(stamp, 2),
            llList2Integer(stamp, 3),
            llList2Integer(stamp, 4),
            llList2Integer(stamp, 5)
        ) + 
        // the amount of time to extend is the amount 
        // paid times the rent time divided by the price
        amount * (integer)(
            (float)RENT / 
            (float)PRICE
        );
        // convert back to a timestamp
        stamp = wasUnixTimeToDateTime(delta);
        // and set the renter and the eviction date
        llSetObjectDesc(
            wasKeyValueEncode(
                [
                    "rentantUUID", wasKeyValueGet(
                        "rentantUUID", 
                        llGetObjectDesc()
                    ),
                    "rentantName", wasKeyValueGet(
                        "rentantName", 
                        llGetObjectDesc()
                    ),
                    "expiresDate", llList2String(stamp, 0) +
                        "-" + llList2String(stamp, 1) + 
                        "-" + llList2String(stamp, 2) + 
                        "T" + llList2String(stamp, 3) +
                        ":" + llList2String(stamp, 4) +
                        ":" + llList2String(stamp, 5)
                ]
            )
        );
        llSetText("☀ Updating... ☀", <1, 1, 0>, 1.0);
        llSetTimerEvent(0);
        nextstate = "rented";
        state trampoline;
    }
    timer() {
        // Get the expiration date
        list expires = llList2List(
            llParseString2List(
                wasKeyValueGet(
                    "expiresDate", 
                    llGetObjectDesc()
                ),
                ["-",":","T", "."],[""]
            ),
            0, 5
        );
        // Get the current date
        list stamp = llList2List(
            llParseString2List(
                llGetTimestamp(),
                ["-",":","T", "."],[""]
            ),
            0, 5
        );
        
        integer delta = wasDateTimeToStamp(
            llList2Integer(expires, 0),
            llList2Integer(expires, 1),
            llList2Integer(expires, 2),
            llList2Integer(expires, 3),
            llList2Integer(expires, 4),
            llList2Integer(expires, 5)
        ) - wasDateTimeToStamp(
            llList2Integer(stamp, 0),
            llList2Integer(stamp, 1),
            llList2Integer(stamp, 2),
            llList2Integer(stamp, 3),
            llList2Integer(stamp, 4),
            llList2Integer(stamp, 5)
        );
        
        // the rent has expired, now evict the rentant
        if(delta <= 0) {
            llSetTimerEvent(0);
            nextstate = "demote";
            state url;
        }
        
        // otherwise, update the remaining time
        list remaining = wasUnixTimeToDateTime(delta);
        remaining = llListReplaceList(remaining, [ llList2Integer(remaining, 0)-1970 ], 0, 0);
        remaining = llListReplaceList(remaining, [ llList2Integer(remaining, 1)-1 ], 1, 1);
        remaining = llListReplaceList(remaining, [ llList2Integer(remaining, 2)-1 ], 2, 2);
        
        llSetText(
            "☀ Private property! ☀" 
            + "\n" +
            "Rented by: " + 
                wasKeyValueGet(
                    "rentantName", 
                    llGetObjectDesc()
                ) 
            + "\n" + 
            "Expires on: " + 
                wasKeyValueGet(
                    "expiresDate", 
                    llGetObjectDesc()
                ) 
            + "\n" + 
            "Remaining: " + 
                llList2String(remaining, 0) + "-" + 
                llList2String(remaining, 1) + "-" +
                llList2String(remaining, 2) + " " +
                llList2String(remaining, 3) + ":" + 
                llList2String(remaining, 4)
            + "\n" +
            "Touch to extend rent.", 
            <0, 1, 1>, 
            1.0
        );
        
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if(change & CHANGED_INVENTORY) {
            llResetScript();
        }
    }
}

state demote {
    state_entry() {
        llSetText("☀ Rent has expired! ☀", <1, 0, 0>, 1.0);
        // demote the agent from the renter role
        llInstantMessage(CORRADE,
            wasKeyValueEncode(
                [
                    "command", "deletefromrole",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "agent", wasURLEscape(
                        wasKeyValueGet(
                            "rentantUUID", 
                            llGetObjectDesc()
                        )
                    ),
                    "role", wasURLEscape(ROLE),
                    "callback", wasURLEscape(URL)
                ]
            )
        );
        // handle any Corrade timeouts
        llSetTimerEvent(60);
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        // Checks if the demote was sent successfully or if that fails but the 
        // agent has already left the group (status 11502) then continue.
        // Otherwise, jump to the trampoline and send the demote again.
        // Status codes:
        // http://grimore.org/secondlife/scripted_agents/corrade/status_codes/progressive
        if(wasKeyValueGet("success", body) != "True" && 
            wasKeyValueGet("status", body) != "11502") {
            llSetText("☀ Could not demote! ☀", <1, 0, 0>, 1.0);
            nextstate = "demote";
            state trampoline;
        }
        llSetText("☀ Renter demoted! ☀", <1, 1, 0>, 1.0);
        llSetTimerEvent(0);
        
        // Now clean up the rental and restart.
        llSetObjectDesc("");
        llResetScript();
    }
    timer() {
        llSetTimerEvent(0);
        nextstate = "demote";
        state trampoline;
    }
}

