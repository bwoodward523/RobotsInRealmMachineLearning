package com.company.assembleegameclient.objects {
import com.company.assembleegameclient.game.GameSprite;

import com.company.assembleegameclient.ui.panels.Panel;
import com.company.assembleegameclient.ui.panels.EssencePanel;

public class Essence extends GameObject implements IInteractiveObject {

    public function Essence(_arg1:XML) {
        super(_arg1);
        isInteractive_ = true;
    }

    public function getPanel(_arg1:GameSprite):Panel {
        return new EssencePanel(_arg1, this);
    }
}
}
