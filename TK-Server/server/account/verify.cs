﻿using Anna.Request;
using common.database;
using common.utils;
using System.Collections.Specialized;

namespace server.account
{
    internal class verify : RequestHandler
    {
        public override void HandleRequest(RequestContext context, NameValueCollection query)
        {
            if(query["secret"] != "69420")
                Write(context, "<Error>Internal Server Error</Error>");
            var status = _db.Verify(query["guid"], query["password"], out DbAccount acc);
            if (status == DbLoginStatus.OK)
                Write(context, Account.FromDb(acc).ToXml().ToString());
            else
                Write(context, "<Error>" + status.GetInfo() + "</Error>");
        }
    }
}
