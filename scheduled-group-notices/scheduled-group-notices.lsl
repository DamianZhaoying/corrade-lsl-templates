///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2014 - License: CC BY 2.0      //
//  Please see: https://creativecommons.org/licenses/by/2.0 for legal details,  //
//  rights of fair usage, the disclaimer and warranty conditions.        //
///////////////////////////////////////////////////////////////////////////
 
///////////////////////////////////////////////////////////////////////////
//                            CONFIGURATION                              //
///////////////////////////////////////////////////////////////////////////
// The UUID / Key of the scripted agent.
string CORRADE = "63c44c23-9f46-4f0d-b00a-5b0e3180a015";
// The name of the group to invite to.
string GROUP = "My Group";
// The password for that group in Corrade.ini.
string PASSWORD = "mypassword";

///////////////////////////////////////////////////////////////////////////
//                          END CONFIGURATION                            //
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
//    Copyright (C) 2014 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
string wasKeyValueSet(string k, string v, string data) {
    if(llStringLength(k) == 0) return "";
    if(llStringLength(v) == 0) return "";
    if(llStringLength(data) == 0) return k + "=" + v;
    integer i = llListFindList(
        llList2ListStrided(
            llParseString2List(data, ["&", "="], []), 
            0, -1, 2
        ), 
    [ k ]);
    if(i != -1) return llDumpList2String(
        llListReplaceList(
            llParseString2List(data, ["&"], []), 
            [ k + "=" + v ], 
        i, i), 
    "&");
    return data + "&" + k + "=" + v;
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

// Store the URL for the callback.
string callback = "";

default {
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
        state sleep;
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if(change & CHANGED_REGION_START) {
            llResetScript();
        }
    }
}

state sleep {
    state_entry() {
        // DEBUG
        llOwnerSay("Waiting for linked-message...");
    }
    link_message(integer sender, integer num, string message, key id) {
        list data = llCSV2List(message);
        // Build a partial key-value pair string with the data we know.
        string kvp = wasKeyValueEncode(
            [
                "command", "notice",
                "group", wasURLEscape(GROUP),
                "password", wasURLEscape(PASSWORD),
                "callback", wasURLEscape(callback)
            ]
        );
        // Add the subject if there is one.
        string subject = llList2String(data, 0);
        if(subject != "") kvp = wasKeyValueSet("subject", wasURLEscape(subject), kvp);
        // Add the message if there is one.
        message = llList2String(data, 1);
        if(message != "") kvp = wasKeyValueSet("message", wasURLEscape(message), kvp);
        // Add the attachment if there is one.
        string item = llList2String(data, 2);
        if(item != "") kvp = wasKeyValueSet("item", wasURLEscape(item), kvp);
        // Send off the notice to Corrade.
        llInstantMessage(CORRADE, kvp);
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        // If sending the notice succeeded, do not complain...
        if(wasKeyValueGet("command", body) == "notice" &&
            wasKeyValueGet("success", body) == "True") return;
        // Announce the owner that sending the notice failed
        llInstantMessage(llGetOwner(), "Failed to send the notice: " + wasURLUnescape(wasKeyValueGet("error", body)));
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if(change & CHANGED_REGION_START) {
            llResetScript();
        }
    }
}
