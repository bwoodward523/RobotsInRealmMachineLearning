package kabam.rotmg.messaging.impl
{
import com.company.assembleegameclient.game.GameSprite;
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


import flash.events.KeyboardEvent;
import flash.ui.Keyboard;

import flash.utils.setTimeout;
import kabam.rotmg.constants.UseType;



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
    var xCoord:Number;
    var yCoord:Number;

    public var STAGE:Stage;

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
    public function setGameState(gs:GameSprite){
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
        sendMessage("Hello, Server!");
    }

    private function sendMessage(message:String):void {
        if (socket.connected) {
            socket.writeUTFBytes(message + "\n"); // Send message with a newline
            socket.flush(); // Send the message immediately
            trace("Message sent: " + message);
        } else {
            trace("Socket is not connected.");
        }
    }
    public function tick():void{
        gs.mui_.setMovementVars(moveLeft, moveRight, moveUp, moveDown);
        gs.mui_.setPlayerMovement();
        if(shootAngle != -1){
            gs.gsc_.player.attemptAttackAngle(shootAngle);
        }
        if(useAbility){
            gs.gsc_.player.useAltWeapon(xCoord,yCoord,UseType.START_USE);
            useAbility = false
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
                print("Received message: " + message);

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
        var angle:int = parseInt(message.substring(6)); // Extract angle after "shoot "
        shootAngle = isNaN(angle) ? -1 : angle;
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
}
}