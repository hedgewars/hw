package net.ercatec.hw2ircsvr;

import net.ercatec.hw.INetClient;
import net.ercatec.hw.ProtocolConnection;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.List;
import java.util.Map;
import java.util.Queue;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.Collections;
import java.util.Vector;

import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;

import java.lang.IllegalArgumentException;

// for auth files
import java.util.Properties;
import java.io.FileInputStream;
import java.io.IOException;

/* TODO
 * disconnect clients that are not irc clients
 * disconnect excess flooders
 * recognizes stuff after : as single arg
 * collect pre-irc-join messages and show on join
 * allow negating regexps
 * ban
 * banlist
 * commandquery // wth did I mean by that?
 * more room info
 * filter rooms
 * warnings
 * global notice
 */

/**
 * @author sheepluva
 * 
 * based on jircs by Alexander Boyd
 */
public class Connection implements INetClient, Runnable
{
    private static final String DESCRIPTION_SHORT
        = "connect to hedgewars via irc!";

    private static final String VERSION = "0.6.7-Alpha_2015-11-07";


    private static final String MAGIC_BYTES       = "[\1\2\3]";
    private static final char   MAGIC_BYTE_ACTION = ((char)1); // ^A
    private static final char   MAGIC_BYTE_BOLD   = ((char)2); // ^B
    private static final char   MAGIC_BYTE_COLOR  = ((char)3); // ^C

    private static final String[] DEFAULT_MOTD = {
        "                                         ",
        " "+MAGIC_BYTE_COLOR+"06"+MAGIC_BYTE_BOLD+"                            SUCH FLUFFY!",
        "                                         ",
        " "+MAGIC_BYTE_COLOR+"04 MUCH BAH     "+MAGIC_BYTE_COLOR+"00__  _                     ",
        " "+MAGIC_BYTE_COLOR+"00          .-.'  `; `-."+MAGIC_BYTE_COLOR+"00_  __  _          ",
        " "+MAGIC_BYTE_COLOR+"00         (_,         .-:'  `; `"+MAGIC_BYTE_COLOR+"00-._      ",
        " "+MAGIC_BYTE_COLOR+"14       ,'"+MAGIC_BYTE_COLOR+"02o "+MAGIC_BYTE_COLOR+"00(        (_,           )     ",
        " "+MAGIC_BYTE_COLOR+"14      (__"+MAGIC_BYTE_COLOR+"00,-'      "+MAGIC_BYTE_COLOR+"15,'"+MAGIC_BYTE_COLOR+"12o "+MAGIC_BYTE_COLOR+"00(            )>   ",
        " "+MAGIC_BYTE_COLOR+"00         (       "+MAGIC_BYTE_COLOR+"15(__"+MAGIC_BYTE_COLOR+"00,-'            )    ",
        " "+MAGIC_BYTE_COLOR+"00          `-'._.--._(             )     ",
        " "+MAGIC_BYTE_COLOR+"14             |||  |||"+MAGIC_BYTE_COLOR+"00`-'._.--._.-'      ",
        " "+MAGIC_BYTE_COLOR+"15                        |||  |||        ",
        " "+MAGIC_BYTE_COLOR+"07"+MAGIC_BYTE_BOLD+"  WOW!                                  ",
        " "+MAGIC_BYTE_COLOR+"09                   VERY SHEEP           ",
        "                                         ",
        "                                         ",
        "                                         ",
        " "+MAGIC_BYTE_COLOR+"4 Latest hw2irc crimes/changes:",
        "     ping: ping of hwserver will only get reply if irc client pingable",
        "     ping: pings of irc clients will only get reply if hwserver pingable",
        "     rooms: id-rotation, make channel names at least 2 digits wide",
        "     auth: support passhash being loaded local auth file and irc pass (sent as cleartext - DO NOT USE!)",
        "                                         ",
        "                                         ",
    };


    private static final String DEFAULT_QUIT_REASON = "User quit";
    // NOT final
    private static char CHAT_COMMAND_CHAR = '\\';

    private final class Room {
        public final int id;
        public final String chan;
        public String name;
        private String owner = "";
        public int nPlayers = 0;
        public int nTeams   = 0;

        public Room(final int id, final String name, final String owner) {
            this.id = id;
            this.chan = (id<10?"#0":"#") + id;
            this.name = name;
            this.setOwner(owner);
        }

        public String getOwner() { return this.owner; }

        public void setOwner(final String owner) {
            // don't to this for first owner
            if (!this.owner.isEmpty()) {

                // owner didn't change
                if (this.owner.equals(owner))
                    return;

                // update old room owner
                final Player oldOwner = allPlayers.get(this.owner);

                if (oldOwner != null)
                    oldOwner.isRoomAdm = false;

            }

            // update new room owner
            final Player newOwner = allPlayers.get(owner);

            if (newOwner != null)
                newOwner.isRoomAdm = true;

            this.owner = owner;

        }
    }

    private final class Player {
        public final String nick;
        public final String ircNick;
        private boolean isAdm;
        private boolean isCont;
        private boolean isReg;
        public boolean inRoom;
        public boolean isRoomAdm;
        private String ircId;
        private String ircHostname;
        private boolean announced;

        // server info
        private String version = "";
        private String ip = "";
        private String room = "";

        public Player(final String nick) {
            this.nick = nick;
            this.ircNick = hwToIrcNick(nick);
            this.announced = false;
            updateIrcHostname();
        }

        public String getIrcHostname() { return ircHostname; }
        public String getIrcId()       { return ircId; }

        public String getRoom()        {
            if (room.isEmpty())
                return room;

            return "[" + ((isAdm?"@":"") + (isRoomAdm?"+":"") + this.room);
        }

        public boolean needsAnnounce() {
            return !announced;
        }

        public void setAnnounced() {
            announced = true;
        }

        public void setInfo(final String ip, final String version, final String room) {
            if (this.version.isEmpty()) {
                this.version = version;
                this.ip = ip.replaceAll("^\\[|]$", "");
                updateIrcHostname();
            }

            if (room.isEmpty())
                this.room = room;
            else
                this.room = room.replaceAll("^\\[[@+]*", "");
        }

        public boolean isServerAdmin()  { return isAdm; }
        //public boolean isContributor()  { return isCont; }
        public boolean isRegistered()   { return isReg; }

        public void setServerAdmin(boolean isAdm) {
            this.isAdm = isAdm; updateIrcHostname(); }
        public void setContributor(boolean isCont) {
            this.isCont = isCont; updateIrcHostname(); }
        public void setRegistered(boolean isReg) {
            this.isReg = isReg; updateIrcHostname(); }

        private void updateIrcHostname() {
            ircHostname = ip.isEmpty()?"":(ip + '/');
            ircHostname += "hw/";
            if (!version.isEmpty())
                ircHostname += version;
            if (isAdm)
                ircHostname += "/admin";
            else if (isCont)
                ircHostname += "/contributor";
            else if (isReg)
                ircHostname += "/member";
            else
                ircHostname += "/player";

            updateIrcId();
        }

        private void updateIrcId() {
            ircId = ircNick + "!~" + ircNick + "@" + ircHostname;
        }
    }

