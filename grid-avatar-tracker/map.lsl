///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2013 - License: GNU GPLv3      //
///////////////////////////////////////////////////////////////////////////
 
///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2013 Wizardry and Steamworks - License: GNU GPLv3    //
///////////////////////////////////////////////////////////////////////////
string wasKeyValueEncode(list kvp) {
    if(llGetListLength(kvp) < 2) return "";
    string k = llList2String(kvp, 0);
    kvp = llDeleteSubList(kvp, 0, 0);
    string v = llList2String(kvp, 0);
    kvp = llDeleteSubList(kvp, 0, 0);
    if(llGetListLength(kvp) < 2) return k + "=" + v;
    return k + "=" + v + "&" + wasKeyValueEncode(kvp);
}
 
///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2015 Wizardry and Steamworks - License: GNU GPLv3    //
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
//    Copyright (C) 2015 Wizardry and Steamworks - License: GNU GPLv3    //
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
//    Copyright (C) 2013 Wizardry and Steamworks - License: GNU GPLv3    //
///////////////////////////////////////////////////////////////////////////
integer wasMenuIndex = 0;
list wasDialogMenu(list input, list actions, string direction) {
    integer cut = 11-wasListCountExclude(actions, [""]);
    if(direction == ">" &&  (wasMenuIndex+1)*cut+wasMenuIndex+1 < llGetListLength(input)) {
        ++wasMenuIndex;
        jump slice;
    }
    if(direction == "<" && wasMenuIndex-1 >= 0) {
        --wasMenuIndex;
        jump slice;
    }
@slice;
    integer multiple = wasMenuIndex*cut;
    input = llList2List(input, multiple+wasMenuIndex, multiple+cut+wasMenuIndex);
    input = wasListMerge(input, actions, "");
    return input;
}
 
///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2013 Wizardry and Steamworks - License: GNU GPLv3    //
///////////////////////////////////////////////////////////////////////////
integer wasListCountExclude(list input, list exclude) {
    if(llGetListLength(input) == 0) return 0;
    if(llListFindList(exclude, (list)llList2String(input, 0)) == -1) 
        return 1 + wasListCountExclude(llDeleteSubList(input, 0, 0), exclude);
    return wasListCountExclude(llDeleteSubList(input, 0, 0), exclude);
}
 
///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2013 Wizardry and Steamworks - License: GNU GPLv3    //
///////////////////////////////////////////////////////////////////////////
list wasListMerge(list l, list m, string merge) {
    if(llGetListLength(l) == 0 && llGetListLength(m) == 0) return [];
    string a = llList2String(m, 0);
    if(a != merge) return [ a ] + wasListMerge(l, llDeleteSubList(m, 0, 0), merge);
    return [ llList2String(l, 0) ] + wasListMerge(llDeleteSubList(l, 0, 0), llDeleteSubList(m, 0, 0), merge);
}

///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2019 Wizardry and Steamworks - License: GNU GPLv3    //
///////////////////////////////////////////////////////////////////////////
float wasMapValueToRange(float value, float xMin, float xMax, float yMin, float yMax) {
    return yMin + (
        (
            yMax - yMin
        )
        *
        (
            value - xMin
        )
        /
        (
            xMax - xMin
        )
    );
}

// Move the dot over the local positon of the avatar on the map.
updateDot(string message) {
    if(active == "")
        return;

    integer idx = llListFindList(avatars, [ message ]);
    if(idx == -1) {
        // DEBUG
        llOwnerSay("Avatar not found in tracked list...");
        return;
    }

    // Stride 4: Avatar name x region name x local position x map UUID
    list update = llList2List(avatars, idx, idx + 3);

    string region = llList2String(update, 1);
    vector position = (vector)llList2String(update, 2);
    key mapUUID = llList2Key(update, 3);

    // DEBUG
    //llOwnerSay("Updating map display...");

    // Set the map textue.
    llSetTexture((string)mapUUID, 0);

    // Compute the offset to move the dot and send it to the link set.
    vector scale = llGetScale();

    // DEBUG
    //llOwnerSay("position:" + (string)position + " x: " + (string)x + " y:" + (string)y);

    llMessageLinked(
        LINK_SET,
        0,
        wasListToCSV(
            [
                "avatar",
                message,
                "region",
                region,
                "position",
                (string)position,
                "scale",
                (string)scale
            ]
        ),
        NULL_KEY
    );
}

// corrade data
string CORRADE = "";
string GROUP = "";
string PASSWORD = "";


// for holding the callback URL
string callback = "";

// menu for selecting avatars
list menu = [];

// Stride 4: Avatar name x region name x local position x map UUID
list avatars = [];

// the active avatar
string active = "";
 
// key-value data will be read into this list
list tuples = [];

