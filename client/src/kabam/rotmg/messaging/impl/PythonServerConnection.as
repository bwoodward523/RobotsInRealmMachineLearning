package kabam.rotmg.messaging.impl
{
import com.company.assembleegameclient.game.GameSprite;

import flash.sampler.getSize;

import kabam.rotmg.game.signals.AddTextLineSignal;
import kabam.rotmg.core.StaticInjectorContext;
import org.swiftsuspenders.Injector;
import kabam.rotmg.game.model.AddTextLineVO;
import flash.display.Stage;

import kabam.lib.net.impl.SocketServer;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.net.Socket;
import flash.utils.ByteArray;
import com.company.assembleegameclient.objects.GameObject;


import flash.events.KeyboardEvent;
import flash.ui.Keyboard;

import flash.utils.setTimeout;
import kabam.rotmg.constants.UseType;

import starling.utils.deg2rad;


//
public class PythonServerConnection extends Sprite{

    private var addTextLine:AddTextLineSignal;

    public var gs:GameSprite = null;
    public var socket:Socket;
    public var serverHost:String = "127.0.0.1";
    public var serverPort:int = 65432;
    public var moveLeft:Boolean = false;
    public var moveRight:Boolean = false;
    public var moveUp:Boolean = false;
    public var moveDown:Boolean = false;
    public var shootAngle:int = -1;
    public var useAbility:Boolean = false;
    public var xCoord:Number;
    public var yCoord:Number;

    public var STAGE:Stage;
    public var prevHP:int = 0;

    //used to prevent sending movement packets everytick instead send them every 10 ticks
    private var skipSend:int = 3;
    private var skipSendCount:int = 0;


    public function PythonServerConnection() {
        var injector:Injector = StaticInjectorContext.getInjector();
        this.addTextLine = injector.getInstance(AddTextLineSignal);
        STAGE = WebMain.STAGE;
        //this.gs = gs;
        socket = new Socket();
        configureListeners();
        connectToServer();
//        if (stage) {
//
//        }
//        else {
//            addEventListener(Event.ADDED_TO_STAGE, this.onAddedToStage);
//        }
    }

    //Set the gamestate variable
    public function setGameState(gs:GameSprite): void{
        this.gs = gs;
    }
    private function configureListeners():void {
        socket.addEventListener(Event.CONNECT, onConnect);
        socket.addEventListener(ProgressEvent.SOCKET_DATA, onDataReceived);
        socket.addEventListener(IOErrorEvent.IO_ERROR, onError);
    }

    public function connectToServer():void {
        try {
            socket.connect(serverHost, serverPort);
            trace("Connecting to server...");
        } catch (error:Error) {
            trace("Failed to connect: " + error.message);
        }
    }

    private function onConnect(event:Event):void {
        trace("Connected to server!");
        //sendMessage("Hello, Server!");
    }

    private function sendMessage(message:String):void {
        if (socket.connected) {
            socket.writeUTFBytes(message + "\n"); // Send message with a newline
            socket.flush(); // Send the message immediately
            //trace("Message sent: " + message);
        } else {
            trace("Socket is not connected.");
        }
    }

    public function sendDamage(hp:int):void{
        sendMessage("182" + hp);

    }
    public function sendCoords(x:Number, y:Number):void{
        if(skipSendCount == skipSend ){
            skipSendCount = 0;
            sendMessage("183" + x.toFixed(2) + " " + y.toFixed(2));
        }
        skipSendCount++;
    }
    public function sendEnemy(go:Vector.<GameObject>){
        var message:String = "184";
        var x:String ,y:String;
        var g:GameObject;
        for each (g in go){
            x = g.tickPosition_.x.toFixed(2);
            y = g.tickPosition_.y.toFixed(2);
            message += x + " " + y + ",";
            //print("" + getAngleBetweenPoints(gs.gsc_.player.x_,gs.gsc_.player.y_,g.tickPosition_.x,g.tickPosition_.y));

        }
        if (message.charAt(message.length - 1) == ",") {
            message = message.slice(0, -1);
        }
        if(message != "184")
            sendMessage(message);
    }
    public function getAngleBetweenPoints(x1:Number, y1:Number, x2:Number, y2:Number):Number {
        // Calculate the difference in x and y coordinates
        var dx:Number = x2 - x1;
        var dy:Number = y2 - y1;

        // Calculate the angle in radians
        var angleRadians:Number = Math.atan2(dy, dx);

        // Convert radians to degrees (optional)
        var angleDegrees:Number = angleRadians * (180 / Math.PI);

        return angleDegrees;
    }
    public function tick():void{
        gs.mui_.setMovementVars(moveLeft, moveRight, moveUp, moveDown);
        gs.mui_.setPlayerMovement();
        if(shootAngle != -1){
            //print("current shoot angle " + shootAngle);
            gs.gsc_.player.attemptAttackAngle(deg2rad(shootAngle));
        }
        if(useAbility){
            gs.gsc_.player.useAltWeapon(xCoord,yCoord,UseType.START_USE);
            useAbility = false
        }
        var currHP:int = gs.gsc_.player.hp_;
        if(prevHP != currHP || prevHP == 0){
            prevHP = currHP;
            sendDamage(currHP);
        }



    }
    private function onDataReceived(event:ProgressEvent):void {
        var byteArray:ByteArray = new ByteArray();
        socket.readBytes(byteArray, 0, socket.bytesAvailable); // Read all available data into a ByteArray
        byteArray.endian = "bigEndian"; // Match the Python server's byte order

        while (byteArray.bytesAvailable >= 5) { // Minimum bytes for header

            // Read the header
            var totalLength:int = byteArray.readInt(); // 4 bytes for message length
            var messageType:int = byteArray.readUnsignedByte(); // 1 byte for message type

            // Check if the entire message is available
            if (byteArray.bytesAvailable >= totalLength - 5) {
                // Read the message content
                var message:String = byteArray.readUTFBytes(totalLength - 5);
                //print("Received message: " + message);

                // Route message to a handler
                handleMessage(messageType, message);

            } else {
                // Not enough bytes yet for the full message, restore ByteArray position
                byteArray.position -= 5;
                break;
            }
        }
    }
    private function handleMessage(messageType:int, message:String):void {
        if (messageType == 1) { // Movement and actions
            clearInputs();

            if (message == "enter_realm") {
                if (gs) gs.gsc_.playerText("/realm");
            } else if (message.indexOf("move_") == 0) {
                handleMovement(message);
            } else if (message.indexOf("shoot") == 0) {
                handleShooting(message);
            } else if (message.indexOf("ability") == 0) {
                handleAbility(message);
            }
        }
    }

    private function handleMovement(message:String):void {
        switch (message) {
            case "move_left":
                moveLeft = true;
                break;
            case "move_right":
                moveRight = true;
                break;
            case "move_down":
                moveDown = true;
                break;
            case "move_up":
                moveUp = true;
                break;
            case "move_none":
                clearInputs();
                break;
        }
    }

    private function handleShooting(message:String):void {
        var parts:Array = message.split(" ");

        if (parts.length == 2 && parts[0] == "shoot") {
            var angle:Number = parseFloat(parts[1]);
            trace("Shoot angle set to: " + angle);
        }
        shootAngle = angle;
        //gs.gsc_.player.attemptAttackAngle(angle);
    }

    private function handleAbility(message:String):void {
        var parts:Array = message.split(" "); // Split into ["ability", "12.36", "82.17"]
        if (parts.length == 3) {
            useAbility = true;
            xCoord = parseFloat(parts[1]);
            yCoord = parseFloat(parts[2]);

        }
    }
    //Print to game chat
    public function print(message:String):void{
        this.addTextLine.dispatch(new AddTextLineVO("*Help*", ((message))));
    }
    private function clearInputs():void{
        moveLeft = false;
        moveRight = false;
        moveUp = false;
        moveDown = false;
    }
    private function onError(event:IOErrorEvent):void {
        trace("Socket error: " + event.text);
    }
    // Function to simulate a key press
    function simulateKeyPressToStage(keyCode:uint):void {
        // Dispatch a key down event
        var keyDownEvent:KeyboardEvent = new KeyboardEvent(
                KeyboardEvent.KEY_DOWN,
                true,    // bubbles
                false,   // cancelable
                0,       // charCode (optional)
                keyCode  // keyCode for the key to simulate
        );
        STAGE.dispatchEvent(keyDownEvent);

        // Dispatch a key up event
        var keyUpEvent:KeyboardEvent = new KeyboardEvent(
                KeyboardEvent.KEY_UP,
                true,    // bubbles
                false,   // cancelable
                0,       // charCode (optional)
                keyCode  // keyCode for the key to simulate
        );
        STAGE.dispatchEvent(keyUpEvent);
    }
    function simulateKeyPressToChat(keyCode:uint):void {
        // Dispatch a key down event
        gs.textBox_.setInputTextAllowed(true);
        var keyDownEvent:KeyboardEvent = new KeyboardEvent(
                KeyboardEvent.KEY_DOWN,
                true,    // bubbles
                false,   // cancelable
                0,       // charCode (optional)
                keyCode  // keyCode for the key to simulate
        );
        gs.textBox_.dispatchEvent(keyDownEvent);

        // Dispatch a key up event
        var keyUpEvent:KeyboardEvent = new KeyboardEvent(
                KeyboardEvent.KEY_UP,
                true,    // bubbles
                false,   // cancelable
                0,       // charCode (optional)
                keyCode  // keyCode for the key to simulate
        );
        gs.textBox_.dispatchEvent(keyUpEvent);
    }

    //Maybe we should define packet types and make a header value for each and encode that

    //Keyboard commands
//    function simulateKeyPress(keyCode:uint):void {
//        // Dispatch a key down event
//        var keyDownEvent:KeyboardEvent = new KeyboardEvent(
//                KeyboardEvent.KEY_DOWN,
//                true,    // bubbles
//                false,   // cancelable
//                0,       // charCode (optional)
//                keyCode  // keyCode for the key to simulate
//        );
//        stage.dispatchEvent(keyDownEvent);
//
//        // Dispatch a key up event
//        var keyUpEvent:KeyboardEvent = new KeyboardEvent(
//                KeyboardEvent.KEY_UP,
//                true,    // bubbles
//                false,   // cancelable
//                0,       // charCode (optional)
//                keyCode  // keyCode for the key to simulate
//        );
//        stage.dispatchEvent(keyUpEvent);
//    }

    //Lets set the mui variables so that we and then call setmovementinput

    //Forward a packet to pyserver
    public function forwardPacketFromClient(messageId:uint, data:ByteArray):void {
//        if (!socket.connected) {
//            trace("Python socket is not connected.");
//            return;
//        }
//
//        try {
//            var packet:ByteArray = new ByteArray();
//            packet.writeInt(data.length + 5); // Packet length
//            packet.writeByte(messageId); // Message ID
//            packet.writeBytes(data); // Original message data
//
//            socket.writeBytes(packet);
//            socket.flush();
//        } catch (e:Error) {
//            trace("Error forwarding packet: " + e.message);
//        }
        return;
    }
    public function forwardPacketFromServer(messageId:uint, data:ByteArray):void {
//        if (!socket.connected) {
//            //trace("Python socket is not connected.");
//            return;
//        }
//
//        try {
//            var packet:ByteArray = new ByteArray();
//            packet.writeInt(data.length + 5); // Packet length
//            packet.writeByte(messageId); // Message ID
//            //packet.writeBytes(data); // Original message data
//            //socket.writeUTFBytes(packet);
//            socket.writeBytes(packet);
//            socket.flush();
//        } catch (e:Error) {
//            trace("Error forwarding packet: " + e.message);
//        }
//    }
        return;
    }
}
}