    public String hw404NickToIrcId(String nick) {
        nick = hwToIrcNick(nick);
        return nick + "!~" + nick + "@hw/404";
    }

    // hash tables are thread-safe
    private final Map<String,  Player>  allPlayers = new Hashtable<String,  Player>();
    private final Map<String,  Player> roomPlayers = new Hashtable<String,  Player>();
    private final Map<Integer, Room>   roomsById   = new Hashtable<Integer, Room>();
    private final Map<String,  Room>   roomsByName = new Hashtable<String,  Room>();
    private final List<Room> roomsSorted = new Vector<Room>();

    private final List<String> ircPingQueue = new Vector<String>();

    private static final String DEFAULT_SERVER_HOST = "netserver.hedgewars.org";
    private static String SERVER_HOST = DEFAULT_SERVER_HOST;
    private static int IRC_PORT = 46667;
    
    private String hostname;

    private static final String LOBBY_CHANNEL_NAME = "#lobby";
    private static final String  ROOM_CHANNEL_NAME = "#room";

    // hack
    // TODO: ,
    private static final char MAGIC_SPACE   = ' ';
    private static final char MAGIC_ATSIGN  = '៙';
    private static final char MAGIC_PERCENT = '％';
    private static final char MAGIC_PLUS    = '＋';
    private static final char MAGIC_EXCLAM  = '❢';
    private static final char MAGIC_COMMA   = '，';
    private static final char MAGIC_COLON   = '：';

    private static String hwToIrcNick(final String nick) {
        return nick
            .replace(' ', MAGIC_SPACE)
            .replace('@', MAGIC_ATSIGN)
            .replace('%', MAGIC_PERCENT)
            .replace('+', MAGIC_PLUS)
            .replace('!', MAGIC_EXCLAM)
            .replace('，', MAGIC_COMMA)
            .replace('：', MAGIC_COLON)
            ;
    }
    private static String ircToHwNick(final String nick) {
        return nick
            .replace(MAGIC_COLON,   '：')
            .replace(MAGIC_COMMA,   '，')
            .replace(MAGIC_EXCLAM,  '!')
            .replace(MAGIC_PLUS,    '+')
            .replace(MAGIC_PERCENT, '%')
            .replace(MAGIC_ATSIGN,  '@')
            .replace(MAGIC_SPACE,   ' ')
            ;
    }

    private ProtocolConnection hwcon;
    private boolean joined = false;
    private boolean ircJoined = false;

    private void collectFurtherInfo() {
        hwcon.sendPing();
        hwcon.processNextClientFlagsMessages();
    }

    public void onPing() {
        send("PING :" + globalServerName);
    }

    public void onPong() {
        if (!ircPingQueue.isEmpty())
                send(":" + globalServerName + " PONG " + globalServerName
                        + " :" + ircPingQueue.remove(0));
            
    }

    public void onConnectionLoss() {
        quit("Connection Loss");
    }

    public void onDisconnect(final String reason) {
        quit(reason);
    }

    public String onPasswordHashNeededForAuth() {
        return passwordHash;
    }

    public void onMalformedMessage(String contents)
    {
        this.logError("MALFORMED MESSAGE: " + contents);
    }

    public void onChat(final String user, final String message) {
        String ircId;
        Player player = allPlayers.get(user);
        if (player == null) {
            // fake user - so probably a notice
            sendChannelNotice(message, hwToIrcNick(user));
            //logWarning("onChat(): Couldn't find player with specified nick! nick: " + user);
            //send(":" + hw404NickToIrcId(user) + " PRIVMSG "
                     //+ LOBBY_CHANNEL_NAME + " :" + hwActionToIrc(message));
        }
        else
            send(":" + player.getIrcId() + " PRIVMSG "
                     + LOBBY_CHANNEL_NAME + " :" + hwActionToIrc(message));
    }

    public void onWelcomeMessage(final String message) {
    }

    public void onNotice(int number) {
    }

    public void onBanListEntry(BanType type, String target, String duration, String reason) {
        // TODO
    }
    public void onBanListEnd() {
        // TODO
    }

    public String onNickCollision(final String nick) {
        return nick + "_";
    }

    public void onNickSet(final String nick) {
        final String newNick = hwToIrcNick(nick);
        // tell irc client
        send(":" + ownIrcNick + "!~" + username + "@"
                            + hostname + " NICK :" + nick);
        ownIrcNick = newNick;
        updateLogPrefix();
        logInfo("Nickname set to " + nick);
    }

    private void flagAsInLobby(final Player player) {
        if (!ircJoined)
            return;
        final String ircNick = player.ircNick;
        if (player.isServerAdmin())
            send(":room-part!~@~ MODE " + LOBBY_CHANNEL_NAME + " -h+o " + ircNick + " " + ircNick);
        //else
            //send(":room-part!~@~ MODE " + LOBBY_CHANNEL_NAME + " +v " + ircNick);
    }

    private void flagAsInRoom(final Player player) {
        if (!ircJoined)
            return;
        final String ircNick = player.ircNick;
        if (player.isServerAdmin())
            send(":room-join!~@~ MODE " + LOBBY_CHANNEL_NAME + " -o+h " + ircNick + " " + ircNick);
        //else
            //send(":room-join!~@~ MODE " + LOBBY_CHANNEL_NAME + " -v " + ircNick);
    }

// TODO somewhere: escape char for magic chars!

// TODO /join with playername => FOLLOW :D

    public void sendPlayerMode(final Player player) {
        char c;
        if (player.isServerAdmin())
            c = player.inRoom?'h':'o';
        else if (player.isRegistered())
            c = 'v';
        else
            // no mode
            return;

        send(":server-join!~@~ MODE " + LOBBY_CHANNEL_NAME + " +" + c + " " + player.ircNick);
    }

    private Player ownPlayer = null;

    public void onLobbyJoin(final String[] users) {

        final List<Player> newPlayers = new ArrayList<Player>(users.length);

        // process joins
        for (final String user : users) {
            final Player player = new Player(user);
            if (ownPlayer == null)
                ownPlayer = player;
            newPlayers.add(player);
            allPlayers.put(user, player);
        }

        // make sure we get the client flags before we announce anything
        collectFurtherInfo();

        // get player info
        // NOTE: if player is in room, then info was already retrieved
        for (final Player player : newPlayers) {
            if (!player.inRoom)
                hwcon.requestInfo(player.nick);
        }

        /* DISABLED - we'll announce later - when receiving info
        // announce joins
        if (ircJoined) {
            for (final Player player : newPlayers) {
                final String ircId = player.getIrcId();
                send(":" + ircId
                         + " JOIN "+ lobbyChannel.name);
                sendPlayerMode(player);
            }
        }
        */
        if (!ircJoined) {
            // don't announced players that were there before join already
            for (final Player player : newPlayers) {
                player.setAnnounced();
            }
        }

        if (!joined) {
            joined = true;
            // forget password hash, we don't need it anymore.
            passwordHash = "";
            logInfo("Hedgewars server/lobby joined.");
            sendSelfNotice("Hedgewars server was joined successfully");
            // do this after join so that rooms can be assigned to their owners
            hwcon.requestRoomsList();
        }
    }

