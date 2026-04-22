# Scripts - Microsoft 365 Admin Toolkit

Dieses Repository enthaelt eine Sammlung von PowerShell-Skripten fuer typische Microsoft 365 Admin-Aufgaben.
Der Fokus liegt auf Exchange Online, Microsoft Graph, Gruppenverwaltung, Lizenzverwaltung und Mail-Analysen.

## Ziel des Repos

Die Skripte sollen wiederkehrende Aufgaben fuer Administratoren vereinfachen:

- Exchange Online Postfachanalyse und Berechtigungen
- Message Trace Auswertungen
- Gruppen anzeigen, erstellen und Mitglieder verwalten
- Lizenzen zuweisen
- MFA-/Authentifizierungsmethoden pruefen
- Benutzerpostfaecher in Shared Mailboxen umwandeln
- Temporary Access Pass (TAP) erzeugen

## Repository-Struktur

- `main.ps1`: Interaktives Admin-Menue als Einstiegspunkt
- `RepoUpdate.ps1`: Klont oder aktualisiert das Repository lokal
- Fachskripte: Je Thema ein separates, direkt ausfuehrbares Skript

## Voraussetzungen

- PowerShell 7+ (`pwsh`)
- Administrative Berechtigungen im jeweiligen Microsoft 365 Tenant
- Internetzugang zu Microsoft 365 Endpunkten
- Optional: Git (fuer `RepoUpdate.ps1`)

## Verwendete Module

Die Skripte installieren benoetigte Module in der Regel automatisch (`Install-Module -Scope CurrentUser`).

Hauefig verwendete Module:

- `ExchangeOnlineManagement`
- `Microsoft.Graph`
- `Microsoft.Graph.Authentication`
- `Microsoft.Graph.Groups`
- `Microsoft.Graph.Users`
- `Microsoft.Graph.Identity.SignIns`
- `Microsoft.Graph.Identity.DirectoryManagement`

## Erforderliche Rechte / Scopes (je nach Skript)

Beispiele fuer angeforderte Graph-Scopes:

- `User.Read.All`
- `Directory.Read.All`
- `UserAuthenticationMethod.ReadWrite.All`
- `UserAuthenticationMethod.Read.All`
- `User.ReadWrite.All`
- `Directory.ReadWrite.All`
- `Organization.Read.All`
- `Group.Read.All`
- `GroupMember.Read.All`

Hinweis: Welche Rollen/Rechte noetig sind, haengt vom konkreten Cmdlet und vom Tenant-Setup (z. B. Conditional Access) ab.

## Schnellstart

### Option 1: Menue verwenden

1. PowerShell 7 starten.
2. Ins Repo-Verzeichnis wechseln.
3. Menue starten:

```powershell
pwsh -File ./main.ps1
```

Danach die gewuenschte Funktion per Nummer auswaehlen.

### Option 2: Einzelskript direkt ausfuehren

```powershell
pwsh -File "./MFA Check.ps1"
```

## Skriptuebersicht

### Einstieg und Wartung

- `main.ps1`
  - Interaktives Menue fuer den Start der Admin-Skripte.
- `RepoUpdate.ps1`
  - Prueft lokales Repo-Verzeichnis und fuehrt `git clone` oder `git pull` aus.

### Exchange: Postfaecher und Berechtigungen

- `Postfachattribute.ps1`
  - Zeigt Basisattribute eines Postfachs (DisplayName, SMTP, Typ, Quotas).
- `Postfachattribute erweitert.ps1`
  - Erweiterte Postfachsicht inkl. Weiterleitung, Statistik, Inbox Rules, explizite Berechtigungen.
- `Alle Postfächer Größe.ps1`
  - Listet Groessen-/Nutzungsdaten aller Postfaecher.
- `Postfachberechtigungen einzelner User.ps1`
  - Sucht tenantweit nach Postfachrechten eines konkreten Users (Full Access, Send As, Send on Behalf).
- `Alle Postfächer Berechtigungen.ps1`
  - Erstellt einen Gesamtueberblick der Berechtigungen ueber alle Postfaecher.

### Exchange: Mail-Analyse

- `Message Trace.ps1`
  - Message Trace fuer einen frei waehlbaren Zeitraum mit Status-Zusammenfassung.
- `Message Trace User.ps1`
  - Message Trace fokussiert auf einen User (gesendet oder empfangen) fuer X Tage.

### Identity / Security

- `MFA Check.ps1`
  - Prueft Authentifizierungsmethoden eines Users und bewertet MFA-Registrierungsstatus.
- `Befristeter Zugriffspass.ps1`
  - Erstellt einen Temporary Access Pass (TAP) fuer einen User mit begrenzter Gueltigkeit.

### Gruppen

- `Gruppen und Mitglieder anzeigen.ps1`
  - Zeigt Exchange-Verteiler, Microsoft 365 Gruppen und Security Groups inkl. Mitgliedern.
- `Gruppen Mitglieder hinzufügen.ps1`
  - Waehlt Gruppentyp, sucht/erstellt Gruppe und fuegt Mitglieder interaktiv hinzu.

### Lizenzen

- `Lizenzen zuweisen.ps1`
  - Zeigt Lizenzbestand (belegt/frei/gesamt) und weist per Index-Auswahl eine Lizenz einem User zu.
  - Enthalten ist ein grosses SKU-Mapping fuer sprechende Lizenznamen.

### User-Mailbox-Konvertierung

- `Convert User zu Shared Mailbox.ps1`
  - Konvertiert eine User Mailbox zu Shared Mailbox.
  - Optional koennen anschliessend M365-Lizenzen entfernt werden.

## Typischer Ablauf in der Praxis

1. `main.ps1` starten.
2. Bei Bedarf zuerst `RepoUpdate.ps1` ausfuehren.
3. Gewuenschtes Admin-Skript waehlen.
4. Anmeldedialoge fuer Exchange Online / Graph bestaetigen.
5. User-/Gruppen-/Zeitraumparameter eingeben.
6. Ausgabe pruefen und dokumentieren.

## Wichtige Hinweise

- Einige Skripte enthalten fest konfigurierte Pfade (z. B. in `main.ps1` und `RepoUpdate.ps1`).
  Diese Pfade sollten auf deine lokale Umgebung angepasst werden.
- Viele Skripte verbinden sich bei fehlender Session automatisch mit Exchange Online oder Graph.
- Bei produktiven Tenants sollten Skripte zuerst in einer Testumgebung geprueft werden.
- Die Ausgabe erfolgt hauptsaechlich in der Konsole (`Format-Table`/`Format-List`) und ist fuer manuelle Admin-Workflows optimiert.

## Sicherheit und Betrieb

- Skripte nur mit passenden Admin-Rollen ausfuehren.
- Prinzip der minimalen Rechte beachten.
- Zugriffe und Aenderungen (z. B. Lizenzzuweisung) intern dokumentieren.
- Bei Conditional Access / MFA-Policies kann interaktive Anmeldung mehrfach erforderlich sein.

## Lizenz / Nutzung

Keine explizite Open-Source-Lizenzdatei im Repository gefunden.
Falls gewuenscht, sollte eine passende `LICENSE` Datei ergaenzt werden.
