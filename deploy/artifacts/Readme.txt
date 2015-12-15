== Cuperativa

Il programma Cuperativa è un software per giocare a carte da soli o
contro il computer. Al momento i giochi sono disponibili sono:
 - Briscola in 2
 - Mariazza
 - Spazzino
 - Scopa
 - Tombolon

== Changelog 

== Versione 0.7.1 (30.06.2009)

- mostra utenti online
- tombolon: distribuisce le carte in modo corretto
- tombolon: chi raggiunge per primo i 31 punti vince
- update via cuperativa server funziona di nuovo
- migliorata la velocità del gioco della mariazza
- briscola: mostra il numero delle carte rimanenti nel mazzo
- online: chat del tavolo sempre visibile


== Versione 0.7.0 (19.05.2009)
- Aggiunto il gioco del Tombolon
- Cambiamenti alla presentazione grafica dei giochi
- Gioco con classifica nella versione online

== Versione 0.6.1 (14.12.2008)
- Aggiunto il gioco della scopa a 2 giocatori(scopetta)
- Aggiornate le animazioni nella mariazza e nella briscola
- Corretti errore nello spazzino sulla presa delle carte

== Versione 0.6.0 (19.11.2008)
- Aggiunto lo spazzino
- Aggiunto la modalità gioco privato online
- Migliorato il layout del programma
- Migliorato l'aggiornamento automatico via server


== Versione 0.5.4 (06.06.2008)
- Migliorato il layout grafico della briscola
- Aggiunto animazioni durante la presa
- Separato il codice sorgente dal file eseguibile
- Ottimizzazione del gioco di una carta
- Feedback quando giocare una carta non è ammesso
- Aggiornamento automatico rapido, online e offline
- BUGFIX: briscola non conosce il pareggio

== Versione 0.5.0
- Aggiunta la briscola in 2
- Migliorata la procedura grafica (flick free) del gioco 

== Versione 0.4.7
- Algoritmo di gioco migliore
- Chat tavolo non finisce quando finisce la partita:
   * Aggiunti nuovi stati per gestire il dopo partita
   * Aggiunti comandi generici client gioco in rete:
      * lascia il tavolo 
      * abbandona gioco 
      * rivincita 
- Icons sui pulsanti di comando
- Opzioni: carte, nomi
- Mazzi di carte: bergamo, milano, napoli, sicilia, treviso
- BUGFIX: Correzione bug algoritmo dichiarazione mariazza di seconda mano
- user name "ricu al satradur" non reso bene nella chat
- Suono inizio partita a richiesta
- Game recorder 
- Unit test
- BUGFIX: viene offerto di cambiare il sette anche quando la briscola non è più in tavola
  in quanto siamo alle ultime 5 carte.
- Miglioria: log Scambio briscola OK _7s -> _As 
- Scambio briscola confermato con la dialogbox
- Redisign della gui:
   * Pulsante connessione
   * Disabilita i tasti Disconnetti e Crea quando non si e' connessi
   * Aggiunta una label in alto come titolo, invece di scrivere sulla titlebar


== Versione 0.4.1
- Gestione automatica del server di rete
- Message box durante il gioco mostrata nel canvas

== Versione 0.3.2
Corretti numerosi errori tra i quali:
- mariazza vale sempre 20 punti, 40 quella di briscola
- carta giocata sovrapposta alla briscola
- mariazza si dichiara solo quando si è di prima mano
Migliorie:
- Tolta la finestra di dos di log nell'exe


== Versione 0.3.1
Prima versione con funzionalità di rete. Eseguibile in formato binario per
windows.

== Versione 0.2.1
Prima versione pubblicata. Stato alpha solo per vedere come potrebbe
funzionare il gioco e l'interfaccia grafica

== FAQ ===
Vedi http://briscola.rubyforge.org


== Autore
Igor Sarzi Sartori

Home del progetto
http://briscola.rubyforge.org
Home:
http://www.invido.it
Email:
6colpiunbucosolo@gmx.net 