    private void makeIrcJoinLobby() {
            sendGlobal("INVITE " + ownIrcNick + " " + LOBBY_CHANNEL_NAME);
            try{Thread.sleep(3000);}catch(Exception e){}
            join(lobbyChannel.name);
            sendSelfNotice("Joining lobby-channel: " + lobbyChannel.name);
    }

    private void announcePlayerJoinLobby(final Player player) {
            player.setAnnounced();
            send(":" + player.getIrcId()
                     + " JOIN "+ lobbyChannel.name);
            sendPlayerMode(player);
    }

    public void onLobbyLeave(final String user, final String reason) {
        final Player player = allPlayers.get(user);
        if (player == null) {
            logWarning("onLobbyLeave(): Couldn't find player with specified nick! nick: " + user);
            sendIfJoined(":" + hw404NickToIrcId(user)
                 + " PART " + lobbyChannel.name + " " + reason);
        }
        else {
            if (ircJoined && player.needsAnnounce())
                announcePlayerJoinLobby(player);
            sendIfJoined(":" + player.getIrcId()
                 + " PART " + lobbyChannel.name + " " + reason);
            allPlayers.remove(user);
        }
    }

    private int lastRoomId = 0;

    public void onRoomInfo(final String name, final String flags,
                           final String newName, final int nUsers,
                           final int nTeams, final String owner,
                           final String map, final String style,
                           final String scheme, final String weapons) {

        Room room = roomsByName.get(name);

        if (room == null) {
            // try to reuse old ids
            if (lastRoomId >= 90)
                lastRoomId = 9;

            // search for first free
            while(roomsById.containsKey(++lastRoomId)) { }

            room = new Room(lastRoomId, newName, owner);
            roomsById.put(lastRoomId, room);
            roomsByName.put(newName, room);
            roomsSorted.add(room);
        }
        else if (!room.name.equals(newName)) {
            room.name = newName;
            roomsByName.put(newName, roomsByName.remove(name));
        }

        // update data
        room.setOwner(owner);
        room.nPlayers = nUsers;
        room.nTeams = nTeams;
    }

    public void onRoomDel(final String name) {
        final Room room = roomsByName.remove(name);

        if (room != null) {
            roomsById.remove(room.id);
            roomsSorted.remove(room);
        }
    }

    public void onRoomJoin(final String[] users) {
    }

    public void onRoomLeave(final String[] users) {
    }

    // TODO vector that remembers who's info was requested for manually
    List<String> requestedInfos =  new Vector<String>();

    public void onUserInfo(final String user, final String ip, final String version, final String room) {
        Player player = allPlayers.get(user);
        if (player != null) {
            player.setInfo(ip, version, room);
            if (ircJoined) {
                if (player.needsAnnounce())
                    announcePlayerJoinLobby(player);
            }
            else {
                if (player == ownPlayer) {
                    
                    makeIrcJoinLobby();
                }
            }
        }

        // if MANUAL send notice
        if (requestedInfos.remove(user)) {
            final String nick = hwToIrcNick(user);
            sendServerNotice(nick + " - " + buildInfoString(ip, version, room));
        }
    }

    public void onUserFlagChange(final String user, final UserFlagType flag, final boolean newValue) {
        final Player player = allPlayers.get(user);
        if (player == null) {
            logError("onUserFlagChange(): Couldn't find player with specified nick! nick: " + user);
            return;
        }
        switch (flag) {
            case ADMIN:
                player.setServerAdmin(newValue);
                if (newValue) {
                    logDebug(user + " is server admin");
                    //sendIfJoined(":server!~@~ MODE " + LOBBY_CHANNEL_NAME + " -v+o " + player.ircNick + " " + player.ircNick);
                }
                break;
            case INROOM:
                player.inRoom = newValue;
                if (newValue) {
                    flagAsInRoom(player);
                    logDebug(user + " entered a room");
                    // get new room info
                    hwcon.requestInfo(player.nick);
                }
                else {
                    flagAsInLobby(player);
                    logDebug(user + " returned to lobby");
                    player.inRoom = false;
                }
                break;
            case REGISTERED:
                player.setRegistered(newValue);
                break;
            default: break;
        }
    }

    public class Channel
    {
        private String topic;
        private final String name;
        private final Map<String, Player> players;

        public Channel(final String name, final String topic, final Map<String, Player> players) {
            this.name = name;
            this.topic = topic;
            this.players = players;
        }
    }

    public void logInfo(final String message) {
        System.out.println(this.logPrefix + ": " + message);
    }

    public void logDebug(final String message) {
        System.out.println(this.logPrefix + "| " + message);
    }

    public void logWarning(final String message) {
        System.err.println(this.logPrefix + "? " + message);
    }

    public void logError(final String message) {
        System.err.println(this.logPrefix + "! " + message);
    }


    //private static final Object mutex = new Object();
    private boolean joinSent = false;
    private Socket socket;
    private String username;
    private String ownIrcNick;
    private String description;
    private static Map<String, Connection> connectionMap = new HashMap<String, Connection>();
    // TODO those MUST NOT be static!
    //private Map<String, Channel> channelMap = new HashMap<String, Channel>();
    private final Channel lobbyChannel;
    private static String globalServerName;
    private String logPrefix;
    private final String clientId;
    private String passwordHash = "";

    private final Connection thisConnection;

    public Connection(Socket socket, final String clientId) throws Exception
    {
        this.ownIrcNick = "NONAME";
        this.socket = socket;
        this.hostname = ((InetSocketAddress)socket.getRemoteSocketAddress())
                 .getAddress().getHostAddress();
        this.clientId = clientId;
        updateLogPrefix();
        thisConnection = this;
        logInfo("New Connection");

        this.hwcon = null;

        try {
            this.hwcon = new ProtocolConnection(this, SERVER_HOST);
            logInfo("Connection to " + SERVER_HOST + " established.");
        }
        catch(Exception ex) {
            final String errmsg = "Could not connect to " + SERVER_HOST + ": "
                + ex.getMessage();
            logError(errmsg);
            sendQuit(errmsg);
        }

        final String lobbyTopic = " # " + SERVER_HOST + " - HEDGEWARS SERVER LOBBY # ";
        this.lobbyChannel = new Channel(LOBBY_CHANNEL_NAME, lobbyTopic, allPlayers);

        // start in new thread
        if (hwcon != null) {
            (this.hwcon.processMessages(true)).start();
        }
    }
    
    private void updateLogPrefix() {
        if (ownIrcNick == null)
            this.logPrefix = clientId + " ";
        else
            this.logPrefix = clientId + " [" + ownIrcNick + "] ";
    }

