﻿using common;
using System.Collections.Generic;

namespace wServer.networking.packets.outgoing
{
    public class NewTick : OutgoingMessage
    {
        public int TickId { get; set; }
        public int TickTime { get; set; }
        public List<ObjectStats> Statuses { get; set; }

        public override MessageId MessageId => MessageId.NEWTICK;

        public NewTick()
        {
            Statuses = new List<ObjectStats>();
        }

        protected override void Write(NWriter wtr)
        {
            wtr.Write(TickId);
            wtr.Write(TickTime);
            wtr.Write((short)Statuses.Count);
            foreach (var status in Statuses)
                status.Write(wtr);
        }
    }
}
