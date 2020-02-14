///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2014 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
//
// This is an automatic grid follower for the Corrade Second Life / OpenSim 
// bot. It uses two different engines: the simulator's built-in autopilot
// and a fly engine that will make Corrade fly to your location.
// You can find more details about the bot by following the URL: 
// http://grimore.org/secondlife/scripted_agents/corrade
//
// The follower script works together with a "configuration" notecard and 
// that must be placed in the same primitive as this script. 
// You are free to use, change, and commercialize it under the CC BY 2.0 
// license at: https://creativecommons.org/licenses/by/2.0
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
vector wasCirclePoint(float radius) {
    float x = llPow(-1, 1 + (integer) llFrand(2)) * llFrand(radius*2);
    float y = llPow(-1, 1 + (integer) llFrand(2)) * llFrand(radius*2);
    if(llPow(x,2) + llPow(y,2) <= llPow(radius,2))
        return <x, y, 0>;
    return wasCirclePoint(radius);
}

///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2014 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
integer wasIsAvatarInSensorRange(key avatar) {
    return llListFindList(
        llGetAgentList(
            AGENT_LIST_REGION, 
            []
        ), 
        (list)((key)avatar)
    ) != -1 && 
        llVecDist(
            llGetPos(), 
            llList2Vector(
                llGetObjectDetails(
                    avatar, 
                    [OBJECT_POS]
                ), 
            0
        )
    ) <= 96;
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

// for holding the callback URL
string callback = "";

// key-value data will be read into this list
string configuration = "";
 
default {
    state_entry() {
        llSetTimerEvent(1);
    }
    link_message(integer sender, integer num, string message, key id) {
        if(sender != 1 || id != "configuration") return;
        configuration = message;
        state off;
    }
    timer() {
        llMessageLinked(LINK_ROOT, 0, "configuration", NULL_KEY);
    }
    attach(key id) {
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if(change & CHANGED_INVENTORY || (change & CHANGED_OWNER))
            llResetScript();
        if(
            (change & CHANGED_REGION_START) || 
            (change & CHANGED_REGION)) {
            state on;
        }
    }
    state_exit() {
        llSetTimerEvent(0);
    }
}

state off {
    state_entry() {
        llSetColor(<.5,0,0>, ALL_SIDES);
    }
    touch_end(integer num) {
        state on;
    }
    attach(key id) {
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if(change & CHANGED_INVENTORY || (change & CHANGED_OWNER))
            llResetScript();
    }
}

state on {
    state_entry() {
        llSetColor(<0,.5,0>, ALL_SIDES);
        state url;
    }
    attach(key id) {
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if(change & CHANGED_INVENTORY || (change & CHANGED_OWNER))
            llResetScript();
    }
}
 
state url {
    state_entry() {
        // DEBUG
        llOwnerSay("Requesting URL...");
        llRequestURL();
    }
    touch_end(integer num) {
        llSetColor(<.5,0,0>, ALL_SIDES);
        llResetScript();
    }
    http_request(key id, string method, string body) {
        if(method != URL_REQUEST_GRANTED) return;
        callback = body;
        // DEBUG
        llOwnerSay("Got URL...");
        state detect;
    }
    attach(key id) {
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if(change & CHANGED_INVENTORY || (change & CHANGED_OWNER))
            llResetScript();
        if(
            (change & CHANGED_REGION_START) || 
            (change & CHANGED_REGION)) {
            state on;
        }
    }
}
 
state detect {
    state_entry() {
        // set color for button
        llSetColor(<0,.5,0>, ALL_SIDES);
        // if Corrade is in-range then just follow
        if(wasIsAvatarInSensorRange(
                (key)wasKeyValueGet(
                    "corrade", 
                    configuration
                )
            )
        ) state select;
        // DEBUG
        llOwnerSay("Detecting if Corrade is online...");
        llRequestAgentData(
            (key)wasKeyValueGet(
                "corrade", 
                configuration
            ),
            DATA_ONLINE
        );
    }
    touch_end(integer num) {
        llSetColor(<.5,0,0>, ALL_SIDES);
        llResetScript();
    }
    dataserver(key id, string data) {
        if(data != "1") {
            // DEBUG
            llOwnerSay("Corrade is not online, sleeping...");
            llResetScript();
            return;
        }
        llSensorRepeat("", 
            (key)wasKeyValueGet(
                "corrade", 
                configuration
            ),
            AGENT,
            (integer)wasURLEscape(
                wasKeyValueGet(
                    "range", 
                    configuration
                )
            ),
            TWO_PI,
            5
        );
    }
    no_sensor() {
        // DEBUG
        llOwnerSay("Teleporting Corrade...");
        llInstantMessage(
            (key)wasKeyValueGet(
                "corrade", 
                configuration
            ), 
            wasKeyValueEncode(
                [
                    "command", "teleport",
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
                    "entity", "region",
                    "region", wasURLEscape(llGetRegionName()),
                    "position", llGetPos() + wasCirclePoint(
                        (integer)wasURLEscape(
                            wasKeyValueGet(
                                "range", 
                                configuration
                            )
                        )
                    ),
                    "deanimate", "True",
                    "callback", callback
                ]
            )
        );
    }
    sensor(integer num) {
        state select;
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "teleport" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Teleport failed...");
            return;
        }
        state select;
    }
    attach(key id) {
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if(change & CHANGED_INVENTORY || (change & CHANGED_OWNER))
            llResetScript();
        if(
            (change & CHANGED_REGION_START) || 
            (change & CHANGED_REGION)) {
            state on;
        }
    }
}

