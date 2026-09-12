// ProxyRelay — relay local que injeta Proxy-Authorization no upstream.
// O Discord/Electron ignora usuario:senha na flag --proxy-server, entao o app
// sobe este relay em 127.0.0.1:porta e aponta o Discord para ele.
using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

public static class ProxyRelay {
    static TcpListener listener;
    static CancellationTokenSource cts;
    static string upHost;
    static int upPort;
    static string authValue;

    public static void Start(int listenPort, string upstreamHost, int upstreamPort, string user, string pass) {
        Stop();
        upHost = upstreamHost;
        upPort = upstreamPort;
        authValue = "Basic " + Convert.ToBase64String(Encoding.ASCII.GetBytes(user + ":" + pass));
        cts = new CancellationTokenSource();
        listener = new TcpListener(IPAddress.Loopback, listenPort);
        listener.Start();
        Task.Run(() => AcceptLoop(cts.Token));
    }

    static void AcceptLoop(CancellationToken token) {
        while (!token.IsCancellationRequested) {
            TcpClient client = null;
            try { client = listener.AcceptTcpClient(); }
            catch { break; }
            Task.Run(() => Handle(client));
        }
    }

    static void Handle(TcpClient client) {
        TcpClient up = null;
        try {
            client.ReceiveTimeout = 15000;
            var cs = client.GetStream();
            var head = new MemoryStream();
            var one = new byte[1];
            while (true) {
                int n = cs.Read(one, 0, 1);
                if (n <= 0) return;
                head.Write(one, 0, n);
                if (head.Length > 65536) return;
                if (head.Length >= 4) {
                    var b = head.GetBuffer();
                    long L = head.Length;
                    if (b[L-4] == 13 && b[L-3] == 10 && b[L-2] == 13 && b[L-1] == 10) break;
                }
            }
            string hs = Encoding.ASCII.GetString(head.ToArray());
            if (hs.IndexOf("Proxy-Authorization:", StringComparison.OrdinalIgnoreCase) < 0) {
                hs = hs.Replace("\r\n\r\n", "\r\nProxy-Authorization: " + authValue + "\r\n\r\n");
            }
            up = new TcpClient();
            up.Connect(upHost, upPort);
            var us = up.GetStream();
            byte[] ob = Encoding.ASCII.GetBytes(hs);
            us.Write(ob, 0, ob.Length);
            var t1 = cs.CopyToAsync(us);
            var t2 = us.CopyToAsync(cs);
            Task.WaitAny(t1, t2);
        } catch { }
        finally {
            try { if (up != null) up.Close(); } catch {}
            try { client.Close(); } catch {}
        }
    }

    public static void Stop() {
        try { if (cts != null) cts.Cancel(); } catch {}
        try { if (listener != null) listener.Stop(); } catch {}
        listener = null;
    }
}
