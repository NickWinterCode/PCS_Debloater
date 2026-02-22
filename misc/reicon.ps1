# =========================================================
# DESKTOP ICON CONTROL SCRIPT (INDEX-BASED, EXE-SAFE)
# =========================================================
# Requirements:
#   - Windows desktop (Explorer) running under same user.
#   - "Auto arrange icons" OFF on desktop.
#   - Run in normal (non-admin) PowerShell.
# =========================================================

# -----------------------------------------
# 1) C#: Read icons (name + position)
# -----------------------------------------
if (-not ([System.Management.Automation.PSTypeName]'DesktopIconReader').Type) {

    $DesktopIconReaderCode = @"
    using System;
    using System.Collections.Generic;
    using System.Runtime.InteropServices;
    
    public class DesktopIconReader {
        const int LVM_FIRST = 0x1000;
        const int LVM_GETITEMCOUNT   = LVM_FIRST + 4;
        const int LVM_GETITEMTEXTW   = LVM_FIRST + 115;
        const int LVM_GETITEMPOSITION = LVM_FIRST + 16;
    
        const uint MEM_COMMIT   = 0x1000;
        const uint MEM_RELEASE  = 0x8000;
        const uint PAGE_READWRITE = 0x04;
        const uint PROCESS_VM_OPERATION = 0x0008;
        const uint PROCESS_VM_READ      = 0x0010;
        const uint PROCESS_VM_WRITE     = 0x0020;
        const int LVIF_TEXT = 0x0001;
    
        [StructLayout(LayoutKind.Sequential)]
        public struct POINT {
            public int x;
            public int y;
        }
    
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct LVITEM {
            public uint mask;
            public int iItem;
            public int iSubItem;
            public uint state;
            public uint stateMask;
            public IntPtr pszText;
            public int cchTextMax;
            public int iImage;
            public IntPtr lParam;
            public int iIndent;
            public int iGroupId;
            public uint cColumns;
            public IntPtr puColumns;
        }
    
        public class IconInfo {
            public string Name;
            public int X;
            public int Y;
        }
    
        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        static extern IntPtr SendMessage(IntPtr hWnd, int Msg, int wParam, IntPtr lParam);
    
        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        static extern IntPtr FindWindowEx(IntPtr parentHandle, IntPtr childAfter, string className, string windowTitle);
    
        [DllImport("user32.dll", SetLastError = true)]
        static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern IntPtr OpenProcess(uint dwDesiredAccess, bool bInheritHandle, uint dwProcessId);
    
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);
    
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, IntPtr lpBuffer, uint nSize, out IntPtr lpNumberOfBytesWritten);
    
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, IntPtr lpBuffer, uint nSize, out IntPtr lpNumberOfBytesRead);
    
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool VirtualFreeEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint dwFreeType);
    
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool CloseHandle(IntPtr hObject);
    
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    
        private static IntPtr _foundListView = IntPtr.Zero;
    
        public static IntPtr GetDesktopListView() {
            _foundListView = IntPtr.Zero;
    
            // 1) Try Progman -> SHELLDLL_DefView -> SysListView32
            IntPtr progman = FindWindowEx(IntPtr.Zero, IntPtr.Zero, "Progman", null);
            IntPtr shell = FindWindowEx(progman, IntPtr.Zero, "SHELLDLL_DefView", null);
            if (shell != IntPtr.Zero) {
                _foundListView = FindWindowEx(shell, IntPtr.Zero, "SysListView32", null);
                if (_foundListView != IntPtr.Zero) return _foundListView;
            }
    
            // 2) Fallback: search all to find SHELLDLL_DefView -> SysListView32
            EnumWindows(new EnumWindowsProc(EnumProc), IntPtr.Zero);
            return _foundListView;
        }
    
        private static bool EnumProc(IntPtr hWnd, IntPtr lParam) {
            IntPtr shellDll = FindWindowEx(hWnd, IntPtr.Zero, "SHELLDLL_DefView", null);
            if (shellDll != IntPtr.Zero) {
                IntPtr listView = FindWindowEx(shellDll, IntPtr.Zero, "SysListView32", null);
                if (listView != IntPtr.Zero) {
                    _foundListView = listView;
                    return false; // stop
                }
            }
            return true; // continue
        }
    
        public static IconInfo[] GetIcons() {
            List<IconInfo> results = new List<IconInfo>();
    
            IntPtr hWnd = GetDesktopListView();
            if (hWnd == IntPtr.Zero) return results.ToArray();
    
            uint processId;
            GetWindowThreadProcessId(hWnd, out processId);
    
            IntPtr hProcess = OpenProcess(PROCESS_VM_OPERATION | PROCESS_VM_READ | PROCESS_VM_WRITE, false, processId);
            if (hProcess == IntPtr.Zero) return results.ToArray();
    
            int count = (int)SendMessage(hWnd, LVM_GETITEMCOUNT, 0, IntPtr.Zero);
            if (count <= 0) {
                CloseHandle(hProcess);
                return results.ToArray();
            }
    
            int pointSize = Marshal.SizeOf(typeof(POINT));
            int lvItemSize = Marshal.SizeOf(typeof(LVITEM));
            int maxChars  = 512;
    
            IntPtr remotePoint = VirtualAllocEx(hProcess, IntPtr.Zero, (uint)pointSize, MEM_COMMIT, PAGE_READWRITE);
            IntPtr remoteItem  = VirtualAllocEx(hProcess, IntPtr.Zero, (uint)lvItemSize, MEM_COMMIT, PAGE_READWRITE);
            IntPtr remoteText  = VirtualAllocEx(hProcess, IntPtr.Zero, (uint)(maxChars * 2), MEM_COMMIT, PAGE_READWRITE);
    
            if (remotePoint == IntPtr.Zero || remoteItem == IntPtr.Zero || remoteText == IntPtr.Zero) {
                if (remotePoint != IntPtr.Zero) VirtualFreeEx(hProcess, remotePoint, 0, MEM_RELEASE);
                if (remoteItem  != IntPtr.Zero) VirtualFreeEx(hProcess, remoteItem,  0, MEM_RELEASE);
                if (remoteText  != IntPtr.Zero) VirtualFreeEx(hProcess, remoteText,  0, MEM_RELEASE);
                CloseHandle(hProcess);
                return results.ToArray();
            }
    
            IntPtr bytesRead;
            IntPtr bytesWritten;
    
            for (int i = 0; i < count; i++) {
                IconInfo info = new IconInfo();
    
                // --- POSITION ---
                SendMessage(hWnd, LVM_GETITEMPOSITION, i, remotePoint);
                byte[] ptBytes = new byte[pointSize];
                GCHandle hPt = GCHandle.Alloc(ptBytes, GCHandleType.Pinned);
                ReadProcessMemory(hProcess, remotePoint, hPt.AddrOfPinnedObject(), (uint)pointSize, out bytesRead);
                POINT pt = (POINT)Marshal.PtrToStructure(hPt.AddrOfPinnedObject(), typeof(POINT));
                hPt.Free();
    
                info.X = pt.x;
                info.Y = pt.y;
    
                // --- TEXT ---
                LVITEM lvi = new LVITEM();
                lvi.mask = LVIF_TEXT;
                lvi.iItem = i;
                lvi.iSubItem = 0;
                lvi.pszText = remoteText;
                lvi.cchTextMax = maxChars;
    
                IntPtr localItem = Marshal.AllocHGlobal(lvItemSize);
                Marshal.StructureToPtr(lvi, localItem, false);
                WriteProcessMemory(hProcess, remoteItem, localItem, (uint)lvItemSize, out bytesWritten);
                Marshal.FreeHGlobal(localItem);
    
                SendMessage(hWnd, LVM_GETITEMTEXTW, i, remoteItem);
    
                byte[] textBytes = new byte[maxChars * 2];
                GCHandle hTxt = GCHandle.Alloc(textBytes, GCHandleType.Pinned);
                ReadProcessMemory(hProcess, remoteText, hTxt.AddrOfPinnedObject(), (uint)(maxChars * 2), out bytesRead);
                info.Name = Marshal.PtrToStringUni(hTxt.AddrOfPinnedObject());
                hTxt.Free();
    
                results.Add(info);
            }
    
            VirtualFreeEx(hProcess, remotePoint, 0, MEM_RELEASE);
            VirtualFreeEx(hProcess, remoteItem,  0, MEM_RELEASE);
            VirtualFreeEx(hProcess, remoteText,  0, MEM_RELEASE);
            CloseHandle(hProcess);
    
            return results.ToArray();
        }
    }
