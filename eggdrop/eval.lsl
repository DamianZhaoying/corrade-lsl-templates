///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2016 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////
//
// A module that evaluates a mathematical expression for Corrade Eggdrop.
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
// http://was.fm/secondlife/wanderer
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

//////////////////////////////////////////////////////////
// Returns a reversed list.
//////////////////////////////////////////////////////////
list wasListReverse(list lst) {
    if(llGetListLength(lst)<=1) return lst;
    return wasListReverse(llList2List(lst, 1, llGetListLength(lst))) + llList2List(lst,0,0);
}
 
//////////////////////////////////////////////////////////
// Deletes elements delete from list input.
//////////////////////////////////////////////////////////
list wasSubtractSubList(list input, list delete) {
    do {
        string tok = llList2String(delete, 0);
        list clean = input;
        do {
            if(llList2String(clean, 0) == tok) {
                integer idx = llListFindList(input, (list)tok);
                input = llDeleteSubList(input, idx, idx);
            }
        } while(clean = llDeleteSubList(clean, 0, 0));
    } while(delete = llDeleteSubList(delete, 0, 0));
    return input;
}
 
//////////////////////////////////////////////////////////
// Returns a list of operators and operands.
//////////////////////////////////////////////////////////
list wasInfixTokenize(string input) {
    list op = [ "+", "-", "(", ")", "%", "*", "/", "^", "sin", "asin", "cos", "acos", "tan", "sqrt", "ln" ];
    list result = llParseString2List(input, [], op);
    return wasSubtractSubList(result, [" "]);
}
 
//////////////////////////////////////////////////////////
// Transforms an infix expression to a postfix expression.
//////////////////////////////////////////////////////////
list wasInfixToPostfix(list infix) {
    list op = [  "+", "-", "%", "*", "/", "^", "sin", "asin", "cos", "acos", "tan", "sqrt", "ln" ];
    list opStack = [];
    list result = [];
    do {
        string t = llList2String(infix, 0);
        infix = llDeleteSubList(infix, 0, 0);
        if(t == "(") {
            opStack += "(";
            jump continue;
        }
        if(t == ")") {
            while(llGetListLength(opStack) != 0) {
                string topa = llList2String(opStack, llGetListLength(opStack)-1);
                opStack = llDeleteSubList(opStack, llGetListLength(opStack)-1, llGetListLength(opStack)-1);
                if(topa != "(" && topa != ")") result += topa;
            }
            opStack = llDeleteSubList(opStack, llGetListLength(opStack)-1, llGetListLength(opStack)-1);
            jump continue;
        }
        integer idx = llListFindList(op, (list)t);
        if(idx == -1) {
            result += t;
            jump continue;
        }
@repeat;
        string topb = llList2String(opStack, llGetListLength(opStack)-1);
        integer odx = llListFindList(op, (list)topb);
        if(odx >= idx) {
            opStack = llDeleteSubList(opStack, llGetListLength(opStack)-1, llGetListLength(opStack)-1);
            result += topb;
            if(llGetListLength(opStack) != 0) jump repeat;
        }
        opStack += t;
@continue;
    } while(llGetListLength(infix) != 0);
    result += wasListReverse(opStack);
    return result;   
}
 
