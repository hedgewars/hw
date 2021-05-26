/*
 * Java net client for Hedgewars, a free turn based strategy game
 * Copyright (c) 2011 Richard Karolyi <sheepluva@ercatec.net>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */

package net.ercatec.hw;

import java.lang.*;
import java.lang.IllegalArgumentException;
import java.lang.Runnable;
import java.lang.Thread;
import java.io.*;
import java.net.*;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Scanner;
import java.util.Vector;
// for auth
import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.security.NoSuchAlgorithmException;

public final class ProtocolConnection implements Runnable
{
    private static final String DEFAULT_HOST = "netserver.hedgewars.org";
    private static final int DEFAULT_PORT = 46631;
    private static final String PROTOCOL_VERSION = "53";

    private final Socket socket;
    private BufferedReader fromSvr;
    private PrintWriter toSvr;
    private final INetClient netClient;
    private boolean quit;
    private boolean debug;

    private final String host;
    private final int port;

    private String nick;

    public ProtocolConnection(INetClient netClient) throws Exception {
        this(netClient, DEFAULT_HOST);
    }

    public ProtocolConnection(INetClient netClient, String host) throws Exception {
        this(netClient, host, DEFAULT_PORT);
    }

    public ProtocolConnection(INetClient netClient, String host, int port) throws Exception {
        this.netClient = netClient;
        this.host = host;
        this.port = port;
        this.nick = nick = "";
        this.quit = false;

        fromSvr = null;
        toSvr = null;

        try {
            socket = new Socket(host, port);
            fromSvr = new BufferedReader(new InputStreamReader(socket.getInputStream()));
            toSvr = new PrintWriter(socket.getOutputStream(), true);
        }
        catch(Exception ex) {
            throw ex;
        }

        ProtocolMessage firstMsg = processNextMessage();
        if (firstMsg.getType() != ProtocolMessage.Type.CONNECTED) {
            closeConnection();
            throw new Exception("First Message wasn't CONNECTED.");
        }

    }

    public void run() {

        try {
            while (!quit) {
                processNextMessage();
            }
        }
        catch(Exception ex) {
            netClient.logError("FATAL: Run loop died unexpectedly!");
            ex.printStackTrace();
            handleConnectionLoss();
        }

        // only gets here when connection was closed
    }

    public void processMessages() {
        processMessages(false);
    }

    public Thread processMessages(boolean inNewThread)
    {
        if (inNewThread)
            return new Thread(this);

        run();
        return null;
    }

    public void processNextClientFlagsMessages()
    {
        while (!quit) {
            if (!processNextMessage(true).isValid)
                break;
        }
    }

    private ProtocolMessage processNextMessage() {
        return processNextMessage(false);
    }

    private void handleConnectionLoss() {
        closeConnection();
        netClient.onConnectionLoss();
    }

    public void close() {
        this.closeConnection();
    }

    private synchronized void closeConnection() {
        if (quit)
            return;

        quit = true;
        try {
            if (fromSvr != null)
                fromSvr.close();
        } catch(Exception ex) {};
        try {
            if (toSvr != null)
                toSvr.close();
        } catch(Exception ex) {};
        try {
            socket.close();
        } catch(Exception ex) {};
    }

    private String resumeLine = "";

