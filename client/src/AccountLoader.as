package {
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.filesystem.File;
import flash.filesystem.FileStream;
import flash.filesystem.FileMode;

public class AccountLoader {
    private var jsonLoader:URLLoader;
    private var xmlLoader:URLLoader;
    private var accountIndex:int;
    public var guid:String;
    public var password:String;
    var accounts:Array = [
        {email: "bota@gmail.com", password: "bota123", module: "afk"},
        {email: "botb@gmail.com", password: "botb123", module: "afk"},
        {email: "testa@gmail.com", password: "password", module: "afk"},
        {email: "testb@gmail.com", password: "password", module: "afk"},
        {email: "testc@gmail.com", password: "password", module: "afk"},
        {email: "testd@gmail.com", password: "password", module: "afk"},
        {email: "teste@gmail.com", password: "password", module: "afk"},
        {email: "testf@gmail.com", password: "password", module: "afk"},
        {email: "testg@gmail.com", password: "password", module: "afk"},
        {email: "testh@gmail.com", password: "password", module: "afk"},
        {email: "testi@gmail.com", password: "password", module: "afk"},
        {email: "testj@gmail.com", password: "password", module: "afk"},
        {email: "dumba@gmail.com", password: "password", module: "afk"},
        {email: "dumbb@gmail.com", password: "password", module: "afk"},
        {email: "dumbc@gmail.com", password: "password", module: "afk"},
        {email: "dumbd@gmail.com", password: "password", module: "afk"},
        {email: "dumbe@gmail.com", password: "password", module: "afk"},
        {email: "dumbf@gmail.com", password: "password", module: "afk"},
        {email: "dumbg@gmail.com", password: "password", module: "afk"},
        {email: "dumbh@gmail.com", password: "password", module: "afk"},
        {email: "dumbi@gmail.com", password: "password", module: "afk"},
        {email: "dumbj@gmail.com", password: "password", module: "afk"},
        {email: "dumbk@gmail.com", password: "password", module: "afk"},
        {email: "dumbl@gmail.com", password: "password", module: "afk"},
        {email: "dumbm@gmail.com", password: "password", module: "afk"},
        {email: "dumbn@gmail.com", password: "password", module: "afk"},
        {email: "dumbo@gmail.com", password: "password", module: "afk"},
        {email: "dumbp@gmail.com", password: "password", module: "afk"},
        {email: "dumbq@gmail.com", password: "password", module: "afk"},
        {email: "dumbr@gmail.com", password: "password", module: "afk"},
        {email: "dumbs@gmail.com", password: "password", module: "afk"},
        {email: "dumbt@gmail.com", password: "password", module: "afk"},
        {email: "dumbu@gmail.com", password: "password", module: "afk"},
        {email: "dumbv@gmail.com", password: "password", module: "afk"},
        {email: "dumbw@gmail.com", password: "password", module: "afk"},
        {email: "dumbx@gmail.com", password: "password", module: "afk"},
        {email: "dumby@gmail.com", password: "password", module: "afk"},
        {email: "dumbz@gmail.com", password: "password", module: "afk"},
        {email: "dumbaa@gmail.com", password: "password", module: "afk"},
        {email: "dumbab@gmail.com", password: "password", module: "afk"},
        {email: "dumbac@gmail.com", password: "password", module: "afk"},
        {email: "dumbad@gmail.com", password: "password", module: "afk"},
        {email: "dumbae@gmail.com", password: "password", module: "afk"},
        {email: "dumbaf@gmail.com", password: "password", module: "afk"},
        {email: "dumbag@gmail.com", password: "password", module: "afk"},
        {email: "dumbah@gmail.com", password: "password", module: "afk"},
        {email: "dumbai@gmail.com", password: "password", module: "afk"},
        {email: "dumbaj@gmail.com", password: "password", module: "afk"},
        {email: "dumbak@gmail.com", password: "password", module: "afk"},
        {email: "dumbal@gmail.com", password: "password", module: "afk"},
        {email: "dumbam@gmail.com", password: "password", module: "afk"},
        {email: "dumban@gmail.com", password: "password", module: "afk"},
        {email: "dumbao@gmail.com", password: "password", module: "afk"},
        {email: "dumbap@gmail.com", password: "password", module: "afk"},
        {email: "dumbaq@gmail.com", password: "password", module: "afk"},
        {email: "dumbar@gmail.com", password: "password", module: "afk"},
        {email: "dumbas@gmail.com", password: "password", module: "afk"},
        {email: "dumbat@gmail.com", password: "password", module: "afk"},
        {email: "dumbau@gmail.com", password: "password", module: "afk"},
        {email: "dumbav@gmail.com", password: "password", module: "afk"},
        {email: "dumbaw@gmail.com", password: "password", module: "afk"},
        {email: "dumbax@gmail.com", password: "password", module: "afk"},
        {email: "dumbay@gmail.com", password: "password", module: "afk"},
        {email: "dumbaz@gmail.com", password: "password", module: "afk"},
        {email: "dumbba@gmail.com", password: "password", module: "afk"},
        {email: "dumbbb@gmail.com", password: "password", module: "afk"}
    ];
    public function AccountLoader() {
        // First load the XML file to get the account index
        var randomIndex:int = Math.floor(Math.random() * accounts.length);
        var selectedAccount:Object = accounts[randomIndex];
        guid = selectedAccount.email;
        password = selectedAccount.password;
//        xmlLoader = new URLLoader();
//        var xmlRequest:URLRequest = new URLRequest(File.applicationDirectory.resolvePath("WebMain-app.xml").url); // Ensure the path is correct for your project
//        xmlLoader.addEventListener(Event.COMPLETE, onXMLLoadComplete);
//        xmlLoader.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
//
//        try {
//            xmlLoader.load(xmlRequest);
//        } catch (error:Error) {
//            trace("Error loading XML: " + error.message);
//        }
    }

    private function onXMLLoadComplete(event:Event):void {
        try {
            // Parse the XML
            var xmlData:XML = new XML(event.target.data);

            // Access the <id> element
            var idString:String = xmlData.id;
            trace("Raw ID String: " + idString);

            // Define the prefix to remove
            var prefix:String = "betterSkillys";

            // Check if the id string starts with the specified prefix
            if (idString.indexOf(prefix) == 0) {
                // Slice off the prefix
                var numericPart:String = idString.substring(prefix.length);

                // Use a regular expression to extract only the numeric characters from the remaining part
                var regex:RegExp = /\d+/;
                var match:Array = numericPart.match(regex);

                if (match) {
                    // Convert the matched numeric part to an integer
                    accountIndex = int(match[0]);
                    trace("Extracted account id from XML: " + accountIndex);
                } else {
                    trace("No numeric part found in id.");
                }
            } else {
                trace("ID does not start with the expected prefix.");
            }

            // Now load the JSON data using the extracted account index
            loadJSONData();
        } catch (e:Error) {
            trace("Error parsing XML: " + e.message);
        }
    }

    private function loadJSONData():void {
        // Now load the JSON data to fetch the account details
        jsonLoader = new URLLoader();
        var jsonRequest:URLRequest = new URLRequest("src/accounts.json"); // Replace with your JSON file URL
        jsonLoader.addEventListener(Event.COMPLETE, onJSONLoadComplete);
        jsonLoader.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
        jsonLoader.load(jsonRequest);
    }
    public function random():void{
        accountIndex = Math.floor(Math.random() * 100);
    }
    private function onJSONLoadComplete(event:Event):void {
        try {
            accountIndex = Math.floor(Math.random() * 100);

            // Parse the JSON content
            var data:Object = JSON.parse(jsonLoader.data);
            // Access the account based on the accountIndex extracted from XML
            if (accountIndex >= 0 && accountIndex < data.accounts.length) {
                var account:Object = data.accounts[accountIndex];
                trace("Account at index " + accountIndex + ":");
                trace("Email: " + account.email);
                trace("Password: " + account.password);
                guid = account.email;
                password = account.password;
            } else {
                trace("Index out of bounds.");
            }
        } catch (e:Error) {
            trace("Error parsing JSON: " + e.message);
        }
    }

    private function onLoadError(event:IOErrorEvent):void {
        trace("Error loading file: " + event.text);
    }
}
}