    private void setNick(final String nick) {
        if (passwordHash.isEmpty()) {
            try {
              final Properties authProps = new Properties();
              final String authFile = this.hostname + ".auth";
              logInfo("Attempting to load auth info from " + authFile);
              authProps.load(new FileInputStream(authFile));
              passwordHash = authProps.getProperty(nick, "");
              if (passwordHash.isEmpty())
                logInfo("Auth info file didn't contain any password hash for: " + nick);
            } catch (IOException e) {
                logInfo("Auth info file couldn't be loaded.");
            }
        }

        // append _ just in case
        if (!passwordHash.isEmpty() || nick.endsWith("_")) {
            ownIrcNick = nick;
            hwcon.setNick(ircToHwNick(nick));
        }
        else {
            final String nick_ = nick + "_";
            ownIrcNick = nick_;
            hwcon.setNick(ircToHwNick(nick_));
        }
    }

    public String getRepresentation()
    {
        return ownIrcNick + "!~" + username + "@" + hostname;
    }

    private static int lastClientId = 0;

    /**
     * @param args
     */
    public static void main(String[] args) throws Throwable
    {
        if (args.length > 0)
        {
            SERVER_HOST = args[0];
        }
        if (args.length > 1)
        {
            IRC_PORT = Integer.parseInt(args[1]);
        }

        globalServerName = "hw2irc";

        if (!SERVER_HOST.equals(DEFAULT_SERVER_HOST))
            globalServerName += "~" + SERVER_HOST;

        final int port = IRC_PORT;
        ServerSocket ss = new ServerSocket(port);
        System.out.println("Listening on port " + port);
        while (true)
        {
            Socket s = ss.accept();
            final String clientId = "client" + (++lastClientId) + '-'
                 + ((InetSocketAddress)s.getRemoteSocketAddress())
                 .getAddress().getHostAddress();
            try {
                Connection clientCon = new Connection(s, clientId);
                //clientCon.run();
                Thread clientThread = new Thread(clientCon, clientId);
                clientThread.start();
            }
            catch (Exception ex) {
                System.err.println("FATAL: Server connection thread " + clientId + " crashed on startup! " + ex.getMessage());
                ex.printStackTrace();
            }

            System.out.println("Note: Not accepting new clients for the next " + SLEEP_BETWEEN_LOGIN_DURATION + "s, trying to avoid reconnecting too quickly.");
            Thread.sleep(SLEEP_BETWEEN_LOGIN_DURATION * 1000);
            System.out.println("Note: Accepting clients again!");
        }
    }

    private static final int SLEEP_BETWEEN_LOGIN_DURATION = 122;

    private boolean hasQuit = false;

    public synchronized void quit(final String reason) {
        if (hasQuit)
            return;

        hasQuit = true;
        // disconnect from hedgewars server
        if (hwcon != null)
            hwcon.disconnect(reason);
        // disconnect irc client
        sendQuit("Quit: " + reason);
        // wait some time so that last data can be pushed
        try {
            Thread.sleep(200);
        }
        catch (Exception e) { }
        // terminate
        terminateConnection = true;
    }


    private static String hwActionToIrc(final String chatMsg) {
        if (!chatMsg.startsWith("/me ") || (chatMsg.length() <= 4))
            return chatMsg;

        return MAGIC_BYTE_ACTION + "ACTION " + chatMsg.substring(4) + MAGIC_BYTE_ACTION;
    }

    private static String ircActionToHw(final String chatMsg) {
        if (!chatMsg.startsWith(MAGIC_BYTE_ACTION + "ACTION ") || (chatMsg.length() <= 9))
            return chatMsg;

        return "/me " + chatMsg.substring(8, chatMsg.length() - 1);
    }

// TODO: why is still still being called when joining bogus channel name?
    public void join(String channelName)
    {
        if (ownPlayer == null) {
            sendSelfNotice("Trying to join while ownPlayer == null. Aborting!");
            quit("Something went horribly wrong.");
            return;
        }


        final Channel channel = getChannel(channelName);

        // TODO reserve special char for creating a new ROOM
        // it will be named after the player name by default
        // can be changed with /topic after

        // not a valid channel
        if (channel == null) {
            sendSelfNotice("You cannot manually create channels here.");
            sendGlobal(ERR_NOSUCHCHANNEL + ownIrcNick + " " + channel.name
                    + " :No such channel");
            return;
        }

        // TODO if inRoom "Can't join rooms while still in room"

        // TODO set this based on room host/admin mode maybe

/* :testuser2131!~r@asdasdasdasd.at JOIN #asdkjasda
:weber.freenode.net MODE #asdkjasda +ns
:weber.freenode.net 353 testuser2131 @ #asdkjasda :@testuser2131
:weber.freenode.net 366 testuser2131 #asdkjasda :End of /NAMES list.
:weber.freenode.net NOTICE #asdkjasda :[freenode-info] why register and identify? your IRC nick is how people know you. http://freenode.net/faq.shtml#nicksetup

*/ 
        send(":" + ownPlayer.getIrcId() + " JOIN "
         + channelName);

        //send(":sheeppidgin!~r@localhost JOIN " + channelName);

        ircJoined = true;

        sendGlobal(":hw2irc MODE #lobby +nt");

        sendTopic(channel);

        sendNames(channel);

    }

    private void sendTopic(final Channel channel) {
        if (channel.topic != null)
            sendGlobal(RPL_TOPIC + ownIrcNick + " " + channel.name
                    + " :" + channel.topic);
        else
            sendGlobal(RPL_NOTOPIC + ownIrcNick + " " + channel.name
                    + " :No topic is set");
    }

    private void sendNames(final Channel channel) {
        // There is no error reply for bad channel names.

        if (channel != null) {
            // send player list
            for (final Player player : channel.players.values()) {

                final String prefix;

                if (player.isServerAdmin())
                    prefix = (player.isServerAdmin())?"@":"%";
                else
                    prefix = (player.isRegistered())?"+":"";

                sendGlobal(RPL_NAMREPLY + ownIrcNick + " = " + channel.name
                        + " :" + prefix + player.ircNick);
            }
        }

        sendGlobal(RPL_ENDOFNAMES + ownIrcNick + " " + channel.name
                + " :End of /NAMES list");
    }

    private void sendList(final String filter) {
        // id column size
        //int idl = 1 + String.valueOf(lastRoomId).length();

        //if (idl < 3)
            //idl = 3;

        // send rooms list
        sendGlobal(RPL_LISTSTART + ownIrcNick 
            //+ String.format(" %1$" + idl + "s  #P  #T  Name", "ID"));
            + String.format(" %1$s #P #T Name", "ID"));

        if (filter.isEmpty() || filter.equals(".")) {
            // lobby
            if (filter.isEmpty())
                sendGlobal(RPL_LIST + ownIrcNick + " " + LOBBY_CHANNEL_NAME
                    + " " + allPlayers.size() + " :" + lobbyChannel.topic);

            // room list could be changed by server while we reply client
            synchronized (roomsSorted) {
                for (final Room room : roomsSorted) {
                    sendGlobal(RPL_LIST + ownIrcNick
                        //+ String.format(" %1$" + idl + "s  %2$2d  :%3$2d  %4$s",
                        + String.format(" %1$s %2$d :%3$d  %4$s",
                            room.chan, room.nPlayers, room.nTeams, room.name));
                }
            }
        }
        // TODO filter

        sendGlobal(RPL_LISTEND + ownIrcNick + " " + " :End of /LIST");
    }