    private ProtocolMessage processNextMessage(boolean onlyIfClientFlags)
    {
        String line;
        final List<String> parts = new ArrayList<String>(32);

        while (!quit) {

            if (!resumeLine.isEmpty()) {
                    line = resumeLine;
                    resumeLine = "";
                }
            else {
                try {
                    line = fromSvr.readLine();
                    
                    if (onlyIfClientFlags && (parts.size() == 0)
                        && !line.equals("CLIENT_FLAGS")) {
                            resumeLine = line;
                            // return invalid message
                            return new ProtocolMessage();
                        }
                }
                catch(Exception whoops) {
                    handleConnectionLoss();
                    break;
                }
            }

            if (line == null) {
                handleConnectionLoss();
                // return invalid message
                return new ProtocolMessage();
            }

            if (!quit && line.isEmpty()) {

                if (parts.size() > 0) {

                    ProtocolMessage msg = new ProtocolMessage(parts);

                    netClient.logDebug("Server: " + msg.toString());

                    if (!msg.isValid()) {
                        netClient.onMalformedMessage(msg.toString());
                        if (msg.getType() != ProtocolMessage.Type.BYE)
                            continue;
                    }

                    final String[] args = msg.getArguments();
                    netClient.sanitizeInputs(args);


                    final int argc = args.length;

                    try {
                        switch (msg.getType()) {

                            case PING:
                                netClient.onPing();
                                break;

                            case LOBBY__JOINED:
                                try {
                                    assertAuthNotIncomplete();
                                }
                                catch (Exception ex) {
                                    disconnect();
                                    netClient.onDisconnect(ex.getMessage());
                                }
                                netClient.onLobbyJoin(args);
                                break;

                            case LOBBY__LEFT:
                                netClient.onLobbyLeave(args[0], args[1]);
                                break;

                            case CLIENT_FLAGS:
                                String user;
                                final String flags = args[0];
                                if (flags.length() < 2) {
                                    //netClient.onMalformedMessage(msg.toString());
                                    break;
                                }
                                final char mode = flags.charAt(0);
                                if ((mode != '-') && (mode != '+')) {
                                    //netClient.onMalformedMessage(msg.toString());
                                    break;
                                }

                                final int l = flags.length();

                                for (int i = 1; i < l; i++) {
                                    // set flag type
                                    final INetClient.UserFlagType flag;
                                    // TODO support more flags
                                    switch (flags.charAt(i)) {
                                        case 'a':
                                            flag = INetClient.UserFlagType.ADMIN;
                                            break;
                                        case 'i':
                                            flag = INetClient.UserFlagType.INROOM;
                                            break;
                                        case 'u':
                                            flag = INetClient.UserFlagType.REGISTERED;
                                            break;
                                        default:
                                            flag = INetClient.UserFlagType.UNKNOWN;
                                            break;
                                        }

                                    for (int j = 1; j < args.length; j++) {
                                        netClient.onUserFlagChange(args[j], flag, mode=='+');
                                    }
                                }
                                break;

                            case CHAT:
                                netClient.onChat(args[0], args[1]);
                                break;

                            case INFO:
                                netClient.onUserInfo(args[0], args[1], args[2], args[3]);
                                break;

                            case PONG:
                                netClient.onPong();
                                break;

                            case NICK:
                                final String newNick = args[0];
                                if (!newNick.equals(this.nick)) {
                                    this.nick = newNick;
                                }
                                    netClient.onNickSet(this.nick);
                                sendMessage(new String[] { "PROTO", PROTOCOL_VERSION });
                                break;

                            case NOTICE:
                                // nickname collision
                                if (args[0].equals("0"))
                                    setNick(netClient.onNickCollision(this.nick));
                                break;

                            case ASKPASSWORD:
                                try {
                                    final String pwHash = netClient.onPasswordHashNeededForAuth();
                                    doAuthPart1(pwHash, args[0]);
                                }
                                catch (Exception ex) {
                                    disconnect();
                                    netClient.onDisconnect(ex.getMessage());
                                }
                                break;

                            case ROOMS:
                                final int nf = ProtocolMessage.ROOM_FIELD_COUNT;
                                for (int a = 0; a < argc; a += nf) {
                                    handleRoomInfo(args[a+1], Arrays.copyOfRange(args, a, a + nf));
                                }

                            case ROOM_ADD:
                                handleRoomInfo(args[1], args);
                                break;

                            case ROOM_DEL:
                                netClient.onRoomDel(args[0]);
                                break;

                            case ROOM_UPD:
                                handleRoomInfo(args[0], Arrays.copyOfRange(args, 1, args.length));
                                break;

                            case BYE:
                                closeConnection();
                                if (argc > 0)
                                    netClient.onDisconnect(args[0]);
                                else
                                    netClient.onDisconnect("");
                                break;

                            case SERVER_AUTH:
                                try {
                                    doAuthPart2(args[0]);
                                }
                                catch (Exception ex) {
                                    disconnect();
                                    netClient.onDisconnect(ex.getMessage());
                                }
                                break;
                        }
                        // end of message
                        return msg;
                    }
                    catch(IllegalArgumentException ex) {

                        netClient.logError("Illegal arguments! "
                            + ProtocolMessage.partsToString(parts)
                            + "caused: " + ex.getMessage());

                        return new ProtocolMessage();
                    }
                }
            }
            else
            {
                parts.add(line);
            }
        }

        netClient.logError("WARNING: Message wasn't parsed correctly: "
                            + ProtocolMessage.partsToString(parts));
        // return invalid message
        return new ProtocolMessage(); // never to be reached
    }

