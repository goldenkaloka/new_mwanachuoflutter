# Install Supabase CLI on Windows (Without Scoop)

## Method 1: Direct Download (Easiest)

### Step 1: Download the CLI
1. Go to: https://github.com/supabase/cli/releases/latest
2. Download: `supabase_windows_amd64.zip` (or `supabase_windows_arm64.zip` if you have ARM)
3. Extract the ZIP file
4. You'll get a file named `supabase.exe`

### Step 2: Add to PATH (Option A - Temporary)
1. Copy `supabase.exe` to a folder like `C:\supabase\`
2. Open PowerShell in that folder
3. Run commands from there:
   ```powershell
   .\supabase.exe --version
   .\supabase.exe login
   ```

### Step 2: Add to PATH (Option B - Permanent)
1. Copy `supabase.exe` to `C:\supabase\` (or any folder you prefer)
2. Add to PATH:
   - Press `Win + X` → System → Advanced system settings
   - Click "Environment Variables"
   - Under "User variables", find "Path" and click "Edit"
   - Click "New" and add: `C:\supabase`
   - Click OK on all dialogs
3. Restart PowerShell/Terminal
4. Verify:
   ```powershell
   supabase --version
   ```

---

## Method 2: Using Chocolatey (If You Have It)

```powershell
choco install supabase
```

---

## Method 3: Using npm (If You Have Node.js)

```powershell
npm install -g supabase
```

---

## Method 4: Using winget (Windows Package Manager)

```powershell
winget install Supabase.CLI
```

---

## Quick Test After Installation

Once installed, test it:
```powershell
supabase --version
```

You should see something like: `supabase 1.x.x`

---

## Next Steps After Installation

1. **Login:**
   ```powershell
   supabase login
   ```

2. **Link your project:**
   ```powershell
   supabase link --project-ref yhuujolmbqvntzifoaed
   ```

3. **Deploy your function:**
   ```powershell
   cd C:\Users\julius\Desktop\new_mwanachuoflutter
   supabase functions deploy send-notification
   ```

---

## Troubleshooting

### "supabase: command not found"
- Make sure you added it to PATH
- Restart your terminal/PowerShell
- Try using the full path: `C:\supabase\supabase.exe --version`

### "Access denied" or permission errors
- Run PowerShell as Administrator
- Or install to a folder you have write access to

### Still having issues?
- Try Method 1 (Direct Download) - it's the most reliable
- Make sure you download the correct version (amd64 for most Windows PCs)


