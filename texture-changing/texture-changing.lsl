///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2014 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
//
// This is a script that uses Corrade to change the texture on the 
// available faces of the primitie. It requires that you have a Corrade bot
// with the following permissions enabled for the group specified in the 
// configuration notecard inside this primitive:
//
// config -> groups -> group [your group] -> permissions -> interact
// config -> groups -> group [your group] -> permissions -> friendship
//
// Additionally, you should be a friend of your bot and have granted modify
// permissions to the bot by using the viewer interface:
//
// Contact -> Friends -> [ Bot ] -> Friend can edit, delete, take objects.
//
// The sit script works together with a "configuration" notecard that must 
// be placed in the same primitive as this script. The purpose of this 
// script is to demonstrate changing textures with Corrade and you are free 
// to use, change, and commercialize it under the CC BY 2.0  license at: 
// https://creativecommons.org/licenses/by/2.0
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
//    Copyright (C) 2011 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
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

// for holding the callback URL
string callback = "";

// for holding the selected face number
string FACE = "";
// for holding the selected texture
string TEXTURE = "";
// for holding the current user
key TOUCH = NULL_KEY;

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
        llSensorRepeat("", (key)CORRADE, AGENT, 10, TWO_PI, 1);
    }
    no_sensor() {
        // DEBUG
        llOwnerSay("Teleporting Corrade...");
        llInstantMessage((key)CORRADE, 
            wasKeyValueEncode(
                [
                    "command", "teleport",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "entity", "region",
                    "region", wasURLEscape(llGetRegionName()),
                    "position", wasURLEscape(
                        (string)(
                            llGetPos() + wasCirclePoint(1)
                        )
                    ),
                    "callback", callback
                ]
            )
        );
    }
    sensor(integer num) {
        llSetTimerEvent(0);
        state check_rights;
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "teleport" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Teleport failed: " + 
                wasURLUnescape(
                    wasKeyValueGet(
                        "error", 
                        body
                    )
                )
            );
            state detect_trampoline;
        }
        llSetTimerEvent(0);
        state check_rights;
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

/* 
 * Trampoline used for delaying teleport requests sent to Corrade. Once code
 * switches into this state, the script waits for some seconds and then 
 * switches to the detect state.
 */
