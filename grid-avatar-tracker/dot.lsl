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

vector position = ZERO_VECTOR;
string region = "";
string avatar = "";

default
{
    touch_start(integer num) {
        // Do not send the SLURL if no avatar has been reported.
        if(position == ZERO_VECTOR ||
            region == "" ||
            avatar == "")
            return;
            
        llInstantMessage(
            llDetectedKey(0),
            "Avatar: " +
            avatar +
            " is currently at: " +
            "http://maps.secondlife.com/secondlife/" + 
            llEscapeURL(region )+ 
            "/" + 
            (string)llFloor(position.x) + 
            "/" + 
            (string)llFloor(position.y) + 
            "/0"
        );
    }
    link_message(integer link, integer value, string message, key id) {
        // DEBUG
        //llOwnerSay("Data received: " + message);
        
        list data = wasCSVToList(message);

        avatar = llList2String(
            data,
            llListFindList(
                data,
                [ 
                    "avatar"
                ]
            ) + 1
        );
        
        region = llList2String(
            data,
            llListFindList(
                data,
                [ 
                    "region"
                ]
            ) + 1
        );

        position = (vector)llList2String(
            data,
            llListFindList(
                data,
                [ 
                    "position"
                ]
            ) + 1
        );

        vector scale = (vector)llList2String(
            data,
            llListFindList(
                data,
                [ 
                    "scale"
                ]
            ) + 1
        );
        
        float x = wasMapValueToRange(position.x, 0, 256, 0, scale.x) - scale.x / 2;
        float y = wasMapValueToRange(position.y, 0, 256, 0, scale.y) - scale.y / 2;
        
        // Set the dot position.
        llSetPos(<x, y, 0>);
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
