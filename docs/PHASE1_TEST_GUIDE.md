# Phase 1 Test Guide - Pawn Turtle-WoW Backport

## 🚀 Installation für Tests

### 1. Addon installieren

```bash
# Im WoW Verzeichnis:
cd Interface/AddOns/

# Erstelle Pawn Test-Verzeichnis
mkdir Pawn_TurtleWoW_Test

# Kopiere die Dateien aus dem Repo
cp -r /path/to/repo/Pawn/* ./Pawn_TurtleWoW_Test/
```

### 2. Addon aktivieren

1. Starte WoW 1.12.1 oder Turtle-WoW Client
2. Im Charakterauswahl-Bildschirm: **"AddOns"** Button
3. Aktiviere **"Pawn (Turtle-WoW Test)"**
4. Login mit einem Charakter

## ✅ Test-Checkliste Phase 1

### Automatischer Start-Test

Nach dem Login solltest du sehen:
```
=== Pawn Turtle-WoW Phase 1 Test Build ===
Phase 1 Components Loaded:
  ✓ VgerCore: 1.20
    - IsVanilla: true
    - IsTurtleWoW: [true/false je nach Client]
  ✓ API Compatibility Layer
  ✓ Event System
  ✓ Equipment Monitor
  ✓ Debug System
  ✓ Test Framework
```

### 📋 Manuelle Tests

#### Test 1: API Kompatibilität
```lua
/p1test api
```
**Erwartetes Ergebnis:**
- "API Tests: 3 passed, 0 failed"

#### Test 2: Timer System
```lua
/p1test timer
```
**Erwartetes Ergebnis:**
- 3 Ticks im Sekundentakt
- "Timer fired after 2 seconds!" nach 2 Sekunden

#### Test 3: Event System
```lua
/p1test event
```
**Dann:** Rüste ein Item aus oder an

**Erwartetes Ergebnis:**
- Nach 0.5 Sekunden: "✓ Event fired for unit: player"

#### Test 4: Equipment Monitor
```lua
/p1test equip
```
**Erwartetes Ergebnis:**
- Liste aller ausgerüsteten Items mit Slot-Namen

**Dann:** Wechsle ein Ausrüstungsteil

**Mit Debug an (`/pawndebug on`):**
- Sollte "Equipped [Item] in [Slot]" zeigen

#### Test 5: Debug System
```lua
/p1test debug
```
**Erwartetes Ergebnis:**
- ERROR message in rot
- WARNING message in gelb
- Performance test Ergebnis in ms

**Debug Log anzeigen:**
```lua
/pawndebug dump
```

### 🔍 Einzelne Komponenten testen

#### VgerCore Version Check
```lua
/script print("VgerCore Version: " .. tostring(VgerCore.Version))
/script print("IsVanilla: " .. tostring(VgerCore.IsVanilla))
/script print("BuildNumber: " .. tostring(VgerCore.BuildNumber))
```

#### GetItemInfo Test
```lua
/script local name = VgerCore.GetItemInfo(6948); print("Hearthstone name: " .. tostring(name))
```

#### Container API Test
```lua
/script print("Backpack slots: " .. PawnAPICompat.GetContainerNumSlots(0))
```

#### Timer Test (manuell)
```lua
/script C_Timer.After(1, function() print("1 second passed!") end)
```

#### Equipment Link Test
```lua
/script local link = GetInventoryItemLink("player", 1); if link then print("Head: " .. link) else print("No head item") end
```

### 🐛 Bekannte Probleme prüfen

1. **Lua Errors beim Login?**
   - `/console scriptErrors 1` aktivieren
   - Screenshot vom Error machen

2. **Timer funktioniert nicht?**
   ```lua
   /script if C_Timer then print("C_Timer exists") else print("C_Timer missing!") end
   ```

3. **Events nicht ausgelöst?**
   ```lua
   /pawndebug on
   ```
   Dann Equipment wechseln und Log prüfen

### 📊 Performance Test

```lua
/run local s=debugprofilestop(); for i=1,1000 do VgerCore.GetItemInfo(6948) end; print("1000 calls: "..(debugprofilestop()-s).."ms")
```
**Sollte sein:** < 50ms

### ⚠️ Wichtige Test-Szenarien

1. **Client-Kompatibilität:**
   - [ ] Vanilla 1.12.1 Client
   - [ ] Turtle-WoW Client
   
2. **Keine Konflikte mit:**
   - [ ] Kein Lua Error beim Start
   - [ ] Andere Addons laden normal
   
3. **Memory Usage:**
   ```lua
   /script UpdateAddOnMemoryUsage(); local mem = GetAddOnMemoryUsage("Pawn_TurtleWoW_Test"); print("Memory: " .. mem .. " KB")
   ```
   **Sollte sein:** < 500 KB nach Start

## 🎯 Erfolgs-Kriterien Phase 1

✅ **Phase 1 ist erfolgreich wenn:**

- [ ] Alle 5 Komponenten laden ohne Fehler
- [ ] `/p1test all` zeigt keine Failures
- [ ] Timer System funktioniert (2 Sekunden Verzögerung korrekt)
- [ ] Equipment Changes werden erkannt (mit Debounce)
- [ ] Debug System zeigt Logs korrekt an
- [ ] Keine Lua Errors im normalen Spielbetrieb
- [ ] Memory Usage unter 500KB

## 📝 Test-Protokoll Template

```
Datum: ________
Client: [ ] Vanilla 1.12.1  [ ] Turtle-WoW
Version: ________

Component Load Test:
[ ] VgerCore loaded
[ ] API Compat loaded  
[ ] Event System loaded
[ ] Equipment Monitor loaded
[ ] Debug System loaded
[ ] Test Framework loaded

Functional Tests:
[ ] API Test passed (___/3)
[ ] Timer Test working
[ ] Event Test working  
[ ] Equipment Test working
[ ] Debug Test working

Performance:
- Memory Usage: _____ KB
- 1000 GetItemInfo calls: _____ ms

Issues Found:
_________________________________
_________________________________

Notes:
_________________________________
```

## 🔧 Troubleshooting

### Addon lädt nicht
1. Prüfe `.toc` Datei Interface Version: `11200`
2. Prüfe Datei-Pfade in `.toc`
3. `/console reloadui`

### Lua Errors
1. `/console scriptErrors 1`
2. Screenshot vom kompletten Error
3. Prüfe ob alle Dateien vorhanden sind

### Timer funktioniert nicht
- Manche private Server haben modifizierte APIs
- Test mit einfachem OnUpdate Frame als Fallback

## 📞 Support

Bei Problemen bitte melden mit:
- Client Version (Vanilla/Turtle-WoW)
- Kompletter Lua Error Text
- Test-Protokoll ausgefüllt