state detect_trampoline {
    state_entry() {
        // DEBUG
        llOwnerSay("Sleeping...");
        llSetTimerEvent(30);
    }
    timer() {
        llSetTimerEvent(0);
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

/*
 * This state checks to see whether Corrade has the necessary rights to 
 * modify your objects. It checks by using the "getfrienddata" command 
 * which requires "friendship" Corrade permissions and then tests whether
 * the "CanModifyTheirObjects" flag is set that indicates whether Corrade
 * is able to alter your objects. In the end it proceeds to the main state.
 */
state check_rights {
    state_entry() {
        // DEBUG
        llOwnerSay("Checking whether Corrade has rights to modify your objects...");
        llInstantMessage(
            (key)CORRADE, 
            wasKeyValueEncode(
                [
                    "command", "getfrienddata",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "agent", wasURLEscape(llGetOwner()),
                    "data", "CanModifyTheirObjects",
                    "callback", wasURLEscape(callback)
                ]
            )
        );
        llSetTimerEvent(60);
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "getfrienddata" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Failed to get friend rights: " + 
                wasURLUnescape(
                    wasKeyValueGet(
                        "error", 
                        body
                    )
                )
            );
            state detect_trampoline;
        }
        // DEBUG
        llOwnerSay("Got friend rights, checking...");
        list data = wasCSVToList(wasURLUnescape(wasKeyValueGet("data", body)));
        integer i = llListFindList(data, [ "CanModifyTheirObjects" ]);
        if(i == -1) {
            // DEBUG
            llOwnerSay("Friend data not returned by the \"getfrienddata\" command...");
            state detect_trampoline;
        }
        if(llList2String(data, i+1) != "True") {
            // DEBUG
            llOwnerSay("Corrade cannot modify your objects, please grant Corrade permissions to modify your objects using your viewer...");
            state detect_trampoline;
        }
        // DEBUG
        llOwnerSay("Corrade has permissions to modify your objects, proceeding...");
        llSetTimerEvent(0);
        state select_face;
    }
    timer() {
        llSetTimerEvent(0);
        // DEBUG
        llOwnerSay("Timeout checking for friend rights...");
        state detect_trampoline;
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

/*
 * In this state we retrieve a face number from the user.
 */
state select_face {
    state_entry() {
        if(TOUCH == NULL_KEY) {
            //DEBUG
            llOwnerSay("Please touch the primitive for a menu...");
            return;
        }
        integer comChannel = (integer)("0x8" + llGetSubString(llGetKey(), 0, 6));
        integer i = llGetNumberOfSides() - 1;
        list buttons = [];
        do {
            buttons += (string)i;
            llListen(comChannel, "", "", (string)i);
        } while(--i > -1);
        buttons += "default";
        llListen(comChannel, "", "", "default");
        buttons += "all";
        llListen(comChannel, "", "", "all");
        llDialog(TOUCH, "Please select a face to change...", buttons, comChannel);
    }
    touch_start(integer num) {
        TOUCH = llDetectedKey(0);
        integer comChannel = (integer)("0x8" + llGetSubString(llGetKey(), 0, 6));
        integer i = llGetNumberOfSides() - 1;
        list buttons = [];
        do {
            buttons += (string)i;
            llListen(comChannel, "", "", (string)i);
        } while(--i > -1);
        buttons += "default";
        llListen(comChannel, "", "", "default");
        buttons += "all";
        llListen(comChannel, "", "", "all");
        llDialog(TOUCH, "Please select a face to change...", buttons, comChannel);
    }
    listen(integer channel, string name, key id, string face) {
        llOwnerSay("Got face: " + face);
        FACE = face;
        state select_texture;
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
/*
 * In this state we let the user select a texture from inventory.
 */
state select_texture {
    state_entry() {
        if(TOUCH == NULL_KEY) return;
        integer comChannel = (integer)("0x8" + llGetSubString(llGetKey(), 0, 6));
        integer i = llGetInventoryNumber(INVENTORY_TEXTURE) -1;
        list buttons = [];
        do {
            string inventoryTexture = llGetInventoryName(INVENTORY_TEXTURE, i);
            buttons += inventoryTexture;
            llListen(comChannel, "", "", inventoryTexture);
        } while(--i > -1);
        llDialog(TOUCH, "Please select from the avilable textures...", buttons, comChannel);
    }
    touch_start(integer num) {
        TOUCH = llDetectedKey(0);
        integer comChannel = (integer)("0x8" + llGetSubString(llGetKey(), 0, 6));
        integer i = llGetInventoryNumber(INVENTORY_TEXTURE) -1;
        list buttons = [];
        do {
            string inventoryTexture = llGetInventoryName(INVENTORY_TEXTURE, i);
            buttons += inventoryTexture;
            llListen(comChannel, "", "", inventoryTexture);
        } while(--i > -1);
        llDialog(TOUCH, "Please select from the avilable textures...", buttons, comChannel);
    }
    listen(integer channel, string name, key id, string inventoryTexture) {
        llOwnerSay("Got texture: " + inventoryTexture);
        TEXTURE = inventoryTexture;
        state change_texture;
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

/*
 * This state is reponsible for setting the texture on the previously 
 * selected face of this primitive. It makes a call to Corrade to set the
 * texture on the selected face and then returns to the face selection.
 * This state relies on the "interact" Corrade permission being set
 * for the group that you are using this script with.
 */
state change_texture {
    state_entry() {
        // DEBUG
        llOwnerSay("Setting texture \"" + TEXTURE + "\" on face \"" + FACE + "\".");
        llInstantMessage(CORRADE, wasKeyValueEncode(
                [
                    // set the texture for the 4th face
                    // on a primitive in a 4m range
                    // specified by UUID
                    "command", "setprimitivetexturedata",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    // the UUID of the primitive
                    "item", wasURLEscape(llGetKey()),
                    "range", 5,
                    // the face
                    "face", FACE,
                    // just set the texture to a texture UUID
                    "data", wasURLEscape(
                        wasListToCSV(
                            [
                                "TextureID", llGetInventoryKey(TEXTURE)
                            ]
                        )
                    ),
                    "callback", wasURLEscape(callback)
                ]
            )
        );
        llSetTimerEvent(60);
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "setprimitivetexturedata" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Failed to set texture: " + 
                wasURLUnescape(
                    wasKeyValueGet(
                        "error", 
                        body
                    )
                )
            );
            state detect_trampoline;
        }
        // DEBUG
        llOwnerSay("Texture set successfully...");
        state select_face;
    }
    timer() {
        llSetTimerEvent(0);
        // DEBUG
        llOwnerSay("Timeout setting texture...");
        state detect_trampoline;
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

