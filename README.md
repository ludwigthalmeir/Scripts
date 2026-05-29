# Scripts - Microsoft 365 Admin Toolkit

Dieses Repository enthaelt interaktive PowerShell-Skripte fuer wiederkehrende Microsoft 365 Administration.
Schwerpunkte sind Exchange Online, Microsoft Graph, Gruppen, Lizenzen, MFA/TAP sowie Message Trace.

## Aktueller Stand (Mai 2026)

Im Repository sind aktuell 16 Skripte plus diese README enthalten.
Alle Skripte koennen einzeln gestartet werden, zentraler Einstieg ist ueber main.ps1.

## Enthaltene Skripte

### Einstieg / Wartung

- main.ps1
  - Interaktives Admin-Menue mit aktuell 16 Menuepunkten.
- RepoUpdate.ps1
  - Klont das Repo bei fehlendem .git oder fuehrt git pull aus.

### Exchange Online - Postfachanalyse und Rechte

- Postfachattribute.ps1
  - Zeigt Basisdaten eines Postfachs (DisplayName, SMTP, Typ, Quotas).
- Postfachattribute erweitert.ps1
  - Zeigt zusaetzlich Forwarding, Statistik, Inbox Rules und explizite Berechtigungen.
- Alle Postfächer Größe.ps1
  - Listet Groesse/Anzahl/Status aller Postfaecher ueber EXO Statistics.
- Postfachberechtigungen einzelner User.ps1
  - Sucht Full Access, Send As und Send on Behalf fuer einen konkreten User tenantweit.
- Alle Postfächer Berechtigungen.ps1
  - Gibt bereichsweiten Berechtigungsueberblick je Mailbox aus (Full Access, Send As, Send on Behalf).

### Exchange Online - Mailanalyse

- Message Trace.ps1
  - Message Trace V2 fuer frei gewaehltes Start-/Enddatum inkl. Status-Summary.
- Message Trace User.ps1
  - User-bezogene Sicht auf gesendete oder empfangene Mails fuer einen Tageszeitraum.

### Gruppenverwaltung

- Gruppen und Mitglieder anzeigen.ps1
  - Kombiniert Exchange Distribution Groups sowie M365- und Security-Gruppen aus Graph.
- Gruppen Mitglieder hinzufügen.ps1
  - Interaktive Auswahl (Security, Distribution, M365), optional Gruppenerstellung und Mitglied-Hinzufuegen.

### Identity / Security

- MFA Check.ps1
  - Liest Authentifizierungsmethoden eines Users und bewertet MFA-Registrierungsstatus.
  - Zeigt zusaetzlich Hinweis auf vorhandene Conditional Access Policies.
- Befristeter Zugriffspass.ps1
  - Erstellt einen Temporary Access Pass (TAP) mit Laufzeit in Stunden (einmalig nutzbar).

### Lizenzen

- Lizenzen zuweisen.ps1
  - Zeigt Tenant-Lizenzuebersicht (belegt/gesamt/frei), mappt SKU-Namen und weist Lizenz per Index zu.

### Mailbox-Konvertierung

- Convert User zu Shared Mailbox.ps1
  - Konvertiert User-Mailbox zu Shared Mailbox.
  - Optionales Entfernen vorhandener M365-Lizenzen ueber Graph.

### Utilities

- wget.ps1
  - Einfacher Datei-Download ueber Invoke-WebRequest (URL interaktiv oder Parameter).
- Restore Public Folder.ps1
  - Sucht Public Folder unter DUMPSTER_ROOT nach Namensmuster und verschiebt optional per Zielpfad.

## Voraussetzungen

- PowerShell 7+ (pwsh)
- Microsoft 365 Adminrechte je nach Aktion
- Internetzugang zu Exchange Online und Microsoft Graph
- Optional: Git fuer RepoUpdate.ps1

## Typische verwendete Module

Die Skripte installieren fehlende Module in der Regel selbst fuer den CurrentUser.

- ExchangeOnlineManagement
- Microsoft.Graph
- Microsoft.Graph.Authentication
- Microsoft.Graph.Groups
- Microsoft.Graph.Users
- Microsoft.Graph.Identity.SignIns
- Microsoft.Graph.Identity.DirectoryManagement

## Typische Graph-Scopes (je Skript unterschiedlich)

- User.Read.All
- Directory.Read.All
- Policy.Read.All
- UserAuthenticationMethod.Read.All
- UserAuthenticationMethod.ReadWrite.All
- User.ReadWrite.All
- Directory.ReadWrite.All
- Organization.Read.All
- Group.Read.All
- GroupMember.Read.All

Hinweis: Der tatsaechlich benoetigte Scope haengt vom Tenant und von Conditional Access/Rollenmodell ab.

## Schnellstart

1. In das Repository wechseln.
2. Menue starten:

```powershell
pwsh -File ./main.ps1
```

1. Funktion per Nummer waehlen.

Direktstart einzelnes Skript:

```powershell
pwsh -File "./MFA Check.ps1"
```

## Wichtige Repo-Hinweise

- main.ps1 nutzt einen fest eingetragenen scriptPath (/home/ludwig/Dokumente/Scripts).
  Passe diesen Pfad an deine Umgebung an, wenn das Menue Skripte nicht findet.
- RepoUpdate.ps1 nutzt ebenfalls einen festen repoDir sowie eine feste repoUrl.
  Bei Forks oder abweichendem lokalen Pfad bitte anpassen.
- Die meisten Skripte verbinden sich selbststaendig zu EXO/Graph, wenn keine Session aktiv ist.
- Restore Public Folder.ps1 enthaelt keine eigene Verbindungslogik und erwartet vorhandene Rechte/Session fuer Public Folder Cmdlets.

## Betriebs- und Sicherheitshinweise

- Skripte nur mit minimal noetigen Admin-Rollen ausfuehren.
- Aenderungen (z. B. Lizenzzuweisungen, TAP, Gruppenmitgliedschaften) dokumentieren.
- Vor Nutzung in produktiven Tenants zuerst in Testumgebung pruefen.

## Lizenz

Aktuell ist keine explizite LICENSE-Datei im Repository vorhanden.
