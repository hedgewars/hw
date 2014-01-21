package org.hedgewars.hedgeroid.netplay;

import org.hedgewars.hedgeroid.Datastructures.Player;
import org.hedgewars.hedgeroid.Datastructures.PlayerInRoom;

final class ClientFlagsUpdate {
    public static final char FLAG_ADMIN = 'a';
    public static final char FLAG_CHIEF = 'h';
    public static final char FLAG_READY = 'r';
    public static final char FLAG_REGISTERED = 'u';

    public final String nick, flags;
    public final boolean newFlagState;

    public ClientFlagsUpdate(String nick, String flags, boolean newFlagState) {
        this.nick = nick;
        this.flags = flags;
        this.newFlagState = newFlagState;
    }

    public Player applyTo(Player p) {
        return new Player(
                p.name,
                updatedFlag(FLAG_REGISTERED, p.registered),
                updatedFlag(FLAG_ADMIN, p.admin));
    }

    public PlayerInRoom applyTo(PlayerInRoom p) {
        return new PlayerInRoom(
                this.applyTo(p.player),
                updatedFlag(FLAG_READY, p.ready),
                updatedFlag(FLAG_CHIEF, p.roomChief));
    }

    public boolean appliesTo(char flag) {
        return flags.indexOf(flag) != -1;
    }

    private boolean updatedFlag(char flag, boolean oldValue) {
        return appliesTo(flag) ? newFlagState : oldValue;
    }

    @Override
    public String toString() {
        return "ClientFlagsUpdate [nick=" + nick + ", flags=" + flags
                + ", newFlagState=" + newFlagState + "]";
    }
}
