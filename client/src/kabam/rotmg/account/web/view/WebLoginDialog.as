package kabam.rotmg.account.web.view
{
import com.company.assembleegameclient.account.ui.Frame;
import com.company.assembleegameclient.account.ui.TextInputField;
import com.company.assembleegameclient.ui.ClickableText;
import com.company.util.KeyCodes;
import com.gskinner.motion.GTween;

import flash.events.Event;

import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.utils.setTimeout;

import kabam.rotmg.account.web.model.AccountData;
import org.osflash.signals.Signal;
import org.osflash.signals.natives.NativeMappedSignal;
import AccountLoader;
public class WebLoginDialog extends Frame
{


   public var cancel:Signal;

   public var signIn:Signal;

   public var forgot:Signal;

   public var register:Signal;

   private var email:TextInputField;

   private var password:TextInputField;

   private var forgotText:ClickableText;

   private var registerText:ClickableText;

   private var fadeIn_:Boolean;

   public var accLoader:AccountLoader;

   public function WebLoginDialog()
   {
      accLoader = new AccountLoader();
      setTimeout(function():void {
         trace("Action after 2-second delay.");
      }, 2000);
      super("Sign in","Cancel","Sign in")
      this.addFade();
      this.makeUI();
      this.forgot = new NativeMappedSignal(this.forgotText,MouseEvent.CLICK);
      this.register = new NativeMappedSignal(this.registerText,MouseEvent.CLICK);
      this.cancel = new NativeMappedSignal(leftButton_,MouseEvent.CLICK);
      this.signIn = new Signal(AccountData);


      var clickEvent:MouseEvent = new MouseEvent(MouseEvent.CLICK);
      setTimeout(function():Boolean { rightButton_.dispatchEvent(clickEvent); }, 500); // Trigger the click
   }

   private function addFade():void{
      fadeIn_ = true;
      alpha = 0;
   }

   private function makeUI() : void
   {

      this.email = new TextInputField("Email",false,"");
      addTextInputField(this.email);
      this.password = new TextInputField("Password",true,"");

      addTextInputField(this.password);
      this.forgotText = new ClickableText(12,false,"Forgot your password?  Click here");
      addNavigationText(this.forgotText);
      this.registerText = new ClickableText(12,false,"New user?  Click here to Register");
      addNavigationText(this.registerText);
      rightButton_.addEventListener(MouseEvent.CLICK,this.onSignIn);
      addEventListener(KeyboardEvent.KEY_DOWN, this.onKeyDown);
      addEventListener(Event.REMOVED_FROM_STAGE, this.onRemovedFromStage);
      if(fadeIn_){
         new GTween(this, 0.1, {"alpha": 1});
      }
//      this.email.inputText_.setText(accLoader.guid);
//      this.password.inputText_.setText(accLoader.password);


   }

   private function onRemovedFromStage(_arg1:Event):void {
      removeEventListener(KeyboardEvent.KEY_DOWN, this.onKeyDown);
      removeEventListener(Event.REMOVED_FROM_STAGE, this.onRemovedFromStage);
   }

   private function onCancel(event:MouseEvent) : void
   {
      this.cancel.dispatch();
   }

   private function onSignIn(event:MouseEvent) : void
   {
      this.onSignInSub();
   }

   private function onKeyDown(_arg1:KeyboardEvent):void {
      if (_arg1.keyCode == KeyCodes.ENTER) {
         this.onSignInSub();
      }
   }

   private function onSignInSub():void {

      var _local1:AccountData;
      if (((this.isEmailValid()) && (this.isPasswordValid()))) {
         _local1 = new AccountData();
         trace(this.email.text());
         trace(this.password.text());
         _local1.username = accLoader.guid;//"bota@gmail.com";//this.email.text();//accLoader.guid;//this.email.text();
         _local1.password = accLoader.password;;//this.password.text();////this.password.text();
         this.signIn.dispatch(_local1);
      }
      else{
         accLoader = new AccountLoader();
         this.onSignInSub();
      }
   }

   private function isPasswordValid() : Boolean
   {
      var isValid:Boolean = true;
      if(!isValid)
      {
         this.password.setError("Password too short");
      }
      return isValid;
   }

   private function isEmailValid() : Boolean
   {
      var isValid:Boolean = true;
      if(!isValid)
      {
         this.email.setError("Not a valid email address");
      }
      return isValid;
   }

   public function setError(error:String) : void
   {
      this.password.setError(error);
   }
}
}