"@
    
    Add-Type -TypeDefinition $DesktopIconReaderCode -Language CSharp
}

function Get-DesktopIconPositions {
    [DesktopIconReader]::GetIcons()
}

# -----------------------------------------
# 2) C#: Move icon by index (no name search)
# -----------------------------------------
if (-not ([System.Management.Automation.PSTypeName]'DesktopIconMoverByIndex').Type) {

$DesktopIconMoverByIndexCode = @"
using System;
using System.Runtime.InteropServices;

public class DesktopIconMoverByIndex {
    const int LVM_FIRST = 0x1000;
    const int LVM_SETITEMPOSITION = LVM_FIRST + 15;

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    static extern IntPtr SendMessage(IntPtr hWnd, int Msg, int wParam, IntPtr lParam);

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    static extern IntPtr FindWindowEx(IntPtr parentHandle, IntPtr childAfter, string className, string windowTitle);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    private static IntPtr _foundListView = IntPtr.Zero;

    public static IntPtr GetDesktopListView() {
        _foundListView = IntPtr.Zero;
        IntPtr progman = FindWindowEx(IntPtr.Zero, IntPtr.Zero, "Progman", null);
        IntPtr shell = FindWindowEx(progman, IntPtr.Zero, "SHELLDLL_DefView", null);
        if (shell != IntPtr.Zero) {
            _foundListView = FindWindowEx(shell, IntPtr.Zero, "SysListView32", null);
            if (_foundListView != IntPtr.Zero) return _foundListView;
        }
        EnumWindows(new EnumWindowsProc(EnumProc), IntPtr.Zero);
        return _foundListView;
    }

    private static bool EnumProc(IntPtr hWnd, IntPtr lParam) {
        IntPtr shellDll = FindWindowEx(hWnd, IntPtr.Zero, "SHELLDLL_DefView", null);
        if (shellDll != IntPtr.Zero) {
            IntPtr listView = FindWindowEx(shellDll, IntPtr.Zero, "SysListView32", null);
            if (listView != IntPtr.Zero) {
                _foundListView = listView;
                return false;
            }
        }
        return true;
    }

    public static string MoveByIndex(int index, int x, int y) {
        IntPtr hWnd = GetDesktopListView();
        if (hWnd == IntPtr.Zero) return "Error: Could not find Desktop Handle.";

        int lparam = (y << 16) | (x & 0xFFFF);
        SendMessage(hWnd, LVM_SETITEMPOSITION, index, (IntPtr)lparam);

        return "Success";
    }
}
"@

    Add-Type -TypeDefinition $DesktopIconMoverByIndexCode -Language CSharp
}