    private void handleRoomInfo(final String name, final String[] info) throws IllegalArgumentException
    {
        // TODO room flags enum array

        final int nUsers;
        final int nTeams;
        
        try {
            nUsers = Integer.parseInt(info[2]);
        }
        catch(IllegalArgumentException ex) {
            throw new IllegalArgumentException(
                "Player count is not an valid integer!",
                ex);
        }

        try {
            nTeams = Integer.parseInt(info[3]);
        }
        catch(IllegalArgumentException ex) {
            throw new IllegalArgumentException(
                "Team count is not an valid integer!",
                ex);
        }

        netClient.onRoomInfo(name, info[0], info[1], nUsers, nTeams,
                             info[4], info[5], info[6], info[7], info[8]);
    }

    private static final String AUTH_SALT = PROTOCOL_VERSION + "!hedgewars";
    private static final int PASSWORD_HASH_LENGTH = 32;
    public static final int SERVER_SALT_MIN_LENGTH = 16;
    private static final String AUTH_ALG = "SHA-1";
    private String serverAuthHash = "";

    private void assertAuthNotIncomplete() throws Exception {
        if (!serverAuthHash.isEmpty()) {
            netClient.logError("AUTH-ERROR: assertAuthNotIncomplete() found that authentication was not completed!");
            throw new Exception("Authentication was not finished properly!");
        }
        serverAuthHash = "";
    }

    private void doAuthPart2(final String serverAuthHash) throws Exception {
        if (!this.serverAuthHash.equals(serverAuthHash)) {
            netClient.logError("AUTH-ERROR: Server's authentication hash is incorrect!");
            throw new Exception("Server failed mutual authentication! (wrong hash provided by server)");
        }
        netClient.logDebug("Auth: Mutual authentication successful.");
        this.serverAuthHash = "";
    }

    private void doAuthPart1(final String pwHash, final String serverSalt) throws Exception {
        if ((pwHash == null) || pwHash.isEmpty()) {
            netClient.logDebug("AUTH: Password required, but no password hash was provided.");
            throw new Exception("Auth: Password needed, but none specified.");
        }
        if (pwHash.length() != PASSWORD_HASH_LENGTH) {
            netClient.logError("AUTH-ERROR: Your password hash has an unexpected length! Should be "
                               + PASSWORD_HASH_LENGTH + " but is " + pwHash.length()
                              );
            throw new Exception("Auth: Your password hash length seems wrong.");
        }
        if (serverSalt.length() < SERVER_SALT_MIN_LENGTH) {
            netClient.logError("AUTH-ERROR: Salt provided by server is too short! Should be at least "
                               + SERVER_SALT_MIN_LENGTH + " but is " + serverSalt.length()
                              );
            throw new Exception("Auth: Server violated authentication protocol! (auth salt too short)");
        }

        final MessageDigest sha1Digest;

        try {
             sha1Digest = MessageDigest.getInstance(AUTH_ALG);
        }
        catch(NoSuchAlgorithmException ex) {
            netClient.logError("AUTH-ERROR: Algorithm required for authentication ("
                                      + AUTH_ALG + ") not available!"
                                     );
            return;
        } 
        

        // generate 130 bit base32 encoded value
        // base32 = 5bits/char => 26 chars, which is more than min req
        final String clientSalt =
            new BigInteger(130, new SecureRandom()).toString(32);

        final String saltedPwHash =
            clientSalt + serverSalt + pwHash + AUTH_SALT;

        final String saltedPwHash2 =
            serverSalt + clientSalt + pwHash + AUTH_SALT;

        final String clientAuthHash =
            new BigInteger(1, sha1Digest.digest(saltedPwHash.getBytes("UTF-8"))).toString(16);

        serverAuthHash =
            new BigInteger(1, sha1Digest.digest(saltedPwHash2.getBytes("UTF-8"))).toString(16);

        sendMessage(new String[] { "PASSWORD", clientAuthHash, clientSalt });

/* When we got password hash, and server asked us for a password, perform mutual authentication:
 * at this point we have salt chosen by server
 * client sends client salt and hash of secret (password hash) salted with client salt, server salt,
 * and static salt (predefined string + protocol number)
 * server should respond with hash of the same set in different order.

    if(m_passwordHash.isEmpty() || m_serverSalt.isEmpty())
        return;

    QString hash = QCryptographicHash::hash(
                m_clientSalt.toAscii()
                .append(m_serverSalt.toAscii())
                .append(m_passwordHash)
                .append(cProtoVer->toAscii())
                .append("!hedgewars")
                , QCryptographicHash::Sha1).toHex();

    m_serverHash = QCryptographicHash::hash(
                m_serverSalt.toAscii()
                .append(m_clientSalt.toAscii())
                .append(m_passwordHash)
                .append(cProtoVer->toAscii())
                .append("!hedgewars")
                , QCryptographicHash::Sha1).toHex();

    RawSendNet(QString("PASSWORD%1%2%1%3").arg(delimiter).arg(hash).arg(m_clientSalt));

Server:  ("ASKPASSWORD", "5S4q9Dd0Qrn1PNsxymtRhupN") 
Client:  ("PASSWORD", "297a2b2f8ef83bcead4056b4df9313c27bb948af", "{cc82f4ca-f73c-469d-9ab7-9661bffeabd1}") 
Server:  ("SERVER_AUTH", "06ecc1cc23b2c9ebd177a110b149b945523752ae") 

 */
    }