    private List<Player> findPlayers(final String expr) {
        List<Player> matches = new ArrayList<Player>(allPlayers.size());

        try {
            final int flags = Pattern.CASE_INSENSITIVE + Pattern.UNICODE_CASE;
            final Pattern regx = Pattern.compile(expr, flags);

            for (final Player p : allPlayers.values()) {
                if ((regx.matcher(p.nick).find())
                    || (regx.matcher(p.ircId).find())
                    //|| (regx.matcher(p.version).find())
                    //|| ((p.ip.length() > 2) && regx.matcher(p.ip).find())
                    || (!p.getRoom().isEmpty() && regx.matcher(p.getRoom()).find())
                ) matches.add(p);
            }
        }
        catch(PatternSyntaxException ex) {
            sendSelfNotice("Pattern not understood: " + ex.getMessage());
        }

        return matches;
    }

    private String buildInfoString(final String ip, final String version, final String room) {
        return (ip.equals("[]")?"":ip + " ") + version + (room.isEmpty()?"":" " + room);
    }

    private void sendWhoForPlayer(final Player player) {
        sendWhoForPlayer(LOBBY_CHANNEL_NAME, player.ircNick, (player.inRoom?player.getRoom():""), player.getIrcHostname());
    }

    private void sendWhoForPlayer(final Player player, final String info) {
        sendWhoForPlayer(LOBBY_CHANNEL_NAME, player.ircNick, info, player.getIrcHostname());
    }

    private void sendWhoForPlayer(final String nick, final String info) {
        sendWhoForPlayer(LOBBY_CHANNEL_NAME, nick, info);
    }

    private void sendWhoForPlayer(final String channel, final String nick, final String info) {
        final Player player = allPlayers.get(nick);

        if (player == null)
            sendWhoForPlayer("OFFLINE", hwToIrcNick(nick), info, "hw/offline");
        else
            sendWhoForPlayer(channel,   player.ircNick,    info, player.getIrcHostname());
    }

    private void sendWhoForPlayer(final String channel, final String ircNick, final String info, final String hostname) {
        sendGlobal(RPL_WHOREPLY + channel + " " + channel
                            + " ~" + ircNick + " " + hostname
                            + " " + globalServerName + " " + ircNick
                            + " H :0 " + info);
    }

    private void sendWhoEnd(final String ofWho) {
        send(RPL_ENDOFWHO + ownIrcNick + " " + ofWho
                        + " :End of /WHO list.");
    }

    private void sendMotd() {
        sendGlobal(RPL_MOTDSTART + ownIrcNick + " :- Message of the Day -");
        final String mline = RPL_MOTD + ownIrcNick + " :";
        for(final String line : DEFAULT_MOTD) {
            sendGlobal(mline + line);
        }
        sendGlobal(RPL_ENDOFMOTD + ownIrcNick + " :End of /MOTD command.");
    }

    private Channel getChannel(final String name) {
        if (name.equals(LOBBY_CHANNEL_NAME)) {
            return lobbyChannel;
        }

        return null;
    }

