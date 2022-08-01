﻿using wServer.core.objects;

namespace wServer.core.commands
{
    public abstract partial class Command
    {
        internal class DeltaTimeCommand : Command
        {
            public DeltaTimeCommand() : base("deltatime")
            {
            }

            protected override bool Process(Player player, TickTime time, string args)
            {
                player.SendInfo($"[DeltaTime]: {player.World.DisplayName} -> {time.ElaspedMsDelta} | {time.LogicTime}");
                return true;
            }
        }

        internal class ClearGraves : Command
        {
            public ClearGraves() : base("cleargraves", permLevel: 90, alias: "cgraves")
            { }

            protected override bool Process(Player player, TickTime time, string args)
            {
                var total = 0;
                foreach (var entry in player.World.StaticObjects)
                {
                    var entity = entry.Value;
                    if (entity is Container || entity.ObjectDesc == null)
                        continue;

                    if (entity.ObjectDesc.ObjectId.StartsWith("Gravestone") && entity.Dist(player) < 15d)
                    {
                        player.World.LeaveWorld(entity);
                        total++;
                    }
                }

                player.SendInfo($"{total} gravestone{(total > 1 ? "s" : "")} removed!");
                return true;
            }
        }
    }
}