    public void sendCommand(final String command)
    {
        String cmd = command;

        // don't execute empty commands
        if (cmd.length() < 1)
            return;

        // replace all newlines since they violate protocol
        cmd = cmd.replace('\n', ' ');

        // parameters are separated by one or more spaces.
        final String[] parts = cmd.split(" +");

        // command is always CAPS
        parts[0] = parts[0].toUpperCase();

        sendMessage(parts);
    }

    public void sendPing()
    {
        sendMessage("PING");
    }

    public void sendPong()
    {
        sendMessage("PONG");
    }

    private void sendMessage(final String msg)
    {
        sendMessage(new String[] { msg });
    }

    private void sendMessage(final String[] parts)
    {
        if (quit)
            return;

        netClient.logDebug("Client: " + messagePartsToString(parts));

        boolean malformed = false;
        String msg = "";

        for (final String part : parts)
        {
            msg += part + '\n';
            if (part.isEmpty() || (part.indexOf('\n') >= 0)) {
                malformed = true;
                break;
            }
        }

        if (malformed) {
            netClient.onMalformedMessage(messagePartsToString(parts));
            return;
        }

        try {
            toSvr.print(msg + '\n'); // don't use println, since we always want '\n'
            toSvr.flush();
        }
        catch(Exception ex) {
            netClient.logError("FATAL: Couldn't send message! " + ex.getMessage());
            ex.printStackTrace();
            handleConnectionLoss();
        }
    }

    private String messagePartsToString(String[] parts) {

        if (parts.length == 0)
            return "([empty message])";

        String result = "(\"" + parts[0] + '"';
        for (int i=1; i < parts.length; i++)
        {
            result += ", \"" + parts[i] + '"';
        }
        result += ')';

        return result;
    }

    public void disconnect() {
        sendMessage(new String[] { "QUIT", "Client quit" });
        closeConnection();
    }

    public void disconnect(final String reason) {
        sendMessage(new String[] { "QUIT", reason.isEmpty()?"-":reason });
        closeConnection();
    }

    public void sendChat(String message) {

        String[] lines = message.split("\n");

        for (String line : lines)
        {
            if (!message.trim().isEmpty())
                sendMessage(new String[] { "CHAT", line });
        }
    }

    public void joinRoom(final String roomName) {

        sendMessage(new String[] { "JOIN_ROOM", roomName });
    }

    public void leaveRoom(final String roomName) {

        sendMessage("PART");
    }

    public void requestInfo(final String user) {

        sendMessage(new String[] { "INFO", user });
    }

    public void setNick(final String nick) {

        this.nick = nick;
        sendMessage(new String[] { "NICK", nick });
    }

    public void kick(final String nick) {

        sendMessage(new String[] { "KICK", nick });
    }

    public void requestRoomsList() {

        sendMessage("LIST");
    }
}

