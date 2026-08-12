import rarfile
import os

rar_path = r"C:\Users\xandao\Downloads\Marcos Cruzamento dados soluções.rar"
extract_dir = r"C:\Users\xandao\Downloads\Marcos_Cruzamento"

os.makedirs(extract_dir, exist_ok=True)

# Try to find unrar.exe in common locations
unrar_paths = [
    r"C:\Program Files\WinRAR\UnRAR.exe",
    r"C:\Program Files (x86)\WinRAR\UnRAR.exe",
    r"C:\Program Files\7-Zip\7z.exe",
]

for p in unrar_paths:
    if os.path.exists(p):
        if "7z" in p.lower():
            rarfile.UNRAR_TOOL = p
        else:
            rarfile.UNRAR_TOOL = p
        print(f"Using: {p}")
        break

try:
    with rarfile.RarFile(rar_path) as rf:
        print("Files in RAR:")
        for f in rf.namelist():
            print(f"  {f}")
        rf.extractall(extract_dir)
        print(f"\nExtracted to: {extract_dir}")
except Exception as e:
    print(f"Error: {e}")
    # Fallback: try 7z
    import subprocess
    z7 = r"C:\Program Files\7-Zip\7z.exe"
    if os.path.exists(z7):
        subprocess.run([z7, "x", "-y", f"-o{extract_dir}", rar_path], check=True)
        print(f"Extracted via 7z to: {extract_dir}")
