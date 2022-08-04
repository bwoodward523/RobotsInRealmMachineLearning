﻿using wServer.core;
using wServer.networking.packets;
using wServer.networking.packets.incoming;

namespace wServer.networking.handlers
{
    internal class GotoAckHandler : PacketHandlerBase<GotoAck>
    {
        public override PacketId ID => PacketId.GOTOACK;

        protected override void HandlePacket(Client client, GotoAck packet, ref TickTime time) => client.Player.GotoAckReceived();
    }
}
