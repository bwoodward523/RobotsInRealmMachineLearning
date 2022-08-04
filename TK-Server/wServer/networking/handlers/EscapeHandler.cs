﻿using wServer.core;
using wServer.core.worlds;
using wServer.networking.packets;
using wServer.networking.packets.incoming;
using wServer.networking.packets.outgoing;

namespace wServer.networking.handlers
{
    internal class EscapeHandler : PacketHandlerBase<Escape>
    {
        public override PacketId ID => PacketId.ESCAPE;

        protected override void HandlePacket(Client client, Escape packet, ref TickTime time) => Handle(client, packet);

        private void Handle(Client client, Escape packet)
        {
            if (client.Player == null || client.Player.World == null)
                return;

            var map = client.Player.World;

            if (map.Id == World.Nexus)
            {
                client.Disconnect("Already in Nexus!");
                return;
            }

            client.Reconnect(new Reconnect()
            {
                Host = "",
                Port = client.CoreServerManager.ServerConfig.serverInfo.port,
                GameId = World.Nexus,
                Name = "Nexus"
            });
        }
    }
}
