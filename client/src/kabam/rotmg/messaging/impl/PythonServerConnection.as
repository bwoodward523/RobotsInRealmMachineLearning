package kabam.rotmg.messaging.impl
{
import com.company.assembleegameclient.game.GameSprite;
import kabam.rotmg.game.signals.AddTextLineSignal;
import kabam.rotmg.core.StaticInjectorContext;
import org.swiftsuspenders.Injector;
import kabam.rotmg.game.model.AddTextLineVO;

import kabam.lib.net.impl.SocketServer;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.net.Socket;
import flash.utils.ByteArray;


import flash.events.KeyboardEvent;
import flash.ui.Keyboard;


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

    public function PythonServerConnection(gs:GameSprite) {
        var injector:Injector = StaticInjectorContext.getInjector();
        this.addTextLine = injector.getInstance(AddTextLineSignal);
        this.gs = gs;
        socket = new Socket();
        configureListeners();
        connectToServer();
    }
    private function configureListeners():void {
        socket.addEventListener(Event.CONNECT, onConnect);
        socket.addEventListener(ProgressEvent.SOCKET_DATA, onDataReceived);
        socket.addEventListener(IOErrorEvent.IO_ERROR, onError);
    }

    private function connectToServer():void {
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
                trace("Received message: " + message);

                // Handle the message based on its content or type
                if (messageType == 1) {
                    //Clear the existing inputs

                    //TODO: Add diagonal movement (up_left {moveLeft = true; moveUp = true;)

                    clearInputs();
                    if(message == "move_left"){
                        moveLeft = true;
                    }
                    else if(message == "move_right"){
                        moveRight = true;
                    }
                    else if(message == "move_down"){
                        moveDown = true;
                    }
                    else if(message == "move_up"){
                        moveUp = true;
                    }
                    this.addTextLine.dispatch(new AddTextLineVO("*Help*", ((message))));
                }
            } else {
                // Not enough bytes yet for the full message, restore ByteArray position
                byteArray.position -= 5;
                break;
            }
        }
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