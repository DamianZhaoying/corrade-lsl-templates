///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2016 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
//
// This script can be used to control Corrade's movement manually using the
// WSAD and arrow keys on the keyboard.
//
// For more information on Corrade, please see:
//     http://grimore.org/secondlife/scripted_agents/corrade
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

// configuration data
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
        if((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START) || (change & CHANGED_OWNER)) {
            llResetScript();
        }
    }
    state_exit() {
        llSetTimerEvent(0);
    }
}

state off {
    state_entry() {
        llReleaseControls();
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
        if((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START) || (change & CHANGED_OWNER)) {
            llResetScript();
        }
    }
}

state on {
    state_entry() {
        llSetColor(<0,.5,0>, ALL_SIDES);
        state detect;
    }
    attach(key id) {
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START) || (change & CHANGED_OWNER)) {
            llResetScript();
        }
    }
}
 
state detect {
    state_entry() {
        // DEBUG
        llOwnerSay("Detecting if Corrade is on the region...");
        if(llListFindList(
            llGetAgentList(
                AGENT_LIST_REGION, 
                []
            ), 
            (list)(
                (key)wasKeyValueGet(
                    "corrade", 
                    configuration
                )
            )
        ) == -1) {
            // DEBUG
            llOwnerSay("Corrade is not in the current region.");
            llResetScript();
        }
        state joy;
    }
    touch_start(integer num) {
        llSetColor(<.5,0,0>, ALL_SIDES);
        llResetScript();
    }
    attach(key id) {
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START) || (change & CHANGED_OWNER)) {
            llResetScript();
        }
    }
}
 
state joy {
    state_entry() {
        llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS);
        llSetColor(<0,0.5,0>, ALL_SIDES);
        // DEBUG
        llOwnerSay("Joystick on...");
    }
    touch_start(integer num) {
        llSetColor(<.5,0,0>, ALL_SIDES);
        llResetScript();
    }
    control(key id, integer level, integer edge) {
        if (level & CONTROL_UP) {
            llRegionSayTo(
                wasKeyValueGet(
                    "corrade", 
                    configuration
                ),
                0,
                wasKeyValueEncode(
                    [
                        // nudges Corrade up
                        "command", "nudge",
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
                        "direction", "up"
                    ]
                )
            );
        }
        if (level & CONTROL_DOWN) {
            llRegionSayTo(
                wasKeyValueGet(
                    "corrade", 
                    configuration
                ),
                0,
                wasKeyValueEncode(
                    [
                        // nudges Corrade down
                        "command", "nudge",
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
                        "direction", "down"
                    ]
                )
            );
        }
        if (level & CONTROL_FWD) {
            llRegionSayTo(
                wasKeyValueGet(
                    "corrade", 
                    configuration
                ),
                0,
                wasKeyValueEncode(
                    [
                        // nudges Corrade forward
                        "command", "nudge",
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
                        "direction", "forward"
                    ]
                )
            );
        }
        if (level & CONTROL_BACK) {
            llRegionSayTo(
                wasKeyValueGet(
                    "corrade", 
                    configuration
                ),
                0,
                wasKeyValueEncode(
                    [
                        // nudges Corrade back
                        "command", "nudge",
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
                        "direction", "back"
                    ]
                )
            );
        }
        if ((level & CONTROL_LEFT) || (level & CONTROL_ROT_LEFT)) {
            llRegionSayTo(
                wasKeyValueGet(
                    "corrade", 
                    configuration
                ),
                0,
                wasKeyValueEncode(
                    [
                        // rotates Corrade left
                        "command", "turn",
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
                        "direction", "left",
                        "radians", 10 * DEG_TO_RAD
                    ]
                )
            );
        }
        if ((level & CONTROL_RIGHT) || (level & CONTROL_ROT_RIGHT)) {
            llRegionSayTo(
                wasKeyValueGet(
                    "corrade", 
                    configuration
                ),
                0,
                wasKeyValueEncode(
                    [
                        // rotates Corrade right
                        "command", "turn",
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
                        "direction", "right",
                        "radians", 10 * DEG_TO_RAD
                    ]
                )
            );
        }
    }
    run_time_permissions(integer permissions) {
        if (permissions & PERMISSION_TAKE_CONTROLS) {
            llTakeControls(CONTROL_FWD | CONTROL_BACK | CONTROL_LEFT | CONTROL_ROT_LEFT | CONTROL_RIGHT | CONTROL_ROT_RIGHT | CONTROL_UP | CONTROL_DOWN, TRUE, FALSE);
            // DEBUG
            llOwnerSay("Controls seized...");
        }
    }
    attach(key id) {
        llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
    changed(integer change) {
        if((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START) || (change & CHANGED_OWNER)) {
            llResetScript();
        }
    }
}