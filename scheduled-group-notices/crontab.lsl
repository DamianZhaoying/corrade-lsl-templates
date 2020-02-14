///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2014 - License: CC BY 2.0      //
//  Please see: https://creativecommons.org/licenses/by/2.0 for legal details,  //
//  rights of fair usage, the disclaimer and warranty conditions.        //
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2011 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
list wasListReverse(list lst) {
    if(llGetListLength(lst)<=1) return lst;
    return wasListReverse(
        llList2List(lst, 1, llGetListLength(lst))
    ) + llList2List(lst,0,0);
}

///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2014 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
string wasDayOfWeek(integer year, integer month, integer day) {
    return llList2String(
        [ "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", 
            "Saturday", "Sunday" ],
        (
            day
            + ((153 * (month + 12 * ((14 - month) / 12) - 3) + 2) / 5)
            + (365 * (year + 4800 - ((14 - month) / 12)))              
            + ((year + 4800 - ((14 - month) / 12)) / 4)
            - ((year + 4800 - ((14 - month) / 12)) / 100)
            + ((year + 4800 - ((14 - month) / 12)) / 400)
            - 32045
        ) % 7
    );
}

///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2014 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
integer wasGetYearDays(integer year) {
    integer leap = (year % 4 == 0 && year % 100 != 0) || 
            (year % 400 == 0);
    if(leap == TRUE) {
        return 366;
    }
    return 365;
}

///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2014 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
integer wasGetMonthDays(integer month, integer year) {
    if (month == 4 || month == 6 || month == 9 || month == 11) {
        return 30;
    }
    if(month == 2) {
        integer leap = (year % 4 == 0 && year % 100 != 0) || 
            (year % 400 == 0);
        if(leap == TRUE) {
            return 29;
        }
        return 28;
    }
    return 31;
}

///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2014 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
string wasUnixTimeToStamp(integer unix) {
    integer year = 1970;
    integer dayno = unix / 86400;
    do {
        dayno -= wasGetYearDays(year);
        ++year;
    } while (dayno >= wasGetYearDays(year));
    integer month = 1;
    do {
        dayno -= wasGetMonthDays(month, year);
        ++month;
    } while (dayno >= wasGetMonthDays(month, year));
    return (string)year + "-" +
           (string)month + "-" +
           (string)(dayno + 1) + "T" +
           (string)((unix % 86400) / 3600) + ":" +
           (string)(((unix % 86400) % 3600) / 60) + ":" +
           (string)(unix % 60) + ".0Z";
}
 
///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2013 Wizardry and Steamworks - License: CC BY 2.0    //
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
//    Copyright (C) 2013 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
integer wasListCountExclude(list input, list exclude) {
    if(llGetListLength(input) == 0) return 0;
    if(llListFindList(exclude, (list)llList2String(input, 0)) == -1) 
        return 1 + wasListCountExclude(llDeleteSubList(input, 0, 0), exclude);
    return wasListCountExclude(llDeleteSubList(input, 0, 0), exclude);
}
 
///////////////////////////////////////////////////////////////////////////
//    Copyright (C) 2013 Wizardry and Steamworks - License: CC BY 2.0    //
///////////////////////////////////////////////////////////////////////////
list wasListMerge(list l, list m, string merge) {
    if(llGetListLength(l) == 0 && llGetListLength(m) == 0) return [];
    string a = llList2String(m, 0);
    if(a != merge) return [ a ] + 
        wasListMerge(l, llDeleteSubList(m, 0, 0), merge);
    return [ llList2String(l, 0) ] + 
        wasListMerge(
            llDeleteSubList(l, 0, 0), 
            llDeleteSubList(m, 0, 0), 
            merge
        );
}

// for notecard reading
integer line = 0;
// time to execute
list time = [];
// message to send
list exec = [];
// subject to send
list subj = [];
// item to send
list item = [];
// inventory notecards
list notes = [];
// current notecard
string note = "";
key agent = NULL_KEY;
// minute store
integer minute = -1;
 
