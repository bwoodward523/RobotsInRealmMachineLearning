﻿using System.Collections.Generic;

namespace wServer.core.objects.connection
{
    public class ConnectedObject : StaticObject
    {
        public ConnectedObject(GameServer manager, ushort objType) : base(manager, objType, null, true, false, true)
        { }

        public ConnectedObjectInfo Connection { get; set; }

        public override bool HitByProjectile(Entity shooter, Projectile projectile, TickTime time) => true;

        protected override void ExportStats(IDictionary<StatDataType, object> stats, bool isOtherPlayer)
        {
            stats[StatDataType.ObjectConnection] = (int)Connection.Bits;

            base.ExportStats(stats, isOtherPlayer);
        }
    }
}
