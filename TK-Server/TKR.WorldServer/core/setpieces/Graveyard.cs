﻿using System.Collections.Generic;
using System.Linq;
using TKR.Shared;
using TKR.Shared.resources;
using TKR.WorldServer.core.miscfile.structures;
using TKR.WorldServer.core.objects;
using TKR.WorldServer.core.objects.containers;
using TKR.WorldServer.core.worlds;
using TKR.WorldServer.logic.loot;

namespace TKR.WorldServer.core.setpieces
{
    internal class Graveyard : ISetPiece
    {
        private static readonly ChestLoot chest = new ChestLoot(
            new TierLoot(4, ItemType.Weapon, 0.3),
            new TierLoot(5, ItemType.Weapon, 0.2),
            new TierLoot(6, ItemType.Weapon, 0.1),
            new TierLoot(3, ItemType.Armor, 0.3),
            new TierLoot(4, ItemType.Armor, 0.2),
            new TierLoot(5, ItemType.Armor, 0.1),
            new TierLoot(1, ItemType.Ability, 0.3),
            new TierLoot(2, ItemType.Ability, 0.2),
            new TierLoot(3, ItemType.Ability, 0.2),
            new TierLoot(1, ItemType.Ring, 0.25),
            new TierLoot(2, ItemType.Ring, 0.15),
            new TierLoot(1, ItemType.Potion, 0.5)
        );

        private static readonly string Cross = "Cross";
        private static readonly string Floor = "Grass";
        private static readonly string WallA = "Grey Wall";
        private static readonly string WallB = "Destructible Grey Wall";


        public override int Size => 34;

        public override void RenderSetPiece(World world, IntPoint pos)
        {
            var t = new int[23, 35];

            for (var x = 0; x < 23; x++)    //Floor
                for (var y = 0; y < 35; y++)
                    t[x, y] = world.Random.Next() % 3 == 0 ? 0 : 1;

            for (var y = 0; y < 35; y++)    //Perimeters
                t[0, y] = t[22, y] = 2;

            for (var x = 0; x < 23; x++)
                t[x, 0] = t[x, 34] = 2;

            var pts = new List<IntPoint>();

            for (var y = 0; y < 11; y++)    //Crosses
                for (var x = 0; x < 7; x++)
                {
                    if (world.Random.Next() % 3 > 0)
                        t[2 + 3 * x, 2 + 3 * y] = 4;
                    else
                        pts.Add(new IntPoint(2 + 3 * x, 2 + 3 * y));
                }

            for (var x = 0; x < 23; x++)    //Corruption
                for (var y = 0; y < 35; y++)
                {
                    if (t[x, y] == 1 || t[x, y] == 0 || t[x, y] == 4)
                        continue;

                    var p = world.Random.NextDouble();

                    if (p < 0.1)
                        t[x, y] = 1;
                    else if (p < 0.4)
                        t[x, y]++;
                }

            //Boss & Chest
            var pt = world.Random.NextLength(pts);
            t[pt.X, pt.Y] = 5;
            t[pt.X + 1, pt.Y] = 6;

            var r = world.Random.Next(0, 4);

            for (var i = 0; i < r; i++)     //Rotation
                t = SetPieces.RotateCW(t);

            var w = t.GetLength(0);
            var h = t.GetLength(1);
            var dat = world.GameServer.Resources.GameData;

            for (var x = 0; x < w; x++)     //Rendering
                for (var y = 0; y < h; y++)
                    if (t[x, y] == 1)
                    {
                        var tile = world.Map[x + pos.X, y + pos.Y];
                        tile.TileId = dat.IdToTileType[Floor];
                        tile.ObjType = 0;
                        tile.UpdateCount++;
                    }
                    else if (t[x, y] == 2)
                    {
                        var tile = world.Map[x + pos.X, y + pos.Y];
                        tile.TileId = dat.IdToTileType[Floor];
                        tile.ObjType = dat.IdToObjectType[WallA];
                        tile.ObjDesc = dat.ObjectDescs[tile.ObjType];

                        if (tile.ObjId == 0)
                            tile.ObjId = world.GetNextEntityId();

                        tile.UpdateCount++;
                    }
                    else if (t[x, y] == 3)
                    {
                        var tile = world.Map[x + pos.X, y + pos.Y];
                        tile.TileId = dat.IdToTileType[Floor];
                        tile.UpdateCount++;

                        var wall = Entity.Resolve(world.GameServer, dat.IdToObjectType[WallB]);
                        wall.Move(x + pos.X + 0.5f, y + pos.Y + 0.5f);
                        world.EnterWorld(wall);
                    }
                    else if (t[x, y] == 4)
                    {
                        var tile = world.Map[x + pos.X, y + pos.Y];
                        tile.TileId = dat.IdToTileType[Floor];
                        tile.ObjType = dat.IdToObjectType[Cross];
                        tile.ObjDesc = dat.ObjectDescs[tile.ObjType];

                        if (tile.ObjId == 0)
                            tile.ObjId = world.GetNextEntityId();

                        tile.UpdateCount++;
                    }
                    else if (t[x, y] == 5)
                    {
                        var container = new Container(world.GameServer, 0x0501, null, false);
                        var items = chest.CalculateItems(world.GameServer, world.Random, 3, 8).ToArray();

                        for (int i = 0; i < items.Length; i++)
                            container.Inventory[i] = items[i];

                        container.Move(pos.X + x + 0.5f, pos.Y + y + 0.5f);
                        world.EnterWorld(container);
                    }
                    else if (t[x, y] == 6)
                    {
                        var mage = Entity.Resolve(world.GameServer, "Deathmage");
                        mage.Move(pos.X + x, pos.Y + y);
                        world.EnterWorld(mage);
                    }
        }
    }
}