default {
    state_entry() {
        // get all the inventory notecards
        integer i = llGetInventoryNumber(INVENTORY_NOTECARD)-1;
        if(i == -1) {
            llSay(0, "No notecards found, idling...");
            return;
        }
        do {
            notes += llGetInventoryName(INVENTORY_NOTECARD, i);
        } while(--i>-1);
        note = llList2String(notes, 0);
        notes = llDeleteSubList(notes, 0, 0);
        line = 0;
        llSay(0, "Reading notecard: " + note);
        llGetNotecardLine(note, line);
    }
    dataserver(key id, string data) {
        if(data == EOF) {
            // if we have read all the notecards, 
            // start processing
            if(llGetListLength(notes) == 0) {
                // check if the crons are set-up properly or bail
                if(llGetListLength(time) == 0 || 
                    llGetListLength(exec) == 0 || 
                    llGetListLength(time) != llGetListLength(exec)) {
                    llSay(0, "No valid schedules found...");
                    return;
                }
                llSay(0, "All notecards have been read...");
                state cron;
            }
            // otherwise permute
            note = llList2String(notes, 0);
            notes = llDeleteSubList(notes, 0, 0);
            line = 0;
            llSay(0, "Reading notecard: " + note);
            llGetNotecardLine(note, line);
            return;
        }
        if(data == "") jump continue;
        integer i = llSubStringIndex(data, "#");
        if(i != -1) data = llDeleteSubString(data, i, -1);
        if(data == "") jump continue;
        list data = llParseString2List(data, [" "], []);
        // *  *  *  *  * message to send to the link-set
        // sanity check a little
        if(llGetListLength(data) < 6 ||
            (llList2String(data, 2) != "*" && llList2Integer(data, 2) == 0) ||
            (llList2String(data, 3) != "*" && llList2Integer(data, 3) == 0)) jump continue;
        list t = llList2List(data, 0, 4);
        // normalize 0x
        i = llGetListLength(t)-1;
        do {
            if(llList2String(t, i) == "*") jump wildcard;
            t = llListReplaceList(t, [ llList2Integer(t, i) ], i, i);
@wildcard;
        } while(--i>-1);
        time += llDumpList2String(t, " ");
        list ms = llParseString2List(llDumpList2String(llList2List(data, 5, -1), " "), ["|"], []);
        // check if subject and message are present
        if(llGetListLength(ms) > 0) {
            subj += llList2String(ms, 0);
            jump message;
        }
        subj += "";
@message;
        if(llGetListLength(ms) > 1) {
            exec += llList2String(ms, 1);
            jump attachment;
        }
        exec += "";
@attachment;
        if(llGetListLength(ms) >= 2) {
            item += llList2String(ms, 2);
            jump continue;
        }
        item += "";
@continue;
        llGetNotecardLine(note, ++line);
    }
    changed(integer change) {
        if(change & CHANGED_INVENTORY) llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
}
 
///////////////////////////////////////////////////////////////////////////
//             [WaS-K] Cron @ http://was.fm/secondlife/cron              //
///////////////////////////////////////////////////////////////////////////
state cron {
    state_entry() {
        // cron runs every minute so we bind the event handler
        // to the second in order to be precisely on the minute
        llSetTimerEvent(1);
        llSay(0, "Scheduler activated...");
    }
    touch_start(integer num) {
        /////////////////////////////////////////////////////////////////////////// ENABLE ME
        // not part of the same group, so bail
        //if(llDetectedGroup(0) == FALSE) return;
        integer comChannel = (integer)("0x8" + llGetSubString(llGetKey(), 0, 6));
        llListen(comChannel, "", "", "");
        llDialog(llDetectedKey(0), "\n                Welcome to the Scheduler.\nCreated in 2014 by Wizardry and Steamworks\n           10 September 2014: Version: 1.0\n\n", ["⌚ Show", "⎙ Remove"], comChannel);
    }
    listen(integer channel, string name, key toucher, string message) {
        if(message == "⌚ Show") {
            llInstantMessage(toucher, "-----------------------------------------");
            integer i = llGetListLength(time)-1;
            do {
                llInstantMessage(toucher, llList2String(time, i) + " ▶︎ " + llList2String(exec, i));
            } while(--i>-1);
            llInstantMessage(toucher, "-----------------------------------------");
            return;
        }
        if(message == "⎙ Remove") {
            llSetTimerEvent(0);
            agent = toucher;
            state remove;
        }
    }
    timer() {
        // build the current date
        list stamp = llParseString2List(
            wasUnixTimeToStamp(llGetUnixTime() - ((integer) llGetGMTclock() - (integer) llGetWallclock())),
            ["-",":","T"],[""]
        );
        
        // only once per minute
        if(llList2Integer(stamp, 4) == minute) return;

        list ymd = llList2List(stamp, 0, 2);
        integer weekDay = llListFindList(
            // convert to cron syntax where Sunday counts as day 0 or 7
            [ "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" ],
            [
                wasDayOfWeek(
                    llList2Integer(ymd, 0), 
                    llList2Integer(ymd, 1), 
                    llList2Integer(ymd, 2)
                )
            ]
        );
        
        // minute, hour, day, month, day of week
        list date  = wasListReverse(llList2List(stamp, 1, -2)) + weekDay;
        integer i = llGetListLength(date)-1;
        // normalize 0x
        do {
            date = llListReplaceList(date, [ llList2Integer(date, i) ], i, i);
        } while(--i>-1);
        
        // check if it is time
        list times = time;
        list execs = exec;
        list subjs = subj;
        list items = item;
        do {
            list cron = llParseString2List(llList2String(times, 0), [" "], []);
            do {
                // crontab syntax counts Sunday as day 0 or 7 
                // so we add an exception on the week day element
                if(llGetListLength(times) == 1 && 
                    llList2Integer(date, 0) == 0 && 
                    llList2Integer(cron, 0) != 0 && 
                    llList2Integer(cron, 7) != 7) {
                    jump continue;
                }
                if(llList2String(date, 0) != llList2String(cron, 0) && llList2String(cron, 0) != "*") {
                    jump continue;
                }
                date = llDeleteSubList(date, 0, 0);
                cron = llDeleteSubList(cron, 0, 0);
            } while(llGetListLength(cron));
            // Send the notice information.
            llMessageLinked(
                LINK_SET, 
                0, 
                llList2CSV(
                    [ 
                        llList2String(subjs, 0),
                        llList2String(execs, 0),
                        llList2String(items, 0) 
                    ]
                ), 
                NULL_KEY
            );
@continue;
            times = llDeleteSubList(times, 0, 0);
            execs = llDeleteSubList(execs, 0, 0);
            subjs = llDeleteSubList(subjs, 0, 0);
            items = llDeleteSubList(items, 0, 0);
        } while(llGetListLength(times));
        
        // only once per minute
        minute = llList2Integer(stamp, 4);
    }
    changed(integer change) {
        if(change & CHANGED_INVENTORY) llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
}

///////////////////////////////////////////////////////////////////////////
//                          Remove Notecard                              //
///////////////////////////////////////////////////////////////////////////
state remove {
    state_entry() {
        // get all the inventory notecards
        integer i = llGetInventoryNumber(INVENTORY_NOTECARD)-1;
        do {
            notes += llGetSubString(llGetInventoryName(INVENTORY_NOTECARD, i), 0, 8);
        } while(--i>-1);
        integer channel = (integer)("0x8" + llGetSubString(llGetKey(), 0, 6));
        llListen(channel, "", "", "");
        llDialog(agent, "\n                Welcome to the Scheduler.\nCreated in 2014 by Wizardry and Steamworks\n           10 September 2014: Version: 1.0\n\n", wasDialogMenu(notes, ["⟵ Back", "⏏ Exit", "Next ⟶"], ""), channel);
        llSetTimerEvent(60);
    }
    listen(integer channel, string name, key id, string message) {
        if(message == "⟵ Back") {
            llSetTimerEvent(60);
            llDialog(id, "\n                Welcome to the Scheduler.\nCreated in 2014 by Wizardry and Steamworks\n           10 September 2014: Version: 1.0\n\n", wasDialogMenu(notes, ["⟵ Back", "⏏ Exit", "Next ⟶"], "<"), -10);
            return;
        }
        if(message == "Next ⟶") {
            llSetTimerEvent(60);
            llDialog(id, "\n                Welcome to the Scheduler.\nCreated in 2014 by Wizardry and Steamworks\n           10 September 2014: Version: 1.0\n\n", wasDialogMenu(notes, ["⟵ Back", "⏏ Exit", "Next ⟶"], ">"), -10);
            return;
        }
        if(message == "⏏ Exit") {
            llInstantMessage(id, "Resuming operations...");
            llResetScript();
        }
        integer i = llGetInventoryNumber(INVENTORY_NOTECARD)-1;
        do {
            string name = llGetInventoryName(INVENTORY_NOTECARD, i);
            if(llSubStringIndex(name, message) == -1) jump continue_inventory;
            llInstantMessage(id, "Deleting notecard: " + message);
            llRemoveInventory(name);
            integer j = llGetListLength(notes)-1;
            do {
                note = llList2String(notes, j);
                if(llSubStringIndex(name, note) == -1) jump continue_notes;
                notes = llDeleteSubList(notes, j, j);
                jump menu;
@continue_notes;
            } while(--j>-1);
@continue_inventory;
        } while(--i>-1);
@menu;
        llSetTimerEvent(60);
        llDialog(id, "\n                Welcome to the Scheduler.\nCreated in 2014 by Wizardry and Steamworks\n           10 September 2014: Version: 1.0\n\n", wasDialogMenu(notes, ["⟵ Back", "⏏ Exit", "Next ⟶"], ""), channel);
    }
    timer() {
        llInstantMessage(agent, "Dialog expired, resuming operations...");
        llResetScript();
    }
    changed(integer change) {
        if(change & CHANGED_INVENTORY) llResetScript();
    }
    on_rez(integer num) {
        llResetScript();
    }
}
