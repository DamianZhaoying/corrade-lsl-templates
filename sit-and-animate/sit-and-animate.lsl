///////////////////////////////////////////////////////////////////////////
//  Copyright (C) Wizardry and Steamworks 2014 - License: CC BY 2.0      //
///////////////////////////////////////////////////////////////////////////

default {
    state_entry() {
        llSetTimerEvent(1);
    }
    timer() {
        // If someone is sitting, hide the poseball.
        key a = llAvatarOnSitTarget();
        if(a == NULL_KEY) {
            llSetAlpha(1, ALL_SIDES);
            return;
        }
        llSetAlpha(0, ALL_SIDES);
    }
    run_time_permissions(integer perm) {
        if(perm & PERMISSION_TRIGGER_ANIMATION) {
            string o = llGetInventoryName(INVENTORY_ANIMATION, 0);
            if(llGetInventoryType(o) != INVENTORY_ANIMATION) return;
            key a = llAvatarOnSitTarget();
            if(a == NULL_KEY) {
                if(perm & PERMISSION_TRIGGER_ANIMATION) {
                    // DEBUG
                    llOwnerSay("Animation stopped...");
                    llSetAlpha(1, ALL_SIDES);
                    llStopAnimation(o);
                }
                return;
            }
            if(perm & PERMISSION_TRIGGER_ANIMATION) {
                // DEBUG
                llOwnerSay("Animation started...");
                llSetAlpha(0, ALL_SIDES);
                llStartAnimation(o);
            }
        }
    }
    changed(integer change) {
        if((change & CHANGED_INVENTORY) || (change & CHANGED_REGION_START)) {
            llResetScript();
        }
        if(change & CHANGED_LINK) {
            key a = llAvatarOnSitTarget();
            if(a == NULL_KEY) return;
            llRequestPermissions(a, PERMISSION_TRIGGER_ANIMATION);
        }
    }
}