    private enum Command
    {
        PASS(1, 1)
        {
            @Override
            public void run(final Connection con, final String prefix, final String[] args)
                    throws Exception
            {
                con.passwordHash = args[0];
            }
        },
        NICK(1, 1)
        {
            @Override
            public void run(final Connection con, final String prefix, final String[] args)
                    throws Exception
            {
                con.setNick(args[0]);
            }
        },
        USER(1, 4)
        {
            @Override
            public void run(final Connection con, final String prefix, final String[] args)
                    throws Exception
            {
                if (con.username != null)
                {
                    con.send("NOTICE AUTH :You can't change your user "
                            + "information after you've logged in right now.");
                    return;
                }
                con.username = args[0];
                String forDescription = args.length > 3 ? args[3]
                        : "(no description)";
                con.description = forDescription;
                /*
                 * Now we'll send the user their initial information.
                 */
                con.sendGlobal(RPL_WELCOME + con.ownIrcNick + " :Welcome to "
                        + globalServerName + " - " + DESCRIPTION_SHORT);
                con.sendGlobal("004 " + con.ownIrcNick + " " + globalServerName
                        + " " + VERSION);

                con.sendMotd();

            }
        },
        MOTD(0, 0)
        {
            @Override
            public void run(final Connection con, final String prefix, final String[] args)
                    throws Exception
            {
                con.sendMotd();
            }
        },
        PING(1, 1)
        {
            @Override
            public void run(final Connection con, final String prefix, final String[] args)
                    throws Exception
            {
                con.ircPingQueue.add(args[0]);
                con.hwcon.sendPing();
            }
        },
        PONG(1, 2)
        {
            @Override
            public void run(final Connection con, final String prefix, final String[] args)
                    throws Exception
            {
                con.hwcon.sendPong();
            }
        },
        NAMES(1, 1)
        {
            @Override
            public void run(final Connection con, final String prefix, final String[] args)
                    throws Exception
            {
                final Channel channel = con.getChannel(args[0]);
                con.sendNames(channel);
            }
        },
        LIST(0, 2)
        {
            @Override
            public void run(final Connection con, final String prefix, final String[] args)
                    throws Exception
            {
                // TODO filter by args[1] (comma sep list of chans), make # optional
                // ignore args[1] (server), TODO: maybe check and send RPL_NOSUCHSERVER if wrong
                con.sendList(args.length > 0?args[0]:"");
            }
        },
        JOIN(1, 2)
        {
            @Override
            public void run(final Connection con, final String prefix, final String[] args)
                    throws Exception
            {
                if (args.length < 1)  {
                    con.sendSelfNotice("You didn't specify what you want to join!");
                    return;
                }

                if (con.ownPlayer == null) {
                    con.sendSelfNotice("Lobby is not ready to be joined yet - hold on a second!");
                    return;
                }

                if (args[0].equals(LOBBY_CHANNEL_NAME)) {
                    //con.sendSelfNotice("Lobby can't be joined manually!");
                    con.join(LOBBY_CHANNEL_NAME);
                    return;
                }
                con.sendSelfNotice("Joining rooms is not supported yet, sorry!");
            }
        },
        WHO(0, 2)
        {
            @Override
            public void run(final Connection con, final String prefix, final String[] args)
                    throws Exception
            {
                if (args.length < 1)
                    return;

                final String target = args[0];

                Map<String, Player> players = null;

                if (target.equals(LOBBY_CHANNEL_NAME)) {
                    players = con.allPlayers;
                }
                // on channel join WHO is called on channel
                else if (target.equals(ROOM_CHANNEL_NAME)) {
                    players = con.roomPlayers;
                }

                if (players != null) {
                    for (final Player player : players.values()) {
                        con.sendWhoForPlayer(player);
                    }
                }
                // not a known channel. assume arg is player name
                // TODO support search expressions!
                else {
                    final String nick = ircToHwNick(target);
                    final Player player = con.allPlayers.get(nick);
                    if (player != null)
                        con.sendWhoForPlayer(player);
                    else {
                        con.sendSelfNotice("WHO: No player named " + nick + ", interpreting term as pattern.");
                        List<Player> matches = con.findPlayers(target);
                        if (matches.isEmpty())
                            con.sendSelfNotice("No Match.");
                        else {
                            for (final Player match : matches) {
                                con.sendWhoForPlayer(match);
                            }
                        }
                    }
                }

                con.sendWhoEnd(target);
            }
        },
        WHOIS(1, 2)
        {
            @Override
            public void run(final Connection con, final String prefix, final String[] args)
                    throws Exception
            {
                // there's an optional param in the beginning that we don't care about
                final String targets = args[args.length-1];
                for (final String target : targets.split(",")) {
                    if (target.isEmpty())
                        continue;
                    final String nick = ircToHwNick(target);
                    // flag this nick as manually requested, so that response is shown
                    if (con.ircJoined) {
                        con.requestedInfos.add(nick);
                        con.hwcon.requestInfo(nick);
                    }

                    final Player player = con.allPlayers.get(nick);
                    if (player != null) {
                        con.send(RPL_WHOISUSER + con.ownIrcNick + " " + target + " ~"
                                + target + " " + player.getIrcHostname() + " * : "
                                + player.ircNick);
                        // TODO send e.g. channels: @#lobby   or   @#123
                        con.send(RPL_ENDOFWHOIS + con.ownIrcNick + " " + target 
                                + " :End of /WHOIS list.");
                    }
                }
            }
        },
        USERHOST(1, 5)
        {
            @Override
            public void run(final Connection con, final String prefix, final String[] args)
                    throws Exception
            {
                /*
                // TODO set server host
                con.hostname = "hw/" + SERVER_HOST;
                
                ArrayList<String> replies = new ArrayList<String>();
                for (String s : arguments)
                {
                    Connection user = connectionMap.get(s);
                    if (user != null)
                        replies.add(user.nick + "=+" + con.ownIrc + "@"
                                + con.hostname);
                }
                con.sendGlobal(RPL_USERHOST + con.ownIrcNick + " :"
                        + delimited(replies.toArray(new String[0]), " "));
                */
            }
        },
        MODE(0, 2)
        {
            @Override
            public void run(final Connection con, final String prefix, final String[] args)
                    throws Exception
            {
                final boolean forChan = args[0].startsWith("#");
                
                if (args.length == 1)
                {
                    if (forChan) {
                        //con.sendGlobal(ERR_NOCHANMODES + args[0]
                        //                + " :Channel doesn't support modes");
                        con.sendGlobal(RPL_CHANNELMODEIS + con.ownIrcNick + " " + args[0]
                                + " +nt");
                    }
                    else
                    {
                        // TODO
                        con.sendSelfNotice("User mode querying not supported yet.");
                    }
                }
                else if (args.length == 2) {

                    if (forChan) {

                        final int l = args[1].length();

                        for (int i = 0; i < l; i++) {

                            final char c = args[1].charAt(i);  

                            switch (c) {
                                case '+':
                                    // skip
                                    break;
                                case '-':
                                    // skip
                                    break;
                                case 'b':
                                    con.sendGlobal(RPL_ENDOFBANLIST
                                        + con.ownIrcNick + " " + args[0]
                                        + " :End of channel ban list");
                                    break;
                                case 'e':
                                    con.sendGlobal(RPL_ENDOFEXCEPTLIST
                                        + con.ownIrcNick + " " + args[0]
                                        + " :End of channel exception list");
                                    break;
                                default:
                                    con.sendGlobal(ERR_UNKNOWNMODE + c
                                        + " :Unknown MODE flag " + c);
                                    break;
                                    
                            }
                        }
                    }
                    // user mode
                    else {
                        con.sendGlobal(ERR_UMODEUNKNOWNFLAG + args[0]
                                        + " :Unknown MODE flag");
                    }
                }
                else
                {
                    con.sendSelfNotice("Specific modes not supported yet.");
                }
            }
        },
        PART(1, 2)
        {
            @Override
            public void run(final Connection con, final String prefix, final String[] args)
                    throws Exception
            {
                String[] channels = args[0].split(",");
                boolean doQuit = false;

                for (String channelName : channels)
                {
                    if (channelName.equals(LOBBY_CHANNEL_NAME)) {
                        doQuit = true;
                    }
                    // TODO: part from room
                    /*
                    synchronized (mutex)
                    {
                        Channel channel = channelMap.get(channelName);
                        if (channelName == null)
                            con
                                    .sendSelfNotice("You're not a member of the channel "
                                            + channelName
                                            + ", so you can't part it.");
                        else
                        {
                            channel.send(":" + con.getRepresentation()
                                    + " PART " + channelName);
                            channel.channelMembers.remove(con);
                            if (channel.channelMembers.size() == 0)
                                channelMap.remove(channelName);
                        }
                    }
                    */
                }

                final String reason;

                if (args.length > 1)
                    reason = args[1];
                else
                    reason = DEFAULT_QUIT_REASON;

                // quit after parting
                if (doQuit)
                    con.quit(reason);
            }
        },
        QUIT(0, 1)
        {
            @Override
            public void run(final Connection con, final String prefix, final String[] args)
                    throws Exception
            {
                final String reason;

                if (args.length == 0)
                    reason = DEFAULT_QUIT_REASON;
                else
                    reason = args[0];

                con.quit(reason);
            }
        },
        PRIVMSG(2, 2)
        {
            @Override
            public void run(final Connection con, final String prefix, final String[] args)
                    throws Exception
            {
                String message = ircActionToHw(args[1]);
                if (message.charAt(0) == CHAT_COMMAND_CHAR) {
                    if (message.length() < 1 )
                        return;
                    message = message.substring(1);
                    // TODO maybe \rebind CUSTOMCMDCHAR command
                    con.hwcon.sendCommand(con.ircToHwNick(message));
                }
                else
                    con.hwcon.sendChat(con.ircToHwNick(message));
            }
        },
        TOPIC(1, 2)
        {
            @Override
            public void run(final Connection con, final String prefix, final String[] args)
                    throws Exception
            {
                final String chan = args[0];

                final Channel channel = con.getChannel(chan);

                if (channel == null) {
                    con.sendSelfNotice("No such channel for topic viewing: "
                            + chan);
                    return;
                }

                // The user wants to see the channel topic.
                if (args.length == 1)
                    con.sendTopic(channel);
                // The user wants to set the channel topic.
                else
                    channel.topic = args[1];
            }
        },
        KICK(3, 3)
        {
            @Override
            public void run(final Connection con, final String prefix, final String[] args)
                    throws Exception
            {
                final String victim = args[1];
                con.logInfo("Issuing kick for " + victim);
                // "KICK #channel nick :kick reason (not relevant)"
                con.hwcon.kick(ircToHwNick(victim));
            }
        }
        ;
        public final int minArgumentCount;
        public final int maxArgumentCount;
        
        private Command(int min, int max)
        {
            minArgumentCount = min;
            maxArgumentCount = max;
        }

        public abstract void run(Connection con, String prefix,
                String[] arguments) throws Exception;
    }
    