// for notecard reading
integer line = 0;
 
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
                llOwnerSay("Error in configuration notecard: password");
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
            if(GROUP == "") {
                llOwnerSay("Error in configuration notecard: group");
                return;
            }
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
        // DEBUG
        llOwnerSay("Requesting URL...");
        llRequestURL();
    }
    http_request(key id, string method, string body) {
        if(method != URL_REQUEST_GRANTED) return;
        callback = body;
        // DEBUG
        llOwnerSay("Got URL...");
        state bind_tracker;
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
 
state bind_tracker {
    state_entry() {
        // DEBUG
        llOwnerSay("Binding to tracker notification...");
        
        llInstantMessage(CORRADE, 
            wasKeyValueEncode(
                [
                    "command", "notify",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "action", "set",
                    "type", "tracker",
                    "URL", wasURLEscape(callback),
                    "callback", wasURLEscape(callback)
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
            llOwnerSay("Unable to bind to tracker notification: " + 
                wasURLUnescape(
                    wasKeyValueGet("error", body)
                )
            );

            llResetScript();
        }
        
        // DEBUG
        llOwnerSay("Tracking notification bound...");
        
        state tracker;
    }
    timer() {
        // DEBUG
        llOwnerSay("Timeout binding to tracker notification...");
        
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

state tracker {
    state_entry() {
        // DEBUG
        llOwnerSay("Tracking...");
    }
    touch_start(integer num_detected) {
        if(llGetListLength(avatars) == 0) {
            llSay(0, "No avatars have been registered yet.");
            return;
        }
            
        menu = llList2ListStrided(avatars, 0, -1, 4);

        // DEBUG
        llOwnerSay("Sending menu with tracked avatars: " + llDumpList2String(menu, ","));
        
        integer comChannel = ((integer)("0x"+llGetSubString((string)llDetectedKey(0),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF;
        llListen(comChannel, "", llDetectedKey(0), "");
        llDialog(llDetectedKey(0), "Please select an avatar from the list of avatars to display on the map.", wasDialogMenu(menu, ["⟵ Back", "", "Next ⟶"], ""), comChannel);
    }
    listen(integer channel, string name, key id, string message) {
        if(message == "⟵ Back") {
            llDialog(id, "Please select an avatar from the list of avatars to display on the map.", wasDialogMenu(menu, ["⟵ Back", "", "Next ⟶"], "<"), channel);
            return;
        }
        if(message == "Next ⟶") {
            llDialog(id, "Please select an avatar from the list of avatars to display on the map.", wasDialogMenu(menu, ["⟵ Back", "", "Next ⟶"], ">"), channel);
            return;
        }
        
        // DEBUG
        llOwnerSay("Chosen avatar: " + message);

        // Set the active avatar.
        active = message;

        llSetTimerEvent(1);
    }
    timer() {
        // Update the avatar on the map.
        updateDot(active);
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        
        // Process tracker notification by retrieving the map for the region.
        if(wasKeyValueGet("type", body) == "tracker") {
            // DEBUG
            llOwnerSay("Tracker: " + wasURLUnescape(body));
            
            string firstname = wasKeyValueGet("firstname", body);
            string lastname = wasKeyValueGet("lastname", body);
            string region = wasKeyValueGet("region", body);

            // DEBUG
            llOwnerSay("Requesting region map UUID...");
            
            // Send the request to retrieve the map UUID.
            llInstantMessage(CORRADE,
                wasKeyValueEncode(
                    [
                        "command", "getgridregiondata",
                        "group", wasURLEscape(GROUP),
                        "password", wasURLEscape(PASSWORD),
                        "region", region,
                        "data", wasListToCSV(
                            [
                                "MapImageID"
                            ]
                        ),
                        // pass the region name and avatar 
                        // name through afterburn
                        "_avatar", (firstname + " " + lastname),
                        "_region", region,
                        "_position", wasKeyValueGet("position", body),
                        // sent to URL
                        "callback", wasURLEscape(callback)
                    ]
                )
            );

            return;
        }

        // Store the map
        if(wasKeyValueGet("command", body) == "getgridregiondata" &&
            wasKeyValueGet("success", body) == "True") {

            // Retrive returned data and extract the map UUID.
            list data = wasCSVToList(
                wasURLUnescape(
                    wasKeyValueGet("data", body)
                )
            );
            
            key mapUUID = llList2Key(
                data,
                llListFindList(
                    data, 
                    [ 
                        "MapImageID" 
                    ]
                ) + 1
            );
            
            if(mapUUID == NULL_KEY) {
                // DEBUG
                llOwnerSay("Failed to retrive remote region map UUID...");
                return;
            }

            // Stride 4: Avatar name x region name x local position x map UUID
            string avatar = wasURLUnescape(
                wasKeyValueGet("_avatar", body)
            );
            string region = wasURLUnescape(
                wasKeyValueGet("_region", body)
            );
            string position = wasURLUnescape(
                wasKeyValueGet("_position", body)
            );

            // DEBUG
            llOwnerSay("Remote region map ID for region: " + region + " is: " + (string)mapUUID);
            
            integer idx = llListFindList(avatars, [ avatar ]);

            // If the avatar is not registered then add the avatar to the list.
            if(idx == -1) {
                // DEBUG
                llOwnerSay("Adding new avatar to tracking list: " + avatar);

                llSetTimerEvent(0);

                avatars += avatar;
                avatars += region;
                avatars += position;
                avatars += (string)mapUUID;

                llSetTimerEvent(1);

                return;
            }
            
            // Extract the avatar from the list and update the details.
            llSetTimerEvent(0);

            list update = llList2List(avatars, idx, idx + 3);
            avatars = llDeleteSubList(avatars, idx, idx + 3);
            
            update = llListReplaceList(update, [region], 1, 1);
            update = llListReplaceList(update, [position], 2, 2);
            update = llListReplaceList(update, [mapUUID], 3, 3);

            avatars += update;

            llSetTimerEvent(1);

            // DEBUG
            llOwnerSay("Update list is: " + llDumpList2String(update, ","));
            llOwnerSay("Full list is: " + llDumpList2String(avatars, ","));

            return;
        }
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
