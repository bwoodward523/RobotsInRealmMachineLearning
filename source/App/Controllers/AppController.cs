using Microsoft.AspNetCore.Mvc;
using System;
using System.Linq;
using System.Xml.Linq;

namespace App.Controllers
{
    [ApiController]
    [Route("app")]
    public class AppController : ControllerBase
    {
        private readonly CoreService _core;

        public AppController(CoreService core)
        {
            _core = core;
            Console.WriteLine("App Controller");
        }

        [HttpPost("getLanguageStrings")]
        public void GetLanguageStrings() => Response.CreateBytes(ReadFile($"{_core.Resources.ResourcePath}/data/languages/en.txt"));
        //[HttpPost("getLanguageStrings")]
        //public void GetLanguageStrings()
        //{
        //    var path = $"{_core.Resources.ResourcePath}/data/languages/en.txt";

        //    byte[] bytes = ReadFile(path);

        //    // Print file contents as UTF-8 text
        //    Console.WriteLine(System.Text.Encoding.UTF8.GetString(bytes));

        //    // Send response
        //    Response.CreateBytes(bytes);
        //}


        [HttpPost("serverList")]
        public void ServerList()
        {
            var servers = _core.GetServerList().Select(_ => _.ToXml());
            if (servers.Any())
            {
                var response = new XElement("Servers", new XElement("Servers", servers));
                Response.CreateXml(response.ToString());
                return;
            }
            Response.CreateError("No Servers");
        }

        [HttpPost("init")]
        public void Init() => Response.CreateBytes(ReadFile($"{_core.Resources.ResourcePath}/data/init.xml"));

        [HttpPost("globalNews")]
        public void GlobalNews() => Response.CreateBytes(ReadFile($"{_core.Resources.ResourcePath}/data/globalNews.json"));

        private static byte[] ReadFile(string path) => System.IO.File.ReadAllBytes(path);
    }
}