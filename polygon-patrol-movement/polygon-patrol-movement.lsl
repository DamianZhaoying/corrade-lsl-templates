///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2014 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
//
// This is an automatic teleporter, and patrol script for the Corrade
// Second Life / OpenSim bot. You can find more details about the bot
// by following the URL: http://was.fm/secondlife/scripted_agents/corrade
//
// The purpose of this script is to demonstrate patroling with Corrade and 
// you are free to use, change, and commercialize it under the CC BY 2.0 
// license which can be found at: https://creativecommons.org/licenses/by/2.0
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
//    Copyright (C) 2013 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
list wasDualQuicksort(list a, list b) {
    if(llGetListLength(a) <= 1) return a+b;
 
    float pivot_a = llList2Float(a, 0);
    a = llDeleteSubList(a, 0, 0);
    vector pivot_b = llList2Vector(b, 0);
    b = llDeleteSubList(b, 0, 0);
 
    list less = [];
    list less_b = [];
    list more = [];
    list more_b = [];
 
    do {
        if(llList2Float(a, 0) > pivot_a) {
            less += llList2List(a, 0, 0);
            less_b += llList2List(b, 0, 0);
            jump continue;
        }
        more += llList2List(a, 0, 0);
        more_b += llList2List(b, 0, 0);
@continue;
        a = llDeleteSubList(a, 0, 0);
        b = llDeleteSubList(b, 0, 0);
    } while(llGetListLength(a));
    return wasDualQuicksort(less, less_b) + [ pivot_a ] + [ pivot_b ] + wasDualQuicksort(more, more_b);
}
 
///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2014 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
// determines whether the segment AB intersects the segment CD
integer wasSegmentIntersect(vector A, vector B, vector C, vector D) {
    vector s1 = <B.x - A.x, B.y - A.y, B.z - A.z>;
    vector s2 = <D.x - C.x, D.y - C.y, D.y - C.z>;
 
    float d = (s1.x * s2.y -s2.x * s1.y);
 
    if(d == 0) return FALSE;
 
    float s = (s1.x * (A.y - C.y) - s1.y * (A.x - C.x)) / d;
    float t = (s2.x * (A.y - C.y) - s2.y * (A.x - C.x)) / d;
 
    // intersection at <A.x + (t * s1.x), A.y + (t * s1.y), A.z + (t * s1.z)>;
    return (integer)(s >= 0 && s <= 1 && t >= 0 && t <= 1 && 
            A.z + t*(B.z - A.z) == C.z + s*(D.z - C.z));
}
 
///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2013 Wizardry and Steamworks - License: CC BY 2.0    //
//    www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html    //
///////////////////////////////////////////////////////////////////////////
integer wasPointInPolygon(vector p, list polygon) {
    integer inside = FALSE;
    integer i = 0;
    integer nvert = llGetListLength(polygon);
    integer j = nvert-1;
    do {
        vector pi = llList2Vector(polygon, i);
        vector pj = llList2Vector(polygon, j);
        if ((pi.y > p.y) != (pj.y > p.y))
            if(p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y) + pi.x)
                inside = !inside;
        j = i++;
    } while(i<nvert);
    return inside;
}
 
///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2013 Wizardry and Steamworks - License: CC BY 2.0    //
//    www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html    //
///////////////////////////////////////////////////////////////////////////
list wasPointToPolygon(list polygon, vector point) {
    integer i = llGetListLength(polygon)-1;
    list l = [];
    do {
        l = llListInsertList(l, (list)llVecDist(point, llList2Vector(polygon, i)), 0);
    } while(--i>-1);
    l = wasDualQuicksort(l, polygon);
    return [llList2Float(l, 0), llList2Vector(l, 1)];
 
}
 
