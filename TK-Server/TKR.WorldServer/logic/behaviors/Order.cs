﻿using System.Linq;
using TKR.WorldServer.core.miscfile.thread;
using TKR.WorldServer.core.objects;
using TKR.WorldServer.utils;

namespace TKR.WorldServer.logic.behaviors
{
    internal class Order : Behavior
    {
        private readonly ushort _children;
        private readonly double _range;
        private readonly string _targetStateName;

        private State _targetState;

        public Order(double range, string children, string targetState)
        {
            _range = range;
            _children = GetObjType(children);
            _targetStateName = targetState;
        }

        protected override void TickCore(Entity host, TickTime time, ref object state)
        {
            if (_targetState == null)
                _targetState = FindState(host.GameServer.BehaviorDb.Definitions[_children].Item1, _targetStateName);

            foreach (var i in host.GetNearestEntities(_range, _children))
                if (!i.CurrentState.Is(_targetState))
                    i.SwitchTo(_targetState);
        }

        private static State FindState(State state, string name)
        {
            if (state.Name == name)
                return state;

            return state.States.Select(i => FindState(i, name)).FirstOrDefault(s => s != null);
        }
    }
}