# Helper: get icons with their listview index
function Get-DesktopIconPositionsWithIndex {
    $icons = Get-DesktopIconPositions
    $i = 0
    foreach ($icon in $icons) {
        [PSCustomObject]@{
            Index = $i
            Name  = $icon.Name
            X     = $icon.X
            Y     = $icon.Y
        }
        $i++
    }
}

# -----------------------------------------
# 3) Helper: Find icon by name with fallbacks
# -----------------------------------------
function Find-DesktopIcon {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)]$Icons
    )

    # 1) Try exact case-sensitive match
    $icon = $Icons | Where-Object { $_.Name -ceq $Name } | Select-Object -First 1
    if ($icon) { return $icon }

    # 2) Try exact case-insensitive match
    $icon = $Icons | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
    if ($icon) { return $icon }

    # 3) Try prefix match (e.g., "LibreOffice" matches "LibreOffice 25.5")
    $icon = $Icons | Where-Object { $_.Name -like "$Name *" } | Select-Object -First 1
    if ($icon) { return $icon }

    # 4) Try contains match as last resort
    $icon = $Icons | Where-Object { $_.Name -like "*$Name*" } | Select-Object -First 1
    return $icon
}

# -----------------------------------------
# 4) Move by name (using index) - with prefix matching
# -----------------------------------------
function Move-DesktopIconByExactName {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][int]$X,
        [Parameter(Mandatory = $true)][int]$Y
    )

    $icons = Get-DesktopIconPositionsWithIndex
    $icon = Find-DesktopIcon -Name $Name -Icons $icons

    if (-not $icon) {
        Write-Error "No desktop icon found matching '$Name'."
        return
    }

    $res = [DesktopIconMoverByIndex]::MoveByIndex($icon.Index, $X, $Y)
    if ($res -eq "Success") {
        Write-Host "Moved '$($icon.Name)' to $X,$Y" -ForegroundColor Green
        $sh = New-Object -ComObject Shell.Application
        $sh.NameSpace(0).Self.InvokeVerb("Refresh")
    } else {
        Write-Error $res
    }
}