    public static String delimited(String[] items, String delimiter)
    {
        StringBuffer response = new StringBuffer();
        boolean first = true;
        for (String s : items)
        {
            if (first)
                first = false;
            else
                response.append(delimiter);
            response.append(s);
        }
        return response.toString();
    }
    
    protected void sendQuit(String quitMessage)
    {
        send(":" + getRepresentation() + " QUIT :" + quitMessage);
    }
    
    @Override
    public void run()
    {
        try
        {
            doServer();
        }
        catch (Exception e) {
            e.printStackTrace();
        }
        finally
        {
            // TODO sense?
            if (ownIrcNick != null && connectionMap.get(ownIrcNick) == this) {
                quit("Client disconnected.");
            }

            try {
                socket.close();
            }
            catch (Exception e) { }

            quit("Connection terminated.");
        }
    }
    
    protected void sendGlobal(String string)
    {
        send(":" + globalServerName + " " + string);
    }
    
    private LinkedBlockingQueue<String> outQueue = new LinkedBlockingQueue<String>(
            1000);
    
    private Thread outThread = new Thread()
    {
        public void run()
        {
            try
            {
                OutputStream out = socket.getOutputStream();
                while (!terminateConnection)
                {
                    String s = outQueue.take();
                    s = s.replace("\n", "").replace("\r", "");
                    s = s + "\r\n";
                    out.write(s.getBytes());
                    out.flush();
                }
            }
            catch (Exception ex)
            {
                thisConnection.logError("Outqueue died");
                //ex.printStackTrace();
            }
            finally {
                outQueue.clear();
                outQueue = null;
                try
                {
                    socket.close();
                }
                catch (Exception e2)
                {
                    e2.printStackTrace();
                }
            }
        }
    };

    private boolean terminateConnection = false;

    private void doServer() throws Exception
    {
        outThread.start();
        InputStream socketIn = socket.getInputStream();
        BufferedReader clientReader = new BufferedReader(new InputStreamReader(
                socketIn));
        String line;
        while (!terminateConnection && ((line = clientReader.readLine()) != null))
        {
            processLine(line);
        }
    }

    public void sanitizeInputs(final String[] inputs) {

        // no for-each loop, because we need write access to the elements

        final int l = inputs.length;

        for (int i = 0; i < l; i++) {
            inputs[i] = inputs[i].replaceAll(MAGIC_BYTES, " ");
        }
    }

    private void processLine(final String line) throws Exception
    {
        String l = line;

        // log things
        if (l.startsWith("PASS") || l.startsWith("pass"))
            this.logInfo("IRC-Client provided PASS");
        else
            this.logDebug("IRC-Client: " + l);

        String prefix = "";
        if (l.startsWith(":"))
        {
            String[] tokens = l.split(" ", 2);
            prefix = tokens[0];
            l = (tokens.length > 1 ? tokens[1] : "");
        }
        String[] tokens1 = l.split(" ", 2);
        String command = tokens1[0];
        l = tokens1.length > 1 ? tokens1[1] : "";
        String[] tokens2 = l.split("(^| )\\:", 2);
        String trailing = null;
        l = tokens2[0];
        if (tokens2.length > 1)
            trailing = tokens2[1];
        ArrayList<String> argumentList = new ArrayList<String>();
        if (!l.equals(""))
            argumentList.addAll(Arrays.asList(l.split(" ")));
        if (trailing != null)
            argumentList.add(trailing);
        final String[] args = argumentList.toArray(new String[0]);

        // process command

        // numeric commands
        if (command.matches("[0-9][0-9][0-9]"))
            command = "N" + command;

        final Command commandObject;

        try {
            commandObject = Command.valueOf(command.toUpperCase());
        }
        catch (Exception ex) {
            // forward raw unknown command to hw server
            hwcon.sendCommand(ircToHwNick(line));
            return;
        }

        if (args.length < commandObject.minArgumentCount
                || args.length > commandObject.maxArgumentCount)
        {
            sendSelfNotice("Invalid number of arguments for this"
                    + " command, expected not more than "
                    + commandObject.maxArgumentCount + " and not less than "
                    + commandObject.minArgumentCount + " but got " + args.length
                    + " arguments");
            return;
        }
        commandObject.run(this, prefix, args);
    }

    /**
     * Sends a notice from the server to the user represented by this
     * connection.
     * 
     * @param string
     *            The text to send as a notice
     */

    private void sendSelfNotice(final String string)
    {
        send(":" + globalServerName + " NOTICE " + ownIrcNick + " :" + string);
    }

    private void sendChannelNotice(final String string) {
        sendChannelNotice(string, globalServerName);
    }

    private void sendChannelNotice(final String string, final String from) {
        // TODO send to room if user is in room
        send(":" + from + " NOTICE " + LOBBY_CHANNEL_NAME + " :" + string);
    }

    private void sendServerNotice(final String string)
    {
        if (ircJoined)
            sendChannelNotice(string, "[INFO]");

        sendSelfNotice(string);
    }

    private String[] padSplit(final String line, final String regex, int max)
    {
        String[] split = line.split(regex);
        String[] output = new String[max];
        for (int i = 0; i < output.length; i++)
        {
            output[i] = "";
        }
        for (int i = 0; i < split.length; i++)
        {
            output[i] = split[i];
        }
        return output;
    }

    public void sendIfJoined(final String s) {
        if (joined)
            send(s);
    }