state select {
    state_entry() {
        // DEBUG
        llOwnerSay("Selecting follow engine...");
        llSetTimerEvent(1);
    }
    touch_end(integer num) {
        llSetColor(<.5,0,0>, ALL_SIDES);
        llResetScript();
    }
    timer() {
        vector cPos = llList2Vector(
            llGetObjectDetails(
                (key)wasKeyValueGet(
                    "corrade", 
                    configuration
                ),
                [OBJECT_POS]
            ),
            0
        );
        vector mPos = llGetPos();
        // If Corrade is in range then stop.
        if(llVecDist(mPos, cPos) < 5) return;
        // If we are flying or the distance between us and Corrade
        // is larger than a given distance then make Corrade fly. 
        if(
            (
                llGetAgentInfo(llGetOwner()) & AGENT_FLYING
            ) || 
            llFabs(mPos.z - cPos.z) > 5) {
            state stop_pilot;
        }
        // Otherwise, stop flight and walk.
        if(llGetAgentInfo(
            (key)wasKeyValueGet(
                "corrade", 
                configuration
            )
        ) & AGENT_FLYING) state stop_flight;
        // If Corrade is not flying then walk.
        state walk;
    }
    attach(key id) {
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if(change & CHANGED_INVENTORY || (change & CHANGED_OWNER))
            llResetScript();
        if(
            (change & CHANGED_REGION_START) || 
            (change & CHANGED_REGION)) {
            state on;
        }
    }
    state_exit() {
        llSetTimerEvent(0);
    }
}

state stop_pilot {
    state_entry() {
        // DEBUG
        llOwnerSay("Stopping autopilot for flight...");
        llRegionSayTo(
            (key)wasKeyValueGet(
                "corrade", 
                configuration
            ),
            0,
            wasKeyValueEncode(
                [
                    "command", "autopilot",
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
                    // move in a radius around the current primitive.
                    "position", llGetPos() + wasCirclePoint(
                        (integer)wasURLEscape(
                            wasKeyValueGet(
                                "range", 
                                configuration
                            )
                        )
                    ),
                    "action", "stop",
                    "callback", wasURLEscape(callback)
                ]
            )
        );
        llSetTimerEvent(60);
    }
    timer() {
        state on;
    }
    touch_end(integer num) {
        llSetColor(<.5,0,0>, ALL_SIDES);
        llResetScript();
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "autopilot" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Failed to stop autopilot...");
            state on;
        }
        state fly;
    }
    attach(key id) {
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if(change & CHANGED_INVENTORY || (change & CHANGED_OWNER))
            llResetScript();
        if(
            (change & CHANGED_REGION_START) || 
            (change & CHANGED_REGION)) {
            state on;
        }
    }
    state_exit() {
        llSetTimerEvent(0);
    }
}

