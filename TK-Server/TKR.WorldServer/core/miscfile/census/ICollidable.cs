﻿namespace TKR.WorldServer.core.miscfile.census
{
    public interface ICollidable<T> where T : ICollidable<T>
    {
        CollisionNode<T> CollisionNode { get; set; }
        CollisionMap<T> Parent { get; set; }
        float X { get; }
        float Y { get; }
    }
}