    public void send(final String s)
    {
        final Queue<String> testQueue = outQueue;
        if (testQueue != null)
        {
            this.logDebug("IRC-Server: " + s);
            testQueue.add(s);
        }
    }

final static String RPL_WELCOME = "001 ";
final static String RPL_YOURHOST = "002 ";
final static String RPL_CREATED = "003 ";
final static String RPL_MYINFO = "004 ";
final static String RPL_BOUNCE = "005 ";
final static String RPL_TRACELINK = "200 ";
final static String RPL_TRACECONNECTING = "201 ";
final static String RPL_TRACEHANDSHAKE = "202 ";
final static String RPL_TRACEUNKNOWN = "203 ";
final static String RPL_TRACEOPERATOR = "204 ";
final static String RPL_TRACEUSER = "205 ";
final static String RPL_TRACESERVER = "206 ";
final static String RPL_TRACESERVICE = "207 ";
final static String RPL_TRACENEWTYPE = "208 ";
final static String RPL_TRACECLASS = "209 ";
final static String RPL_TRACERECONNECT = "210 ";
final static String RPL_STATSLINKINFO = "211 ";
final static String RPL_STATSCOMMANDS = "212 ";
final static String RPL_STATSCLINE = "213 ";
final static String RPL_STATSNLINE = "214 ";
final static String RPL_STATSILINE = "215 ";
final static String RPL_STATSKLINE = "216 ";
final static String RPL_STATSQLINE = "217 ";
final static String RPL_STATSYLINE = "218 ";
final static String RPL_ENDOFSTATS = "219 ";
final static String RPL_UMODEIS = "221 ";
final static String RPL_SERVICEINFO = "231 ";
final static String RPL_ENDOFSERVICES = "232 ";
final static String RPL_SERVICE = "233 ";
final static String RPL_SERVLIST = "234 ";
final static String RPL_SERVLISTEND = "235 ";
final static String RPL_STATSVLINE = "240 ";
final static String RPL_STATSLLINE = "241 ";
final static String RPL_STATSUPTIME = "242 ";
final static String RPL_STATSOLINE = "243 ";
final static String RPL_STATSHLINE = "244 ";
final static String RPL_STATSPING = "246 ";
final static String RPL_STATSBLINE = "247 ";
final static String RPL_STATSDLINE = "250 ";
final static String RPL_LUSERCLIENT = "251 ";
final static String RPL_LUSEROP = "252 ";
final static String RPL_LUSERUNKNOWN = "253 ";
final static String RPL_LUSERCHANNELS = "254 ";
final static String RPL_LUSERME = "255 ";
final static String RPL_ADMINME = "256 ";
final static String RPL_ADMINEMAIL = "259 ";
final static String RPL_TRACELOG = "261 ";
final static String RPL_TRACEEND = "262 ";
final static String RPL_TRYAGAIN = "263 ";
final static String RPL_NONE = "300 ";
final static String RPL_AWAY = "301 ";
final static String RPL_USERHOST = "302 ";
final static String RPL_ISON = "303 ";
final static String RPL_UNAWAY = "305 ";
final static String RPL_NOWAWAY = "306 ";
final static String RPL_WHOISUSER = "311 ";
final static String RPL_WHOISSERVER = "312 ";
final static String RPL_WHOISOPERATOR = "313 ";
final static String RPL_WHOWASUSER = "314 ";
final static String RPL_ENDOFWHO = "315 ";
final static String RPL_WHOISCHANOP = "316 ";
final static String RPL_WHOISIDLE = "317 ";
final static String RPL_ENDOFWHOIS = "318 ";
final static String RPL_WHOISCHANNELS = "319 ";
final static String RPL_LISTSTART = "321 ";
final static String RPL_LIST = "322 ";
final static String RPL_LISTEND = "323 ";
final static String RPL_CHANNELMODEIS = "324 ";
final static String RPL_UNIQOPIS = "325 ";
final static String RPL_NOTOPIC = "331 ";
final static String RPL_TOPIC = "332 ";
final static String RPL_INVITING = "341 ";
final static String RPL_SUMMONING = "342 ";
final static String RPL_INVITELIST = "346 ";
final static String RPL_ENDOFINVITELIST = "347 ";
final static String RPL_EXCEPTLIST = "348 ";
final static String RPL_ENDOFEXCEPTLIST = "349 ";
final static String RPL_VERSION = "351 ";
final static String RPL_WHOREPLY = "352 ";
final static String RPL_NAMREPLY = "353 ";
final static String RPL_KILLDONE = "361 ";
final static String RPL_CLOSING = "362 ";
final static String RPL_CLOSEEND = "363 ";
final static String RPL_LINKS = "364 ";
final static String RPL_ENDOFLINKS = "365 ";
final static String RPL_ENDOFNAMES = "366 ";
final static String RPL_BANLIST = "367 ";
final static String RPL_ENDOFBANLIST = "368 ";
final static String RPL_ENDOFWHOWAS = "369 ";
final static String RPL_INFO = "371 ";
final static String RPL_MOTD = "372 ";
final static String RPL_INFOSTART = "373 ";
final static String RPL_ENDOFINFO = "374 ";
final static String RPL_MOTDSTART = "375 ";
final static String RPL_ENDOFMOTD = "376 ";
final static String RPL_YOUREOPER = "381 ";
final static String RPL_REHASHING = "382 ";
final static String RPL_YOURESERVICE = "383 ";
final static String RPL_MYPORTIS = "384 ";
final static String RPL_TIME = "391 ";
final static String RPL_USERSSTART = "392 ";
final static String RPL_USERS = "393 ";
final static String RPL_ENDOFUSERS = "394 ";
final static String RPL_NOUSERS = "395 ";
final static String ERR_NOSUCHNICK = "401 ";
final static String ERR_NOSUCHSERVER = "402 ";
final static String ERR_NOSUCHCHANNEL = "403 ";
final static String ERR_CANNOTSENDTOCHAN = "404 ";
final static String ERR_TOOMANYCHANNELS = "405 ";
final static String ERR_WASNOSUCHNICK = "406 ";
final static String ERR_TOOMANYTARGETS = "407 ";
final static String ERR_NOSUCHSERVICE = "408 ";
final static String ERR_NOORIGIN = "409 ";
final static String ERR_NORECIPIENT = "411 ";
final static String ERR_NOTEXTTOSEND = "412 ";
final static String ERR_NOTOPLEVEL = "413 ";
final static String ERR_WILDTOPLEVEL = "414 ";
final static String ERR_BADMASK = "415 ";
final static String ERR_UNKNOWNCOMMAND = "421 ";
final static String ERR_NOMOTD = "422 ";
final static String ERR_NOADMININFO = "423 ";
final static String ERR_FILEERROR = "424 ";
final static String ERR_NONICKNAMEGIVEN = "431 ";
final static String ERR_ERRONEUSNICKNAME = "432 ";
final static String ERR_NICKNAMEINUSE = "433 ";
final static String ERR_NICKCOLLISION = "436 ";
final static String ERR_UNAVAILRESOURCE = "437 ";
final static String ERR_USERNOTINCHANNEL = "441 ";
final static String ERR_NOTONCHANNEL = "442 ";
final static String ERR_USERONCHANNEL = "443 ";
final static String ERR_NOLOGIN = "444 ";
final static String ERR_SUMMONDISABLED = "445 ";
final static String ERR_USERSDISABLED = "446 ";
final static String ERR_NOTREGISTERED = "451 ";
final static String ERR_NEEDMOREPARAMS = "461 ";
final static String ERR_ALREADYREGISTRED = "462 ";
final static String ERR_NOPERMFORHOST = "463 ";
final static String ERR_PASSWDMISMATCH = "464 ";
final static String ERR_YOUREBANNEDCREEP = "465 ";
final static String ERR_YOUWILLBEBANNED = "466 ";
final static String ERR_KEYSET = "467 ";
final static String ERR_CHANNELISFULL = "471 ";
final static String ERR_UNKNOWNMODE = "472 ";
final static String ERR_INVITEONLYCHAN = "473 ";
final static String ERR_BANNEDFROMCHAN = "474 ";
final static String ERR_BADCHANNELKEY = "475 ";
final static String ERR_BADCHANMASK = "476 ";
final static String ERR_NOCHANMODES = "477 ";
final static String ERR_BANLISTFULL = "478 ";
final static String ERR_NOPRIVILEGES = "481 ";
final static String ERR_CHANOPRIVSNEEDED = "482 ";
final static String ERR_CANTKILLSERVER = "483 ";
final static String ERR_RESTRICTED = "484 ";
final static String ERR_UNIQOPPRIVSNEEDED = "485 ";
final static String ERR_NOOPERHOST = "491 ";
final static String ERR_NOSERVICEHOST = "492 ";
final static String ERR_UMODEUNKNOWNFLAG = "501 ";
final static String ERR_USERSDONTMATCH = "502 ";

}