state fly {
    state_entry() {
        // DEBUG
        llOwnerSay("Flying to agent...");
        llRegionSayTo(
            (key)wasKeyValueGet(
                "corrade", 
                configuration
            ),
            0,
            wasKeyValueEncode(
                [
                    "command", "flyto",
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
                    // move in a radius around the current primitive.
                    "position", llGetPos() + wasCirclePoint(
                        (integer)wasURLEscape(
                            wasKeyValueGet(
                                "range", 
                                configuration
                            )
                        )
                    ),
                    "fly", "True",
                    "vicinity", wasCirclePoint(
                        (integer)wasURLEscape(
                            wasKeyValueGet(
                                "range", 
                                configuration
                            )
                        )
                    ),
                    "duration", "2500",
                    "callback", wasURLEscape(callback)
                ]
            )
        );
        llSetTimerEvent(60);
    }
    timer() {
        state on;
    }
    touch_end(integer num) {
        llSetColor(<.5,0,0>, ALL_SIDES);
        llResetScript();
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "flyto" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Flight failed...");
            state on;
        }
        state select;
    }
    attach(key id) {
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if(change & CHANGED_INVENTORY || (change & CHANGED_OWNER))
            llResetScript();
        if(
            (change & CHANGED_REGION_START) || 
            (change & CHANGED_REGION)) {
            state on;
        }
    }
    state_exit() {
        llSetTimerEvent(0);
    }
}

state stop_flight {
    state_entry() {
        // DEBUG
        llOwnerSay("Landing agent for walking...");
        llRegionSayTo(
            wasKeyValueGet(
                "corrade", 
                configuration
            ),
            0,
            wasKeyValueEncode(
                [
                    "command", "fly",
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
                    "action", "stop",
                    "callback", wasURLEscape(callback)
                ]
            )
        );
        llSetTimerEvent(60);
    }
    timer() {
        state on;
    }
    touch_end(integer num) {
        llSetColor(<.5,0,0>, ALL_SIDES);
        llResetScript();
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "fly" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Landing failed...");
            state on;
        }
        llOwnerSay("Landed...");
        state walk;
    }
    attach(key id) {
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if(change & CHANGED_INVENTORY || (change & CHANGED_OWNER))
            llResetScript();
        if(
            (change & CHANGED_REGION_START) || 
            (change & CHANGED_REGION)) {
            state on;
        }
    }
    state_exit() {
        llSetTimerEvent(0);
    }
}

state walk {
    state_entry() {
        // DEBUG
        llOwnerSay("Walking to agent...");
        llRegionSayTo(
            (key)wasKeyValueGet(
                "corrade", 
                configuration
            ),
            0,
            wasKeyValueEncode(
                [
                    "command", "autopilot",
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
                    // move in a radius around the current primitive.
                    "position", llGetPos() + wasCirclePoint(
                        (integer)wasURLEscape(
                            wasKeyValueGet(
                                "range", 
                                configuration
                            )
                        )
                    ),
                    "action", "start",
                    "callback", wasURLEscape(callback)
                ]
            )
        );
        llSetTimerEvent(60);
    }
    timer() {
        state on;
    }
    touch_end(integer num) {
        llSetColor(<.5,0,0>, ALL_SIDES);
        llResetScript();
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "autopilot" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Failed to start autopilot...");
            state on;
        }
        state select;
    }
    attach(key id) {
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if(change & CHANGED_INVENTORY || (change & CHANGED_OWNER))
            llResetScript();
        if(
            (change & CHANGED_REGION_START) || 
            (change & CHANGED_REGION)) {
            state on;
        }
    }
    state_exit() {
        llSetTimerEvent(0);
    }
}