///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2013 Wizardry and Steamworks - License: CC BY 2.0    //
//    www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html    //
///////////////////////////////////////////////////////////////////////////
vector wasPolygonCentroid(list polygon, vector start, float tollerance, integer power) {
    // calculate the distance to the point farthest away from the start.
    list wpf = wasPointToPolygon(polygon, start);
    float dist = llList2Float(wpf, 0);
    vector next = llList2Vector(wpf, 1);
 
    // now calculate the next jump point
    next = start + ((dist/power)/dist) * (next-start);
 
    // if it falls withing the tollerance range, return it;
    if(llVecMag(start-next) < tollerance) return next;
    return wasPolygonCentroid(polygon, next, tollerance, power*power);
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
//    Copyright (C) 2011 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
vector wasPolygonPoint(list polygon) {
    vector c = wasPolygonCentroid(polygon, llList2Vector(polygon, 0), 0.05, 2);
    float r = llList2Float(wasPointToPolygon(polygon, c), 0);
    vector d;
    do {
        d = c + wasCirclePoint(r);
    } while(wasPointInPolygon(d, polygon) == FALSE);
    return d;
}
 
///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2015 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
// determines whether the path between the current positon m and the 
// computed next position d will intersect any two sides of the polygon
vector wasPolygonPath(vector m, list polygon) {
    integer c = llGetListLength(polygon) - 1;
    vector d = wasPolygonPoint(polygon);
    integer i = 0;
    do {
        vector s = llList2Vector(polygon, c);
        vector p = llList2Vector(polygon, c-1);
        // project in plane
        if(wasSegmentIntersect(
            <m.x, m.y, 0>, 
            <d.x, d.y, 0>, 
            <s.x, s.y, 0>, 
            <p.x, p.y, 0>))
            ++i;
    } while(--c > 0);
    if(i > 1) return wasPolygonPath(m, polygon);
    return d;
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

// corrade data
string CORRADE = "";
string GROUP = "";
string PASSWORD = "";
float RADIUS = 0;
float WAIT = 0;
list POLYGON = [];

// for holding Corrade's current location
vector location = ZERO_VECTOR;

// for holding the callback URL
string callback = "";

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
            
            // BEGIN POLYGON
            integer i = llGetListLength(tuples)-1;
            do {
                string n = llList2String(tuples, i);
                if(llSubStringIndex(n, "point_") != -1) {
                    list l = llParseString2List(n, ["_"], []);
                    if(llList2String(l, 0) == "point") {
                        integer x = llList2Integer(
                                l, 
                                1
                        )-1;
                        // extend the polygon to the number of points
                        while(llGetListLength(POLYGON) < x)
                            POLYGON += "";
                        // and insert the point at the location
                        POLYGON = llListReplaceList(
                            POLYGON, 
                            (list)(
                                (vector)(
                                "<" + llList2CSV(
                                    llParseString2List(
                                        llList2String(
                                            tuples, 
                                            llListFindList(
                                                tuples, 
                                                (list)n
                                            )
                                            +1
                                        ), 
                                        ["<", ",", ">"], 
                                        []
                                    )
                                ) + ">")
                            ), 
                            x,
                            x
                        );
                    }
                }
            } while(--i>-1);
            // now clean up any empty slots
            i = llGetListLength(POLYGON)-1;
            do {
                if(llList2String(POLYGON, i) == "")
                    POLYGON = llDeleteSubList(POLYGON, i, i);
            } while(--i > -1);
            // END POLYGON
            
            WAIT = llList2Float(
                          tuples,
                          llListFindList(
                              tuples, 
                              [
                                  "wait"
                              ]
                          )
                      +1);
            if(WAIT == 0) {
                llOwnerSay("Error in configuration notecard: wait");
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
        llSensor("", (key)CORRADE, AGENT, 10, TWO_PI);
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
                            llGetPos() + wasCirclePoint(RADIUS)
                        )
                    ),
                    "callback", callback
                ]
            )
        );
        llSensorRepeat("", (key)CORRADE, AGENT, 10, TWO_PI, 60);
    }
    sensor(integer num) {
        llSetTimerEvent(0);
        state wander;
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "teleport" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Teleport failed...");
            return;
        }
        llSetTimerEvent(0);
        state wander;
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

state wander {
    state_entry() {
        // DEBUG
        llOwnerSay("Wandering ready...");
        // initialize location from current location
        location = llGetPos();
        llSetTimerEvent(1 + llFrand(WAIT));
    }
    timer() {
        llRequestAgentData((key)CORRADE, DATA_ONLINE);
    }
    dataserver(key id, string data) {
        if(data != "1") {
            // DEBUG
            llOwnerSay("Corrade is not online, sleeping...");
            llResetScript();
            return;
        }
        // DEBUG
        //llOwnerSay("Sending stop...");
        llInstantMessage(CORRADE, 
            wasKeyValueEncode(
                [
                    "command", "autopilot",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "action", "stop",
                    "callback", wasURLEscape(callback)
                ]
            )
        );
    }
    http_request(key id, string method, string body) {
        llHTTPResponse(id, 200, "OK");
        if(wasKeyValueGet("command", body) != "autopilot" ||
            wasKeyValueGet("success", body) != "True") {
            // DEBUG
            llOwnerSay("Could not get Corrade to stop, restarting script...");
            llResetScript();
        }
        // DEBUG
        llOwnerSay("Sending next move...");
        // get the next location
        location = wasPolygonPath(location, POLYGON);
        vector pos = llGetPos();
        llInstantMessage(CORRADE,
            wasKeyValueEncode(
                [
                    "command", "autopilot",
                    "group", wasURLEscape(GROUP),
                    "password", wasURLEscape(PASSWORD),
                    "position", wasURLEscape(
                        (string)(<location.x, location.y, pos.z>)
                    ),
                    "action", "start"
                ]
            )
        );
        llSetTimerEvent(1 + llFrand(WAIT));
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