# -----------------------------------------
# 5) Swap-aware move by name - with prefix matching
# -----------------------------------------
function Get-ClosestIconTo {
    param(
        [Parameter(Mandatory = $true)][int]$X,
        [Parameter(Mandatory = $true)][int]$Y,
        [int]$MaxDistance = 5
    )

    $icons = Get-DesktopIconPositionsWithIndex
    if (-not $icons) { return $null }

    $closest = $null
    $best = [double]::MaxValue

    foreach ($icon in $icons) {
        $dx = $icon.X - $X
        $dy = $icon.Y - $Y
        $d = [math]::Sqrt($dx*$dx + $dy*$dy)
        if ($d -le $MaxDistance -and $d -lt $best) {
            $best = $d
            $closest = $icon
        }
    }

    $closest
}

function Set-IconPositionWithSwap {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][int]$X,
        [Parameter(Mandatory = $true)][int]$Y,
        [int]$SnapTolerance = 5
    )

    $icons = Get-DesktopIconPositionsWithIndex
    $thisIcon = Find-DesktopIcon -Name $Name -Icons $icons

    if (-not $thisIcon) {
        Write-Error "Icon '$Name' not found on desktop."
        return
    }

    $targetIcon = Get-ClosestIconTo -X $X -Y $Y -MaxDistance $SnapTolerance

    if ($targetIcon -and $targetIcon.Name -ne $thisIcon.Name) {
        Write-Host "Swapping '$($thisIcon.Name)' with '$($targetIcon.Name)'" -ForegroundColor Yellow
        [DesktopIconMoverByIndex]::MoveByIndex($targetIcon.Index, $thisIcon.X, $thisIcon.Y)
        [DesktopIconMoverByIndex]::MoveByIndex($thisIcon.Index, $X, $Y)
        $sh = New-Object -ComObject Shell.Application
        $sh.NameSpace(0).Self.InvokeVerb("Refresh")
    } else {
        # Use actual found icon name for the move
        Move-DesktopIconByExactName -Name $thisIcon.Name -X $X -Y $Y
    }
}

# -----------------------------------------
# 6) Map desktop items to file paths, move EXEs
# -----------------------------------------
function Get-DesktopShellItems {
    $shell = New-Object -ComObject Shell.Application
    $desktopNS = $shell.NameSpace(0)   # 0 = Desktop (virtual)

    $items = @()
    for ($i = 0; $i -lt $desktopNS.Items().Count; $i++) {
        $item = $desktopNS.Items().Item($i)
        $obj = [PSCustomObject]@{
            Name       = $item.Name
            Path       = $item.Path
            IsLink     = $item.IsLink()
            TargetPath = $null
        }
        if ($obj.IsLink) {
            try {
                $lnk = $item.GetLink()
                $obj.TargetPath = $lnk.Path
            } catch { }
        }
        $items += $obj
    }

    $items
}

function Get-DesktopIconNameForExe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExePath
    )

    $resolved = Resolve-Path -LiteralPath $ExePath -ErrorAction Stop
    $fullExe = $resolved.Path

    $shellItems = Get-DesktopShellItems

    $directItem = $shellItems | Where-Object { $_.Path -eq $fullExe } | Select-Object -First 1
    $shortcutItem = $shellItems | Where-Object { $_.TargetPath -eq $fullExe } | Select-Object -First 1

    if ($directItem) { return $directItem.Name }
    if ($shortcutItem) { return $shortcutItem.Name }

    Write-Error "No desktop item found whose Path or TargetPath equals '$fullExe'."
    return $null
}

function Set-ExePositionWithSwap {
    param(
        [Parameter(Mandatory = $true)][string]$ExePath,
        [Parameter(Mandatory = $true)][int]$X,
        [Parameter(Mandatory = $true)][int]$Y,
        [int]$SnapTolerance = 5
    )

    $name = Get-DesktopIconNameForExe -ExePath $ExePath
    if (-not $name) { return }

    Set-IconPositionWithSwap -Name $name -X $X -Y $Y -SnapTolerance $SnapTolerance
}

# -----------------------------------------
# 7) Usage examples (commented)
# -----------------------------------------

# See all icons:
# Get-DesktopIconPositionsWithIndex | Format-Table -AutoSize

# Move by visible name (swap-aware) - now supports partial names:
# Set-IconPositionWithSwap -Name "LibreOffice" -X 36 -Y 402
# This will find "LibreOffice 25.5", "LibreOffice 26.0", etc.

# Move EXE directly on desktop:
# Set-ExePositionWithSwap -ExePath "$env:USERPROFILE\Desktop\SomeApp.exe" -X 1836 -Y 2