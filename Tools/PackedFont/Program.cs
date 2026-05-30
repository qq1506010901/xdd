using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Text;
using System.Text.RegularExpressions;

static class UltraCompressor
{
    // ---------- Base91 编码表 ----------
    private const string Base91Table =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" +
        "!#$%&()*+,./:;<=>?@[]^_`{|}~\"";

    public static string ToBase91(byte[] data)
    {
        var sb = new StringBuilder();
        int b = 0;   // bit 缓冲
        int n = 0;   // 当前缓冲中有多少位

        foreach (byte value in data)
        {
            b |= (value & 255) << n;
            n += 8;

            // 每当缓存位数足够时（>13），输出 2 个 Base91 字符
            if (n > 13)
            {
                int v = b & 8191; // 2^13 - 1
                if (v > 88)
                {
                    b >>= 13;
                    n -= 13;
                }
                else
                {
                    v = b & 16383;
                    b >>= 14;
                    n -= 14;
                }

                sb.Append(Base91Table[v % 91]);
                sb.Append(Base91Table[v / 91]);
            }
        }

        // 输出剩余位
        if (n > 0)
        {
            int v = b;
            sb.Append(Base91Table[v % 91]);
            if (n > 7 || v > 90)
                sb.Append(Base91Table[v / 91]);
        }

        return sb.ToString();
    }


    // ---------- 自适应位打包 ----------
    public static byte[] PackBits(int[] arr)
    {
        if (arr.Length == 0) return Array.Empty<byte>();

        int max = 0;
        foreach (var v in arr) max = Math.Max(max, Math.Abs(v));
        int bits = max <= 15 ? 4 : max <= 63 ? 6 : 8;

        int bitCount = 0;
        int current = 0;
        var bytes = new List<byte>();

        foreach (int value in arr)
        {
            int v = value & ((1 << bits) - 1);
            current |= v << bitCount;
            bitCount += bits;
            while (bitCount >= 8)
            {
                bytes.Add((byte)(current & 0xFF));
                current >>= 8;
                bitCount -= 8;
            }
        }

        if (bitCount > 0)
            bytes.Add((byte)current);

        // 在开头写入：bits, 元素数量
        bytes.Insert(0, (byte)arr.Length); // [1] 元素数量
        bytes.Insert(0, (byte)bits);       // [0] bit位数

        return bytes.ToArray();
    }
}

class Program
{
    static void Main()
    {
        string curDir = Environment.CurrentDirectory;
        string inDir = Path.Combine(curDir, "in");
        string outDir = Path.Combine(curDir, "out");
        Directory.CreateDirectory(outDir);

        string[] files = Directory.GetFiles(inDir, "*.lua");
        int index = 0;
        foreach (var file in files)
        {
            string text = File.ReadAllText(file);
            string pattern = @"\['(?<key>[^']+)'\]\s*=\s*\{\{(?<first>[^\}]+)\},\{(?<second>[^\}]+)\}\}";
            var matches = Regex.Matches(text, pattern, RegexOptions.Singleline);

            var sb = new StringBuilder();
            sb.AppendLine($"TextBase91_{index}="+ "{");
            index++;
            foreach (Match m in matches)
            {
                string key = m.Groups["key"].Value;
                string combined = (m.Groups["first"].Value + "," + m.Groups["second"].Value)
                    .Replace("\r", "").Replace("\n", "").Trim(',');

                try
                {
                    int[] data = Array.ConvertAll(combined.Split(','), s => int.Parse(s.Trim()));
                    byte[] packed = UltraCompressor.PackBits(data);
                    string base91 = UltraCompressor.ToBase91(packed);
                    sb.AppendLine($"    ['{key}'] = '{base91}',");
                }
                catch (Exception ex) 
                {
                    Console.WriteLine($"跳过{key}");
                    Console.WriteLine(ex.Message);
                    continue;
                }
            }

            sb.AppendLine("}");
            string outFile = Path.Combine(outDir, Path.GetFileName(file));
            File.WriteAllText(outFile, sb.ToString(), Encoding.UTF8);
            Console.WriteLine($"✅ 已生成 Lua 文件：{outFile}");
        }

        Console.WriteLine("✅ 全部完成！");
        Console.ReadLine();

    }
}
