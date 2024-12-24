package kabam.rotmg.messaging.impl
{
import kabam.lib.net.impl.SocketServer;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.net.Socket;

public class PythonServerConnection {
    public var socket:Socket;
    public var serverHost:String = "127.0.0.1";
    public var serverPort:int = 65432;
    public function PythonServerConnection() {
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
        var response:String = socket.readUTFBytes(socket.bytesAvailable);
        trace("Message received from server: " + response);
    }

    private function onError(event:IOErrorEvent):void {
        trace("Socket error: " + event.text);
    }
}
}