//////////////////////////////////////////////////////////
// Evaluate a postfix expression.
//////////////////////////////////////////////////////////
float wasPostfixEval(list postfix) {
    list op = [ "+", "-", "%", "*", "/", "^", "sin", "asin", "cos", "acos", "tan", "sqrt", "ln" ];
    list orStack = [];
    do {
        string t = llList2String(postfix, 0);
        postfix = llDeleteSubList(postfix, 0, 0);
        integer idx = llListFindList(op, (list)t);
        if(idx == -1) {
            orStack += t;
            jump continue;
        }
        float a = llList2Float(orStack, llGetListLength(orStack)-1);
        orStack = llDeleteSubList(orStack, llGetListLength(orStack)-1, llGetListLength(orStack)-1);
        float b = llList2Float(orStack, llGetListLength(orStack)-1);
        float r = 0;
        if(t == "+") {
            orStack = llDeleteSubList(orStack, llGetListLength(orStack)-1, llGetListLength(orStack)-1);
            r = b + a;
            jump push;
        }
        if(t == "-") {
            orStack = llDeleteSubList(orStack, llGetListLength(orStack)-1, llGetListLength(orStack)-1);
            r = b - a;
            jump push;
        }
        if(t == "*") {
            orStack = llDeleteSubList(orStack, llGetListLength(orStack)-1, llGetListLength(orStack)-1);
            r = b * a;
            jump push;
        }
        if(t == "/") {
            orStack = llDeleteSubList(orStack, llGetListLength(orStack)-1, llGetListLength(orStack)-1);
            if(a == 0) {
                r = (float)"NaN";
                jump push;
            }
            r = b / a;
            jump push;
        }
        if(t == "^") {
            orStack = llDeleteSubList(orStack, llGetListLength(orStack)-1, llGetListLength(orStack)-1);
            r = llPow(b,a);
            jump push;
        }
        if(t == "%") {
            orStack = llDeleteSubList(orStack, llGetListLength(orStack)-1, llGetListLength(orStack)-1);
            r = (integer)b % (integer)a;
            jump push;
        }
        if(t == "sin") {
            r = llSin(a * DEG_TO_RAD);
            jump push;
        }
        if(t == "asin") {
            r = llAsin(a * DEG_TO_RAD);
            jump push;
        }
        if(t == "cos") {
            r = llCos(a * DEG_TO_RAD);
            jump push;
        }
        if(t == "acos") {
            r = llAcos(a * DEG_TO_RAD);
            jump push;
        }
        if(t == "tan") {
            r = llTan(a * DEG_TO_RAD);
            jump push;
        }
        if(t == "ln") {
            r = llLog(a);
            jump push;
        }
        if(t == "sqrt") {
            r = llSqrt(a);
        }
@push;
        orStack += r;
@continue;
    } while(llGetListLength(postfix) != 0);
    return llList2Float(orStack, 0);
}

// configuration data
string configuration = "";
// callback URL
string URL = "";
// store message over state.
string data = "";

// Notecard reading.
key nQuery = NULL_KEY;
integer nLine = 0;
list nList = [];

default {
    state_entry() {
        llOwnerSay("[Eval] Starting module...");
        llSetTimerEvent(10);
    }
    link_message(integer sender, integer num, string message, key id) {
        if(id != "configuration") return;
        llOwnerSay("[Eval] Got configuration...");
        configuration = message;
        state listen_group;
    }
    timer() {
        llOwnerSay("[Eval] Requesting configuration...");
        llMessageLinked(LINK_THIS, 0, "configuration", NULL_KEY);
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

state listen_group {
    state_entry() {
        // DEBUG
        llOwnerSay("[Eval] Waiting for group messages...");
    }
    link_message(integer sender, integer num, string message, key id) {
        // We only care about notifications now.
        if(id != "notification")
            return;
        
        // This script only processes group notifications.
        if(wasKeyValueGet("type", message) != "group")
            return;
            
        // Get the sent message.
        data = wasURLUnescape(
            wasKeyValueGet(
                "message", 
                message
            )
        );
        
        // Check if this is an eggdrop command.
        if(llGetSubString(data, 0, 0) != 
            wasKeyValueGet("command", configuration))
            return;
        
        // Check if the command matches the current module.
        list command = llParseString2List(data, [" "], []);
        if(llList2String(command, 0) != 
            wasKeyValueGet("command", configuration) + "eval")
            return;
            
        // Remove command.
        command = llDeleteSubList(command, 0, 0);
        
        // Dump the rest of the message.
        data = (string)wasPostfixEval(
            wasInfixToPostfix(
                wasInfixTokenize(
                    llDumpList2String(
                        command,
                        " "
                    )
                )
            )
        );
        
        state tell;
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
}

state tell {
    state_entry() {
        // DEBUG
        llOwnerSay("[Eval] Sending to group.");
        llInstantMessage(
            wasKeyValueGet(
                "corrade", 
                configuration
            ), 
            wasKeyValueEncode(
                [
                    "command", "tell",
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
                    "entity", "group",
                    "message", wasURLEscape(data)
                ]
            )
        );
        state listen_group;
    }
}
