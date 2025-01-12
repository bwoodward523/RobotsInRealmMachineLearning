package kabam.rotmg.messaging.impl
{
import com.company.assembleegameclient.game.GameSprite;

import flash.sampler.getSize;
import flash.utils.Dictionary;

import kabam.rotmg.game.signals.AddTextLineSignal;
import kabam.rotmg.core.StaticInjectorContext;
import org.swiftsuspenders.Injector;
import kabam.rotmg.game.model.AddTextLineVO;
import flash.display.Stage;
import com.company.assembleegameclient.objects.Projectile;
import flash.geom.Point;

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
    public var questPosition:Point;
    private var skipSendQuest:int = 3;
    private var skipSendQuestCount:int = 0;
    //used to prevent sending movement packets everytick instead send them every 10 ticks
    private var skipSend:int = 3;
    private var skipSendCount:int = 0;

    public var numOfProjectiles:int = 0;
    //make projectile dictionary and grab projectiles by their id
    private var projectiles:Dictionary;
    //make velocity dictionary that pairs with projectile dictionary
    private var velocities:Dictionary;


    public function PythonServerConnection() {
        var injector:Injector = StaticInjectorContext.getInjector();
        this.addTextLine = injector.getInstance(AddTextLineSignal);
        STAGE = WebMain.STAGE;
        //this.gs = gs;
        socket = new Socket();
        configureListeners();
        connectToServer();


        //Initialize Dictionary
        this.projectiles = new Dictionary();
        this.velocities = new Dictionary();
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

    public function sendEnemy(go:Vector.<GameObject>):void{
        var message:String = "184";
        var x:String ,y:String;
        var g:GameObject;
        for each (g in go){
            x = g.tickPosition_.x.toFixed(2);
            y = g.tickPosition_.y.toFixed(2);
            message += x + " " + y + " " + g.hp_ + ",";
        }
        if (message.charAt(message.length - 1) == ",") {
            message = message.slice(0, -1);
        }
        if(message != "184")
            sendMessage(message);
    }
    public function sendProjectiles():void{
        var message:String = "185";
        var data:String = ""
        for (var key:* in velocities){
            if(velocities[key] && projectiles[key]){
                data += projectiles[key].dmg + " " + projectiles[key].x + " " + projectiles[key].y + " " + velocities[key].vx + " " + velocities[key].vy + ",";
            }
        }

        message = message + data;

        if (message.charAt(message.length - 1) == ","){
            message = message.slice(0, -1);
        }
        sendMessage(message);
    }
    public function setQuestPosition(x:Number, y:Number):void{
        questPosition = new Point(x,y);
        sendQuestPosition();
    }
    public function sendQuestPosition():void{
        if(skipSendQuestCount == skipSendQuest ){
            skipSendQuestCount = 0;
            sendMessage("186" + x.toFixed(2) + " " + y.toFixed(2));
        }
        skipSendQuestCount++;
    }
    public function sendDeath():void{
        var message:String = "187"
        sendMessage(message);
    }
    //Take the projectiles out of the object pool
    public function removeProjectile(ownerid, bulletid):void{
        var id = Projectile.findObjId(ownerid, bulletid);
        delete projectiles[id];
        delete velocities[id];
    }

    public function getProjectileStartTime(ownerid,bulletid):Number{
        var id = Projectile.findObjId(ownerid, bulletid);
        if(projectiles[id]){
            return projectiles[Projectile.findObjId(ownerid, bulletid)].t0;
        }
        return -1;
    }
    public function receiveProjectile(ownerid, bulletid, damage, ang, startX,startY, startTime):void {
        var id = Projectile.findObjId(ownerid, bulletid);

        if(projectiles[id]){
            //if projectile has already been added to the dictionary then calculate its velocity
            //get previous x and y and calculate velocity
            var x1:Number = projectiles[id].x;
            var y1:Number = projectiles[id].y;
            var t0:Number = projectiles[id].t0;
            var elapsedTime:Number = startTime - t0;
            var vx:Number = ((startX - x1)/elapsedTime) * 1000;
            var vy:Number = ((startY - y1)/elapsedTime) * 1000;

            //trace("t0: " + t0 + ", t1: "+startTime + ", elapsedTime: " + elapsedTime );
//            trace("x1: " + x1 +
//                    ", y1: " + y1 +
//                    ", t0: " + t0 +
//                    ", elapsedTime: " + elapsedTime +
//                    ", curX: " + startX +
//                    ", curY: " + startY +
//                    ", vx: " + vx +
//                    ", vy: " + vy);
            velocities[id] =  {vx: vx, vy: vy};

            //update projectile
            projectiles[id] = {x: startX, y: startY, dmg: damage, t0: startTime};

            //trace("velocity : (" + velocities[id].vx + "," + velocities[id].vy + ")")
        }
        else if(!velocities[id]){ //if we have not already gotten the velocity
            //projectile is new. we add to our dictionary and wait for required data for velocity
            projectiles[id] = {x: startX, y: startY, dmg: damage, t0: startTime};
        }
    }

    public function tick():void{
        gs.mui_.setMovementVars(moveLeft, moveRight, moveUp, moveDown);
        gs.mui_.setPlayerMovement();
        if(shootAngle != -1){
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


        //check to see if projectiles are in the list
        var count:int = 0;
        for (var key:* in velocities) {
            count++;
            break;
        }
        //Gather valid projectiles and pack them up and ship em out
        if(count > 0)
            sendProjectiles();
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
            //trace("Shoot angle set to: " + angle);
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
}
}