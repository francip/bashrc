using System;
using System.Diagnostics;

class WslShell
{
    static int Main(string[] args)
    {
        var psi = new ProcessStartInfo();
        psi.FileName = @"C:\Windows\System32\wsl.exe";
        psi.UseShellExecute = false;

        // wsl-shell.exe is only invoked by sshd, so this is always an SSH session.
        // Pass SSH_CONNECTION to WSL via WSLENV so bashrc can detect SSH sessions.
        string sshConn = Environment.GetEnvironmentVariable("SSH_CONNECTION") ?? "0.0.0.0 0 0.0.0.0 22";
        psi.Environment["SSH_CONNECTION"] = sshConn;
        string wslenv = Environment.GetEnvironmentVariable("WSLENV") ?? "";
        psi.Environment["WSLENV"] = (wslenv.Length > 0 ? wslenv + ":" : "") + "SSH_CONNECTION";

        if (args.Length >= 2 && args[0] == "-c")
        {
            // Command mode: ssh runs "shell -c command"
            psi.Arguments = "-- bash -l -c " + Escape("cd && " + args[1]);
        }
        else if (args.Length == 0)
        {
            // Interactive session: login shell, start in home dir
            psi.Arguments = "-- bash -c \"cd && exec bash -li\"";
        }
        else
        {
            // Fallback
            psi.Arguments = "-- bash -l " + string.Join(" ", args);
        }

        var p = Process.Start(psi);
        p.WaitForExit();
        return p.ExitCode;
    }

    static string Escape(string s)
    {
        return "\"" + s.Replace("\\", "\\\\").Replace("\"", "\\\"") + "\"";
    }
}
