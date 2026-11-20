# PrintCam · RUBBS3D

Controlla una stampa 3D con due iPhone. Il primo riprende il piatto e illumina il pezzo con la torcia. Dal secondo apri Safari per guardare la diretta e regolare la luce, anche fuori casa tramite Tailscale.

## Cosa serve

- Un iPhone con iOS 16 o successivo da mettere in verticale vicino alla stampante.
- Un secondo iPhone con Safari. Installa Tailscale su entrambi e collegali allo stesso account.
- Per il primo sideload da Windows servono un PC, un cavo USB dati, Sideloadly e un account Apple.

## 1. Scarica PrintCam.ipa

Apri la scheda **Actions** di questo repository e seleziona **Crea IPA**. Apri una compilazione con la spunta verde. In fondo alla pagina, nella sezione **Artifacts**, scarica **PrintCam-per-sideload** ed estrai il file ZIP. Al suo interno trovi **PrintCam.ipa**. Per scaricare gli artefatti accedi a GitHub.

Se sei il proprietario puoi avviare una nuova compilazione con **Run workflow → main → Run workflow**. Se hai scaricato lo ZIP con il pulsante verde **Code**, hai i sorgenti del progetto. Per l’installazione su iPhone usa l’IPA generata da Actions.

## 2. Installa l’app da Windows

1. Scarica [Sideloadly per Windows dal sito ufficiale](https://sideloadly.io/). Segui le indicazioni della pagina per le versioni Windows di iTunes e iCloud.
2. Collega via USB **l’iPhone che userai vicino alla stampante**. Sbloccalo e conferma **Autorizza questo computer** se richiesto.
3. Apri Sideloadly e seleziona il telefono nel campo **iDevice**. Trascina **PrintCam.ipa** nella casella IPA.
4. Inserisci il tuo account Apple in Sideloadly, premi **Start** e completa l’autenticazione. Attendi **Done**.
5. Apri PrintCam sull’iPhone. Se compare un avviso sullo sviluppatore, vai in **Impostazioni → Generali → VPN e gestione dispositivo**, scegli il profilo con la tua email e autorizzalo.
6. Se richiesto, attiva **Impostazioni → Privacy e sicurezza → Modalità sviluppatore**. Riavvia, sblocca e conferma.

Con un account Apple gratuito la firma dura sette giorni. Puoi usare il rinnovo automatico di Sideloadly oppure firmare di nuovo la stessa IPA con lo stesso account. Per il rinnovo automatico il PC deve poter raggiungere il telefono.

## 3. Collega la postazione a Safari

1. Apri Tailscale su entrambi gli iPhone e verifica che risultino connessi. Copia l’IPv4 Tailscale **del telefono vicino alla stampante**, nel formato 100.x.y.z.
2. Apri PrintCam su quel telefono. Inserisci l’IP in **Collega il secondo iPhone**, premi **Avvia telecamera** e autorizza la fotocamera e la rete locale, se richiesto.
3. Inquadra il piatto e premi **Condividi link privato**. Invia il collegamento completo al secondo telefono e aprilo in Safari. La parte dopo il simbolo # contiene la chiave per accedere alla diretta e comandare la luce. Tieni il link privato.
4. In Safari attendi **In diretta**. Premi **Luce tenue · 25%** e controlla che si accenda la torcia del primo iPhone.
5. Per verificare l’accesso fuori casa, lascia la postazione sul Wi-Fi e passa alla rete mobile solo sul secondo iPhone. Mantieni Tailscale connesso e riapri il link.

## Durante la stampa

| Comando | Effetto |
| --- | --- |
| Primo strato · 70% | Illumina il piatto per osservare la deposizione iniziale. |
| Luce tenue · 25% | Riduce la luce per un controllo serale o su superfici riflettenti. |
| Cursore Intensità | Regola la torcia tra 0 e 100%. La disponibilità dipende dal telefono. |
| Spegni | Spegne la torcia mentre continui a vedere le immagini. |
| Oscura interfaccia | Mostra una schermata nera sulla postazione mantenendo PrintCam aperta. Tocca per tornare ai comandi. |
| Ferma telecamera | Interrompe la diretta dalla postazione. |

Per una stampa lunga lascia il telefono alimentato con PrintCam in primo piano. Il tasto laterale blocca iOS e interrompe la ripresa. Puoi chiudere Safari sul secondo telefono e riaprirlo più tardi. La diretta aggiorna immagini JPEG a bassa frequenza. Il pannello controlla la fotocamera e la luce del telefono.

## Se qualcosa non funziona

| Sintomo | Cosa controllare |
| --- | --- |
| Sideloadly non vede l’iPhone | Sbloccalo, verifica che il cavo supporti i dati e autorizza il PC. |
| Safari mostra Segnale assente | Apri PrintCam sulla postazione, riavvia la telecamera e verifica Tailscale su entrambi i telefoni. Con regole personalizzate consenti TCP 8787 fra i due dispositivi. |
| Safari mostra Link scaduto | Condividi di nuovo il link dalla postazione. La chiave cambia quando il processo dell’app riparte. |
| Manca il pulsante per condividere | Avvia la telecamera e verifica l’IPv4 Tailscale inserito. |
| L’app smette di aprirsi dopo una settimana | Rinnova la firma con Sideloadly usando lo stesso account Apple. |

Usa il collegamento Tailscale senza aprire porte sul router. Il server ascolta anche sulle interfacce IPv4 locali e richiede la chiave per accedere a immagini e comandi.

## Demo e compilazione su Mac

Per provare la UI, scarica ed estrai i sorgenti e apri **viewer.html** dal disco in un browser. La demo usa una stampa illustrata e permette di provare i comandi senza collegare i telefoni.

Su Mac installa Xcode e XcodeGen, esegui `xcodegen generate` nella cartella che contiene project.yml e apri PrintCam.xcodeproj. In **Signing & Capabilities** seleziona il tuo team e, se richiesto, imposta un identificatore univoco. Seleziona l’iPhone fisico e premi **Run**.
